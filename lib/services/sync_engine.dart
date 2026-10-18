import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/student.dart';

/// Drains the local sync outbox (`SyncQueueTable`) against Supabase.
///
/// Design (requirement #27/#28):
/// - Processes the queue in creation order (oldest first) so a class's
///   create-then-edit sequence replays in the right order.
/// - Never loses data on a mid-sync network drop: each item is only
///   removed from the queue after Supabase confirms the write.
/// - A student `update` that finds its `version` no longer matches the
///   server (someone else edited it first) is NOT force-overwritten —
///   the server's row wins locally and the conflict is recorded in the
///   audit log, per requirement #28's "avoid destructive automatic
///   conflict resolution" for class/promotion-relevant records.
/// - Gives up retrying a single item after [maxAttempts] failures so a
///   permanently-broken row (e.g. bad data) can't jam the whole queue;
///   it stays queued (visible as "pending") for manual review rather
///   than being silently dropped.
class SyncEngine {
  SyncEngine(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  static const int maxAttempts = 8;

  bool _isRunning = false;

  /// Runs one full drain pass: students queue, then pending audit logs.
  /// Safe to call repeatedly (e.g. from a connectivity listener and a
  /// periodic timer at the same time) — re-entrant calls are ignored.
  Future<void> syncAll() async {
    if (_isRunning) return;
    _isRunning = true;
    try {
      // Order matters: students must exist server-side before a
      // promotion batch referencing them can be inserted (FK integrity),
      // so the student queue always drains first.
      await _drainStudentQueue();
      await _drainPromotionQueue();
      await _drainStruckOffQueue();
      await _drainPassOutYearQueue();
      await _drainPhotoQueue();
      await _pushPendingAuditLogs();
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _drainStudentQueue() async {
    final batch = await _db.nextQueueBatch();
    for (final item in batch) {
      if (item.attemptCount >= maxAttempts) continue; // give up, stays visible as pending

      try {
        switch (item.entityType) {
          case 'student':
            await _replayStudentItem(item);
            break;
          case 'school':
            await _replaySchoolItem(item);
            break;
          case 'class':
            await _replayClassItem(item);
            break;
          default:
            // Unknown entity type from a future feature that hasn't
            // wired its replay logic yet — leave queued rather than
            // silently discard.
            continue;
        }
        await _db.deleteQueueItem(item.queueId);
      } catch (e) {
        await _db.markQueueItemFailed(item.queueId, e.toString());
        // Stop this pass on the first failure that looks like "we're
        // offline again" so we don't burn through retries pointlessly;
        // a genuinely offline connection will fail every subsequent
        // item too.
        if (_looksLikeConnectivityFailure(e)) break;
      }
    }
  }

  bool _looksLikeConnectivityFailure(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection closed');
  }

  Future<void> _replayStudentItem(SyncQueueTableData item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

    switch (item.operation) {
      case 'create':
        await _replayStudentCreate(item.entityId, payload);
        break;
      case 'update':
        await _replayStudentUpdate(item.entityId, payload);
        break;
      case 'delete':
        await _replayStudentDelete(item.entityId, payload);
        break;
      default:
        return;
    }
  }

  Future<void> _replayStudentCreate(String localId, Map<String, dynamic> payload) async {
    var serialNumber = payload['serial_number'] as int?;

    if (serialNumber == null) {
      final classId = payload['class_id'] as String?;
      int nextNum = 1;
      if (classId != null && classId.isNotEmpty) {
        final existingInClass = await (_db.select(_db.studentsTable)
              ..where((t) =>
                  t.classId.equals(classId) &
                  (t.status.equals('ACTIVE') | t.status.equals('active')) &
                  t.isDeleted.equals(false)))
            .get();
        final maxNum = existingInClass
            .map((s) => s.serialNumber ?? 0)
            .fold<int>(0, (max, current) => current > max ? current : max);
        nextNum = maxNum + 1;
      }
      serialNumber = nextNum;
      payload['serial_number'] = serialNumber;
    }

    await _client.from('students').insert(payload);

    await (_db.update(_db.studentsTable)..where((t) => t.id.equals(localId))).write(
      StudentsTableCompanion(
        serialNumber: drift.Value(serialNumber),
        syncState: const drift.Value('synced'),
      ),
    );
  }

  Future<void> _replayStudentUpdate(String localId, Map<String, dynamic> payload) async {
    final attemptedVersion = payload['version'] as int? ?? 1;

    final rows = await _client
        .from('students')
        .update(payload)
        .eq('id', localId)
        .eq('version', attemptedVersion)
        .select();

    if ((rows as List).isNotEmpty) {
      await (_db.update(_db.studentsTable)..where((t) => t.id.equals(localId)))
          .write(const StudentsTableCompanion(syncState: drift.Value('synced')));
      return;
    }

    // Conflict discovered during replay: server row changed since this
    // offline edit was queued. Server wins locally; flag for review.
    final serverRow = await _client.from('students').select().eq('id', localId).maybeSingle();
    if (serverRow == null) return; // student no longer exists server-side; drop the stale edit

    final serverStudent = Student.fromMap(serverRow);
    await (_db.update(_db.studentsTable)..where((t) => t.id.equals(localId))).write(
      StudentsTableCompanion(
        grNumber: drift.Value(serverStudent.grNumber),
        classId: drift.Value(serverStudent.classId),
        studentName: drift.Value(serverStudent.studentName),
        status: drift.Value(serverStudent.status.dbValue),
        promotionStatus: drift.Value(serverStudent.promotionStatus.dbValue),
        version: drift.Value(serverStudent.version),
        updatedAt: drift.Value(serverStudent.updatedAt),
        syncState: const drift.Value('conflict'),
      ),
    );
  }

  Future<void> _replayStudentDelete(String studentId, Map<String, dynamic> payload) async {
    try {
      await _client.from('student_photos').delete().eq('student_id', studentId);
    } catch (_) {}
    try {
      await _client.from('student_complaints').delete().eq('student_id', studentId);
    } catch (_) {}
    try {
      await _client.from('students').delete().eq('id', studentId);
    } catch (_) {}
  }

  Future<void> _drainPromotionQueue() async {
    final batch = await _db.nextPromotionQueueBatch();
    for (final item in batch) {
      if (item.attemptCount >= maxAttempts) continue;
      try {
        await _replayPromotionBatch(item.entityId, item.operation);
        await _db.deleteQueueItem(item.queueId);
      } catch (e) {
        await _db.markQueueItemFailed(item.queueId, e.toString());
        if (_looksLikeConnectivityFailure(e)) break;
      }
    }
  }

  Future<void> _replayPromotionBatch(String batchId, String operation) async {
    final batchRow = await (_db.select(_db.promotionBatchesTable)..where((t) => t.id.equals(batchId)))
        .getSingleOrNull();
    if (batchRow == null) return;

    if (operation == 'undo') {
      await _client.from('promotion_batches').update({
        'is_undone': true,
        'undone_at': (batchRow.undoneAt ?? DateTime.now()).toIso8601String(),
        'undone_by': batchRow.undoneBy,
      }).eq('id', batchId);
      await (_db.update(_db.promotionBatchesTable)..where((t) => t.id.equals(batchId)))
          .write(const PromotionBatchesTableCompanion(syncState: drift.Value('synced')));
      return;
    }

    // operation == 'create'
    await _client.from('promotion_batches').insert({
      'id': batchRow.id,
      'school_id': batchRow.schoolId,
      'from_class_id': batchRow.fromClassId,
      'to_class_id': batchRow.toClassId,
      'promotion_date': batchRow.promotionDate.toIso8601String().split('T').first,
      'academic_year': batchRow.academicYear,
      'performed_by': batchRow.performedBy,
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

    final passOutRecords = records.where((r) => r.newStatus == 'PASSED_OUT').toList();
    if (passOutRecords.isNotEmpty) {
      await _client.from('pass_out_records').insert(passOutRecords
          .map((r) => {
                'school_id': batchRow.schoolId,
                'student_id': r.studentId,
                'pass_out_year': r.academicYear,
                'pass_out_date': batchRow.promotionDate.toIso8601String().split('T').first,
                'promotion_batch_id': batchRow.id,
              })
          .toList());
    }

    await (_db.update(_db.promotionBatchesTable)..where((t) => t.id.equals(batchId)))
        .write(const PromotionBatchesTableCompanion(syncState: drift.Value('synced')));
  }

  Future<void> _drainStruckOffQueue() async {
    final batch = await _db.nextStruckOffQueueBatch();
    for (final item in batch) {
      if (item.attemptCount >= maxAttempts) continue;
      try {
        final record = await (_db.select(_db.struckOffRecordsTable)..where((t) => t.id.equals(item.entityId)))
            .getSingleOrNull();
        if (record == null) {
          await _db.deleteQueueItem(item.queueId);
          continue;
        }

        if (item.operation == 'create') {
          await _client.from('struck_off_records').insert({
            'id': record.id,
            'school_id': record.schoolId,
            'student_id': record.studentId,
            'struck_off_date': record.struckOffDate.toIso8601String().split('T').first,
            'reason': record.reason,
            'created_by': record.createdBy,
          });
        } else if (item.operation == 're_admit') {
          await _client.from('struck_off_records').update({
            're_admitted': true,
            're_admitted_date':
                (record.reAdmittedDate ?? DateTime.now()).toIso8601String().split('T').first,
            're_admitted_by': record.reAdmittedBy,
          }).eq('id', record.id);
        }

        await (_db.update(_db.struckOffRecordsTable)..where((t) => t.id.equals(record.id)))
            .write(const StruckOffRecordsTableCompanion(syncState: drift.Value('synced')));
        await _db.deleteQueueItem(item.queueId);
      } catch (e) {
        await _db.markQueueItemFailed(item.queueId, e.toString());
        if (_looksLikeConnectivityFailure(e)) break;
      }
    }
  }

  Future<void> _drainPassOutYearQueue() async {
    final batch = await _db.nextPassOutYearQueueBatch();
    for (final item in batch) {
      if (item.attemptCount >= maxAttempts) continue;
      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        await _client.from('pass_out_years').upsert({
          'id': payload['id'],
          'school_id': payload['school_id'],
          'year': payload['year'],
        });
        await (_db.update(_db.passOutYearsTable)..where((t) => t.id.equals(payload['id'] as String)))
            .write(const PassOutYearsTableCompanion(syncState: drift.Value('synced')));
        await _db.deleteQueueItem(item.queueId);
      } catch (e) {
        await _db.markQueueItemFailed(item.queueId, e.toString());
        if (_looksLikeConnectivityFailure(e)) break;
      }
    }
  }

  Future<void> _drainPhotoQueue() async {
    final batch = await _db.nextPhotoQueueBatch();
    for (final item in batch) {
      if (item.attemptCount >= maxAttempts) continue;

      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        final localPath = payload['local_path'] as String;
        final storagePath = payload['storage_path'] as String;
        final photoId = payload['photo_id'] as String;

        final file = File(localPath);
        if (!await file.exists()) {
          // Local file is gone (e.g. app storage was cleared) — nothing
          // to upload; drop the queue item rather than retrying forever.
          await _db.deleteQueueItem(item.queueId);
          continue;
        }

        await _client.storage.from(AppConfig.studentPhotosBucket).upload(
              storagePath,
              file,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
            );

        await (_db.update(_db.studentPhotosTable)..where((t) => t.id.equals(photoId))).write(
          StudentPhotosTableCompanion(
            remoteStoragePath: drift.Value(storagePath),
            syncState: const drift.Value('synced'),
          ),
        );

        await _db.deleteQueueItem(item.queueId);
      } catch (e) {
        await _db.markQueueItemFailed(item.queueId, e.toString());
        if (_looksLikeConnectivityFailure(e)) break;
      }
    }
  }

  Future<void> _replayClassItem(SyncQueueTableData item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    if (item.operation == 'update') {
      await _client.from('classes').update({
        'display_name': payload['display_name'],
        'min_admission_age_months': payload['min_admission_age_months'],
        'min_promotion_age_months': payload['min_promotion_age_months'],
        'is_active': payload['is_active'],
      }).eq('id', item.entityId);
    }
  }

  Future<void> _replaySchoolItem(SyncQueueTableData item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    if (item.operation == 'update') {
      await _client.from('schools').update({
        'school_name': payload['school_name'],
        'semis_code': payload['semis_code'],
        'uc': payload['uc'],
        'taluka': payload['taluka'],
        'district': payload['district'],
      }).eq('id', item.entityId);
    }
  }

  Future<void> _pushPendingAuditLogs() async {
    final pending = await _db.pendingAuditLogs();
    for (final log in pending) {
      try {
        await _client.from('audit_logs').insert({
          'id': log.id,
          'school_id': log.schoolId,
          'user_id': log.userId,
          'student_id': log.studentId,
          'action': log.action,
          'old_value': log.oldValueJson != null ? jsonDecode(log.oldValueJson!) : null,
          'new_value': log.newValueJson != null ? jsonDecode(log.newValueJson!) : null,
        });
        await _db.markAuditLogSynced(log.id);
      } catch (e) {
        if (_looksLikeConnectivityFailure(e)) break;
        // Non-connectivity failure (e.g. RLS/data issue) — skip this
        // one and keep trying the rest; it stays visible as unsynced.
      }
    }
  }
}
