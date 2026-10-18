import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/age_calculator.dart';
import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/school.dart';
import '../models/student.dart';
import '../services/connectivity_service.dart';
import 'class_repository.dart';
import 'student_repository.dart';

class PromotionCandidate {
  final Student student;
  final bool isAgeEligible; // relevant for ECE -> Class 1; true elsewhere
  const PromotionCandidate({required this.student, required this.isAgeEligible});
}

class PromotionPreview {
  final SchoolClass fromClass;
  final SchoolClass? toClass; // null => Pass Out
  final List<Student> students;
  final DateTime promotionDate;
  const PromotionPreview({required this.fromClass, required this.toClass, required this.students, required this.promotionDate});
}

/// Implements requirements #14-#19: eligibility, the
/// select→preview→confirm workflow, fail-in-place, promotion history,
/// and undo — all usable with no internet connection.
class PromotionRepository {
  PromotionRepository(this._client, this._db, this._connectivity, this._classRepo, this._studentRepo);

  final SupabaseClient _client;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final ClassRepository _classRepo;
  final StudentRepository _studentRepo;
  final _uuid = const Uuid();

  /// Builds the candidate list for the Promote Students screen. For a
  /// class with a configured `minPromotionAgeMonths` (ECE -> Class 1),
  /// only age-eligible students are pre-checked; every other class has
  /// no age gate, so nothing is pre-selected — the teacher chooses
  /// (matches the UI reference, where only some of 28 students are
  /// pre-ticked).
  Future<List<PromotionCandidate>> getCandidates({
    required SchoolClass fromClass,
    required DateTime promotionDate,
  }) async {
    final students = await _db.studentsForClass(fromClass.id);
    final active = students.where((s) => s.status == 'ACTIVE').toList();

    return active.map((row) {
      final student = _studentFromRow(row);
      bool eligible = true;
      if (fromClass.minPromotionAgeMonths != null) {
        eligible = AgeCalculator.isAtLeastMonths(
          dateOfBirth: student.dateOfBirth,
          asOf: promotionDate,
          minMonths: fromClass.minPromotionAgeMonths!,
        );
      }
      return PromotionCandidate(student: student, isAgeEligible: eligible);
    }).toList()
      ..sort((a, b) => (a.student.serialNumber ?? 0).compareTo(b.student.serialNumber ?? 0));
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

  /// Executes the promotion after the user has confirmed the preview.
  /// Works fully offline: local rows are written first regardless of
  /// connectivity, then pushed (or queued) to Supabase.
  Future<void> promoteStudents({
    required String schoolId,
    required SchoolClass fromClass,
    required List<String> selectedStudentIds,
    required DateTime promotionDate,
    SchoolClass? targetClass,
    String? performedBy,
  }) async {
    if (selectedStudentIds.isEmpty) return;

    final SchoolClass? toClass;
    if (targetClass != null) {
      toClass = targetClass;
    } else if (fromClass.promotesToClassId != null) {
      toClass = await _classRepo.getClassById(fromClass.promotesToClassId!);
    } else {
      toClass = null;
    }

    if (toClass == null && !fromClass.isTerminal && targetClass == null) {
      throw StateError('${fromClass.displayName} has no configured promotion target.');
    }

    final batchId = _uuid.v4();
    final academicYear = promotionDate.year;
    final online = await _connectivity.isOnline();

    await _db.into(_db.promotionBatchesTable).insert(
          PromotionBatchesTableCompanion.insert(
            id: batchId,
            schoolId: schoolId,
            fromClassId: fromClass.id,
            toClassId: drift.Value(toClass?.id),
            promotionDate: promotionDate,
            academicYear: academicYear,
            performedBy: drift.Value(performedBy),
          ),
        );

    for (final studentId in selectedStudentIds) {
      final student = await _studentRepo.getById(studentId);
      if (student == null) continue;

      final newStatus = toClass != null ? StudentStatus.active : StudentStatus.passedOut;

      await _db.into(_db.promotionRecordsTable).insert(
            PromotionRecordsTableCompanion.insert(
              id: _uuid.v4(),
              batchId: batchId,
              studentId: studentId,
              previousClassId: fromClass.id,
              newClassId: drift.Value(toClass?.id),
              previousStatus: student.status.dbValue,
              newStatus: newStatus.dbValue,
              result: 'PROMOTED',
              academicYear: academicYear,
            ),
          );

      final updated = student.copyWith(
        classId: toClass?.id ?? fromClass.id,
        status: newStatus,
        promotionStatus: PromotionStatus.promoted,
        passOutYear: toClass == null ? academicYear : null,
      );
      // Reuses StudentRepository so the same offline-first / conflict
      // logic applies to promotion-driven edits as any other edit.
      await _studentRepo.updateStudent(updated);
    }

    await _studentRepo.autoCorrectSerialNumbersForClass(fromClass.id);
    if (toClass != null) {
      await _studentRepo.autoCorrectSerialNumbersForClass(toClass.id);
    }

    await _writeAudit(
      schoolId: schoolId,
      action: 'STUDENTS_PROMOTED',
      userId: performedBy,
      newValue: {
        'batch_id': batchId,
        'from_class': fromClass.displayName,
        'to_class': toClass?.displayName ?? 'PASSED_OUT',
        'count': selectedStudentIds.length,
      },
    );

    await _pushOrQueueBatch(
      batchId: batchId,
      schoolId: schoolId,
      operation: 'create',
      online: online,
    );
  }

  /// Requirement #17: a failed student stays in the same class. Still
  /// recorded in promotion history (a single-record batch) so the
  /// year-by-year history in requirement #18 is complete.
  Future<void> markStudentFailed({
    required String schoolId,
    required Student student,
    required DateTime asOfDate,
    String? performedBy,
  }) async {
    final batchId = _uuid.v4();
    final academicYear = asOfDate.year;
    final online = await _connectivity.isOnline();

    await _db.into(_db.promotionBatchesTable).insert(
          PromotionBatchesTableCompanion.insert(
            id: batchId,
            schoolId: schoolId,
            fromClassId: student.classId,
            toClassId: drift.Value(student.classId), // stays in the same class
            promotionDate: asOfDate,
            academicYear: academicYear,
            performedBy: drift.Value(performedBy),
          ),
        );

    await _db.into(_db.promotionRecordsTable).insert(
          PromotionRecordsTableCompanion.insert(
            id: _uuid.v4(),
            batchId: batchId,
            studentId: student.id,
            previousClassId: student.classId,
            newClassId: drift.Value(student.classId),
            previousStatus: student.status.dbValue,
            newStatus: student.status.dbValue,
            result: 'FAILED',
            academicYear: academicYear,
          ),
        );

    final updated = student.copyWith(promotionStatus: PromotionStatus.failed);
    await _studentRepo.updateStudent(updated);

    await _writeAudit(
      schoolId: schoolId,
      studentId: student.id,
      action: 'STUDENT_FAILED',
      userId: performedBy,
      newValue: {'batch_id': batchId, 'academic_year': academicYear},
    );

    await _pushOrQueueBatch(batchId: batchId, schoolId: schoolId, operation: 'create', online: online);
  }

  /// Requirement #19: undo the most recent promotion for a class.
  /// Restores every affected student's previous class/status, keeps the
  /// batch (marked `isUndone`) and its records intact for the audit
  /// trail — never deletes history.
  Future<bool> undoLastPromotion({required String schoolId, required String fromClassId, String? performedBy}) async {
    final batch = await _db.latestActiveBatchForClass(fromClassId);
    if (batch == null) return false;

    final records = await _db.recordsForBatch(batch.id);
    final online = await _connectivity.isOnline();

    for (final record in records) {
      final student = await _studentRepo.getById(record.studentId);
      if (student == null) continue;

      final restored = student.copyWith(
        classId: record.previousClassId,
        status: StudentStatusX.fromDb(record.previousStatus),
        promotionStatus: PromotionStatus.none,
        passOutYear: StudentStatusX.fromDb(record.previousStatus) == StudentStatus.passedOut
            ? student.passOutYear
            : null,
      );
      await _studentRepo.updateStudent(restored);
    }

    await (_db.update(_db.promotionBatchesTable)..where((t) => t.id.equals(batch.id))).write(
      PromotionBatchesTableCompanion(
        isUndone: const drift.Value(true),
        undoneAt: drift.Value(DateTime.now()),
        undoneBy: drift.Value(performedBy),
        syncState: const drift.Value('pendingUpdate'),
      ),
    );

    await _writeAudit(
      schoolId: schoolId,
      action: 'PROMOTION_UNDONE',
      userId: performedBy,
      oldValue: {'batch_id': batch.id},
    );

    await _pushOrQueueBatch(batchId: batch.id, schoolId: schoolId, operation: 'undo', online: online);
    return true;
  }

  Future<bool> hasUndoableBatch(String fromClassId) async {
    final batch = await _db.latestActiveBatchForClass(fromClassId);
    return batch != null;
  }

  Future<void> _writeAudit({
    required String schoolId,
    String? studentId,
    required String action,
    String? userId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) {
    return _db.into(_db.auditLogsTable).insert(
          AuditLogsTableCompanion.insert(
            id: _uuid.v4(),
            schoolId: schoolId,
            userId: drift.Value(userId),
            studentId: drift.Value(studentId),
            action: action,
            oldValueJson: drift.Value(oldValue != null ? jsonEncode(oldValue) : null),
            newValueJson: drift.Value(newValue != null ? jsonEncode(newValue) : null),
          ),
        );
  }

  Future<void> _pushOrQueueBatch({
    required String batchId,
    required String schoolId,
    required String operation, // 'create' | 'undo'
    required bool online,
  }) async {
    if (online) {
      try {
        await _pushBatchNow(batchId, operation);
        return;
      } catch (_) {
        // Fall through to queueing on any failure (network drop mid-push).
      }
    }
    await _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            entityType: 'promotion_batch',
            entityId: batchId,
            operation: operation,
            payloadJson: jsonEncode({'batch_id': batchId, 'school_id': schoolId}),
          ),
        );
  }

