import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/enums.dart';
import '../services/connectivity_service.dart';
import '../services/image_compression_service.dart';
import '../services/offline_storage_service.dart';
import '../services/photo_storage_service.dart';

class StudentPhoto {
  final String id;
  final String studentId;
  final PhotoType photoType;
  final String? localPath;
  final String? remoteStoragePath;
  final int version;
  final SyncState syncState;

  const StudentPhoto({
    required this.id,
    required this.studentId,
    required this.photoType,
    this.localPath,
    this.remoteStoragePath,
    required this.version,
    required this.syncState,
  });

  /// True once there's something to actually display (local file
  /// present, or already uploaded so a signed URL can be fetched).
  bool get hasContent => localPath != null || remoteStoragePath != null;
}

/// Requirement #9 (student photos) implemented offline-first:
/// capture/pick -> compress locally -> save to local DB immediately (so
/// the UI shows it instantly, works with no network) -> upload now if
/// online, else queue for the sync engine.
class StudentPhotoRepository {
  StudentPhotoRepository(
    this._db,
    this._compression,
    this._storage,
    this._connectivity,
  );

  final AppDatabase _db;
  final ImageCompressionService _compression;
  final PhotoStorageService _storage;
  final ConnectivityService _connectivity;
  final _uuid = const Uuid();

  Stream<List<StudentPhoto>> watchPhotosForStudent(String studentId) {
    return _db.watchStudentPhotos(studentId).map((rows) => rows.map(_fromRow).toList());
  }

  /// Returns only the latest (highest version) row per [PhotoType] —
  /// what every screen actually wants to render.
  Stream<Map<PhotoType, StudentPhoto>> watchLatestPhotosByType(String studentId) {
    return watchPhotosForStudent(studentId).map((all) {
      final latest = <PhotoType, StudentPhoto>{};
      for (final photo in all) {
        final current = latest[photo.photoType];
        if (current == null || photo.version > current.version) {
          latest[photo.photoType] = photo;
        }
      }
      return latest;
    });
  }

  Future<String> signedUrlFor(StudentPhoto photo) {
    if (photo.remoteStoragePath == null) {
      throw StateError('Photo has not been uploaded yet.');
    }
    return _storage.signedUrlFor(photo.remoteStoragePath!);
  }

  /// Captures/replaces a photo for [photoType]. Requirement #9: "Any
  /// photo can also be replaced" — a replace creates a new version
  /// rather than overwriting, so history is preserved (requirement #11:
  /// "do not permanently overwrite historical information").
  Future<void> captureAndSave({
    required String schoolId,
    required String studentId,
    required PhotoType photoType,
    required File rawFile,
    String? userId,
  }) async {
    final compressed = await _compression.compressForUpload(rawFile);

    final existing = await (_db.select(_db.studentPhotosTable)
          ..where((t) => t.studentId.equals(studentId) & t.photoType.equals(photoType.dbValue)))
        .get();
    final nextVersion = existing.isEmpty
        ? 1
        : existing.map((e) => e.version).reduce((a, b) => a > b ? a : b) + 1;

    final id = _uuid.v4();
    final online = await _connectivity.isOnline();

    await _db.into(_db.studentPhotosTable).insertOnConflictUpdate(
          StudentPhotosTableCompanion.insert(
            id: id,
            studentId: studentId,
            photoType: photoType.dbValue,
            localPath: drift.Value(compressed.path),
            version: drift.Value(nextVersion),
            syncState: const drift.Value('pendingCreate'),
          ),
        );

    await _db.into(_db.auditLogsTable).insert(
          AuditLogsTableCompanion.insert(
            id: _uuid.v4(),
            schoolId: schoolId,
            userId: drift.Value(userId),
            studentId: drift.Value(studentId),
            action: 'PHOTO_${photoType.dbValue}_ADDED',
            newValueJson: drift.Value(jsonEncode({'version': nextVersion})),
          ),
        );

    final storagePath = _storage.storagePath(
      schoolId: schoolId,
      studentId: studentId,
      photoType: photoType,
      version: nextVersion,
    );

    if (online) {
      try {
        await _storage.upload(storagePath: storagePath, file: compressed);
        await (_db.update(_db.studentPhotosTable)..where((t) => t.id.equals(id))).write(
          StudentPhotosTableCompanion(
            remoteStoragePath: drift.Value(storagePath),
            syncState: const drift.Value('synced'),
          ),
        );
        try {
          OfflineStorageService(_db).exportCurrentStateToStorage();
        } catch (_) {}
        return;
      } catch (_) {
        // Fall through to queueing — network dropped mid-upload.
      }
    }

    await _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            entityType: 'photo',
            entityId: id,
            operation: 'photo_upload',
            payloadJson: jsonEncode({
              'photo_id': id,
              'school_id': schoolId,
              'student_id': studentId,
              'photo_type': photoType.dbValue,
              'version': nextVersion,
              'local_path': compressed.path,
              'storage_path': storagePath,
            }),
          ),
        );
    try {
      OfflineStorageService(_db).exportCurrentStateToStorage();
    } catch (_) {}
  }

  StudentPhoto _fromRow(StudentPhotosTableData row) => StudentPhoto(
        id: row.id,
        studentId: row.studentId,
        photoType: PhotoTypeX.fromDb(row.photoType),
        localPath: row.localPath,
        remoteStoragePath: row.remoteStoragePath,
        version: row.version,
        syncState: SyncState.values.firstWhere((s) => s.name == row.syncState, orElse: () => SyncState.synced),
      );
}
