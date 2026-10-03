import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/school.dart';
import '../services/connectivity_service.dart';
import '../services/offline_storage_service.dart';

/// School profile access. Requirement #5: school info is editable later,
/// and requirement #31 says the schema is multi-school-ready even though
/// v1 only ever shows the single school the logged-in user belongs to.
class SchoolRepository {
  SchoolRepository(this._client, this._db, this._connectivity);

  final SupabaseClient _client;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  /// Returns the local cached school for [userId], or null if nothing has been
  /// created yet by this user. Protects data privacy across multiple accounts.
  Future<School?> getLocalSchool({String? userId, bool isMasterAdmin = false}) async {
    final uid = userId ?? _client.auth.currentUser?.id;
    final schools = await _db.select(_db.schoolsTable).get();
    if (schools.isEmpty) return null;

    if (uid != null && uid.isNotEmpty) {
      final userSchool = schools.where((s) => s.createdBy == uid).firstOrNull;
      if (userSchool != null) return _fromRow(userSchool);

      if (isMasterAdmin || uid == 'master_super_admin' || uid == 'local_admin') {
        return _fromRow(schools.first);
      }
      return null;
    }

    return _fromRow(schools.first);
  }

  Stream<School?> watchLocalSchool({String? userId, bool isMasterAdmin = false}) {
    final uid = userId ?? _client.auth.currentUser?.id;
    if (uid != null && uid.isNotEmpty) {
      return _db.select(_db.schoolsTable).watch().map((schools) {
        if (schools.isEmpty) return null;
        final userSchool = schools.where((s) => s.createdBy == uid).firstOrNull;
        if (userSchool != null) return _fromRow(userSchool);

        if (isMasterAdmin || uid == 'master_super_admin' || uid == 'local_admin') {
          return _fromRow(schools.first);
        }
        return null;
      });
    }

    return (_db.select(_db.schoolsTable)..limit(1)).watchSingleOrNull().map(
          (row) => row == null ? null : _fromRow(row),
        );
  }

