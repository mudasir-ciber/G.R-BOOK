import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../services/connectivity_service.dart';

/// Requirement #20: Pass Out Years screen shows only years that exist
/// (plus lets the user add a new one), and selecting a year shows only
/// that year's passed-out students.
class PassOutRepository {
  PassOutRepository(this._client, this._db, this._connectivity);

  final SupabaseClient _client;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final _uuid = const Uuid();

  Stream<List<int>> watchYears(String schoolId) => _db.watchPassOutYears(schoolId);

  Stream<List<Student>> watchStudentsForYear(String schoolId, int year) {
    return _db.watchPassOutStudentsForYear(schoolId, year).map((rows) => rows.map(_studentFromRow).toList());
  }

  Future<void> addYear({required String schoolId, required int year}) async {
    final id = _uuid.v4();
    final online = await _connectivity.isOnline();

    await _db.into(_db.passOutYearsTable).insertOnConflictUpdate(
          PassOutYearsTableCompanion.insert(id: id, schoolId: schoolId, year: year),
        );

    if (online) {
      try {
        await _client.from('pass_out_years').upsert({'id': id, 'school_id': schoolId, 'year': year});
        await (_db.update(_db.passOutYearsTable)..where((t) => t.id.equals(id)))
            .write(const PassOutYearsTableCompanion(syncState: drift.Value('synced')));
        return;
      } catch (_) {
        // fall through to queueing
      }
    }

    await _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            entityType: 'pass_out_year',
            entityId: id,
            operation: 'create',
            payloadJson: jsonEncode({'id': id, 'school_id': schoolId, 'year': year}),
          ),
        );
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
