import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/school.dart';
import '../services/connectivity_service.dart';

/// School profile access. Requirement #5: school info is editable later,
/// and requirement #31 says the schema is multi-school-ready even though
/// v1 only ever shows the single school the logged-in user belongs to.
class SchoolRepository {
  SchoolRepository(this._client, this._db, this._connectivity);

  final SupabaseClient _client;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  /// Returns the local cached school, or null if nothing has been
  /// bootstrapped yet (fresh install, first login).
  Future<School?> getLocalSchool() async {
    final row = await (_db.select(_db.schoolsTable)..limit(1)).getSingleOrNull();
    if (row == null) return null;
    return _fromRow(row);
  }

  Stream<School?> watchLocalSchool() {
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
      throw const SchoolRepositoryException(
        'An internet connection is required the first time you sign in on this device.',
      );
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const SchoolRepositoryException('Not signed in.');
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
      await _db.into(_db.classesTable).insertOnConflictUpdate(
            ClassesTableCompanion.insert(
              id: map['id'] as String,
              schoolId: map['school_id'] as String,
              classCode: map['class_code'] as String,
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
    if (!online) {
      throw const SchoolRepositoryException(
        'Adding a school requires an internet connection the first time.',
      );
    }

    final userId = _client.auth.currentUser!.id;

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

    final schoolId = const Uuid().v4();
    final now = DateTime.now().toUtc();

    await _client.from('schools').insert({
      'id': schoolId,
      'school_name': schoolName,
      'semis_code': semisCode,
      'uc': uc,
      'taluka': taluka,
      'district': district,
      'created_by': userId,
    });

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

    await _client.from('school_members').insert({
      'school_id': schoolId,
      'profile_id': userId,
      'role': 'owner',
    });

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

    // 1. Insert all classes with null promotes_to_class_id first to prevent
    // foreign key constraint violation (classes_promotes_to_class_id_fkey).
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

    // 2. Link the promotion chain now that all target class rows exist in the table.
    await _client.from('classes').update({
      'promotes_to_class_id': insertedIds['1'],
    }).eq('id', insertedIds['ECE']!);

    for (var i = 1; i <= 4; i++) {
      await _client.from('classes').update({
        'promotes_to_class_id': insertedIds['${i + 1}'],
      }).eq('id', insertedIds['$i']!);
    }

    // 3. Immediately seed local classes table in SQLite
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

    await bootstrapFromServer();
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
  }
}

class SchoolRepositoryException implements Exception {
  final String message;
  const SchoolRepositoryException(this.message);
  @override
  String toString() => message;
}
