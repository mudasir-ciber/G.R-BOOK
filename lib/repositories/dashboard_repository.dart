import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../core/age_calculator.dart';
import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/student.dart';

/// How age is resolved when computing dashboard statistics
/// (requirement #23: "Today / Admission Date / Custom Date").
enum AgeReference { today, admissionDate, custom }

class AgeBucket {
  final int years;
  final int count;
  const AgeBucket({required this.years, required this.count});
}

class ClassAgeStats {
  final List<AgeBucket> buckets; // sorted ascending by years
  final Student? youngest;
  final Student? oldest;
  final int totalStudents;
  const ClassAgeStats({
    required this.buckets,
    required this.youngest,
    required this.oldest,
    required this.totalStudents,
  });

  factory ClassAgeStats.empty() =>
      const ClassAgeStats(buckets: [], youngest: null, oldest: null, totalStudents: 0);
}

/// Requirement #22-24: dashboard aggregates. Every read is local-only
/// (offline-capable by construction) and every age is computed with the
/// calendar-accurate AgeCalculator — never a days/365 approximation.
class DashboardRepository {
  DashboardRepository(this._db);

  final AppDatabase _db;

  /// Requirement #22: ONLY status == ACTIVE counts — never STRUCK_OFF
  /// or PASSED_OUT.
  Stream<int> watchTotalActiveStudents(String schoolId) {
    final countExp = _db.studentsTable.id.count();
    final query = _db.selectOnly(_db.studentsTable)
      ..addColumns([countExp])
      ..where(_db.studentsTable.schoolId.equals(schoolId) &
          _db.studentsTable.status.equals('ACTIVE') &
          _db.studentsTable.isDeleted.equals(false));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Live age statistics for one class, recomputed whenever the
  /// student list changes OR the reference date changes (the caller
  /// passes a resolver so "today" doesn't need a fresh stream every
  /// tick — the UI re-requests this when the user switches reference).
  Stream<ClassAgeStats> watchAgeStatsForClass(String classId, AgeReference reference, {DateTime? customDate}) {
    final query = _db.select(_db.studentsTable)
      ..where((t) =>
          t.classId.equals(classId) & t.status.equals('ACTIVE') & t.isDeleted.equals(false));

    return query.watch().map((rows) {
      if (rows.isEmpty) return ClassAgeStats.empty();

      final students = rows.map(_studentFromRow).toList();

      DateTime asOfFor(Student s) => switch (reference) {
            AgeReference.today => DateTime.now(),
            AgeReference.admissionDate => s.dateOfAdmission,
            AgeReference.custom => customDate ?? DateTime.now(),
          };

      final agesByStudent = <Student, AgeResult>{
        for (final s in students) s: AgeCalculator.calculate(dateOfBirth: s.dateOfBirth, asOf: asOfFor(s)),
      };

      final grouped = groupBy(agesByStudent.entries, (e) => e.value.years);
      final buckets = grouped.entries
          .map((e) => AgeBucket(years: e.key, count: e.value.length))
          .sorted((a, b) => a.years.compareTo(b.years));

      // Youngest/oldest compare total age precisely (years, then
      // months, then days) rather than just the bucketed year.
      Student? youngest;
      Student? oldest;
      AgeResult? youngestAge;
      AgeResult? oldestAge;
      for (final entry in agesByStudent.entries) {
        final age = entry.value;
        if (youngestAge == null || _isYounger(age, youngestAge)) {
          youngestAge = age;
          youngest = entry.key;
        }
        if (oldestAge == null || _isYounger(oldestAge, age)) {
          oldestAge = age;
          oldest = entry.key;
        }
      }

      return ClassAgeStats(
        buckets: buckets,
        youngest: youngest,
        oldest: oldest,
        totalStudents: students.length,
      );
    });
  }

  bool _isYounger(AgeResult a, AgeResult b) {
    if (a.years != b.years) return a.years < b.years;
    if (a.months != b.months) return a.months < b.months;
    return a.days < b.days;
  }

  Student _studentFromRow(StudentsTableData row) => Student(
        id: row.id,
        clientGeneratedId: row.clientGeneratedId,
        schoolId: row.schoolId,
        classId: row.classId,
        grNumber: row.grNumber,
        serialNumber: row.serialNumber,
        studentName: row.studentName,
        fatherName: row.fatherName,
        motherName: row.motherName,
        dateOfBirth: row.dateOfBirth,
        dateOfAdmission: row.dateOfAdmission,
        fatherCnic: row.fatherCnic,
        bFormNumber: row.bFormNumber,
        phoneNumber: row.phoneNumber,
        address: row.address,
        previousSchool: row.previousSchool,
        previousGrNumber: row.previousGrNumber,
        remarks: row.remarks,
        status: StudentStatusX.fromDb(row.status),
        promotionStatus: PromotionStatusX.fromDb(row.promotionStatus),
        struckOffDate: row.struckOffDate,
        struckOffReason: row.struckOffReason,
        passOutYear: row.passOutYear,
        version: row.version,
        updatedAt: row.updatedAt,
        createdAt: row.createdAt,
        createdBy: row.createdBy,
        updatedBy: row.updatedBy,
        isDeleted: row.isDeleted,
      );
}