  School _fromRow(SchoolsTableData row) => School(
        id: row.id,
        schoolName: row.schoolName,
        semisCode: row.semisCode,
        uc: row.uc,
        taluka: row.taluka,
        district: row.district,
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Pulls the current user's school + its classes down from Supabase
  /// into the local database. Called once after login when the local
  /// cache is empty (or pulled-to-refresh from Settings later).
  /// Requires connectivity — bootstrapping cannot happen fully offline
  /// on a brand-new device, which is expected and reasonable.
  Future<School?> bootstrapFromServer() async {
    final online = await _connectivity.isOnline();
    if (!online) {
      // Offline fallback: Allow app to proceed to AddSchoolScreen or restore screen
      return null;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final membership = await _client
        .from('school_members')
        .select('school_id, schools(*)')
        .eq('profile_id', userId)
        .limit(1)
        .maybeSingle();

    if (membership == null) return null; // user has not created/joined a school yet

    final schoolMap = membership['schools'] as Map<String, dynamic>;
    final school = School.fromMap(schoolMap);

    await _db.into(_db.schoolsTable).insertOnConflictUpdate(
          SchoolsTableCompanion.insert(
            id: school.id,
            schoolName: school.schoolName,
            semisCode: Value(school.semisCode),
            uc: Value(school.uc),
            taluka: Value(school.taluka),
            district: Value(school.district),
            createdBy: school.createdBy,
            createdAt: school.createdAt,
            updatedAt: school.updatedAt,
          ),
        );

    final classRows = await _client
        .from('classes')
        .select()
        .eq('school_id', school.id)
        .eq('is_active', true)
        .order('sort_order');

    for (final row in classRows as List) {
      final map = row as Map<String, dynamic>;
      final serverId = map['id'] as String;
      final serverCode = map['class_code'] as String;

      // Check if local class row exists for this school and class code
      final localMatches = await (_db.select(_db.classesTable)
            ..where((t) => t.schoolId.equals(school.id) & t.classCode.equals(serverCode)))
          .get();

      for (final local in localMatches) {
        if (local.id != serverId) {
          // Re-link students to serverId
          await (_db.update(_db.studentsTable)..where((t) => t.classId.equals(local.id)))
              .write(StudentsTableCompanion(classId: Value(serverId)));

          // Re-link promotion batches to serverId
          await (_db.update(_db.promotionBatchesTable)..where((t) => t.fromClassId.equals(local.id)))
              .write(PromotionBatchesTableCompanion(fromClassId: Value(serverId)));
          await (_db.update(_db.promotionBatchesTable)..where((t) => t.toClassId.equals(local.id)))
              .write(PromotionBatchesTableCompanion(toClassId: Value(serverId)));

          // Re-link promotion records to serverId
          await (_db.update(_db.promotionRecordsTable)..where((t) => t.previousClassId.equals(local.id)))
              .write(PromotionRecordsTableCompanion(previousClassId: Value(serverId)));
          await (_db.update(_db.promotionRecordsTable)..where((t) => t.newClassId.equals(local.id)))
              .write(PromotionRecordsTableCompanion(newClassId: Value(serverId)));

          // Re-link promotesToClassId in classesTable to serverId
          await (_db.update(_db.classesTable)..where((t) => t.promotesToClassId.equals(local.id)))
              .write(ClassesTableCompanion(promotesToClassId: Value(serverId)));

          // Delete obsolete local class row
          await (_db.delete(_db.classesTable)..where((t) => t.id.equals(local.id))).go();
        }
      }

      await _db.into(_db.classesTable).insertOnConflictUpdate(
            ClassesTableCompanion.insert(
              id: serverId,
              schoolId: map['school_id'] as String,
              classCode: serverCode,
              displayName: map['display_name'] as String,
              sortOrder: Value(map['sort_order'] as int? ?? 0),
              minAdmissionAgeMonths: Value(map['min_admission_age_months'] as int?),
              minPromotionAgeMonths: Value(map['min_promotion_age_months'] as int?),
              promotesToClassId: Value(map['promotes_to_class_id'] as String?),
              isTerminal: Value(map['is_terminal'] as bool? ?? false),
              isActive: Value(map['is_active'] as bool? ?? true),
            ),
          );
    }

    return school;
  }

  /// Creates a brand-new school for the current user (the "Add School"
  /// screen) plus its default 6 classes, and makes the user its owner.
  /// This mirrors supabase/sql/04_seed_first_school.sql but driven from
  /// the app for any future school onboarded after the first one.
  Future<School> createSchool({
    required String schoolName,
    String? semisCode,
    String? uc,
    String? taluka,
    String? district,
  }) async {
    final online = await _connectivity.isOnline();
    final userId = _client.auth.currentUser?.id ?? 'local_admin';
    final schoolId = const Uuid().v4();
    final now = DateTime.now().toUtc();

    if (online && _client.auth.currentUser != null) {
      // Ensure the profile row exists so foreign key references on schools.created_by never fail:
      try {
        await _client.from('profiles').upsert({
          'id': userId,
          'full_name': _client.auth.currentUser?.userMetadata?['full_name'] ?? 'School Admin',
          'mobile_number': _client.auth.currentUser?.userMetadata?['mobile_number'] ??
              _client.auth.currentUser?.email?.split('@').first ??
              '',
        });
      } catch (_) {}

      try {
        await _client.from('schools').insert({
          'id': schoolId,
          'school_name': schoolName,
          'semis_code': semisCode,
          'uc': uc,
          'taluka': taluka,
          'district': district,
          'created_by': userId,
        });

        await _client.from('school_members').insert({
          'school_id': schoolId,
          'profile_id': userId,
          'role': 'owner',
        });
      } catch (_) {}
    }

    final school = School(
      id: schoolId,
      schoolName: schoolName,
      semisCode: semisCode,
      uc: uc,
      taluka: taluka,
      district: district,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.schoolsTable).insertOnConflictUpdate(
          SchoolsTableCompanion.insert(
            id: school.id,
            schoolName: school.schoolName,
            semisCode: Value(school.semisCode),
            uc: Value(school.uc),
            taluka: Value(school.taluka),
            district: Value(school.district),
            createdBy: school.createdBy,
            createdAt: school.createdAt,
            updatedAt: school.updatedAt,
          ),
        );

    const defaultClasses = [
      {'code': 'ECE', 'name': 'ECE', 'order': 0, 'minAdmission': 36},
      {'code': '1', 'name': 'Class 1', 'order': 1},
      {'code': '2', 'name': 'Class 2', 'order': 2},
      {'code': '3', 'name': 'Class 3', 'order': 3},
      {'code': '4', 'name': 'Class 4', 'order': 4},
      {'code': '5', 'name': 'Class 5', 'order': 5, 'terminal': true},
    ];

    final insertedIds = <String, String>{};
    for (final c in defaultClasses) {
      final classId = const Uuid().v4();
      insertedIds[c['code'] as String] = classId;
    }

    if (online && _client.auth.currentUser != null) {
      try {
        final classRows = defaultClasses.map((c) {
          final code = c['code'] as String;
          return {
            'id': insertedIds[code]!,
            'school_id': schoolId,
            'class_code': code,
            'display_name': c['name'],
            'sort_order': c['order'],
            'min_admission_age_months': c['minAdmission'],
            'min_promotion_age_months': code == 'ECE' ? 61 : null,
            'promotes_to_class_id': null,
            'is_terminal': c['terminal'] ?? false,
            'is_active': true,
          };
        }).toList();

        await _client.from('classes').insert(classRows);

        await _client.from('classes').update({
          'promotes_to_class_id': insertedIds['1'],
        }).eq('id', insertedIds['ECE']!);

        for (var i = 1; i <= 4; i++) {
          await _client.from('classes').update({
            'promotes_to_class_id': insertedIds['${i + 1}'],
          }).eq('id', insertedIds['$i']!);
        }
      } catch (_) {}
    }

    // Immediately seed local classes table in SQLite
    for (final c in defaultClasses) {
      final code = c['code'] as String;
      String? promo;
      if (code == 'ECE') promo = insertedIds['1'];
      if (code == '1') promo = insertedIds['2'];
      if (code == '2') promo = insertedIds['3'];
      if (code == '3') promo = insertedIds['4'];
      if (code == '4') promo = insertedIds['5'];

      await _db.into(_db.classesTable).insertOnConflictUpdate(
            ClassesTableCompanion.insert(
              id: insertedIds[code]!,
              schoolId: schoolId,
              classCode: code,
              displayName: c['name'] as String,
              sortOrder: Value(c['order'] as int? ?? 0),
              minAdmissionAgeMonths: Value(c['minAdmission'] as int?),
              minPromotionAgeMonths: Value(code == 'ECE' ? 61 : null),
              promotesToClassId: Value(promo),
              isTerminal: Value((c['terminal'] as bool?) ?? false),
              isActive: const Value(true),
            ),
          );
    }

    // Export initial state to phone's GR_BOOK storage
    try {
      final storage = OfflineStorageService(_db);
      await storage.exportCurrentStateToStorage();
    } catch (_) {}

    return school;
  }

  Future<void> updateSchoolProfile(School school) async {
    final online = await _connectivity.isOnline();

    await (_db.update(_db.schoolsTable)..where((t) => t.id.equals(school.id)))
        .write(
      SchoolsTableCompanion(
        schoolName: Value(school.schoolName),
        semisCode: Value(school.semisCode),
        uc: Value(school.uc),
        taluka: Value(school.taluka),
        district: Value(school.district),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (online) {
      await _client.from('schools').update({
        'school_name': school.schoolName,
        'semis_code': school.semisCode,
        'uc': school.uc,
        'taluka': school.taluka,
        'district': school.district,
      }).eq('id', school.id);
    } else {
      await _db.into(_db.syncQueueTable).insert(
            SyncQueueTableCompanion.insert(
              entityType: 'school',
              entityId: school.id,
              operation: 'update',
              payloadJson: jsonEncode(school.toMap()),
            ),
          );
    }

    try {
      final storage = OfflineStorageService(_db);
      await storage.exportCurrentStateToStorage();
    } catch (_) {}
  }
}

class SchoolRepositoryException implements Exception {
  final String message;
  const SchoolRepositoryException(this.message);
  @override
  String toString() => message;
}
