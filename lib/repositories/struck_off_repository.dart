import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../services/connectivity_service.dart';
import 'student_repository.dart';

/// Requirement #21: struck-off students disappear from active class
/// lists (already true — those screens filter `status == ACTIVE`) but
/// are never physically deleted, and re-admission restores them while
/// preserving the historical event.
class StruckOffRepository {
  StruckOffRepository(this._client, this._db, this._connectivity, this._studentRepo);

  final SupabaseClient _client;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final StudentRepository _studentRepo;
  final _uuid = const Uuid();

  Stream<List<Student>> watchStruckOffStudents(String schoolId) {
    return _db.watchStruckOffStudents(schoolId).map((rows) => rows.map(_studentFromRow).toList());
  }

  Future<void> struckOffStudent({
    required String schoolId,
    required Student student,
    required DateTime struckOffDate,
    required String reason,
    String? performedBy,
  }) async {
    final recordId = _uuid.v4();
    final online = await _connectivity.isOnline();

    await _db.into(_db.struckOffRecordsTable).insert(
          StruckOffRecordsTableCompanion.insert(
            id: recordId,
            schoolId: schoolId,
            studentId: student.id,
            struckOffDate: struckOffDate,
            reason: reason,
            createdBy: drift.Value(performedBy),
          ),
        );

    final updated = student.copyWith(
      status: StudentStatus.struckOff,
      struckOffDate: struckOffDate,
      struckOffReason: reason,
    );
    await _studentRepo.updateStudent(updated);

    await _writeAudit(
      schoolId: schoolId,
      studentId: student.id,
      action: 'STUDENT_STRUCK_OFF',
      userId: performedBy,
      newValue: {'record_id': recordId, 'reason': reason},
    );

    await _pushOrQueue(recordId: recordId, schoolId: schoolId, operation: 'create', online: online);
  }

  /// Restores the student to ACTIVE. The struck-off record itself is
  /// kept and simply flagged `reAdmitted` — requirement #21 explicitly
  /// says to preserve the historical event, not erase it.
  Future<bool> reAdmitStudent({
    required String schoolId,
    required Student student,
    String? performedBy,
  }) async {
    final record = await (_db.select(_db.struckOffRecordsTable)
          ..where((t) => t.studentId.equals(student.id) & t.reAdmitted.equals(false))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
    if (record == null) return false;

    final online = await _connectivity.isOnline();
    final now = DateTime.now();

    await (_db.update(_db.struckOffRecordsTable)..where((t) => t.id.equals(record.id))).write(
      StruckOffRecordsTableCompanion(
        reAdmitted: const drift.Value(true),
        reAdmittedDate: drift.Value(now),
        reAdmittedBy: drift.Value(performedBy),
        syncState: const drift.Value('pendingUpdate'),
      ),
    );

    final restored = student.copyWith(
      status: StudentStatus.active,
      struckOffDate: null,
      struckOffReason: null,
    );
    await _studentRepo.updateStudent(restored);

    await _writeAudit(
      schoolId: schoolId,
      studentId: student.id,
      action: 'STUDENT_RE_ADMITTED',
      userId: performedBy,
      newValue: {'record_id': record.id},
    );

    await _pushOrQueue(recordId: record.id, schoolId: schoolId, operation: 're_admit', online: online);
    return true;
  }

  Future<void> _writeAudit({
    required String schoolId,
    String? studentId,
    required String action,
    String? userId,
    Map<String, dynamic>? newValue,
  }) {
    return _db.into(_db.auditLogsTable).insert(
          AuditLogsTableCompanion.insert(
            id: _uuid.v4(),
            schoolId: schoolId,
            userId: drift.Value(userId),
            studentId: drift.Value(studentId),
            action: action,
            newValueJson: drift.Value(newValue != null ? jsonEncode(newValue) : null),
          ),
        );
  }

  Future<void> _pushOrQueue({
    required String recordId,
    required String schoolId,
    required String operation, // 'create' | 're_admit'
    required bool online,
  }) async {
    if (online) {
      try {
        await _pushNow(recordId, operation);
        return;
      } catch (_) {
        // fall through to queueing
      }
    }
    await _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            entityType: 'struck_off_record',
            entityId: recordId,
            operation: operation,
            payloadJson: jsonEncode({'record_id': recordId, 'school_id': schoolId}),
          ),
        );
  }

  Future<void> _pushNow(String recordId, String operation) async {
    final record =
        await (_db.select(_db.struckOffRecordsTable)..where((t) => t.id.equals(recordId))).getSingle();

    if (operation == 'create') {
      await _client.from('struck_off_records').insert({
        'id': record.id,
        'school_id': record.schoolId,
        'student_id': record.studentId,
        'struck_off_date': record.struckOffDate.toIso8601String().split('T').first,
        'reason': record.reason,
        'created_by': record.createdBy,
      });
    } else {
      await _client.from('struck_off_records').update({
        're_admitted': true,
        're_admitted_date': (record.reAdmittedDate ?? DateTime.now()).toIso8601String().split('T').first,
        're_admitted_by': record.reAdmittedBy,
      }).eq('id', recordId);
    }

    await (_db.update(_db.struckOffRecordsTable)..where((t) => t.id.equals(recordId)))
        .write(const StruckOffRecordsTableCompanion(syncState: drift.Value('synced')));
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
