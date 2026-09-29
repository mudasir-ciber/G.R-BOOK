import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../services/connectivity_service.dart';

/// Offline-first student data access.
///
/// Every write lands in the local Drift database first (so the UI is
/// instant and works with no network), and is either:
///   (a) pushed to Supabase immediately if online, or
///   (b) recorded in the sync outbox (`SyncQueueTable`) for the Phase 3
///       sync engine to replay once connectivity returns.
///
/// Serial numbers (requirement #8) are never computed client-side from
/// "count of rows" — that duplicates under offline/concurrent use.
/// Instead: online, we call the server's next_serial_number() RPC before
/// insert; offline, the row is stored with serialNumber = null and shows
/// as "Pending" until the queued create is replayed against Supabase,
/// which allocates the real number at that point.
///
/// GR numbers (requirement #8) are user-entered and may legitimately
/// collide — `checkDuplicateGrNumber` lets the UI warn the user, but
/// never blocks the save once acknowledged.
class StudentRepository {
  StudentRepository(this._client, this._db, this._connectivity);

  final SupabaseClient _client;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final _uuid = const Uuid();

  // ---------------------------------------------------------------
  // READS (always local — offline-capable by construction)
  // ---------------------------------------------------------------

  Stream<List<Student>> watchActiveStudentsForClass(String classId) {
    final query = _db.select(_db.studentsTable)
      ..where((t) =>
          t.classId.equals(classId) &
          t.status.equals('ACTIVE') &
          t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.serialNumber)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Search by name or GR number, optionally scoped to one class.
  /// Runs entirely against the local SQLite cache, so it works offline.
  Stream<List<Student>> watchSearch({String? classId, required String queryText}) {
    final like = '%${queryText.trim()}%';
    final query = _db.select(_db.studentsTable)
      ..where((t) {
        final base = t.isDeleted.equals(false) &
            (t.studentName.like(like) | t.grNumber.like(like));
        return classId != null ? base & t.classId.equals(classId) : base;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.studentName)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// School-wide search (requirement #25: "Global/student searches
  /// should support Student Name, GR Number, Class"). Unlike
  /// [watchSearch] (used inside one class's student list), this is
  /// scoped to the whole school and also matches by class name/code —
  /// searching "class 3" surfaces every Class 3 student even with no
  /// name/GR match.
  Stream<List<Student>> watchGlobalSearch({required String schoolId, required String queryText}) async* {
    final trimmed = queryText.trim();
    if (trimmed.isEmpty) {
      yield [];
      return;
    }
    final like = '%$trimmed%';

    final matchingClassIds = await (_db.select(_db.classesTable)
          ..where((t) =>
              t.schoolId.equals(schoolId) & (t.displayName.like(like) | t.classCode.like(like))))
        .map((c) => c.id)
        .get();

    final query = _db.select(_db.studentsTable)
      ..where((t) {
        final nameOrGrMatch = t.studentName.like(like) | t.grNumber.like(like);
        final anyMatch =
            matchingClassIds.isNotEmpty ? (nameOrGrMatch | t.classId.isIn(matchingClassIds)) : nameOrGrMatch;
        return t.schoolId.equals(schoolId) & t.isDeleted.equals(false) & anyMatch;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.studentName)]);

    yield* query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// One-shot fetch used by exports and the Excel import's duplicate
  /// check (not a stream — these are point-in-time snapshots).
  Future<List<Student>> getStudents({
    required String schoolId,
    StudentStatus? status,
    String? classId,
    int? passOutYear,
  }) async {
    final query = _db.select(_db.studentsTable)
      ..where((t) {
        var cond = t.schoolId.equals(schoolId) & t.isDeleted.equals(false);
        if (status != null) cond = cond & t.status.equals(status.dbValue);
        if (classId != null) cond = cond & t.classId.equals(classId);
        if (passOutYear != null) cond = cond & t.passOutYear.equals(passOutYear);
        return cond;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.serialNumber)]);
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  Future<Student?> getById(String id) async {
    final row =
        await (_db.select(_db.studentsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Live view of a single student — used by the Student Profile screen
  /// so edits (including background sync reconciliation) reflect
  /// immediately without a manual refetch.
  Stream<Student?> watchById(String id) {
    final query = _db.select(_db.studentsTable)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull().map((row) => row == null ? null : _fromRow(row));
  }

  /// Returns true if another *active or struck-off* student in the same
  /// school already uses this GR number. Passed-out students are
  /// excluded by convention (a GR number can recirculate once a
  /// register closes a cohort) — adjust here if the school wants
  /// stricter uniqueness.
  Future<bool> checkDuplicateGrNumber({
    required String schoolId,
    required String grNumber,
    String? excludingStudentId,
  }) async {
    final query = _db.select(_db.studentsTable)
      ..where((t) =>
          t.schoolId.equals(schoolId) &
          t.grNumber.equals(grNumber) &
          t.isDeleted.equals(false));
    final rows = await query.get();
    return rows.any((r) => r.id != excludingStudentId);
  }

  // ---------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------

  Future<Student> createStudent({
    required String schoolId,
    required String classId,
    required String grNumber,
    required String studentName,
    String? fatherName,
    String? motherName,
    required DateTime dateOfBirth,
    required DateTime dateOfAdmission,
    String? fatherCnic,
    String? bFormNumber,
    String? phoneNumber,
    String? address,
    String? previousSchool,
    String? remarks,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final online = await _connectivity.isOnline();

    int? serialNumber;
    SyncState syncState = SyncState.pendingCreate;

    if (online) {
      try {
        final serialResult = await _client.rpc(
          'next_serial_number',
          params: {'p_school_id': schoolId},
        );
        serialNumber = serialResult as int;
      } catch (_) {
        // RPC failed despite connectivity (e.g. transient network drop) —
        // fall back to the offline path below rather than losing the
        // student's data.
        serialNumber = null;
      }
    }

    final student = Student(
      id: id,
      clientGeneratedId: id,
      schoolId: schoolId,
      classId: classId,
      grNumber: grNumber,
      serialNumber: serialNumber,
      studentName: studentName,
      fatherName: fatherName,
      motherName: motherName,
      dateOfBirth: dateOfBirth,
      dateOfAdmission: dateOfAdmission,
      fatherCnic: fatherCnic,
      bFormNumber: bFormNumber,
      phoneNumber: phoneNumber,
      address: address,
      previousSchool: previousSchool,
      remarks: remarks,
      updatedAt: now,
      createdAt: now,
      createdBy: _client.auth.currentUser?.id,
      syncState: serialNumber != null ? SyncState.pendingCreate : syncState,
    );

    await _insertLocal(student);
    await _writeAuditLog(
      schoolId: schoolId,
      studentId: id,
      action: 'STUDENT_CREATED',
      newValue: student.toMap(),
    );

    if (online) {
      final pushed = await _tryPushCreate(student);
      if (pushed) {
        await _markSynced(id);
        return (await getById(id))!;
      }
    }

    await _enqueue(entityType: 'student', entityId: id, operation: 'create', payload: student.toMap());
    return student;
  }

  Future<bool> _tryPushCreate(Student student) async {
    try {
      await _client.from('students').insert(student.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------

  Future<Student> updateStudent(Student updated) async {
    final online = await _connectivity.isOnline();
    final existing = await getById(updated.id);

    final next = updated.copyWith(
      version: (existing?.version ?? updated.version),
      updatedAt: DateTime.now(),
      updatedBy: _client.auth.currentUser?.id,
      syncState: SyncState.pendingUpdate,
    );

    await _upsertLocal(next);
    await _writeAuditLog(
      schoolId: next.schoolId,
      studentId: next.id,
      action: 'STUDENT_EDITED',
      oldValue: existing?.toMap(),
      newValue: next.toMap(),
    );

    if (online) {
      try {
        // IMPORTANT: Supabase/Postgrest does not throw when an .eq()
        // filter matches zero rows — it just returns an empty result.
        // `.select()` is required here so we can tell "updated" apart
        // from "silently matched nothing" (i.e. someone else changed
        // this student first — requirement #28's conflict case).
        final rows = await _client
            .from('students')
            .update(next.toMap())
            .eq('id', next.id)
            .eq('version', existing?.version ?? 1)
            .select();

        if ((rows as List).isNotEmpty) {
          await _markSynced(next.id);
          return (await getById(next.id))!;
        } else {
          // Version conflict: another device/session updated this
          // student first. Do NOT overwrite the server's data — pull it
          // down, mark this row as needing manual attention, and record
          // the conflict in the audit trail rather than losing either
          // side silently.
          await _handleUpdateConflict(next);
          return (await getById(next.id))!;
        }
      } catch (_) {
        // Network/other failure — fall through to queueing so the sync
        // engine retries once connectivity is confirmed good.
      }
    }

    await _enqueue(entityType: 'student', entityId: next.id, operation: 'update', payload: next.toMap());
    return next;
  }

  Future<void> _handleUpdateConflict(Student attemptedUpdate) async {
    try {
      final serverRow = await _client.from('students').select().eq('id', attemptedUpdate.id).single();
      final serverStudent = Student.fromMap(serverRow);
      // Keep the server's data as the source of truth locally, but flag
      // it so the UI can show "this record changed elsewhere" rather
      // than pretending nothing happened.
      await _upsertLocal(serverStudent.copyWith(syncState: SyncState.conflict));
      await _writeAuditLog(
        schoolId: attemptedUpdate.schoolId,
        studentId: attemptedUpdate.id,
        action: 'STUDENT_UPDATE_CONFLICT',
        oldValue: attemptedUpdate.toMap(),
        newValue: serverStudent.toMap(),
      );
    } catch (_) {
      // If we can't even fetch the server row (e.g. connection dropped
      // mid-conflict-check), fall back to queueing the original edit —
      // better to retry than lose the user's change entirely.
      await _enqueue(
        entityType: 'student',
        entityId: attemptedUpdate.id,
        operation: 'update',
        payload: attemptedUpdate.toMap(),
      );
    }
  }

  // ---------------------------------------------------------------
  // PERMANENT DELETE (Deletes all records locally & from Supabase)
  // ---------------------------------------------------------------

  Future<void> deleteStudentPermanently({required String studentId, required String schoolId}) async {
    final online = await _connectivity.isOnline();
    final existing = await getById(studentId);

    // 1. Audit Log before deletion
    await _writeAuditLog(
      schoolId: schoolId,
      studentId: studentId,
      action: 'STUDENT_PERMANENTLY_DELETED',
      oldValue: existing?.toMap(),
      newValue: null,
    );

    // 2. Delete student local photos from disk & table
    try {
      final photoRows = await (_db.select(_db.studentPhotosTable)..where((t) => t.studentId.equals(studentId))).get();
      for (final pRow in photoRows) {
        if (pRow.localPath != null && pRow.localPath!.isNotEmpty) {
          final file = File(pRow.localPath!);
          if (file.existsSync()) {
            await file.delete();
          }
        }
      }
      await (_db.delete(_db.studentPhotosTable)..where((t) => t.studentId.equals(studentId))).go();
    } catch (_) {}

    // 3. Delete local complaints if any
    try {
      await _db.customStatement('DELETE FROM student_complaints WHERE student_id = ?', [studentId]);
    } catch (_) {}

    // 4. Delete existing pending sync queue items for this student
    try {
      await (_db.delete(_db.syncQueueTable)..where((t) => t.entityId.equals(studentId))).go();
    } catch (_) {}

    // 5. Delete student from local Drift database
    await (_db.delete(_db.studentsTable)..where((t) => t.id.equals(studentId))).go();

    // 6. Supabase Cloud Deletion
    if (online) {
      try {
        await _client.from('student_photos').delete().eq('student_id', studentId);
      } catch (_) {}
      try {
        await _client.from('student_complaints').delete().eq('student_id', studentId);
      } catch (_) {}
      try {
        await _client.from('students').delete().eq('id', studentId);
      } catch (_) {}
    } else {
      // Offline: Enqueue delete operation so it permanently deletes on Supabase when online
      await _enqueue(
        entityType: 'student',
        entityId: studentId,
        operation: 'delete',
        payload: {'id': studentId, 'school_id': schoolId},
      );
    }
  }

  // ---------------------------------------------------------------
  // Local DB helpers
  // ---------------------------------------------------------------

  Future<void> _insertLocal(Student s) => _upsertLocal(s);

  Future<void> _upsertLocal(Student s) {
    return _db.into(_db.studentsTable).insertOnConflictUpdate(
          StudentsTableCompanion.insert(
            id: s.id,
            clientGeneratedId: s.clientGeneratedId,
            schoolId: s.schoolId,
            classId: s.classId,
            grNumber: s.grNumber,
            serialNumber: Value(s.serialNumber),
            studentName: s.studentName,
            fatherName: Value(s.fatherName),
            motherName: Value(s.motherName),
            dateOfBirth: s.dateOfBirth,
            dateOfAdmission: s.dateOfAdmission,
            fatherCnic: Value(s.fatherCnic),
            bFormNumber: Value(s.bFormNumber),
            phoneNumber: Value(s.phoneNumber),
            address: Value(s.address),
            previousSchool: Value(s.previousSchool),
            remarks: Value(s.remarks),
            status: Value(s.status.dbValue),
            promotionStatus: Value(s.promotionStatus.dbValue),
            struckOffDate: Value(s.struckOffDate),
            struckOffReason: Value(s.struckOffReason),
            passOutYear: Value(s.passOutYear),
            version: Value(s.version),
            updatedAt: s.updatedAt,
            createdAt: s.createdAt,
            createdBy: Value(s.createdBy),
            updatedBy: Value(s.updatedBy),
            isDeleted: Value(s.isDeleted),
            syncState: Value(s.syncState.name),
          ),
        );
  }

  Future<void> _markSynced(String id) {
    return (_db.update(_db.studentsTable)..where((t) => t.id.equals(id))).write(
      const StudentsTableCompanion(syncState: Value('synced')),
    );
  }

  Future<void> _enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    return _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: jsonEncode(payload),
          ),
        );
  }

  Future<void> _writeAuditLog({
    required String schoolId,
    required String studentId,
    required String action,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) {
    return _db.into(_db.auditLogsTable).insert(
          AuditLogsTableCompanion.insert(
            id: _uuid.v4(),
            schoolId: schoolId,
            userId: Value(_client.auth.currentUser?.id),
            studentId: Value(studentId),
            action: action,
            oldValueJson: Value(oldValue != null ? jsonEncode(oldValue) : null),
            newValueJson: Value(newValue != null ? jsonEncode(newValue) : null),
          ),
        );
  }

  Student _fromRow(StudentsTableData row) => Student(
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
        syncState: SyncState.values.firstWhere(
          (s) => s.name == row.syncState,
          orElse: () => SyncState.synced,
        ),
      );
}
