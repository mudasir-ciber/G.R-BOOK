import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

/// Mirrors public.schools (subset needed offline).
class SchoolsTable extends Table {
  TextColumn get id => text()();
  TextColumn get schoolName => text()();
  TextColumn get semisCode => text().nullable()();
  TextColumn get uc => text().nullable()();
  TextColumn get taluka => text().nullable()();
  TextColumn get district => text().nullable()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirrors public.classes.
class ClassesTable extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text()();
  TextColumn get classCode => text()();
  TextColumn get displayName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get minAdmissionAgeMonths => integer().nullable()();
  IntColumn get minPromotionAgeMonths => integer().nullable()();
  TextColumn get promotesToClassId => text().nullable()();
  BoolColumn get isTerminal => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirrors public.students. `syncState` and `dirtySince` are local-only
/// bookkeeping columns that never exist on the server.
class StudentsTable extends Table {
  TextColumn get id => text()(); // = clientGeneratedId until first sync assigns server id
  TextColumn get clientGeneratedId => text()();
  TextColumn get schoolId => text()();
  TextColumn get classId => text()();
  TextColumn get grNumber => text()();
  IntColumn get serialNumber => integer().nullable()(); // null until server allocates one offline-created row
  TextColumn get studentName => text()();
  TextColumn get fatherName => text().nullable()();
  TextColumn get motherName => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime()();
  DateTimeColumn get dateOfAdmission => dateTime()();
  TextColumn get fatherCnic => text().nullable()();
  TextColumn get bFormNumber => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get previousSchool => text().nullable()();
  TextColumn get previousGrNumber => text().nullable()();
  TextColumn get remarks => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  TextColumn get promotionStatus => text().withDefault(const Constant('NONE'))();
  DateTimeColumn get struckOffDate => dateTime().nullable()();
  TextColumn get struckOffReason => text().nullable()();
  IntColumn get passOutYear => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Local-only sync bookkeeping:
  TextColumn get syncState => text().withDefault(const Constant('synced'))();
  DateTimeColumn get dirtySince => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirrors public.promotion_batches. Offline-created batches use the
/// same id locally and on the server (no remapping needed), matching
/// the pattern already used for StudentsTable.
class PromotionBatchesTable extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text()();
  TextColumn get fromClassId => text()();
  TextColumn get toClassId => text().nullable()(); // null => this batch results in Pass Out
  DateTimeColumn get promotionDate => dateTime()();
  IntColumn get academicYear => integer()();
  TextColumn get performedBy => text().nullable()();
  BoolColumn get isUndone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get undoneAt => dateTime().nullable()();
  TextColumn get undoneBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncState => text().withDefault(const Constant('pendingCreate'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirrors public.promotion_records — one row per student per batch,
/// including FAILED outcomes (requirement #17/#18: never destroy
/// historical promotion information).
class PromotionRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get batchId => text()();
  TextColumn get studentId => text()();
  TextColumn get previousClassId => text()();
  TextColumn get newClassId => text().nullable()();
  TextColumn get previousStatus => text()();
  TextColumn get newStatus => text()();
  TextColumn get result => text()(); // PROMOTED | FAILED
  IntColumn get academicYear => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirrors public.struck_off_records. Requirement #21: never physically
/// delete a struck-off event — re-admission flips `reAdmitted` on the
/// same row rather than removing it.
class StruckOffRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text()();
  TextColumn get studentId => text()();
  DateTimeColumn get struckOffDate => dateTime()();
  TextColumn get reason => text()();
  BoolColumn get reAdmitted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get reAdmittedDate => dateTime().nullable()();
  TextColumn get reAdmittedBy => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncState => text().withDefault(const Constant('pendingCreate'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks which pass-out years exist for a school (requirement #20's
/// "Pass Out Years screen should show only years that actually exist in
/// the system, plus Add New Year") — a year can be added before any
/// student has actually passed out into it yet, so this can't be
/// derived purely from `students.pass_out_year`.
class PassOutYearsTable extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text()();
  IntColumn get year => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncState => text().withDefault(const Constant('pendingCreate'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbox pattern: every offline mutation is recorded here with enough
/// payload to replay against Supabase once connectivity returns. This is
/// what makes create/update/promote/struck-off/photo-upload all safely
/// synchronizable per requirement #27.
class SyncQueueTable extends Table {
  IntColumn get queueId => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'student' | 'promotion_batch' | 'struck_off' | 'photo' | ...
  TextColumn get entityId => text()(); // local id of the affected row
  TextColumn get operation => text()(); // 'create' | 'update' | 'delete' | 'promote' | 'struck_off' | 're_admit' | 'photo_upload'
  TextColumn get payloadJson => text()(); // full serialized payload needed to replay
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// Local cache of signed URLs / local file paths for the 4 photo slots.
class StudentPhotosTable extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text()();
  TextColumn get photoType => text()(); // STUDENT | B_FORM | FATHER_CNIC | TOKEN
  TextColumn get localPath => text().nullable()(); // compressed local copy
  TextColumn get remoteStoragePath => text().nullable()(); // storage.objects path once uploaded
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncState => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only local mirror of audit events, written immediately on
/// every mutation (even offline) and reconciled with server audit_logs
/// on sync. Never exposed with an update/delete API from the app layer.
class AuditLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get studentId => text().nullable()();
  TextColumn get action => text()();
  TextColumn get oldValueJson => text().nullable()();
  TextColumn get newValueJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncState => text().withDefault(const Constant('pendingCreate'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  SchoolsTable,
  ClassesTable,
  StudentsTable,
  SyncQueueTable,
  StudentPhotosTable,
  AuditLogsTable,
  PromotionBatchesTable,
  PromotionRecordsTable,
  StruckOffRecordsTable,
  PassOutYearsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Never a destructive drop — the local DB may hold unsynced
          // student/photo data that must survive every app update.
          if (from < 2) {
            await m.createTable(promotionBatchesTable);
            await m.createTable(promotionRecordsTable);
          }
          if (from < 3) {
            await m.createTable(struckOffRecordsTable);
            await m.createTable(passOutYearsTable);
          }
          if (from < 4) {
            await m.addColumn(studentsTable, studentsTable.previousGrNumber);
          }
        },
        beforeOpen: (details) async {
          try {
            await customStatement('ALTER TABLE students ADD COLUMN previous_gr_number TEXT;');
          } catch (_) {
            // Already added or newly created database
          }
        },
      );

  // ---- Convenience queries used across repositories ----

  Future<List<StudentsTableData>> studentsForClass(String classId) {
    return (select(studentsTable)
          ..where((t) => t.classId.equals(classId) & t.isDeleted.equals(false)))
        .get();
  }

  Stream<List<StudentsTableData>> watchStudentsForClass(String classId, {required String status}) {
    return (select(studentsTable)
          ..where((t) =>
              t.classId.equals(classId) &
              t.status.equals(status) &
              t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.serialNumber)]))
        .watch();
  }

  Future<int> pendingSyncCount() async {
    final rows = await select(syncQueueTable).get();
    return rows.length;
  }

  /// Live pending-item count for the sync status banner (requirement #27).
  Stream<int> watchPendingSyncCount() {
    final countExp = syncQueueTable.queueId.count();
    final query = selectOnly(syncQueueTable)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  static const _queuedIndependently = ['photo', 'promotion_batch', 'struck_off_record', 'pass_out_year'];

  Future<List<SyncQueueTableData>> nextQueueBatch({int limit = 50}) {
    return (select(syncQueueTable)
          ..where((t) => t.entityType.isNotIn(_queuedIndependently))
          ..orderBy([(t) => OrderingTerm(expression: t.queueId)])
          ..limit(limit))
        .get();
  }

  Future<void> deleteQueueItem(int queueId) {
    return (delete(syncQueueTable)..where((t) => t.queueId.equals(queueId))).go();
  }

  Future<void> markQueueItemFailed(int queueId, String error) async {
    final row = await (select(syncQueueTable)..where((t) => t.queueId.equals(queueId)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(syncQueueTable)..where((t) => t.queueId.equals(queueId))).write(
      SyncQueueTableCompanion(
        attemptCount: Value(row.attemptCount + 1),
        lastError: Value(error),
      ),
    );
  }

  /// All photo rows for a student (every version, every slot) — the
  /// repository/UI picks the latest version per photoType from this.
  Stream<List<StudentPhotosTableData>> watchStudentPhotos(String studentId) {
    final query = select(studentPhotosTable)..where((t) => t.studentId.equals(studentId));
    return query.watch();
  }

  /// Union of explicitly-added years (PassOutYearsTable) and any year
  /// that already has passed-out students, so a year is never missing
  /// just because it predates the dedicated years table.
  Stream<List<int>> watchPassOutYears(String schoolId) {
    final addedYears = (select(passOutYearsTable)..where((t) => t.schoolId.equals(schoolId))).watch();
    final studentYears = (selectOnly(studentsTable, distinct: true)
          ..addColumns([studentsTable.passOutYear])
          ..where(studentsTable.schoolId.equals(schoolId) &
              studentsTable.status.equals('PASSED_OUT') &
              studentsTable.passOutYear.isNotNull()))
        .watch()
        .map((rows) => rows.map((r) => r.read(studentsTable.passOutYear)!).toList());

    return addedYears.asyncMap((added) async {
      final fromStudents = await studentYears.first;
      final years = <int>{...added.map((r) => r.year), ...fromStudents};
      final sorted = years.toList()..sort();
      return sorted;
    });
  }

  Stream<List<StudentsTableData>> watchPassOutStudentsForYear(String schoolId, int year) {
    final query = select(studentsTable)
      ..where((t) =>
          t.schoolId.equals(schoolId) & t.status.equals('PASSED_OUT') & t.passOutYear.equals(year))
      ..orderBy([(t) => OrderingTerm(expression: t.serialNumber)]);
    return query.watch();
  }

  Stream<List<StudentsTableData>> watchStruckOffStudents(String schoolId) {
    final query = select(studentsTable)
      ..where((t) => t.schoolId.equals(schoolId) & t.status.equals('STRUCK_OFF') & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.struckOffDate, mode: OrderingMode.desc)]);
    return query.watch();
  }

  Future<List<SyncQueueTableData>> nextStruckOffQueueBatch({int limit = 20}) {
    return (select(syncQueueTable)
          ..where((t) => t.entityType.equals('struck_off_record'))
          ..orderBy([(t) => OrderingTerm(expression: t.queueId)])
          ..limit(limit))
        .get();
  }

  Future<List<SyncQueueTableData>> nextPassOutYearQueueBatch({int limit = 20}) {
    return (select(syncQueueTable)
          ..where((t) => t.entityType.equals('pass_out_year'))
          ..orderBy([(t) => OrderingTerm(expression: t.queueId)])
          ..limit(limit))
        .get();
  }

  Future<List<SyncQueueTableData>> nextPromotionQueueBatch({int limit = 20}) {
    return (select(syncQueueTable)
          ..where((t) => t.entityType.equals('promotion_batch'))
          ..orderBy([(t) => OrderingTerm(expression: t.queueId)])
          ..limit(limit))
        .get();
  }

  /// Most recent non-undone batch for a class — drives the "Undo Last
  /// Promotion" affordance (requirement #19).
  Future<PromotionBatchesTableData?> latestActiveBatchForClass(String fromClassId) {
    return (select(promotionBatchesTable)
          ..where((t) => t.fromClassId.equals(fromClassId) & t.isUndone.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<PromotionRecordsTableData>> recordsForBatch(String batchId) {
    return (select(promotionRecordsTable)..where((t) => t.batchId.equals(batchId))).get();
  }

  Future<List<SyncQueueTableData>> nextPhotoQueueBatch({int limit = 20}) {
    return (select(syncQueueTable)
          ..where((t) => t.entityType.equals('photo'))
          ..orderBy([(t) => OrderingTerm(expression: t.queueId)])
          ..limit(limit))
        .get();
  }

  /// Pending (unsynced) audit log rows, oldest first, for the sync engine.
  Future<List<AuditLogsTableData>> pendingAuditLogs() {
    return (select(auditLogsTable)..where((t) => t.syncState.equals('pendingCreate'))).get();
  }

  Future<void> markAuditLogSynced(String id) {
    return (update(auditLogsTable)..where((t) => t.id.equals(id)))
        .write(const AuditLogsTableCompanion(syncState: Value('synced')));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Ensures the bundled sqlite3 native library is available on all
    // supported Android versions (10 through 16) without relying on the
    // OS-provided sqlite, which varies by OEM/API level.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gr_book.sqlite'));
    return NativeDatabase.createInBackground(file, logStatements: false);
  });
}