  Future<void> _pushBatchNow(String batchId, String operation) async {
    final batch = await (_db.select(_db.promotionBatchesTable)..where((t) => t.id.equals(batchId)))
        .getSingle();

    if (operation == 'undo') {
      await _client.from('promotion_batches').update({
        'is_undone': true,
        'undone_at': (batch.undoneAt ?? DateTime.now()).toIso8601String(),
        'undone_by': batch.undoneBy,
      }).eq('id', batchId);
      await (_db.update(_db.promotionBatchesTable)..where((t) => t.id.equals(batchId)))
          .write(const PromotionBatchesTableCompanion(syncState: drift.Value('synced')));
      return;
    }

    // operation == 'create'
    await _client.from('promotion_batches').insert({
      'id': batch.id,
      'school_id': batch.schoolId,
      'from_class_id': batch.fromClassId,
      'to_class_id': batch.toClassId,
      'promotion_date': batch.promotionDate.toIso8601String().split('T').first,
      'academic_year': batch.academicYear,
      'performed_by': batch.performedBy,
    });

    final records = await _db.recordsForBatch(batchId);
    if (records.isNotEmpty) {
      await _client.from('promotion_records').insert(records
          .map((r) => {
                'id': r.id,
                'batch_id': r.batchId,
                'student_id': r.studentId,
                'previous_class_id': r.previousClassId,
                'new_class_id': r.newClassId,
                'previous_status': r.previousStatus,
                'new_status': r.newStatus,
                'result': r.result,
                'academic_year': r.academicYear,
              })
          .toList());
    }

    // Pass Out records for any student this batch moved to PASSED_OUT.
    final passOutRecords = records.where((r) => r.newStatus == 'PASSED_OUT').toList();
    if (passOutRecords.isNotEmpty) {
      await _client.from('pass_out_records').insert(passOutRecords
          .map((r) => {
                'school_id': batch.schoolId,
                'student_id': r.studentId,
                'pass_out_year': r.academicYear,
                'pass_out_date': batch.promotionDate.toIso8601String().split('T').first,
                'promotion_batch_id': batch.id,
              })
          .toList());
    }

    await (_db.update(_db.promotionBatchesTable)..where((t) => t.id.equals(batchId)))
        .write(const PromotionBatchesTableCompanion(syncState: drift.Value('synced')));
  }
}
