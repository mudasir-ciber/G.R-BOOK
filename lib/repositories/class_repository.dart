import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/school.dart';

class ClassWithActiveCount {
  final SchoolClass schoolClass;
  final int activeStudentCount;
  const ClassWithActiveCount({required this.schoolClass, required this.activeStudentCount});
}

/// All reads come from the local Drift cache — classes rarely change and
/// are bootstrapped/synced by SchoolRepository, so class screens work
/// fully offline (requirement #25/#27).
class ClassRepository {
  ClassRepository(this._db);

  final AppDatabase _db;

  /// Ensures that all 6 default classes (ECE to Class 5) exist for the school
  /// in the local Drift SQLite database. If none exist, seeds them immediately.
  Future<void> ensureDefaultClasses(String schoolId) async {
    final existing = await (_db.select(_db.classesTable)
          ..where((t) => t.schoolId.equals(schoolId)))
        .get();

    // 1. Ensure all existing classes have isActive = true
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

    final existingCodes = existing.map((c) => c.classCode).toSet();
    if (existingCodes.length >= defaultClasses.length &&
        defaultClasses.every((c) => existingCodes.contains(c['code']))) {
      return;
    }

    final insertedIds = <String, String>{};
    for (final c in defaultClasses) {
      final code = c['code'] as String;
      final match = existing.cast<ClassesTableData?>().firstWhere(
            (e) => e?.classCode == code,
            orElse: () => null,
          );
      insertedIds[code] = match?.id ?? const Uuid().v4();
    }

    for (final c in defaultClasses) {
      final code = c['code'] as String;
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

  Stream<List<SchoolClass>> watchClasses(String schoolId) {
    ensureDefaultClasses(schoolId);
    final query = _db.select(_db.classesTable)
      ..where((t) => t.schoolId.equals(schoolId) & t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Streams each class alongside a live count of its ACTIVE students —
  /// what the Classes screen and Dashboard (requirement #22) both need.
  Stream<List<ClassWithActiveCount>> watchClassesWithActiveCounts(String schoolId) {
    ensureDefaultClasses(schoolId);
    final classesQuery = _db.select(_db.classesTable)
      ..where((t) => t.schoolId.equals(schoolId) & t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);

    return classesQuery.watch().asyncMap((classRows) async {
      final result = <ClassWithActiveCount>[];
      for (final row in classRows) {
        final countExp = _db.studentsTable.id.count();
        final query = _db.selectOnly(_db.studentsTable)
          ..addColumns([countExp])
          ..where(_db.studentsTable.classId.equals(row.id) &
              _db.studentsTable.status.equals('ACTIVE') &
              _db.studentsTable.isDeleted.equals(false));
        final count = await query.map((r) => r.read(countExp) ?? 0).getSingle();
        result.add(ClassWithActiveCount(schoolClass: _fromRow(row), activeStudentCount: count));
      }
      return result;
    });
  }

  Future<SchoolClass?> getClassById(String classId) async {
    final row = await (_db.select(_db.classesTable)..where((t) => t.id.equals(classId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
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
