import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/school.dart';
import '../services/connectivity_service.dart';

class ClassWithActiveCount {
  final SchoolClass schoolClass;
  final int activeStudentCount;
  const ClassWithActiveCount({required this.schoolClass, required this.activeStudentCount});
}

/// All reads come from the local Drift cache — classes rarely change and
/// are bootstrapped/synced by SchoolRepository, so class screens work
/// fully offline (requirement #25/#27).
class ClassRepository {
  ClassRepository(this._db, this._client, this._connectivity);

  final AppDatabase _db;
  final SupabaseClient _client;
  final ConnectivityService _connectivity;

  /// Deduplicates classes in the local SQLite database for a school.
  /// If duplicate rows exist for the same class code, this picks the canonical
  /// row (prioritizing the one with students), migrates all student and
  /// promotion records to that ID, and deletes the duplicate class rows.
  Future<void> deduplicateClasses(String schoolId) async {
    final allRows = await (_db.select(_db.classesTable)
          ..where((t) => t.schoolId.equals(schoolId)))
        .get();

    if (allRows.isEmpty) return;

    final grouped = <String, List<ClassesTableData>>{};
    for (final row in allRows) {
      final code = row.classCode.trim().toUpperCase();
      grouped.putIfAbsent(code, () => []).add(row);
    }

    final canonicalMap = <String, String>{};

    for (final entry in grouped.entries) {
      final code = entry.key;
      final rows = entry.value;

      if (rows.length == 1) {
        canonicalMap[code] = rows.first.id;
        continue;
      }

      // Duplicates exist for this class code.
      // Find candidate with the most students.
      ClassesTableData? bestRow;
      int maxStudentCount = -1;

      for (final r in rows) {
        final countExp = _db.studentsTable.id.count();
        final q = _db.selectOnly(_db.studentsTable)
          ..addColumns([countExp])
          ..where(_db.studentsTable.classId.equals(r.id) &
              _db.studentsTable.isDeleted.equals(false));
        final studentCount = await q.map((row) => row.read(countExp) ?? 0).getSingle();

        if (studentCount > maxStudentCount) {
          maxStudentCount = studentCount;
          bestRow = r;
        }
      }

      bestRow ??= rows.first;
      final canonicalId = bestRow.id;
      canonicalMap[code] = canonicalId;

      for (final dup in rows) {
        if (dup.id == canonicalId) continue;

        // 1. Re-link students to canonicalId
        await (_db.update(_db.studentsTable)
              ..where((t) => t.classId.equals(dup.id)))
            .write(StudentsTableCompanion(classId: Value(canonicalId)));

        // 2. Re-link promotion batches
        await (_db.update(_db.promotionBatchesTable)
              ..where((t) => t.fromClassId.equals(dup.id)))
            .write(PromotionBatchesTableCompanion(fromClassId: Value(canonicalId)));
        await (_db.update(_db.promotionBatchesTable)
              ..where((t) => t.toClassId.equals(dup.id)))
            .write(PromotionBatchesTableCompanion(toClassId: Value(canonicalId)));

        // 3. Re-link promotion records
        await (_db.update(_db.promotionRecordsTable)
              ..where((t) => t.previousClassId.equals(dup.id)))
            .write(PromotionRecordsTableCompanion(previousClassId: Value(canonicalId)));
        await (_db.update(_db.promotionRecordsTable)
              ..where((t) => t.newClassId.equals(dup.id)))
            .write(PromotionRecordsTableCompanion(newClassId: Value(canonicalId)));

        // 4. Re-link classes promotesToClassId
        await (_db.update(_db.classesTable)
              ..where((t) => t.promotesToClassId.equals(dup.id)))
            .write(ClassesTableCompanion(promotesToClassId: Value(canonicalId)));

        // 5. Delete duplicate class row
        await (_db.delete(_db.classesTable)..where((t) => t.id.equals(dup.id))).go();
      }
    }

    // Re-link promotion pointers for canonical classes: ECE -> 1 -> 2 -> 3 -> 4 -> 5 -> null
    for (final code in ['ECE', '1', '2', '3', '4', '5']) {
      final id = canonicalMap[code];
      if (id == null) continue;

      String? targetId;
      if (code == 'ECE') {
        targetId = canonicalMap['1'];
      } else {
        final num = int.tryParse(code);
        if (num != null && num < 5) {
          targetId = canonicalMap['${num + 1}'];
        }
      }

      await (_db.update(_db.classesTable)..where((t) => t.id.equals(id))).write(
        ClassesTableCompanion(
          isActive: const Value(true),
          promotesToClassId: Value(targetId),
        ),
      );
    }
  }

