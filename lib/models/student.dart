import 'enums.dart';

const _unset = Object();

class Student {
  final String id; // server uuid (may equal clientGeneratedId pre-sync)
  final String clientGeneratedId;
  final String schoolId;
  final String classId;

  final String grNumber;
  /// Null until the server allocates one via next_serial_number() on
  /// first sync. Offline-created rows show a "Pending…" placeholder in
  /// the UI instead of a number to avoid guessing (and colliding on)
  /// a value client-side.
  final int? serialNumber;

  final String studentName;
  final String? fatherName;
  final String? motherName;
  final DateTime dateOfBirth;
  final DateTime dateOfAdmission;
  final String? fatherCnic;
  final String? bFormNumber;
  final String? phoneNumber;
  final String? address;
  final String? previousSchool;
  final String? remarks;

  final StudentStatus status;
  final PromotionStatus promotionStatus;

  final DateTime? struckOffDate;
  final String? struckOffReason;

  final int? passOutYear;

  final int version;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? createdBy;
  final String? updatedBy;

  final bool isDeleted;

  /// Local-only bookkeeping (not sent to Supabase directly).
  final SyncState syncState;

  const Student({
    required this.id,
    required this.clientGeneratedId,
    required this.schoolId,
    required this.classId,
    required this.grNumber,
    this.serialNumber,
    required this.studentName,
    this.fatherName,
    this.motherName,
    required this.dateOfBirth,
    required this.dateOfAdmission,
    this.fatherCnic,
    this.bFormNumber,
    this.phoneNumber,
    this.address,
    this.previousSchool,
    this.remarks,
    this.status = StudentStatus.active,
    this.promotionStatus = PromotionStatus.none,
    this.struckOffDate,
    this.struckOffReason,
    this.passOutYear,
    this.version = 1,
    required this.updatedAt,
    required this.createdAt,
    this.createdBy,
    this.updatedBy,
    this.isDeleted = false,
    this.syncState = SyncState.synced,
  });

  Student copyWith({
    String? id,
    String? classId,
    String? grNumber,
    Object? serialNumber = _unset,
    String? studentName,
    String? fatherName,
    String? motherName,
    DateTime? dateOfBirth,
    DateTime? dateOfAdmission,
    String? fatherCnic,
    String? bFormNumber,
    String? phoneNumber,
    String? address,
    String? previousSchool,
    String? remarks,
    StudentStatus? status,
    PromotionStatus? promotionStatus,
    DateTime? struckOffDate,
    String? struckOffReason,
    int? passOutYear,
    int? version,
    DateTime? updatedAt,
    String? updatedBy,
    bool? isDeleted,
    SyncState? syncState,
  }) {
    return Student(
      id: id ?? this.id,
      clientGeneratedId: clientGeneratedId,
      schoolId: schoolId,
      classId: classId ?? this.classId,
      grNumber: grNumber ?? this.grNumber,
      serialNumber: identical(serialNumber, _unset) ? this.serialNumber : serialNumber as int?,
      studentName: studentName ?? this.studentName,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfAdmission: dateOfAdmission ?? this.dateOfAdmission,
      fatherCnic: fatherCnic ?? this.fatherCnic,
      bFormNumber: bFormNumber ?? this.bFormNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      previousSchool: previousSchool ?? this.previousSchool,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      promotionStatus: promotionStatus ?? this.promotionStatus,
      struckOffDate: struckOffDate ?? this.struckOffDate,
      struckOffReason: struckOffReason ?? this.struckOffReason,
      passOutYear: passOutYear ?? this.passOutYear,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      syncState: syncState ?? this.syncState,
    );
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      clientGeneratedId: map['client_generated_id'] as String,
      schoolId: map['school_id'] as String,
      classId: map['class_id'] as String,
      grNumber: map['gr_number'] as String,
      serialNumber: map['serial_number'] as int?,
      studentName: map['student_name'] as String,
      fatherName: map['father_name'] as String?,
      motherName: map['mother_name'] as String?,
      dateOfBirth: DateTime.parse(map['date_of_birth'] as String),
      dateOfAdmission: DateTime.parse(map['date_of_admission'] as String),
      fatherCnic: map['father_cnic'] as String?,
      bFormNumber: map['b_form_number'] as String?,
      phoneNumber: map['phone_number'] as String?,
      address: map['address'] as String?,
      previousSchool: map['previous_school'] as String?,
      remarks: map['remarks'] as String?,
      status: StudentStatusX.fromDb(map['status'] as String),
      promotionStatus: PromotionStatusX.fromDb(map['promotion_status'] as String),
      struckOffDate: map['struck_off_date'] != null
          ? DateTime.parse(map['struck_off_date'] as String)
          : null,
      struckOffReason: map['struck_off_reason'] as String?,
      passOutYear: map['pass_out_year'] as int?,
      version: map['version'] as int? ?? 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as String?,
      updatedBy: map['updated_by'] as String?,
      isDeleted: map['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_generated_id': clientGeneratedId,
      'school_id': schoolId,
      'class_id': classId,
      'gr_number': grNumber,
      'serial_number': serialNumber,
      'student_name': studentName,
      'father_name': fatherName,
      'mother_name': motherName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'date_of_admission': dateOfAdmission.toIso8601String().split('T').first,
      'father_cnic': fatherCnic,
      'b_form_number': bFormNumber,
      'phone_number': phoneNumber,
      'address': address,
      'previous_school': previousSchool,
      'remarks': remarks,
      'status': status.dbValue,
      'promotion_status': promotionStatus.dbValue,
      'struck_off_date': struckOffDate?.toIso8601String().split('T').first,
      'struck_off_reason': struckOffReason,
      'pass_out_year': passOutYear,
      'version': version,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'is_deleted': isDeleted,
    };
  }
}
