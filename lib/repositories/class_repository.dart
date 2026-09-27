import 'package:drift/drift.dart';

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

  Stream<List<SchoolClass>> watchClasses(String schoolId) {
    final query = _db.select(_db.classesTable)
      ..where((t) => t.schoolId.equals(schoolId) & t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Streams each class alongside a live count of its ACTIVE students —
  /// what the Classes screen and Dashboard (requirement #22) both need.
  Stream<List<ClassWithActiveCount>> watchClassesWithActiveCounts(String schoolId) {
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
