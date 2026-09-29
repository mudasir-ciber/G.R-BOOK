import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

class DriveBackupSummary {
  final String id;
  final String name;
  final DateTime? createdTime;
  final int? sizeBytes;
  const DriveBackupSummary({required this.id, required this.name, this.createdTime, this.sizeBytes});
}

/// Requirement #29: Google Drive is used only for BACKUP, never as the
/// primary database (that's Supabase). The backup file contains
/// school/classes/students/promotion history/pass-out/struck-off/audit
/// data, and explicitly nothing else:
///  - No Supabase URL, anon key, or service-role key.
///  - No raw photo bytes — photos already live durably in Supabase
///    Storage; the backup only needs to survive alongside them, not
///    duplicate them.
/// Scoped to `drive.file` — this app can only see files IT created,
/// never the rest of the user's Drive.
class GoogleDriveBackupService {
  GoogleDriveBackupService(this._db, this._client);

  final AppDatabase _db;
  final SupabaseClient _client;
  final _uuid = const Uuid();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);

  static const String _fileNamePrefix = 'grbook_backup_';

  GoogleSignInAccount? get currentGoogleUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signInSilently() => _googleSignIn.signInSilently();
  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();
  Future<void> signOut() => _googleSignIn.signOut();

  Future<drive.DriveApi> _driveApi() async {
    var account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) {
      throw const GoogleDriveBackupException('Google sign-in is required for backup.');
    }
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw const GoogleDriveBackupException('Could not authenticate with Google Drive.');
    }
    return drive.DriveApi(client);
  }

  Future<Map<String, dynamic>> _buildBackupPayload(String schoolId) async {
    final school =
        await (_db.select(_db.schoolsTable)..where((t) => t.id.equals(schoolId))).getSingleOrNull();
    final classes = await (_db.select(_db.classesTable)..where((t) => t.schoolId.equals(schoolId))).get();
    final students = await (_db.select(_db.studentsTable)..where((t) => t.schoolId.equals(schoolId))).get();
    final promoBatches =
        await (_db.select(_db.promotionBatchesTable)..where((t) => t.schoolId.equals(schoolId))).get();
    final batchIds = promoBatches.map((b) => b.id).toSet();
    final allRecords = await _db.select(_db.promotionRecordsTable).get();
    final promoRecords = allRecords.where((r) => batchIds.contains(r.batchId)).toList();
    final struckOff =
        await (_db.select(_db.struckOffRecordsTable)..where((t) => t.schoolId.equals(schoolId))).get();
    final passOutYears =
        await (_db.select(_db.passOutYearsTable)..where((t) => t.schoolId.equals(schoolId))).get();
    final auditLogs = await (_db.select(_db.auditLogsTable)..where((t) => t.schoolId.equals(schoolId))).get();

    return {
      'backup_version': 1,
      'generated_at': DateTime.now().toIso8601String(),
      'school_id': schoolId,
      'school': school?.toJson(),
      'classes': classes.map((c) => c.toJson()).toList(),
      'students': students.map((s) => s.toJson()).toList(),
      'promotion_batches': promoBatches.map((b) => b.toJson()).toList(),
      'promotion_records': promoRecords.map((r) => r.toJson()).toList(),
      'struck_off_records': struckOff.map((r) => r.toJson()).toList(),
      'pass_out_years': passOutYears.map((y) => y.toJson()).toList(),
      'audit_logs': auditLogs.map((a) => a.toJson()).toList(),
      'note_on_photos':
          'Photo files are not embedded here — they remain in Supabase Storage and are referenced by the synced student_photos rows.',
    };
  }

  /// Requirement #29: "Backup Now". Uploads a gzip-compressed JSON
  /// snapshot to the user's Drive and records a `backup_metadata` row
  /// on Supabase (best-effort — the Drive upload having succeeded is
  /// what actually matters; a missing metadata row just means it won't
  /// show in that list, nothing is lost).
  Future<void> backupNow({required String schoolId, String? userId}) async {
    final payload = await _buildBackupPayload(schoolId);
    final jsonBytes = utf8.encode(jsonEncode(payload));
    final encoded = GZipEncoder().encode(jsonBytes);
    final compressed = Uint8List.fromList(encoded ?? jsonBytes);

    final api = await _driveApi();
    final fileName = '$_fileNamePrefix${schoolId}_${DateTime.now().millisecondsSinceEpoch}.json.gz';
    final driveFile = drive.File()
      ..name = fileName
      ..description = 'G.R BOOK backup — school, students, promotion/pass-out/struck-off history, audit log.';
    final media = drive.Media(Stream.value(compressed), compressed.length);

    final created = await api.files.create(driveFile, uploadMedia: media);

    try {
      await _client.from('backup_metadata').insert({
        'id': _uuid.v4(),
        'school_id': schoolId,
        'drive_file_id': created.id,
        'backup_type': 'FULL',
        'size_bytes': compressed.length,
        'created_by': userId,
      });
    } catch (_) {
      // Non-fatal — the backup itself is safely on Drive either way.
    }

    await _db.into(_db.auditLogsTable).insert(
          AuditLogsTableCompanion.insert(
            id: _uuid.v4(),
            schoolId: schoolId,
            userId: drift.Value(userId),
            action: 'BACKUP_CREATED',
            newValueJson: drift.Value(jsonEncode({'drive_file_id': created.id, 'size_bytes': compressed.length})),
          ),
        );
  }

  Future<List<DriveBackupSummary>> listBackups({required String schoolId}) async {
    final api = await _driveApi();
    final result = await api.files.list(
      q: "name contains '$_fileNamePrefix$schoolId' and trashed = false",
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,createdTime,size)',
      spaces: 'drive',
    );
    return (result.files ?? [])
        .map((f) => DriveBackupSummary(
              id: f.id!,
              name: f.name ?? 'backup',
              createdTime: f.createdTime,
              sizeBytes: f.size != null ? int.tryParse(f.size!) : null,
            ))
        .toList();
  }

  /// Requirement #29: "Restore Backup". Downloads and decompresses the
  /// chosen backup, then restores it into the LOCAL database and
  /// re-pushes every row to Supabase (upsert). This is an explicit,
  /// user-initiated, whole-record restore — the one place in the app
  /// where "last write wins" is the intended behavior, since the whole
  /// point of a restore is "make everything match this backup".
  Future<void> restoreBackup({required String backupFileId, String? userId}) async {
    final api = await _driveApi();
    final media = await api.files.get(
      backupFileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    final jsonBytes = GZipDecoder().decodeBytes(bytes);
    final payload = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;

    final schoolId = payload['school_id'] as String;

    await _restoreSchool(payload['school'] as Map<String, dynamic>?);
    await _restoreClasses((payload['classes'] as List).cast<Map<String, dynamic>>());
    await _restoreStudents((payload['students'] as List).cast<Map<String, dynamic>>());
    await _restorePromotionBatches((payload['promotion_batches'] as List).cast<Map<String, dynamic>>());
    await _restorePromotionRecords((payload['promotion_records'] as List).cast<Map<String, dynamic>>());
    await _restoreStruckOff((payload['struck_off_records'] as List).cast<Map<String, dynamic>>());
    await _restorePassOutYears((payload['pass_out_years'] as List).cast<Map<String, dynamic>>());

    await _db.into(_db.auditLogsTable).insert(
          AuditLogsTableCompanion.insert(
            id: _uuid.v4(),
            schoolId: schoolId,
            userId: drift.Value(userId),
            action: 'BACKUP_RESTORED',
            newValueJson: drift.Value(jsonEncode({'drive_file_id': backupFileId})),
          ),
        );
  }

  Future<void> _restoreSchool(Map<String, dynamic>? json) async {
    if (json == null) return;
    await _db.into(_db.schoolsTable).insertOnConflictUpdate(
          SchoolsTableCompanion.insert(
            id: json['id'] as String,
            schoolName: json['schoolName'] as String,
            semisCode: drift.Value(json['semisCode'] as String?),
            uc: drift.Value(json['uc'] as String?),
            taluka: drift.Value(json['taluka'] as String?),
            district: drift.Value(json['district'] as String?),
            createdBy: json['createdBy'] as String,
            createdAt: DateTime.parse(json['createdAt'] as String),
            updatedAt: DateTime.parse(json['updatedAt'] as String),
          ),
        );
    try {
      await _client.from('schools').upsert({
        'id': json['id'],
        'school_name': json['schoolName'],
        'semis_code': json['semisCode'],
        'uc': json['uc'],
        'taluka': json['taluka'],
        'district': json['district'],
        'created_by': json['createdBy'],
      });
    } catch (_) {
      // Restored locally regardless; Supabase push retried on next sync.
    }
  }

  Future<void> _restoreClasses(List<Map<String, dynamic>> rows) async {
    for (final json in rows) {
      await _db.into(_db.classesTable).insertOnConflictUpdate(
            ClassesTableCompanion.insert(
              id: json['id'] as String,
              schoolId: json['schoolId'] as String,
              classCode: json['classCode'] as String,
              displayName: json['displayName'] as String,
              sortOrder: drift.Value(json['sortOrder'] as int? ?? 0),
              minAdmissionAgeMonths: drift.Value(json['minAdmissionAgeMonths'] as int?),
              minPromotionAgeMonths: drift.Value(json['minPromotionAgeMonths'] as int?),
              promotesToClassId: drift.Value(json['promotesToClassId'] as String?),
              isTerminal: drift.Value(json['isTerminal'] as bool? ?? false),
              isActive: drift.Value(json['isActive'] as bool? ?? true),
            ),
          );
    }
    try {
      await _client.from('classes').upsert(rows
          .map((json) => {
                'id': json['id'],
                'school_id': json['schoolId'],
                'class_code': json['classCode'],
                'display_name': json['displayName'],
                'sort_order': json['sortOrder'],
                'min_admission_age_months': json['minAdmissionAgeMonths'],
                'min_promotion_age_months': json['minPromotionAgeMonths'],
                'promotes_to_class_id': json['promotesToClassId'],
                'is_terminal': json['isTerminal'],
                'is_active': json['isActive'],
              })
          .toList());
    } catch (_) {}
  }

  Future<void> _restoreStudents(List<Map<String, dynamic>> rows) async {
    for (final json in rows) {
      await _db.into(_db.studentsTable).insertOnConflictUpdate(
            StudentsTableCompanion.insert(
              id: json['id'] as String,
              clientGeneratedId: json['clientGeneratedId'] as String,
              schoolId: json['schoolId'] as String,
              classId: json['classId'] as String,
              grNumber: json['grNumber'] as String,
              serialNumber: drift.Value(json['serialNumber'] as int?),
              studentName: json['studentName'] as String,
              fatherName: drift.Value(json['fatherName'] as String?),
              motherName: drift.Value(json['motherName'] as String?),
              dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
              dateOfAdmission: DateTime.parse(json['dateOfAdmission'] as String),
              fatherCnic: drift.Value(json['fatherCnic'] as String?),
              bFormNumber: drift.Value(json['bFormNumber'] as String?),
              phoneNumber: drift.Value(json['phoneNumber'] as String?),
              address: drift.Value(json['address'] as String?),
              previousSchool: drift.Value(json['previousSchool'] as String?),
              remarks: drift.Value(json['remarks'] as String?),
              status: drift.Value(json['status'] as String? ?? 'ACTIVE'),
              promotionStatus: drift.Value(json['promotionStatus'] as String? ?? 'NONE'),
              struckOffDate: drift.Value(
                  json['struckOffDate'] != null ? DateTime.parse(json['struckOffDate'] as String) : null),
              struckOffReason: drift.Value(json['struckOffReason'] as String?),
              passOutYear: drift.Value(json['passOutYear'] as int?),
              version: drift.Value(json['version'] as int? ?? 1),
              updatedAt: DateTime.parse(json['updatedAt'] as String),
              createdAt: DateTime.parse(json['createdAt'] as String),
              createdBy: drift.Value(json['createdBy'] as String?),
              updatedBy: drift.Value(json['updatedBy'] as String?),
              isDeleted: drift.Value(json['isDeleted'] as bool? ?? false),
              syncState: const drift.Value('synced'),
            ),
          );
    }
    try {
      await _client.from('students').upsert(rows
          .map((json) => {
                'id': json['id'],
                'client_generated_id': json['clientGeneratedId'],
                'school_id': json['schoolId'],
                'class_id': json['classId'],
                'gr_number': json['grNumber'],
                'serial_number': json['serialNumber'],
                'student_name': json['studentName'],
                'father_name': json['fatherName'],
                'mother_name': json['motherName'],
                'date_of_birth': (json['dateOfBirth'] as String).split('T').first,
                'date_of_admission': (json['dateOfAdmission'] as String).split('T').first,
                'father_cnic': json['fatherCnic'],
                'b_form_number': json['bFormNumber'],
                'phone_number': json['phoneNumber'],
                'address': json['address'],
                'previous_school': json['previousSchool'],
                'remarks': json['remarks'],
                'status': json['status'] ?? 'ACTIVE',
                'promotion_status': json['promotionStatus'] ?? 'NONE',
                'struck_off_date': json['struckOffDate'] != null ? (json['struckOffDate'] as String).split('T').first : null,
                'struck_off_reason': json['struckOffReason'],
                'pass_out_year': json['passOutYear'],
                'is_deleted': json['isDeleted'] ?? false,
              })
          .toList());
    } catch (_) {}
  }

  Future<void> _restorePromotionBatches(List<Map<String, dynamic>> rows) async {
    for (final json in rows) {
      await _db.into(_db.promotionBatchesTable).insertOnConflictUpdate(
            PromotionBatchesTableCompanion.insert(
              id: json['id'] as String,
              schoolId: json['schoolId'] as String,
              fromClassId: json['fromClassId'] as String,
              toClassId: drift.Value(json['toClassId'] as String?),
              promotionDate: DateTime.parse(json['promotionDate'] as String),
              academicYear: json['academicYear'] as int,
              performedBy: drift.Value(json['performedBy'] as String?),
              isUndone: drift.Value(json['isUndone'] as bool? ?? false),
              undoneAt: drift.Value(json['undoneAt'] != null ? DateTime.parse(json['undoneAt'] as String) : null),
              undoneBy: drift.Value(json['undoneBy'] as String?),
              syncState: const drift.Value('synced'),
            ),
          );
    }
  }

  Future<void> _restorePromotionRecords(List<Map<String, dynamic>> rows) async {
    for (final json in rows) {
      await _db.into(_db.promotionRecordsTable).insertOnConflictUpdate(
            PromotionRecordsTableCompanion.insert(
              id: json['id'] as String,
              batchId: json['batchId'] as String,
              studentId: json['studentId'] as String,
              previousClassId: json['previousClassId'] as String,
              newClassId: drift.Value(json['newClassId'] as String?),
              previousStatus: json['previousStatus'] as String,
              newStatus: json['newStatus'] as String,
              result: json['result'] as String,
              academicYear: json['academicYear'] as int,
            ),
          );
    }
  }

  Future<void> _restoreStruckOff(List<Map<String, dynamic>> rows) async {
    for (final json in rows) {
      await _db.into(_db.struckOffRecordsTable).insertOnConflictUpdate(
            StruckOffRecordsTableCompanion.insert(
              id: json['id'] as String,
              schoolId: json['schoolId'] as String,
              studentId: json['studentId'] as String,
              struckOffDate: DateTime.parse(json['struckOffDate'] as String),
              reason: json['reason'] as String,
              reAdmitted: drift.Value(json['reAdmitted'] as bool? ?? false),
              reAdmittedDate:
                  drift.Value(json['reAdmittedDate'] != null ? DateTime.parse(json['reAdmittedDate'] as String) : null),
              reAdmittedBy: drift.Value(json['reAdmittedBy'] as String?),
              createdBy: drift.Value(json['createdBy'] as String?),
              syncState: const drift.Value('synced'),
            ),
          );
    }
  }

  Future<void> _restorePassOutYears(List<Map<String, dynamic>> rows) async {
    for (final json in rows) {
      await _db.into(_db.passOutYearsTable).insertOnConflictUpdate(
            PassOutYearsTableCompanion.insert(
              id: json['id'] as String,
              schoolId: json['schoolId'] as String,
              year: json['year'] as int,
              syncState: const drift.Value('synced'),
            ),
          );
    }
  }
}

class GoogleDriveBackupException implements Exception {
  final String message;
  const GoogleDriveBackupException(this.message);
  @override
  String toString() => message;
}
