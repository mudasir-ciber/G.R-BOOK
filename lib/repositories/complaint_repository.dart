import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../features/auth/auth_providers.dart';
import '../models/complaint.dart';
import '../services/connectivity_service.dart';

class ComplaintRepository {
  ComplaintRepository({
    required SupabaseClient client,
    required AppDatabase db,
    required ConnectivityService connectivity,
  })  : _client = client,
        _db = db,
        _connectivity = connectivity;

  final SupabaseClient _client;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final _uuid = const Uuid();

  bool _tableInitialized = false;

  Future<void> _ensureTable() async {
    if (_tableInitialized) return;
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS student_complaints (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        student_name TEXT,
        gr_number TEXT,
        class_name TEXT,
        parent_name TEXT,
        parent_mobile TEXT,
        complaint_text TEXT NOT NULL,
        local_photo_path TEXT,
        remote_photo_url TEXT,
        communication_method TEXT NOT NULL,
        communication_status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_state TEXT NOT NULL DEFAULT 'pendingCreate'
      );
    ''');
    _tableInitialized = true;
  }

  Future<File> compressAndSavePhoto(File rawFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final complaintsDir = Directory(p.join(docsDir.path, 'complaint_photos'));
    if (!await complaintsDir.exists()) {
      await complaintsDir.create(recursive: true);
    }

    final targetPath = p.join(
      complaintsDir.path,
      'complaint_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final compressed = await FlutterImageCompress.compressAndGetFile(
      rawFile.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1200,
      minHeight: 1200,
      format: CompressFormat.jpeg,
    );

    return compressed != null ? File(compressed.path) : rawFile;
  }

  Future<StudentComplaint> createComplaint({
    required String schoolId,
    required String studentId,
    required String studentName,
    required String grNumber,
    required String className,
    required String parentName,
    required String parentMobile,
    required String complaintText,
    File? attachedPhoto,
    required String communicationMethod,
    required String communicationStatus,
  }) async {
    await _ensureTable();

    final complaintId = _uuid.v4();
    final now = DateTime.now();

    String? localPhotoPath;
    if (attachedPhoto != null) {
      final saved = await compressAndSavePhoto(attachedPhoto);
      localPhotoPath = saved.path;
    }

    final complaint = StudentComplaint(
      id: complaintId,
      schoolId: schoolId,
      studentId: studentId,
      studentName: studentName,
      grNumber: grNumber,
      className: className,
      parentName: parentName,
      parentMobile: parentMobile,
      complaintText: complaintText,
      localPhotoPath: localPhotoPath,
      communicationMethod: communicationMethod,
      communicationStatus: communicationStatus,
      createdAt: now,
      syncState: 'pendingCreate',
    );

    await _db.customInsert(
      '''
      INSERT INTO student_complaints (
        id, school_id, student_id, student_name, gr_number, class_name,
        parent_name, parent_mobile, complaint_text, local_photo_path,
        remote_photo_url, communication_method, communication_status,
        created_at, sync_state
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(complaint.id),
        Variable.withString(complaint.schoolId),
        Variable.withString(complaint.studentId),
        Variable.withString(complaint.studentName),
        Variable.withString(complaint.grNumber),
        Variable.withString(complaint.className),
        Variable.withString(complaint.parentName),
        Variable.withString(complaint.parentMobile),
        Variable.withString(complaint.complaintText),
        Variable.withString(complaint.localPhotoPath ?? ''),
        Variable.withString(''),
        Variable.withString(complaint.communicationMethod),
        Variable.withString(complaint.communicationStatus),
        Variable.withString(complaint.createdAt.toIso8601String()),
        Variable.withString(complaint.syncState),
      ],
    );

    // Try online sync in background if online
    _maybeSyncOnline(complaint);

    return complaint;
  }

  Future<void> _maybeSyncOnline(StudentComplaint complaint) async {
    final online = await _connectivity.isOnline();
    if (!online) return;

    try {
      String? remoteUrl;
      if (complaint.localPhotoPath != null && complaint.localPhotoPath!.isNotEmpty) {
        final file = File(complaint.localPhotoPath!);
        if (await file.exists()) {
          final storagePath = '${complaint.schoolId}/complaints/${complaint.id}.jpg';
          await _client.storage.from(AppConfig.studentPhotosBucket).upload(
                storagePath,
                file,
                fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
              );
          remoteUrl = storagePath;
        }
      }

      await _client.from('student_complaints').upsert({
        'id': complaint.id,
        'school_id': complaint.schoolId,
        'student_id': complaint.studentId,
        'student_name': complaint.studentName,
        'gr_number': complaint.grNumber,
        'class_name': complaint.className,
        'parent_name': complaint.parentName,
        'parent_mobile': complaint.parentMobile,
        'complaint_text': complaint.complaintText,
        'remote_photo_url': remoteUrl,
        'communication_method': complaint.communicationMethod,
        'communication_status': complaint.communicationStatus,
        'created_at': complaint.createdAt.toIso8601String(),
      });

      await _db.customUpdate(
        'UPDATE student_complaints SET sync_state = ?, remote_photo_url = ? WHERE id = ?',
        variables: [
          Variable.withString('synced'),
          Variable.withString(remoteUrl ?? ''),
          Variable.withString(complaint.id),
        ],
      );
    } catch (_) {
      // Swallowed — remains pendingCreate in local DB for next sync cycle
    }
  }

  Future<List<StudentComplaint>> getComplaintsForStudent(String studentId) async {
    await _ensureTable();
    final rows = await _db.customSelect(
      'SELECT * FROM student_complaints WHERE student_id = ? ORDER BY created_at DESC',
      variables: [Variable.withString(studentId)],
    ).get();

    return rows.map((r) => StudentComplaint.fromMap(r.data)).toList();
  }

  Stream<List<StudentComplaint>> watchComplaintsForStudent(String studentId) async* {
    await _ensureTable();
    yield* _db
        .customSelect(
          'SELECT * FROM student_complaints WHERE student_id = ? ORDER BY created_at DESC',
          variables: [Variable.withString(studentId)],
        )
        .watch()
        .map((rows) => rows.map((r) => StudentComplaint.fromMap(r.data)).toList());
  }
}

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  return ComplaintRepository(
    client: ref.watch(supabaseClientProvider),
    db: ref.watch(appDatabaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

final studentComplaintsStreamProvider =
    StreamProvider.family<List<StudentComplaint>, String>((ref, studentId) {
  return ref.watch(complaintRepositoryProvider).watchComplaintsForStudent(studentId);
});