  /// Ensures that all 6 default classes (ECE to Class 5) exist for the school
  /// in the local Drift SQLite database. If none exist, seeds them immediately.
  Future<void> ensureDefaultClasses(String schoolId) async {
    // 1. First self-heal any duplicate rows in local SQLite
    await deduplicateClasses(schoolId);

    final existing = await (_db.select(_db.classesTable)
          ..where((t) => t.schoolId.equals(schoolId)))
        .get();

    // Ensure all existing classes have isActive = true
    final hasInactive = existing.any((c) => !c.isActive);
    if (hasInactive) {
      await (_db.update(_db.classesTable)
            ..where((t) => t.schoolId.equals(schoolId)))
          .write(const ClassesTableCompanion(isActive: Value(true)));
    }

    const defaultClasses = [
      {'code': 'ECE', 'name': 'ECE', 'order': 0, 'minAdmission': 36},
      {'code': '1', 'name': 'Class 1', 'order': 1},
      {'code': '2', 'name': 'Class 2', 'order': 2},
      {'code': '3', 'name': 'Class 3', 'order': 3},
      {'code': '4', 'name': 'Class 4', 'order': 4},
      {'code': '5', 'name': 'Class 5', 'order': 5, 'terminal': true},
    ];

    final existingCodes = existing.map((c) => c.classCode.trim().toUpperCase()).toSet();
    if (defaultClasses.every((c) => existingCodes.contains((c['code'] as String).toUpperCase()))) {
      return;
    }

    final insertedIds = <String, String>{};
    for (final c in defaultClasses) {
      final code = (c['code'] as String).toUpperCase();
      final match = existing.cast<ClassesTableData?>().firstWhere(
            (e) => e?.classCode.trim().toUpperCase() == code,
            orElse: () => null,
          );
      insertedIds[c['code'] as String] = match?.id ?? const Uuid().v4();
    }

    for (final c in defaultClasses) {
      final code = c['code'] as String;
      // Do not re-insert if this class code is already in database
      if (existingCodes.contains(code.toUpperCase())) {
        continue;
      }

      String? promotesToId;
      if (code == 'ECE') {
        promotesToId = insertedIds['1'];
      } else {
        final num = int.tryParse(code);
        if (num != null && num < 5) {
          promotesToId = insertedIds['${num + 1}'];
        }
      }

      await _db.into(_db.classesTable).insertOnConflictUpdate(
            ClassesTableCompanion.insert(
              id: insertedIds[code]!,
              schoolId: schoolId,
              classCode: code,
              displayName: c['name'] as String,
              sortOrder: Value(c['order'] as int? ?? 0),
              minAdmissionAgeMonths: Value(c['minAdmission'] as int?),
              minPromotionAgeMonths: Value(code == 'ECE' ? 61 : null),
              promotesToClassId: Value(promotesToId),
              isTerminal: Value((c['terminal'] as bool?) ?? false),
              isActive: const Value(true),
            ),
          );
    }
  }

  /// Includes inactive classes too — used by Manage Classes so an
  /// admin can see and re-enable a class they turned off.
  Stream<List<SchoolClass>> watchAllClasses(String schoolId) {
    ensureDefaultClasses(schoolId);
    final query = _db.select(_db.classesTable)
      ..where((t) => t.schoolId.equals(schoolId))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return query.watch().map((rows) {
      final seenCodes = <String>{};
      final uniqueList = <SchoolClass>[];
      for (final row in rows) {
        final code = row.classCode.trim().toUpperCase();
        if (!seenCodes.contains(code)) {
          seenCodes.add(code);
          uniqueList.add(_fromRow(row));
        }
      }
      return uniqueList;
    });
  }

