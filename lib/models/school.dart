class School {
  final String id;
  final String schoolName;
  final String? semisCode;
  final String? uc;
  final String? taluka;
  final String? district;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const School({
    required this.id,
    required this.schoolName,
    this.semisCode,
    this.uc,
    this.taluka,
    this.district,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  School copyWith({
    String? schoolName,
    String? semisCode,
    String? uc,
    String? taluka,
    String? district,
  }) {
    return School(
      id: id,
      schoolName: schoolName ?? this.schoolName,
      semisCode: semisCode ?? this.semisCode,
      uc: uc ?? this.uc,
      taluka: taluka ?? this.taluka,
      district: district ?? this.district,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory School.fromMap(Map<String, dynamic> map) => School(
        id: map['id'] as String,
        schoolName: map['school_name'] as String,
        semisCode: map['semis_code'] as String?,
        uc: map['uc'] as String?,
        taluka: map['taluka'] as String?,
        district: map['district'] as String?,
        createdBy: map['created_by'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'school_name': schoolName,
        'semis_code': semisCode,
        'uc': uc,
        'taluka': taluka,
        'district': district,
        'created_by': createdBy,
      };
}

class SchoolClass {
  final String id;
  final String schoolId;
  final String classCode; // 'ECE','1'..'5'
  final String displayName; // 'ECE','Class 1'..'Class 5'
  final int sortOrder;
  final int? minAdmissionAgeMonths;
  final int? minPromotionAgeMonths;
  final String? promotesToClassId;
  final bool isTerminal;
  final bool isActive;

  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.classCode,
    required this.displayName,
    required this.sortOrder,
    this.minAdmissionAgeMonths,
    this.minPromotionAgeMonths,
    this.promotesToClassId,
    this.isTerminal = false,
    this.isActive = true,
  });

  factory SchoolClass.fromMap(Map<String, dynamic> map) => SchoolClass(
        id: map['id'] as String,
        schoolId: map['school_id'] as String,
        classCode: map['class_code'] as String,
        displayName: map['display_name'] as String,
        sortOrder: map['sort_order'] as int,
        minAdmissionAgeMonths: map['min_admission_age_months'] as int?,
        minPromotionAgeMonths: map['min_promotion_age_months'] as int?,
        promotesToClassId: map['promotes_to_class_id'] as String?,
        isTerminal: map['is_terminal'] as bool? ?? false,
        isActive: map['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'school_id': schoolId,
        'class_code': classCode,
        'display_name': displayName,
        'sort_order': sortOrder,
        'min_admission_age_months': minAdmissionAgeMonths,
        'min_promotion_age_months': minPromotionAgeMonths,
        'promotes_to_class_id': promotesToClassId,
        'is_terminal': isTerminal,
        'is_active': isActive,
      };
}
