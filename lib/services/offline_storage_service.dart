import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';

class RestoreSummary {
  const RestoreSummary({
    required this.success,
    required this.schoolName,
    required this.classesCount,
    required this.studentsCount,
    required this.photosCount,
    required this.message,
    this.folderPath,
  });

  final bool success;
  final String schoolName;
  final int classesCount;
  final int studentsCount;
  final int photosCount;
  final String message;
  final String? folderPath;
}

/// Service that manages the persistent, public `GR_BOOK` folder on the phone's
/// file manager.
///
/// Features:
/// 1. Completely independent of Supabase — works 100% offline.
/// 2. Creates `GR_BOOK` folder in phone storage (Documents or Download).
/// 3. Exports all school data organized section-wise by class:
///    - `GR_BOOK/classes/<Class_Name>/students.json`
///    - `GR_BOOK/photos/` (keeps physical copies safe from app uninstall)
///    - `GR_BOOK/gr_book_complete_backup.json`
/// 4. Restores all records seamlessly when app is reinstalled or when user taps "Add Data".
class OfflineStorageService {
  OfflineStorageService(this._db);

  final AppDatabase _db;

  static const String rootFolderName = 'GR_BOOK';

  /// Resolves the persistent public folder where records survive app uninstallation.
  Future<Directory> getOrCreateGrBookDir() async {
    Directory? targetDir;

    if (Platform.isAndroid) {
      final candidates = [
        Directory('/storage/emulated/0/Documents/$rootFolderName'),
        Directory('/storage/emulated/0/Download/$rootFolderName'),
        Directory('/storage/emulated/0/$rootFolderName'),
      ];

      for (final candidate in candidates) {
        try {
          if (!await candidate.exists()) {
            await candidate.create(recursive: true);
          }
          // Test write permissions
          final testFile = File(p.join(candidate.path, '.test_gr_probe'));
          await testFile.writeAsString('gr_probe');
          await testFile.delete();
          targetDir = candidate;
          break;
        } catch (_) {
          continue;
        }
      }
    }

    if (targetDir == null) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final candidate = Directory(p.join(extDir.path, rootFolderName));
          if (!await candidate.exists()) {
            await candidate.create(recursive: true);
          }
          targetDir = candidate;
        }
      } catch (_) {}
    }

    if (targetDir == null) {
      final appDocs = await getApplicationDocumentsDirectory();
      targetDir = Directory(p.join(appDocs.path, rootFolderName));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
    }

    // Ensure subdirectories exist
    final classesDir = Directory(p.join(targetDir.path, 'classes'));
    if (!await classesDir.exists()) await classesDir.create(recursive: true);

    final photosDir = Directory(p.join(targetDir.path, 'photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);

    final exportsDir = Directory(p.join(targetDir.path, 'exports'));
    if (!await exportsDir.exists()) await exportsDir.create(recursive: true);

    return targetDir;
  }

  /// Exports current database state section-wise into the phone's `GR_BOOK` directory.
  Future<String> exportCurrentStateToStorage() async {
    try {
      final grDir = await getOrCreateGrBookDir();
      final schools = await _db.select(_db.schoolsTable).get();
      if (schools.isEmpty) return grDir.path;

      final school = schools.first;
      final schoolId = school.id;

      final classes = await (_db.select(_db.classesTable)..where((t) => t.schoolId.equals(schoolId))).get();
      final students = await (_db.select(_db.studentsTable)..where((t) => t.schoolId.equals(schoolId) & t.isDeleted.equals(false))).get();
      final photos = await _db.select(_db.studentPhotosTable).get();
      final promoBatches = await (_db.select(_db.promotionBatchesTable)..where((t) => t.schoolId.equals(schoolId))).get();
      final promoRecords = await _db.select(_db.promotionRecordsTable).get();
      final struckOff = await (_db.select(_db.struckOffRecordsTable)..where((t) => t.schoolId.equals(schoolId))).get();
      final passOutYears = await (_db.select(_db.passOutYearsTable)..where((t) => t.schoolId.equals(schoolId))).get();

      // Read complaints if table exists
      List<Map<String, dynamic>> complaints = [];
      try {
        final rows = await _db.customSelect('SELECT * FROM student_complaints').get();
        complaints = rows.map((r) => r.data).toList();
      } catch (_) {}

      Map<String, dynamic> studentToExportMap(StudentsTableData s) {
        final m = Map<String, dynamic>.from(s.toJson());
        final dobStr = s.dateOfBirth.toIso8601String().split('T').first;
        final doaStr = s.dateOfAdmission.toIso8601String().split('T').first;
        m['dateOfBirth'] = dobStr;
        m['date_of_birth'] = dobStr;
        m['dob'] = dobStr;
        m['dateOfAdmission'] = doaStr;
        m['date_of_admission'] = doaStr;
        m['admission'] = doaStr;
        if (s.struckOffDate != null) {
          final soStr = s.struckOffDate!.toIso8601String().split('T').first;
          m['struckOffDate'] = soStr;
          m['struck_off_date'] = soStr;
        }
        return m;
      }

      // 1. Write full complete backup JSON (for one-tap restore)
      final fullPayload = {
        'backup_version': 2,
        'app_name': 'G.R BOOK',
        'creator': 'Mudasir Ahmed Ghanghro',
        'generated_at': DateTime.now().toIso8601String(),
        'school_id': schoolId,
        'school': school.toJson(),
        'classes': classes.map((c) => c.toJson()).toList(),
        'students': students.map(studentToExportMap).toList(),
        'photos': photos.map((p) => p.toJson()).toList(),
        'promotion_batches': promoBatches.map((b) => b.toJson()).toList(),
        'promotion_records': promoRecords.map((r) => r.toJson()).toList(),
        'struck_off_records': struckOff.map((r) => r.toJson()).toList(),
        'pass_out_years': passOutYears.map((y) => y.toJson()).toList(),
        'complaints': complaints,
      };

      final backupFile = File(p.join(grDir.path, 'gr_book_complete_backup.json'));
      await backupFile.writeAsString(const JsonEncoder.withIndent('  ').convert(fullPayload));

      // 2. Write School Profile Info
      final schoolFile = File(p.join(grDir.path, 'school_profile.json'));
      await schoolFile.writeAsString(const JsonEncoder.withIndent('  ').convert(school.toJson()));

      // 3. Write section-wise class folders
      final classesDir = Directory(p.join(grDir.path, 'classes'));
      for (final cls in classes) {
        final safeName = cls.displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
        final classFolder = Directory(p.join(classesDir.path, safeName));
        if (!await classFolder.exists()) {
          await classFolder.create(recursive: true);
        }

        final classStudents = students.where((s) => s.classId == cls.id).toList();
        final classData = {
          'class_id': cls.id,
          'class_name': cls.displayName,
          'class_code': cls.classCode,
          'student_count': classStudents.length,
          'updated_at': DateTime.now().toIso8601String(),
          'students': classStudents.map(studentToExportMap).toList(),
        };

        final classFile = File(p.join(classFolder.path, 'students.json'));
        await classFile.writeAsString(const JsonEncoder.withIndent('  ').convert(classData));
      }

      // 4. Copy student photos into GR_BOOK/photos folder so they survive app uninstall
      final photosDir = Directory(p.join(grDir.path, 'photos'));
      for (final photo in photos) {
        if (photo.localPath != null && photo.localPath!.isNotEmpty) {
          final srcFile = File(photo.localPath!);
          if (await srcFile.exists()) {
            final ext = p.extension(photo.localPath!).isNotEmpty ? p.extension(photo.localPath!) : '.jpg';
            final targetName = 'photo_${photo.studentId}_${photo.photoType}$ext';
            final destFile = File(p.join(photosDir.path, targetName));
            try {
              if (!await destFile.exists() || (await destFile.length()) != (await srcFile.length())) {
                await srcFile.copy(destFile.path);
              }
            } catch (_) {}
          }
        }
      }

      return grDir.path;
    } catch (e) {
      debugPrint('Error exporting to offline storage: $e');
      rethrow;
    }
  }

  /// Restores database from a selected `GR_BOOK` directory or JSON file.
  Future<RestoreSummary> restoreFromStorageFolder({String? customPath}) async {
    try {
      File? targetBackupFile;
      Directory? grDir;

      if (customPath != null && customPath.isNotEmpty) {
        final f = File(customPath);
        final d = Directory(customPath);
        if (await f.exists()) {
          targetBackupFile = f;
          grDir = f.parent;
        } else if (await d.exists()) {
          grDir = d;
          final candidate = File(p.join(d.path, 'gr_book_complete_backup.json'));
          if (await candidate.exists()) {
            targetBackupFile = candidate;
          }
        }
      }

      if (targetBackupFile == null) {
        grDir = await getOrCreateGrBookDir();
        final candidate = File(p.join(grDir.path, 'gr_book_complete_backup.json'));
        if (await candidate.exists()) {
          targetBackupFile = candidate;
        }
      }

      if (targetBackupFile == null || !await targetBackupFile.exists()) {
        return RestoreSummary(
          success: false,
          schoolName: '',
          classesCount: 0,
          studentsCount: 0,
          photosCount: 0,
          message: 'No "gr_book_complete_backup.json" found in ${grDir?.path ?? "storage"}.',
          folderPath: grDir?.path,
        );
      }

      final jsonStr = await targetBackupFile.readAsString();
      final payload = jsonDecode(jsonStr) as Map<String, dynamic>;

  int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  bool _parseBool(dynamic val, {bool fallback = false}) {
    if (val == null) return fallback;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val.toLowerCase() == 'true' || val == '1';
    return fallback;
  }

  DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is int) {
      if (val > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val > 1000000000) return DateTime.fromMillisecondsSinceEpoch(val * 1000);
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    if (val is num) {
      final i = val.toInt();
      if (i > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(i);
      if (i > 1000000000) return DateTime.fromMillisecondsSinceEpoch(i * 1000);
      return DateTime.fromMillisecondsSinceEpoch(i);
    }
    if (val is String) {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return null;
      final iso = DateTime.tryParse(trimmed);
      if (iso != null) return iso;
      final asInt = int.tryParse(trimmed);
      if (asInt != null) {
        if (asInt > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(asInt);
        if (asInt > 1000000000) return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
      }
      for (final pattern in const ['dd-MM-yyyy', 'dd/MM/yyyy', 'd-M-yyyy', 'd/M/yyyy', 'yyyy-MM-dd', 'yyyy/MM/dd']) {
        try {
          return DateFormat(pattern).parseStrict(trimmed);
        } catch (_) {}
      }
    }
    return null;
  }

      // 1. Restore School
      final schoolMap = payload['school'] as Map<String, dynamic>?;
      if (schoolMap == null) {
        return const RestoreSummary(
          success: false,
          schoolName: '',
          classesCount: 0,
          studentsCount: 0,
          photosCount: 0,
          message: 'Backup file is missing school profile.',
        );
      }

      final schoolName = schoolMap['schoolName']?.toString() ?? 'Restored School';
      await _db.into(_db.schoolsTable).insertOnConflictUpdate(
            SchoolsTableCompanion.insert(
              id: schoolMap['id'].toString(),
              schoolName: schoolName,
              semisCode: drift.Value(schoolMap['semisCode']?.toString()),
              uc: drift.Value(schoolMap['uc']?.toString()),
              taluka: drift.Value(schoolMap['taluka']?.toString()),
              district: drift.Value(schoolMap['district']?.toString()),
              createdBy: schoolMap['createdBy']?.toString() ?? 'local_admin',
              createdAt: _parseDateTime(schoolMap['createdAt']) ?? DateTime.now(),
              updatedAt: _parseDateTime(schoolMap['updatedAt']) ?? DateTime.now(),
            ),
          );

      // 2. Restore Classes
      final classList = (payload['classes'] as List?) ?? [];
      for (final item in classList) {
        final c = item as Map<String, dynamic>;
        await _db.into(_db.classesTable).insertOnConflictUpdate(
              ClassesTableCompanion.insert(
                id: c['id'].toString(),
                schoolId: c['schoolId'].toString(),
                classCode: c['classCode'].toString(),
                displayName: c['displayName'].toString(),
                sortOrder: drift.Value(_parseInt(c['sortOrder']) ?? 0),
                minAdmissionAgeMonths: drift.Value(_parseInt(c['minAdmissionAgeMonths'])),
                minPromotionAgeMonths: drift.Value(_parseInt(c['minPromotionAgeMonths'])),
                promotesToClassId: drift.Value(c['promotesToClassId']?.toString()),
                isTerminal: drift.Value(_parseBool(c['isTerminal'], fallback: false)),
                isActive: drift.Value(_parseBool(c['isActive'], fallback: true)),
              ),
            );
      }

      // 3. Restore Students
      final studentList = (payload['students'] as List?) ?? [];
      for (final item in studentList) {
        final s = item as Map<String, dynamic>;
        final studentId = s['id'].toString();
        final existingStudent = await (_db.select(_db.studentsTable)..where((t) => t.id.equals(studentId))).getSingleOrNull();

        final parsedDob = _parseDateTime(s['dateOfBirth'] ?? s['date_of_birth'] ?? s['dob']);
        final parsedDoa = _parseDateTime(s['dateOfAdmission'] ?? s['date_of_admission'] ?? s['admission']);

        // Preserve existing DOB from local DB if backup doesn't have a parseable date, NEVER overwrite with today's date!
        final finalDob = parsedDob ?? existingStudent?.dateOfBirth ?? DateTime(DateTime.now().year - 6, 1, 1);
        final finalDoa = parsedDoa ?? existingStudent?.dateOfAdmission ?? DateTime.now();

        await _db.into(_db.studentsTable).insertOnConflictUpdate(
              StudentsTableCompanion.insert(
                id: studentId,
                clientGeneratedId: (s['clientGeneratedId'] ?? s['id']).toString(),
                schoolId: s['schoolId'].toString(),
                classId: s['classId'].toString(),
                grNumber: s['grNumber'].toString(),
                serialNumber: drift.Value(_parseInt(s['serialNumber'])),
                studentName: s['studentName'].toString(),
                fatherName: drift.Value(s['fatherName']?.toString()),
                motherName: drift.Value(s['motherName']?.toString()),
                dateOfBirth: finalDob,
                dateOfAdmission: finalDoa,
                fatherCnic: drift.Value(s['fatherCnic']?.toString()),
                bFormNumber: drift.Value(s['bFormNumber']?.toString()),
                phoneNumber: drift.Value(s['phoneNumber']?.toString()),
                address: drift.Value(s['address']?.toString()),
                previousSchool: drift.Value(s['previousSchool']?.toString()),
                remarks: drift.Value(s['remarks']?.toString()),
                status: drift.Value(s['status']?.toString() ?? 'ACTIVE'),
                promotionStatus: drift.Value(s['promotionStatus']?.toString() ?? 'NONE'),
                struckOffDate: drift.Value(_parseDateTime(s['struckOffDate'] ?? s['struck_off_date'])),
                struckOffReason: drift.Value(s['struckOffReason']?.toString()),
                passOutYear: drift.Value(_parseInt(s['passOutYear'])),
                version: drift.Value(_parseInt(s['version']) ?? 1),
                updatedAt: _parseDateTime(s['updatedAt']) ?? DateTime.now(),
                createdAt: _parseDateTime(s['createdAt']) ?? DateTime.now(),
                createdBy: drift.Value(s['createdBy']?.toString()),
                updatedBy: drift.Value(s['updatedBy']?.toString()),
                isDeleted: drift.Value(_parseBool(s['isDeleted'], fallback: false)),
                syncState: const drift.Value('synced'),
              ),
            );
      }

      // 4. Restore Photos and map to preserved files in GR_BOOK/photos
      final photoList = (payload['photos'] as List?) ?? [];
      final photosDir = grDir != null ? Directory(p.join(grDir.path, 'photos')) : null;
      int photosRestored = 0;

      for (final item in photoList) {
        final pItem = item as Map<String, dynamic>;
        String? resolvedLocalPath = pItem['localPath']?.toString();

        // If localPath doesn't exist anymore (e.g. after uninstall), resolve from GR_BOOK/photos
        if (resolvedLocalPath == null || !File(resolvedLocalPath).existsSync()) {
          if (photosDir != null && await photosDir.exists()) {
            final expectedFileName = 'photo_${pItem['studentId']}_${pItem['photoType']}.jpg';
            final candidate = File(p.join(photosDir.path, expectedFileName));
            if (await candidate.exists()) {
              resolvedLocalPath = candidate.path;
            }
          }
        }

        await _db.into(_db.studentPhotosTable).insertOnConflictUpdate(
              StudentPhotosTableCompanion.insert(
                id: pItem['id'].toString(),
                studentId: pItem['studentId'].toString(),
                photoType: pItem['photoType'].toString(),
                localPath: drift.Value(resolvedLocalPath),
                remoteStoragePath: drift.Value(pItem['remoteStoragePath']?.toString()),
                version: drift.Value(_parseInt(pItem['version']) ?? 1),
                syncState: const drift.Value('synced'),
                createdAt: drift.Value(_parseDateTime(pItem['createdAt']) ?? DateTime.now()),
              ),
            );
        if (resolvedLocalPath != null && File(resolvedLocalPath).existsSync()) {
          photosRestored++;
        }
      }

      // 5. Restore Pass Out Years
      final passOutYears = (payload['pass_out_years'] as List?) ?? [];
      for (final item in passOutYears) {
        final y = item as Map<String, dynamic>;
        final yVal = _parseInt(y['year']) ?? DateTime.now().year;
        await _db.into(_db.passOutYearsTable).insertOnConflictUpdate(
              PassOutYearsTableCompanion.insert(
                id: y['id'].toString(),
                schoolId: y['schoolId'].toString(),
                year: yVal,
                createdAt: drift.Value(_parseDateTime(y['createdAt']) ?? DateTime.now()),
                syncState: const drift.Value('synced'),
              ),
            );
      }

      // 6. Restore Struck Off Records
      final struckOffList = (payload['struck_off_records'] as List?) ?? [];
      for (final item in struckOffList) {
        final so = item as Map<String, dynamic>;
        await _db.into(_db.struckOffRecordsTable).insertOnConflictUpdate(
              StruckOffRecordsTableCompanion.insert(
                id: so['id'].toString(),
                schoolId: so['schoolId'].toString(),
                studentId: so['studentId'].toString(),
                struckOffDate: _parseDateTime(so['struckOffDate']) ?? DateTime.now(),
                reason: so['reason']?.toString() ?? 'Struck Off',
                reAdmitted: drift.Value(_parseBool(so['reAdmitted'], fallback: false)),
                reAdmittedDate: drift.Value(_parseDateTime(so['reAdmittedDate'])),
                reAdmittedBy: drift.Value(so['reAdmittedBy']?.toString()),
                createdBy: drift.Value(so['createdBy']?.toString()),
                createdAt: drift.Value(_parseDateTime(so['createdAt']) ?? DateTime.now()),
                syncState: const drift.Value('synced'),
              ),
            );
      }

      return RestoreSummary(
        success: true,
        schoolName: schoolName,
        classesCount: classList.length,
        studentsCount: studentList.length,
        photosCount: photosRestored,
        message: 'Successfully restored $schoolName with ${studentList.length} students and ${classList.length} classes.',
        folderPath: grDir?.path,
      );
    } catch (e) {
      debugPrint('Error restoring from offline storage: $e');
      return RestoreSummary(
        success: false,
        schoolName: '',
        classesCount: 0,
        studentsCount: 0,
        photosCount: 0,
        message: 'Restore failed: $e',
      );
    }
  }
}
