import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
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

      // 1. Write full complete backup JSON (for one-tap restore)
      final fullPayload = {
        'backup_version': 2,
        'app_name': 'G.R. Book',
        'creator': 'Mudasir Ahmed Ghanghro',
        'generated_at': DateTime.now().toIso8601String(),
        'school_id': schoolId,
        'school': school.toJson(),
        'classes': classes.map((c) => c.toJson()).toList(),
        'students': students.map((s) => s.toJson()).toList(),
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
          'students': classStudents.map((s) => s.toJson()).toList(),
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

      final schoolName = schoolMap['schoolName'] as String? ?? 'Restored School';
      await _db.into(_db.schoolsTable).insertOnConflictUpdate(
            SchoolsTableCompanion.insert(
              id: schoolMap['id'] as String,
              schoolName: schoolName,
              semisCode: drift.Value(schoolMap['semisCode'] as String?),
              uc: drift.Value(schoolMap['uc'] as String?),
              taluka: drift.Value(schoolMap['taluka'] as String?),
              district: drift.Value(schoolMap['district'] as String?),
              createdBy: schoolMap['createdBy'] as String? ?? 'local_admin',
              createdAt: schoolMap['createdAt'] != null ? DateTime.parse(schoolMap['createdAt'] as String) : DateTime.now(),
              updatedAt: schoolMap['updatedAt'] != null ? DateTime.parse(schoolMap['updatedAt'] as String) : DateTime.now(),
            ),
          );

      // 2. Restore Classes
      final classList = (payload['classes'] as List?) ?? [];
      for (final item in classList) {
        final c = item as Map<String, dynamic>;
        await _db.into(_db.classesTable).insertOnConflictUpdate(
              ClassesTableCompanion.insert(
                id: c['id'] as String,
                schoolId: c['schoolId'] as String,
                classCode: c['classCode'] as String,
                displayName: c['displayName'] as String,
                sortOrder: drift.Value(c['sortOrder'] as int? ?? 0),
                minAdmissionAgeMonths: drift.Value(c['minAdmissionAgeMonths'] as int?),
                minPromotionAgeMonths: drift.Value(c['minPromotionAgeMonths'] as int?),
                promotesToClassId: drift.Value(c['promotesToClassId'] as String?),
                isTerminal: drift.Value(c['isTerminal'] as bool? ?? false),
                isActive: drift.Value(c['isActive'] as bool? ?? true),
              ),
            );
      }

      // 3. Restore Students
      final studentList = (payload['students'] as List?) ?? [];
      for (final item in studentList) {
        final s = item as Map<String, dynamic>;
        await _db.into(_db.studentsTable).insertOnConflictUpdate(
              StudentsTableCompanion.insert(
                id: s['id'] as String,
                clientGeneratedId: s['clientGeneratedId'] as String? ?? s['id'] as String,
                schoolId: s['schoolId'] as String,
                classId: s['classId'] as String,
                grNumber: s['grNumber'] as String,
                serialNumber: drift.Value(s['serialNumber'] as int?),
                studentName: s['studentName'] as String,
                fatherName: drift.Value(s['fatherName'] as String?),
                motherName: drift.Value(s['motherName'] as String?),
                dateOfBirth: DateTime.parse(s['dateOfBirth'] as String),
                dateOfAdmission: DateTime.parse(s['dateOfAdmission'] as String),
                fatherCnic: drift.Value(s['fatherCnic'] as String?),
                bFormNumber: drift.Value(s['bFormNumber'] as String?),
                phoneNumber: drift.Value(s['phoneNumber'] as String?),
                address: drift.Value(s['address'] as String?),
                previousSchool: drift.Value(s['previousSchool'] as String?),
                remarks: drift.Value(s['remarks'] as String?),
                status: drift.Value(s['status'] as String? ?? 'ACTIVE'),
                promotionStatus: drift.Value(s['promotionStatus'] as String? ?? 'NONE'),
                struckOffDate: drift.Value(s['struckOffDate'] != null ? DateTime.parse(s['struckOffDate'] as String) : null),
                struckOffReason: drift.Value(s['struckOffReason'] as String?),
                passOutYear: drift.Value(s['passOutYear'] as int?),
                version: drift.Value(s['version'] as int? ?? 1),
                updatedAt: DateTime.parse(s['updatedAt'] as String),
                createdAt: DateTime.parse(s['createdAt'] as String),
                createdBy: drift.Value(s['createdBy'] as String?),
                updatedBy: drift.Value(s['updatedBy'] as String?),
                isDeleted: drift.Value(s['isDeleted'] as bool? ?? false),
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
        String? resolvedLocalPath = pItem['localPath'] as String?;

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
                id: pItem['id'] as String,
                studentId: pItem['studentId'] as String,
                photoType: pItem['photoType'] as String,
                localPath: drift.Value(resolvedLocalPath),
                remoteStoragePath: drift.Value(pItem['remoteStoragePath'] as String?),
                version: drift.Value(pItem['version'] as int? ?? 1),
                syncState: const drift.Value('synced'),
                createdAt: drift.Value(pItem['createdAt'] != null ? DateTime.parse(pItem['createdAt'] as String) : DateTime.now()),
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
        await _db.into(_db.passOutYearsTable).insertOnConflictUpdate(
              PassOutYearsTableCompanion.insert(
                id: y['id'] as String,
                schoolId: y['schoolId'] as String,
                year: y['year'] as int,
                createdAt: drift.Value(y['createdAt'] != null ? DateTime.parse(y['createdAt'] as String) : DateTime.now()),
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
                id: so['id'] as String,
                schoolId: so['schoolId'] as String,
                studentId: so['studentId'] as String,
                struckOffDate: DateTime.parse(so['struckOffDate'] as String),
                reason: so['reason'] as String,
                reAdmitted: drift.Value(so['reAdmitted'] as bool? ?? false),
                reAdmittedDate: drift.Value(so['reAdmittedDate'] != null ? DateTime.parse(so['reAdmittedDate'] as String) : null),
                reAdmittedBy: drift.Value(so['reAdmittedBy'] as String?),
                createdBy: drift.Value(so['createdBy'] as String?),
                createdAt: drift.Value(so['createdAt'] != null ? DateTime.parse(so['createdAt'] as String) : DateTime.now()),
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
