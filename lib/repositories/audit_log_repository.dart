import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

class AuditLogEntry {
  final String id;
  final String action;
  final String? studentId;
  final String? studentName;
  final String? userId;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.action,
    this.studentId,
    this.studentName,
    this.userId,
    this.oldValue,
    this.newValue,
    required this.createdAt,
  });

  /// Turns e.g. "STUDENT_UPDATE_CONFLICT" into "Student Update Conflict"
  /// for display.
  String get displayAction => action
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');
}

/// Requirement #26: every important modification is logged, the log is
/// append-only (no update/delete API is exposed anywhere in the app —
/// see AppDatabase/AuditLogsTable), and this repository is read-only by
/// design so the UI can never be wired to silently destroy history.
class AuditLogRepository {
  AuditLogRepository(this._db);

  final AppDatabase _db;

  Stream<List<AuditLogEntry>> watchLogs({
    required String schoolId,
    String? studentId,
    int limit = 200,
  }) {
    final query = _db.select(_db.auditLogsTable).join([
      leftOuterJoin(
        _db.studentsTable,
        _db.studentsTable.id.equalsExp(_db.auditLogsTable.studentId),
      ),
    ])
      ..where(_db.auditLogsTable.schoolId.equals(schoolId))
      ..orderBy([OrderingTerm(expression: _db.auditLogsTable.createdAt, mode: OrderingMode.desc)])
      ..limit(limit);

    if (studentId != null) {
      query.where(_db.auditLogsTable.studentId.equals(studentId));
    }

    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  AuditLogEntry _fromRow(TypedResult row) {
    final log = row.readTable(_db.auditLogsTable);
    final student = row.readTableOrNull(_db.studentsTable);
    return AuditLogEntry(
      id: log.id,
      action: log.action,
      studentId: log.studentId,
      studentName: student?.studentName,
      userId: log.userId,
      oldValue: log.oldValueJson != null ? jsonDecode(log.oldValueJson!) as Map<String, dynamic> : null,
      newValue: log.newValueJson != null ? jsonDecode(log.newValueJson!) as Map<String, dynamic> : null,
      createdAt: log.createdAt,
    );
  }
}