  Stream<List<SchoolClass>> watchClasses(String schoolId) {
    ensureDefaultClasses(schoolId);
    final query = _db.select(_db.classesTable)
      ..where((t) => t.schoolId.equals(schoolId) & t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return query.watch().map((rows) {
      final seenCodes = <String>{};
      final uniqueList = <SchoolClass>[];
      for (final row in rows) {
        final code = row.classCode.trim().toUpperCase();
        if (!seenCodes.contains(code)) {
          seenCodes.add(code);
          uniqueList.add(_fromRow(row));
        }
      }
      return uniqueList;
    });
  }

  /// Streams each class alongside a live count of its ACTIVE students —
  /// what the Classes screen and Dashboard (requirement #22) both need.
  Stream<List<ClassWithActiveCount>> watchClassesWithActiveCounts(String schoolId) {
    ensureDefaultClasses(schoolId);
    final classesQuery = _db.select(_db.classesTable)
      ..where((t) => t.schoolId.equals(schoolId) & t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);

    return classesQuery.watch().asyncMap((classRows) async {
      final codeMap = <String, ClassesTableData>{};
      final allIdsForCode = <String, List<String>>{};

      for (final row in classRows) {
        final code = row.classCode.trim().toUpperCase();
        if (!codeMap.containsKey(code)) {
          codeMap[code] = row;
        }
        allIdsForCode.putIfAbsent(code, () => []).add(row.id);
      }

      final result = <ClassWithActiveCount>[];
      for (final entry in codeMap.entries) {
        final code = entry.key;
        final primaryRow = entry.value;
        final matchingIds = allIdsForCode[code] ?? [primaryRow.id];

        final countExp = _db.studentsTable.id.count();
        final query = _db.selectOnly(_db.studentsTable)
          ..addColumns([countExp])
          ..where(_db.studentsTable.classId.isIn(matchingIds) &
              _db.studentsTable.status.equals('ACTIVE') &
              _db.studentsTable.isDeleted.equals(false));
        final count = await query.map((r) => r.read(countExp) ?? 0).getSingle();
        result.add(ClassWithActiveCount(schoolClass: _fromRow(primaryRow), activeStudentCount: count));
      }
      return result;
    });
  }

  Future<SchoolClass?> getClassById(String classId) async {
    final row = await (_db.select(_db.classesTable)..where((t) => t.id.equals(classId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Requirement #6: classes must be manageable through Settings.
  Future<void> updateClass(SchoolClass updated) async {
    final online = await _connectivity.isOnline();

    await (_db.update(_db.classesTable)..where((t) => t.id.equals(updated.id))).write(
      ClassesTableCompanion(
        displayName: Value(updated.displayName),
        minAdmissionAgeMonths: Value(updated.minAdmissionAgeMonths),
        minPromotionAgeMonths: Value(updated.minPromotionAgeMonths),
        isActive: Value(updated.isActive),
      ),
    );

    if (online) {
      try {
        await _client.from('classes').update({
          'display_name': updated.displayName,
          'min_admission_age_months': updated.minAdmissionAgeMonths,
          'min_promotion_age_months': updated.minPromotionAgeMonths,
          'is_active': updated.isActive,
        }).eq('id', updated.id);
        return;
      } catch (_) {
        // fall through to queueing
      }
    }

    await _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            entityType: 'class',
            entityId: updated.id,
            operation: 'update',
            payloadJson: jsonEncode({
              'display_name': updated.displayName,
              'min_admission_age_months': updated.minAdmissionAgeMonths,
              'min_promotion_age_months': updated.minPromotionAgeMonths,
              'is_active': updated.isActive,
            }),
          ),
        );
  }

  SchoolClass _fromRow(ClassesTableData row) => SchoolClass(
        id: row.id,
        schoolId: row.schoolId,
        classCode: row.classCode,
        displayName: row.displayName,
        sortOrder: row.sortOrder,
        minAdmissionAgeMonths: row.minAdmissionAgeMonths,
        minPromotionAgeMonths: row.minPromotionAgeMonths,
        promotesToClassId: row.promotesToClassId,
        isTerminal: row.isTerminal,
        isActive: row.isActive,
      );
}
