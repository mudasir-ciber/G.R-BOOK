// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SchoolsTableTable extends SchoolsTable
    with TableInfo<$SchoolsTableTable, SchoolsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchoolsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolNameMeta =
      const VerificationMeta('schoolName');
  @override
  late final GeneratedColumn<String> schoolName = GeneratedColumn<String>(
      'school_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _semisCodeMeta =
      const VerificationMeta('semisCode');
  @override
  late final GeneratedColumn<String> semisCode = GeneratedColumn<String>(
      'semis_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ucMeta = const VerificationMeta('uc');
  @override
  late final GeneratedColumn<String> uc = GeneratedColumn<String>(
      'uc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _talukaMeta = const VerificationMeta('taluka');
  @override
  late final GeneratedColumn<String> taluka = GeneratedColumn<String>(
      'taluka', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _districtMeta =
      const VerificationMeta('district');
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
      'district', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        schoolName,
        semisCode,
        uc,
        taluka,
        district,
        createdBy,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schools_table';
  @override
  VerificationContext validateIntegrity(Insertable<SchoolsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_name')) {
      context.handle(
          _schoolNameMeta,
          schoolName.isAcceptableOrUnknown(
              data['school_name']!, _schoolNameMeta));
    } else if (isInserting) {
      context.missing(_schoolNameMeta);
    }
    if (data.containsKey('semis_code')) {
      context.handle(_semisCodeMeta,
          semisCode.isAcceptableOrUnknown(data['semis_code']!, _semisCodeMeta));
    }
    if (data.containsKey('uc')) {
      context.handle(_ucMeta, uc.isAcceptableOrUnknown(data['uc']!, _ucMeta));
    }
    if (data.containsKey('taluka')) {
      context.handle(_talukaMeta,
          taluka.isAcceptableOrUnknown(data['taluka']!, _talukaMeta));
    }
    if (data.containsKey('district')) {
      context.handle(_districtMeta,
          district.isAcceptableOrUnknown(data['district']!, _districtMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchoolsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchoolsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      schoolName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_name'])!,
      semisCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semis_code']),
      uc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uc']),
      taluka: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}taluka']),
      district: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}district']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SchoolsTableTable createAlias(String alias) {
    return $SchoolsTableTable(attachedDatabase, alias);
  }
}

class SchoolsTableData extends DataClass
    implements Insertable<SchoolsTableData> {
  final String id;
  final String schoolName;
  final String? semisCode;
  final String? uc;
  final String? taluka;
  final String? district;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SchoolsTableData(
      {required this.id,
      required this.schoolName,
      this.semisCode,
      this.uc,
      this.taluka,
      this.district,
      required this.createdBy,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_name'] = Variable<String>(schoolName);
    if (!nullToAbsent || semisCode != null) {
      map['semis_code'] = Variable<String>(semisCode);
    }
    if (!nullToAbsent || uc != null) {
      map['uc'] = Variable<String>(uc);
    }
    if (!nullToAbsent || taluka != null) {
      map['taluka'] = Variable<String>(taluka);
    }
    if (!nullToAbsent || district != null) {
      map['district'] = Variable<String>(district);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SchoolsTableCompanion toCompanion(bool nullToAbsent) {
    return SchoolsTableCompanion(
      id: Value(id),
      schoolName: Value(schoolName),
      semisCode: semisCode == null && nullToAbsent
          ? const Value.absent()
          : Value(semisCode),
      uc: uc == null && nullToAbsent ? const Value.absent() : Value(uc),
      taluka:
          taluka == null && nullToAbsent ? const Value.absent() : Value(taluka),
      district: district == null && nullToAbsent
          ? const Value.absent()
          : Value(district),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SchoolsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchoolsTableData(
      id: serializer.fromJson<String>(json['id']),
      schoolName: serializer.fromJson<String>(json['schoolName']),
      semisCode: serializer.fromJson<String?>(json['semisCode']),
      uc: serializer.fromJson<String?>(json['uc']),
      taluka: serializer.fromJson<String?>(json['taluka']),
      district: serializer.fromJson<String?>(json['district']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolName': serializer.toJson<String>(schoolName),
      'semisCode': serializer.toJson<String?>(semisCode),
      'uc': serializer.toJson<String?>(uc),
      'taluka': serializer.toJson<String?>(taluka),
      'district': serializer.toJson<String?>(district),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SchoolsTableData copyWith(
          {String? id,
          String? schoolName,
          Value<String?> semisCode = const Value.absent(),
          Value<String?> uc = const Value.absent(),
          Value<String?> taluka = const Value.absent(),
          Value<String?> district = const Value.absent(),
          String? createdBy,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SchoolsTableData(
        id: id ?? this.id,
        schoolName: schoolName ?? this.schoolName,
        semisCode: semisCode.present ? semisCode.value : this.semisCode,
        uc: uc.present ? uc.value : this.uc,
        taluka: taluka.present ? taluka.value : this.taluka,
        district: district.present ? district.value : this.district,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SchoolsTableData copyWithCompanion(SchoolsTableCompanion data) {
    return SchoolsTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolName:
          data.schoolName.present ? data.schoolName.value : this.schoolName,
      semisCode: data.semisCode.present ? data.semisCode.value : this.semisCode,
      uc: data.uc.present ? data.uc.value : this.uc,
      taluka: data.taluka.present ? data.taluka.value : this.taluka,
      district: data.district.present ? data.district.value : this.district,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchoolsTableData(')
          ..write('id: $id, ')
          ..write('schoolName: $schoolName, ')
          ..write('semisCode: $semisCode, ')
          ..write('uc: $uc, ')
          ..write('taluka: $taluka, ')
          ..write('district: $district, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, schoolName, semisCode, uc, taluka,
      district, createdBy, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchoolsTableData &&
          other.id == this.id &&
          other.schoolName == this.schoolName &&
          other.semisCode == this.semisCode &&
          other.uc == this.uc &&
          other.taluka == this.taluka &&
          other.district == this.district &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SchoolsTableCompanion extends UpdateCompanion<SchoolsTableData> {
  final Value<String> id;
  final Value<String> schoolName;
  final Value<String?> semisCode;
  final Value<String?> uc;
  final Value<String?> taluka;
  final Value<String?> district;
  final Value<String> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SchoolsTableCompanion({
    this.id = const Value.absent(),
    this.schoolName = const Value.absent(),
    this.semisCode = const Value.absent(),
    this.uc = const Value.absent(),
    this.taluka = const Value.absent(),
    this.district = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchoolsTableCompanion.insert({
    required String id,
    required String schoolName,
    this.semisCode = const Value.absent(),
    this.uc = const Value.absent(),
    this.taluka = const Value.absent(),
    this.district = const Value.absent(),
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        schoolName = Value(schoolName),
        createdBy = Value(createdBy),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SchoolsTableData> custom({
    Expression<String>? id,
    Expression<String>? schoolName,
    Expression<String>? semisCode,
    Expression<String>? uc,
    Expression<String>? taluka,
    Expression<String>? district,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolName != null) 'school_name': schoolName,
      if (semisCode != null) 'semis_code': semisCode,
      if (uc != null) 'uc': uc,
      if (taluka != null) 'taluka': taluka,
      if (district != null) 'district': district,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchoolsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? schoolName,
      Value<String?>? semisCode,
      Value<String?>? uc,
      Value<String?>? taluka,
      Value<String?>? district,
      Value<String>? createdBy,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SchoolsTableCompanion(
      id: id ?? this.id,
      schoolName: schoolName ?? this.schoolName,
      semisCode: semisCode ?? this.semisCode,
      uc: uc ?? this.uc,
      taluka: taluka ?? this.taluka,
      district: district ?? this.district,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolName.present) {
      map['school_name'] = Variable<String>(schoolName.value);
    }
    if (semisCode.present) {
      map['semis_code'] = Variable<String>(semisCode.value);
    }
    if (uc.present) {
      map['uc'] = Variable<String>(uc.value);
    }
    if (taluka.present) {
      map['taluka'] = Variable<String>(taluka.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchoolsTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolName: $schoolName, ')
          ..write('semisCode: $semisCode, ')
          ..write('uc: $uc, ')
          ..write('taluka: $taluka, ')
          ..write('district: $district, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassesTableTable extends ClassesTable
    with TableInfo<$ClassesTableTable, ClassesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classCodeMeta =
      const VerificationMeta('classCode');
  @override
  late final GeneratedColumn<String> classCode = GeneratedColumn<String>(
      'class_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minAdmissionAgeMonthsMeta =
      const VerificationMeta('minAdmissionAgeMonths');
  @override
  late final GeneratedColumn<int> minAdmissionAgeMonths = GeneratedColumn<int>(
      'min_admission_age_months', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minPromotionAgeMonthsMeta =
      const VerificationMeta('minPromotionAgeMonths');
  @override
  late final GeneratedColumn<int> minPromotionAgeMonths = GeneratedColumn<int>(
      'min_promotion_age_months', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _promotesToClassIdMeta =
      const VerificationMeta('promotesToClassId');
  @override
  late final GeneratedColumn<String> promotesToClassId =
      GeneratedColumn<String>('promotes_to_class_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isTerminalMeta =
      const VerificationMeta('isTerminal');
  @override
  late final GeneratedColumn<bool> isTerminal = GeneratedColumn<bool>(
      'is_terminal', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_terminal" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        schoolId,
        classCode,
        displayName,
        sortOrder,
        minAdmissionAgeMonths,
        minPromotionAgeMonths,
        promotesToClassId,
        isTerminal,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classes_table';
  @override
  VerificationContext validateIntegrity(Insertable<ClassesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('class_code')) {
      context.handle(_classCodeMeta,
          classCode.isAcceptableOrUnknown(data['class_code']!, _classCodeMeta));
    } else if (isInserting) {
      context.missing(_classCodeMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('min_admission_age_months')) {
      context.handle(
          _minAdmissionAgeMonthsMeta,
          minAdmissionAgeMonths.isAcceptableOrUnknown(
              data['min_admission_age_months']!, _minAdmissionAgeMonthsMeta));
    }
    if (data.containsKey('min_promotion_age_months')) {
      context.handle(
          _minPromotionAgeMonthsMeta,
          minPromotionAgeMonths.isAcceptableOrUnknown(
              data['min_promotion_age_months']!, _minPromotionAgeMonthsMeta));
    }
    if (data.containsKey('promotes_to_class_id')) {
      context.handle(
          _promotesToClassIdMeta,
          promotesToClassId.isAcceptableOrUnknown(
              data['promotes_to_class_id']!, _promotesToClassIdMeta));
    }
    if (data.containsKey('is_terminal')) {
      context.handle(
          _isTerminalMeta,
          isTerminal.isAcceptableOrUnknown(
              data['is_terminal']!, _isTerminalMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id'])!,
      classCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_code'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      minAdmissionAgeMonths: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}min_admission_age_months']),
      minPromotionAgeMonths: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}min_promotion_age_months']),
      promotesToClassId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}promotes_to_class_id']),
      isTerminal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_terminal'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $ClassesTableTable createAlias(String alias) {
    return $ClassesTableTable(attachedDatabase, alias);
  }
}

class ClassesTableData extends DataClass
    implements Insertable<ClassesTableData> {
  final String id;
  final String schoolId;
  final String classCode;
  final String displayName;
  final int sortOrder;
  final int? minAdmissionAgeMonths;
  final int? minPromotionAgeMonths;
  final String? promotesToClassId;
  final bool isTerminal;
  final bool isActive;
  const ClassesTableData(
      {required this.id,
      required this.schoolId,
      required this.classCode,
      required this.displayName,
      required this.sortOrder,
      this.minAdmissionAgeMonths,
      this.minPromotionAgeMonths,
      this.promotesToClassId,
      required this.isTerminal,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    map['class_code'] = Variable<String>(classCode);
    map['display_name'] = Variable<String>(displayName);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || minAdmissionAgeMonths != null) {
      map['min_admission_age_months'] = Variable<int>(minAdmissionAgeMonths);
    }
    if (!nullToAbsent || minPromotionAgeMonths != null) {
      map['min_promotion_age_months'] = Variable<int>(minPromotionAgeMonths);
    }
    if (!nullToAbsent || promotesToClassId != null) {
      map['promotes_to_class_id'] = Variable<String>(promotesToClassId);
    }
    map['is_terminal'] = Variable<bool>(isTerminal);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  ClassesTableCompanion toCompanion(bool nullToAbsent) {
    return ClassesTableCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      classCode: Value(classCode),
      displayName: Value(displayName),
      sortOrder: Value(sortOrder),
      minAdmissionAgeMonths: minAdmissionAgeMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(minAdmissionAgeMonths),
      minPromotionAgeMonths: minPromotionAgeMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(minPromotionAgeMonths),
      promotesToClassId: promotesToClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(promotesToClassId),
      isTerminal: Value(isTerminal),
      isActive: Value(isActive),
    );
  }

  factory ClassesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassesTableData(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      classCode: serializer.fromJson<String>(json['classCode']),
      displayName: serializer.fromJson<String>(json['displayName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      minAdmissionAgeMonths:
          serializer.fromJson<int?>(json['minAdmissionAgeMonths']),
      minPromotionAgeMonths:
          serializer.fromJson<int?>(json['minPromotionAgeMonths']),
      promotesToClassId:
          serializer.fromJson<String?>(json['promotesToClassId']),
      isTerminal: serializer.fromJson<bool>(json['isTerminal']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'classCode': serializer.toJson<String>(classCode),
      'displayName': serializer.toJson<String>(displayName),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'minAdmissionAgeMonths': serializer.toJson<int?>(minAdmissionAgeMonths),
      'minPromotionAgeMonths': serializer.toJson<int?>(minPromotionAgeMonths),
      'promotesToClassId': serializer.toJson<String?>(promotesToClassId),
      'isTerminal': serializer.toJson<bool>(isTerminal),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  ClassesTableData copyWith(
          {String? id,
          String? schoolId,
          String? classCode,
          String? displayName,
          int? sortOrder,
          Value<int?> minAdmissionAgeMonths = const Value.absent(),
          Value<int?> minPromotionAgeMonths = const Value.absent(),
          Value<String?> promotesToClassId = const Value.absent(),
          bool? isTerminal,
          bool? isActive}) =>
      ClassesTableData(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        classCode: classCode ?? this.classCode,
        displayName: displayName ?? this.displayName,
        sortOrder: sortOrder ?? this.sortOrder,
        minAdmissionAgeMonths: minAdmissionAgeMonths.present
            ? minAdmissionAgeMonths.value
            : this.minAdmissionAgeMonths,
        minPromotionAgeMonths: minPromotionAgeMonths.present
            ? minPromotionAgeMonths.value
            : this.minPromotionAgeMonths,
        promotesToClassId: promotesToClassId.present
            ? promotesToClassId.value
            : this.promotesToClassId,
        isTerminal: isTerminal ?? this.isTerminal,
        isActive: isActive ?? this.isActive,
      );
  ClassesTableData copyWithCompanion(ClassesTableCompanion data) {
    return ClassesTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      classCode: data.classCode.present ? data.classCode.value : this.classCode,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      minAdmissionAgeMonths: data.minAdmissionAgeMonths.present
          ? data.minAdmissionAgeMonths.value
          : this.minAdmissionAgeMonths,
      minPromotionAgeMonths: data.minPromotionAgeMonths.present
          ? data.minPromotionAgeMonths.value
          : this.minPromotionAgeMonths,
      promotesToClassId: data.promotesToClassId.present
          ? data.promotesToClassId.value
          : this.promotesToClassId,
      isTerminal:
          data.isTerminal.present ? data.isTerminal.value : this.isTerminal,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassesTableData(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('classCode: $classCode, ')
          ..write('displayName: $displayName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('minAdmissionAgeMonths: $minAdmissionAgeMonths, ')
          ..write('minPromotionAgeMonths: $minPromotionAgeMonths, ')
          ..write('promotesToClassId: $promotesToClassId, ')
          ..write('isTerminal: $isTerminal, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      schoolId,
      classCode,
      displayName,
      sortOrder,
      minAdmissionAgeMonths,
      minPromotionAgeMonths,
      promotesToClassId,
      isTerminal,
      isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassesTableData &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.classCode == this.classCode &&
          other.displayName == this.displayName &&
          other.sortOrder == this.sortOrder &&
          other.minAdmissionAgeMonths == this.minAdmissionAgeMonths &&
          other.minPromotionAgeMonths == this.minPromotionAgeMonths &&
          other.promotesToClassId == this.promotesToClassId &&
          other.isTerminal == this.isTerminal &&
          other.isActive == this.isActive);
}

class ClassesTableCompanion extends UpdateCompanion<ClassesTableData> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<String> classCode;
  final Value<String> displayName;
  final Value<int> sortOrder;
  final Value<int?> minAdmissionAgeMonths;
  final Value<int?> minPromotionAgeMonths;
  final Value<String?> promotesToClassId;
  final Value<bool> isTerminal;
  final Value<bool> isActive;
  final Value<int> rowid;
  const ClassesTableCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.classCode = const Value.absent(),
    this.displayName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.minAdmissionAgeMonths = const Value.absent(),
    this.minPromotionAgeMonths = const Value.absent(),
    this.promotesToClassId = const Value.absent(),
    this.isTerminal = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassesTableCompanion.insert({
    required String id,
    required String schoolId,
    required String classCode,
    required String displayName,
    this.sortOrder = const Value.absent(),
    this.minAdmissionAgeMonths = const Value.absent(),
    this.minPromotionAgeMonths = const Value.absent(),
    this.promotesToClassId = const Value.absent(),
    this.isTerminal = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        schoolId = Value(schoolId),
        classCode = Value(classCode),
        displayName = Value(displayName);
  static Insertable<ClassesTableData> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<String>? classCode,
    Expression<String>? displayName,
    Expression<int>? sortOrder,
    Expression<int>? minAdmissionAgeMonths,
    Expression<int>? minPromotionAgeMonths,
    Expression<String>? promotesToClassId,
    Expression<bool>? isTerminal,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (classCode != null) 'class_code': classCode,
      if (displayName != null) 'display_name': displayName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (minAdmissionAgeMonths != null)
        'min_admission_age_months': minAdmissionAgeMonths,
      if (minPromotionAgeMonths != null)
        'min_promotion_age_months': minPromotionAgeMonths,
      if (promotesToClassId != null) 'promotes_to_class_id': promotesToClassId,
      if (isTerminal != null) 'is_terminal': isTerminal,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? schoolId,
      Value<String>? classCode,
      Value<String>? displayName,
      Value<int>? sortOrder,
      Value<int?>? minAdmissionAgeMonths,
      Value<int?>? minPromotionAgeMonths,
      Value<String?>? promotesToClassId,
      Value<bool>? isTerminal,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return ClassesTableCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      classCode: classCode ?? this.classCode,
      displayName: displayName ?? this.displayName,
      sortOrder: sortOrder ?? this.sortOrder,
      minAdmissionAgeMonths:
          minAdmissionAgeMonths ?? this.minAdmissionAgeMonths,
      minPromotionAgeMonths:
          minPromotionAgeMonths ?? this.minPromotionAgeMonths,
      promotesToClassId: promotesToClassId ?? this.promotesToClassId,
      isTerminal: isTerminal ?? this.isTerminal,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (classCode.present) {
      map['class_code'] = Variable<String>(classCode.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (minAdmissionAgeMonths.present) {
      map['min_admission_age_months'] =
          Variable<int>(minAdmissionAgeMonths.value);
    }
    if (minPromotionAgeMonths.present) {
      map['min_promotion_age_months'] =
          Variable<int>(minPromotionAgeMonths.value);
    }
    if (promotesToClassId.present) {
      map['promotes_to_class_id'] = Variable<String>(promotesToClassId.value);
    }
    if (isTerminal.present) {
      map['is_terminal'] = Variable<bool>(isTerminal.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassesTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('classCode: $classCode, ')
          ..write('displayName: $displayName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('minAdmissionAgeMonths: $minAdmissionAgeMonths, ')
          ..write('minPromotionAgeMonths: $minPromotionAgeMonths, ')
          ..write('promotesToClassId: $promotesToClassId, ')
          ..write('isTerminal: $isTerminal, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudentsTableTable extends StudentsTable
    with TableInfo<$StudentsTableTable, StudentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientGeneratedIdMeta =
      const VerificationMeta('clientGeneratedId');
  @override
  late final GeneratedColumn<String> clientGeneratedId =
      GeneratedColumn<String>('client_generated_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
      'class_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _grNumberMeta =
      const VerificationMeta('grNumber');
  @override
  late final GeneratedColumn<String> grNumber = GeneratedColumn<String>(
      'gr_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serialNumberMeta =
      const VerificationMeta('serialNumber');
  @override
  late final GeneratedColumn<int> serialNumber = GeneratedColumn<int>(
      'serial_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _studentNameMeta =
      const VerificationMeta('studentName');
  @override
  late final GeneratedColumn<String> studentName = GeneratedColumn<String>(
      'student_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fatherNameMeta =
      const VerificationMeta('fatherName');
  @override
  late final GeneratedColumn<String> fatherName = GeneratedColumn<String>(
      'father_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _motherNameMeta =
      const VerificationMeta('motherName');
  @override
  late final GeneratedColumn<String> motherName = GeneratedColumn<String>(
      'mother_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateOfBirthMeta =
      const VerificationMeta('dateOfBirth');
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
      'date_of_birth', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dateOfAdmissionMeta =
      const VerificationMeta('dateOfAdmission');
  @override
  late final GeneratedColumn<DateTime> dateOfAdmission =
      GeneratedColumn<DateTime>('date_of_admission', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _fatherCnicMeta =
      const VerificationMeta('fatherCnic');
  @override
  late final GeneratedColumn<String> fatherCnic = GeneratedColumn<String>(
      'father_cnic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bFormNumberMeta =
      const VerificationMeta('bFormNumber');
  @override
  late final GeneratedColumn<String> bFormNumber = GeneratedColumn<String>(
      'b_form_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _previousSchoolMeta =
      const VerificationMeta('previousSchool');
  @override
  late final GeneratedColumn<String> previousSchool = GeneratedColumn<String>(
      'previous_school', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remarksMeta =
      const VerificationMeta('remarks');
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
      'remarks', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('ACTIVE'));
  static const VerificationMeta _promotionStatusMeta =
      const VerificationMeta('promotionStatus');
  @override
  late final GeneratedColumn<String> promotionStatus = GeneratedColumn<String>(
      'promotion_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('NONE'));
  static const VerificationMeta _struckOffDateMeta =
      const VerificationMeta('struckOffDate');
  @override
  late final GeneratedColumn<DateTime> struckOffDate =
      GeneratedColumn<DateTime>('struck_off_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _struckOffReasonMeta =
      const VerificationMeta('struckOffReason');
  @override
  late final GeneratedColumn<String> struckOffReason = GeneratedColumn<String>(
      'struck_off_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _passOutYearMeta =
      const VerificationMeta('passOutYear');
  @override
  late final GeneratedColumn<int> passOutYear = GeneratedColumn<int>(
      'pass_out_year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedByMeta =
      const VerificationMeta('updatedBy');
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
      'updated_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _dirtySinceMeta =
      const VerificationMeta('dirtySince');
  @override
  late final GeneratedColumn<DateTime> dirtySince = GeneratedColumn<DateTime>(
      'dirty_since', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientGeneratedId,
        schoolId,
        classId,
        grNumber,
        serialNumber,
        studentName,
        fatherName,
        motherName,
        dateOfBirth,
        dateOfAdmission,
        fatherCnic,
        bFormNumber,
        phoneNumber,
        address,
        previousSchool,
        remarks,
        status,
        promotionStatus,
        struckOffDate,
        struckOffReason,
        passOutYear,
        version,
        updatedAt,
        createdAt,
        createdBy,
        updatedBy,
        isDeleted,
        syncState,
        dirtySince
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students_table';
  @override
  VerificationContext validateIntegrity(Insertable<StudentsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_generated_id')) {
      context.handle(
          _clientGeneratedIdMeta,
          clientGeneratedId.isAcceptableOrUnknown(
              data['client_generated_id']!, _clientGeneratedIdMeta));
    } else if (isInserting) {
      context.missing(_clientGeneratedIdMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('gr_number')) {
      context.handle(_grNumberMeta,
          grNumber.isAcceptableOrUnknown(data['gr_number']!, _grNumberMeta));
    } else if (isInserting) {
      context.missing(_grNumberMeta);
    }
    if (data.containsKey('serial_number')) {
      context.handle(
          _serialNumberMeta,
          serialNumber.isAcceptableOrUnknown(
              data['serial_number']!, _serialNumberMeta));
    }
    if (data.containsKey('student_name')) {
      context.handle(
          _studentNameMeta,
          studentName.isAcceptableOrUnknown(
              data['student_name']!, _studentNameMeta));
    } else if (isInserting) {
      context.missing(_studentNameMeta);
    }
    if (data.containsKey('father_name')) {
      context.handle(
          _fatherNameMeta,
          fatherName.isAcceptableOrUnknown(
              data['father_name']!, _fatherNameMeta));
    }
    if (data.containsKey('mother_name')) {
      context.handle(
          _motherNameMeta,
          motherName.isAcceptableOrUnknown(
              data['mother_name']!, _motherNameMeta));
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
          _dateOfBirthMeta,
          dateOfBirth.isAcceptableOrUnknown(
              data['date_of_birth']!, _dateOfBirthMeta));
    } else if (isInserting) {
      context.missing(_dateOfBirthMeta);
    }
    if (data.containsKey('date_of_admission')) {
      context.handle(
          _dateOfAdmissionMeta,
          dateOfAdmission.isAcceptableOrUnknown(
              data['date_of_admission']!, _dateOfAdmissionMeta));
    } else if (isInserting) {
      context.missing(_dateOfAdmissionMeta);
    }
    if (data.containsKey('father_cnic')) {
      context.handle(
          _fatherCnicMeta,
          fatherCnic.isAcceptableOrUnknown(
              data['father_cnic']!, _fatherCnicMeta));
    }
    if (data.containsKey('b_form_number')) {
      context.handle(
          _bFormNumberMeta,
          bFormNumber.isAcceptableOrUnknown(
              data['b_form_number']!, _bFormNumberMeta));
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('previous_school')) {
      context.handle(
          _previousSchoolMeta,
          previousSchool.isAcceptableOrUnknown(
              data['previous_school']!, _previousSchoolMeta));
    }
    if (data.containsKey('remarks')) {
      context.handle(_remarksMeta,
          remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('promotion_status')) {
      context.handle(
          _promotionStatusMeta,
          promotionStatus.isAcceptableOrUnknown(
              data['promotion_status']!, _promotionStatusMeta));
    }
    if (data.containsKey('struck_off_date')) {
      context.handle(
          _struckOffDateMeta,
          struckOffDate.isAcceptableOrUnknown(
              data['struck_off_date']!, _struckOffDateMeta));
    }
    if (data.containsKey('struck_off_reason')) {
      context.handle(
          _struckOffReasonMeta,
          struckOffReason.isAcceptableOrUnknown(
              data['struck_off_reason']!, _struckOffReasonMeta));
    }
    if (data.containsKey('pass_out_year')) {
      context.handle(
          _passOutYearMeta,
          passOutYear.isAcceptableOrUnknown(
              data['pass_out_year']!, _passOutYearMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('updated_by')) {
      context.handle(_updatedByMeta,
          updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    if (data.containsKey('dirty_since')) {
      context.handle(
          _dirtySinceMeta,
          dirtySince.isAcceptableOrUnknown(
              data['dirty_since']!, _dirtySinceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      clientGeneratedId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_generated_id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_id'])!,
      grNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gr_number'])!,
      serialNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}serial_number']),
      studentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_name'])!,
      fatherName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}father_name']),
      motherName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mother_name']),
      dateOfBirth: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_of_birth'])!,
      dateOfAdmission: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_of_admission'])!,
      fatherCnic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}father_cnic']),
      bFormNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}b_form_number']),
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      previousSchool: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}previous_school']),
      remarks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remarks']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      promotionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}promotion_status'])!,
      struckOffDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}struck_off_date']),
      struckOffReason: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}struck_off_reason']),
      passOutYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pass_out_year']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      updatedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_by']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
      dirtySince: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}dirty_since']),
    );
  }

  @override
  $StudentsTableTable createAlias(String alias) {
    return $StudentsTableTable(attachedDatabase, alias);
  }
}

class StudentsTableData extends DataClass
    implements Insertable<StudentsTableData> {
  final String id;
  final String clientGeneratedId;
  final String schoolId;
  final String classId;
  final String grNumber;
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
  final String status;
  final String promotionStatus;
  final DateTime? struckOffDate;
  final String? struckOffReason;
  final int? passOutYear;
  final int version;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? createdBy;
  final String? updatedBy;
  final bool isDeleted;
  final String syncState;
  final DateTime? dirtySince;
  const StudentsTableData(
      {required this.id,
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
      required this.status,
      required this.promotionStatus,
      this.struckOffDate,
      this.struckOffReason,
      this.passOutYear,
      required this.version,
      required this.updatedAt,
      required this.createdAt,
      this.createdBy,
      this.updatedBy,
      required this.isDeleted,
      required this.syncState,
      this.dirtySince});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_generated_id'] = Variable<String>(clientGeneratedId);
    map['school_id'] = Variable<String>(schoolId);
    map['class_id'] = Variable<String>(classId);
    map['gr_number'] = Variable<String>(grNumber);
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<int>(serialNumber);
    }
    map['student_name'] = Variable<String>(studentName);
    if (!nullToAbsent || fatherName != null) {
      map['father_name'] = Variable<String>(fatherName);
    }
    if (!nullToAbsent || motherName != null) {
      map['mother_name'] = Variable<String>(motherName);
    }
    map['date_of_birth'] = Variable<DateTime>(dateOfBirth);
    map['date_of_admission'] = Variable<DateTime>(dateOfAdmission);
    if (!nullToAbsent || fatherCnic != null) {
      map['father_cnic'] = Variable<String>(fatherCnic);
    }
    if (!nullToAbsent || bFormNumber != null) {
      map['b_form_number'] = Variable<String>(bFormNumber);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || previousSchool != null) {
      map['previous_school'] = Variable<String>(previousSchool);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    map['status'] = Variable<String>(status);
    map['promotion_status'] = Variable<String>(promotionStatus);
    if (!nullToAbsent || struckOffDate != null) {
      map['struck_off_date'] = Variable<DateTime>(struckOffDate);
    }
    if (!nullToAbsent || struckOffReason != null) {
      map['struck_off_reason'] = Variable<String>(struckOffReason);
    }
    if (!nullToAbsent || passOutYear != null) {
      map['pass_out_year'] = Variable<int>(passOutYear);
    }
    map['version'] = Variable<int>(version);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || dirtySince != null) {
      map['dirty_since'] = Variable<DateTime>(dirtySince);
    }
    return map;
  }

  StudentsTableCompanion toCompanion(bool nullToAbsent) {
    return StudentsTableCompanion(
      id: Value(id),
      clientGeneratedId: Value(clientGeneratedId),
      schoolId: Value(schoolId),
      classId: Value(classId),
      grNumber: Value(grNumber),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      studentName: Value(studentName),
      fatherName: fatherName == null && nullToAbsent
          ? const Value.absent()
          : Value(fatherName),
      motherName: motherName == null && nullToAbsent
          ? const Value.absent()
          : Value(motherName),
      dateOfBirth: Value(dateOfBirth),
      dateOfAdmission: Value(dateOfAdmission),
      fatherCnic: fatherCnic == null && nullToAbsent
          ? const Value.absent()
          : Value(fatherCnic),
      bFormNumber: bFormNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(bFormNumber),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      previousSchool: previousSchool == null && nullToAbsent
          ? const Value.absent()
          : Value(previousSchool),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      status: Value(status),
      promotionStatus: Value(promotionStatus),
      struckOffDate: struckOffDate == null && nullToAbsent
          ? const Value.absent()
          : Value(struckOffDate),
      struckOffReason: struckOffReason == null && nullToAbsent
          ? const Value.absent()
          : Value(struckOffReason),
      passOutYear: passOutYear == null && nullToAbsent
          ? const Value.absent()
          : Value(passOutYear),
      version: Value(version),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDeleted: Value(isDeleted),
      syncState: Value(syncState),
      dirtySince: dirtySince == null && nullToAbsent
          ? const Value.absent()
          : Value(dirtySince),
    );
  }

  factory StudentsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentsTableData(
      id: serializer.fromJson<String>(json['id']),
      clientGeneratedId: serializer.fromJson<String>(json['clientGeneratedId']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      classId: serializer.fromJson<String>(json['classId']),
      grNumber: serializer.fromJson<String>(json['grNumber']),
      serialNumber: serializer.fromJson<int?>(json['serialNumber']),
      studentName: serializer.fromJson<String>(json['studentName']),
      fatherName: serializer.fromJson<String?>(json['fatherName']),
      motherName: serializer.fromJson<String?>(json['motherName']),
      dateOfBirth: serializer.fromJson<DateTime>(json['dateOfBirth']),
      dateOfAdmission: serializer.fromJson<DateTime>(json['dateOfAdmission']),
      fatherCnic: serializer.fromJson<String?>(json['fatherCnic']),
      bFormNumber: serializer.fromJson<String?>(json['bFormNumber']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      address: serializer.fromJson<String?>(json['address']),
      previousSchool: serializer.fromJson<String?>(json['previousSchool']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      status: serializer.fromJson<String>(json['status']),
      promotionStatus: serializer.fromJson<String>(json['promotionStatus']),
      struckOffDate: serializer.fromJson<DateTime?>(json['struckOffDate']),
      struckOffReason: serializer.fromJson<String?>(json['struckOffReason']),
      passOutYear: serializer.fromJson<int?>(json['passOutYear']),
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncState: serializer.fromJson<String>(json['syncState']),
      dirtySince: serializer.fromJson<DateTime?>(json['dirtySince']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientGeneratedId': serializer.toJson<String>(clientGeneratedId),
      'schoolId': serializer.toJson<String>(schoolId),
      'classId': serializer.toJson<String>(classId),
      'grNumber': serializer.toJson<String>(grNumber),
      'serialNumber': serializer.toJson<int?>(serialNumber),
      'studentName': serializer.toJson<String>(studentName),
      'fatherName': serializer.toJson<String?>(fatherName),
      'motherName': serializer.toJson<String?>(motherName),
      'dateOfBirth': serializer.toJson<DateTime>(dateOfBirth),
      'dateOfAdmission': serializer.toJson<DateTime>(dateOfAdmission),
      'fatherCnic': serializer.toJson<String?>(fatherCnic),
      'bFormNumber': serializer.toJson<String?>(bFormNumber),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'address': serializer.toJson<String?>(address),
      'previousSchool': serializer.toJson<String?>(previousSchool),
      'remarks': serializer.toJson<String?>(remarks),
      'status': serializer.toJson<String>(status),
      'promotionStatus': serializer.toJson<String>(promotionStatus),
      'struckOffDate': serializer.toJson<DateTime?>(struckOffDate),
      'struckOffReason': serializer.toJson<String?>(struckOffReason),
      'passOutYear': serializer.toJson<int?>(passOutYear),
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncState': serializer.toJson<String>(syncState),
      'dirtySince': serializer.toJson<DateTime?>(dirtySince),
    };
  }

  StudentsTableData copyWith(
          {String? id,
          String? clientGeneratedId,
          String? schoolId,
          String? classId,
          String? grNumber,
          Value<int?> serialNumber = const Value.absent(),
          String? studentName,
          Value<String?> fatherName = const Value.absent(),
          Value<String?> motherName = const Value.absent(),
          DateTime? dateOfBirth,
          DateTime? dateOfAdmission,
          Value<String?> fatherCnic = const Value.absent(),
          Value<String?> bFormNumber = const Value.absent(),
          Value<String?> phoneNumber = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> previousSchool = const Value.absent(),
          Value<String?> remarks = const Value.absent(),
          String? status,
          String? promotionStatus,
          Value<DateTime?> struckOffDate = const Value.absent(),
          Value<String?> struckOffReason = const Value.absent(),
          Value<int?> passOutYear = const Value.absent(),
          int? version,
          DateTime? updatedAt,
          DateTime? createdAt,
          Value<String?> createdBy = const Value.absent(),
          Value<String?> updatedBy = const Value.absent(),
          bool? isDeleted,
          String? syncState,
          Value<DateTime?> dirtySince = const Value.absent()}) =>
      StudentsTableData(
        id: id ?? this.id,
        clientGeneratedId: clientGeneratedId ?? this.clientGeneratedId,
        schoolId: schoolId ?? this.schoolId,
        classId: classId ?? this.classId,
        grNumber: grNumber ?? this.grNumber,
        serialNumber:
            serialNumber.present ? serialNumber.value : this.serialNumber,
        studentName: studentName ?? this.studentName,
        fatherName: fatherName.present ? fatherName.value : this.fatherName,
        motherName: motherName.present ? motherName.value : this.motherName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        dateOfAdmission: dateOfAdmission ?? this.dateOfAdmission,
        fatherCnic: fatherCnic.present ? fatherCnic.value : this.fatherCnic,
        bFormNumber: bFormNumber.present ? bFormNumber.value : this.bFormNumber,
        phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
        address: address.present ? address.value : this.address,
        previousSchool:
            previousSchool.present ? previousSchool.value : this.previousSchool,
        remarks: remarks.present ? remarks.value : this.remarks,
        status: status ?? this.status,
        promotionStatus: promotionStatus ?? this.promotionStatus,
        struckOffDate:
            struckOffDate.present ? struckOffDate.value : this.struckOffDate,
        struckOffReason: struckOffReason.present
            ? struckOffReason.value
            : this.struckOffReason,
        passOutYear: passOutYear.present ? passOutYear.value : this.passOutYear,
        version: version ?? this.version,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
        isDeleted: isDeleted ?? this.isDeleted,
        syncState: syncState ?? this.syncState,
        dirtySince: dirtySince.present ? dirtySince.value : this.dirtySince,
      );
  StudentsTableData copyWithCompanion(StudentsTableCompanion data) {
    return StudentsTableData(
      id: data.id.present ? data.id.value : this.id,
      clientGeneratedId: data.clientGeneratedId.present
          ? data.clientGeneratedId.value
          : this.clientGeneratedId,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      classId: data.classId.present ? data.classId.value : this.classId,
      grNumber: data.grNumber.present ? data.grNumber.value : this.grNumber,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      studentName:
          data.studentName.present ? data.studentName.value : this.studentName,
      fatherName:
          data.fatherName.present ? data.fatherName.value : this.fatherName,
      motherName:
          data.motherName.present ? data.motherName.value : this.motherName,
      dateOfBirth:
          data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      dateOfAdmission: data.dateOfAdmission.present
          ? data.dateOfAdmission.value
          : this.dateOfAdmission,
      fatherCnic:
          data.fatherCnic.present ? data.fatherCnic.value : this.fatherCnic,
      bFormNumber:
          data.bFormNumber.present ? data.bFormNumber.value : this.bFormNumber,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      address: data.address.present ? data.address.value : this.address,
      previousSchool: data.previousSchool.present
          ? data.previousSchool.value
          : this.previousSchool,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      status: data.status.present ? data.status.value : this.status,
      promotionStatus: data.promotionStatus.present
          ? data.promotionStatus.value
          : this.promotionStatus,
      struckOffDate: data.struckOffDate.present
          ? data.struckOffDate.value
          : this.struckOffDate,
      struckOffReason: data.struckOffReason.present
          ? data.struckOffReason.value
          : this.struckOffReason,
      passOutYear:
          data.passOutYear.present ? data.passOutYear.value : this.passOutYear,
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      dirtySince:
          data.dirtySince.present ? data.dirtySince.value : this.dirtySince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentsTableData(')
          ..write('id: $id, ')
          ..write('clientGeneratedId: $clientGeneratedId, ')
          ..write('schoolId: $schoolId, ')
          ..write('classId: $classId, ')
          ..write('grNumber: $grNumber, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('studentName: $studentName, ')
          ..write('fatherName: $fatherName, ')
          ..write('motherName: $motherName, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('dateOfAdmission: $dateOfAdmission, ')
          ..write('fatherCnic: $fatherCnic, ')
          ..write('bFormNumber: $bFormNumber, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('address: $address, ')
          ..write('previousSchool: $previousSchool, ')
          ..write('remarks: $remarks, ')
          ..write('status: $status, ')
          ..write('promotionStatus: $promotionStatus, ')
          ..write('struckOffDate: $struckOffDate, ')
          ..write('struckOffReason: $struckOffReason, ')
          ..write('passOutYear: $passOutYear, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncState: $syncState, ')
          ..write('dirtySince: $dirtySince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        clientGeneratedId,
        schoolId,
        classId,
        grNumber,
        serialNumber,
        studentName,
        fatherName,
        motherName,
        dateOfBirth,
        dateOfAdmission,
        fatherCnic,
        bFormNumber,
        phoneNumber,
        address,
        previousSchool,
        remarks,
        status,
        promotionStatus,
        struckOffDate,
        struckOffReason,
        passOutYear,
        version,
        updatedAt,
        createdAt,
        createdBy,
        updatedBy,
        isDeleted,
        syncState,
        dirtySince
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentsTableData &&
          other.id == this.id &&
          other.clientGeneratedId == this.clientGeneratedId &&
          other.schoolId == this.schoolId &&
          other.classId == this.classId &&
          other.grNumber == this.grNumber &&
          other.serialNumber == this.serialNumber &&
          other.studentName == this.studentName &&
          other.fatherName == this.fatherName &&
          other.motherName == this.motherName &&
          other.dateOfBirth == this.dateOfBirth &&
          other.dateOfAdmission == this.dateOfAdmission &&
          other.fatherCnic == this.fatherCnic &&
          other.bFormNumber == this.bFormNumber &&
          other.phoneNumber == this.phoneNumber &&
          other.address == this.address &&
          other.previousSchool == this.previousSchool &&
          other.remarks == this.remarks &&
          other.status == this.status &&
          other.promotionStatus == this.promotionStatus &&
          other.struckOffDate == this.struckOffDate &&
          other.struckOffReason == this.struckOffReason &&
          other.passOutYear == this.passOutYear &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDeleted == this.isDeleted &&
          other.syncState == this.syncState &&
          other.dirtySince == this.dirtySince);
}

class StudentsTableCompanion extends UpdateCompanion<StudentsTableData> {
  final Value<String> id;
  final Value<String> clientGeneratedId;
  final Value<String> schoolId;
  final Value<String> classId;
  final Value<String> grNumber;
  final Value<int?> serialNumber;
  final Value<String> studentName;
  final Value<String?> fatherName;
  final Value<String?> motherName;
  final Value<DateTime> dateOfBirth;
  final Value<DateTime> dateOfAdmission;
  final Value<String?> fatherCnic;
  final Value<String?> bFormNumber;
  final Value<String?> phoneNumber;
  final Value<String?> address;
  final Value<String?> previousSchool;
  final Value<String?> remarks;
  final Value<String> status;
  final Value<String> promotionStatus;
  final Value<DateTime?> struckOffDate;
  final Value<String?> struckOffReason;
  final Value<int?> passOutYear;
  final Value<int> version;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDeleted;
  final Value<String> syncState;
  final Value<DateTime?> dirtySince;
  final Value<int> rowid;
  const StudentsTableCompanion({
    this.id = const Value.absent(),
    this.clientGeneratedId = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.classId = const Value.absent(),
    this.grNumber = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.studentName = const Value.absent(),
    this.fatherName = const Value.absent(),
    this.motherName = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.dateOfAdmission = const Value.absent(),
    this.fatherCnic = const Value.absent(),
    this.bFormNumber = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.previousSchool = const Value.absent(),
    this.remarks = const Value.absent(),
    this.status = const Value.absent(),
    this.promotionStatus = const Value.absent(),
    this.struckOffDate = const Value.absent(),
    this.struckOffReason = const Value.absent(),
    this.passOutYear = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.dirtySince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsTableCompanion.insert({
    required String id,
    required String clientGeneratedId,
    required String schoolId,
    required String classId,
    required String grNumber,
    this.serialNumber = const Value.absent(),
    required String studentName,
    this.fatherName = const Value.absent(),
    this.motherName = const Value.absent(),
    required DateTime dateOfBirth,
    required DateTime dateOfAdmission,
    this.fatherCnic = const Value.absent(),
    this.bFormNumber = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.previousSchool = const Value.absent(),
    this.remarks = const Value.absent(),
    this.status = const Value.absent(),
    this.promotionStatus = const Value.absent(),
    this.struckOffDate = const Value.absent(),
    this.struckOffReason = const Value.absent(),
    this.passOutYear = const Value.absent(),
    this.version = const Value.absent(),
    required DateTime updatedAt,
    required DateTime createdAt,
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.dirtySince = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        clientGeneratedId = Value(clientGeneratedId),
        schoolId = Value(schoolId),
        classId = Value(classId),
        grNumber = Value(grNumber),
        studentName = Value(studentName),
        dateOfBirth = Value(dateOfBirth),
        dateOfAdmission = Value(dateOfAdmission),
        updatedAt = Value(updatedAt),
        createdAt = Value(createdAt);
  static Insertable<StudentsTableData> custom({
    Expression<String>? id,
    Expression<String>? clientGeneratedId,
    Expression<String>? schoolId,
    Expression<String>? classId,
    Expression<String>? grNumber,
    Expression<int>? serialNumber,
    Expression<String>? studentName,
    Expression<String>? fatherName,
    Expression<String>? motherName,
    Expression<DateTime>? dateOfBirth,
    Expression<DateTime>? dateOfAdmission,
    Expression<String>? fatherCnic,
    Expression<String>? bFormNumber,
    Expression<String>? phoneNumber,
    Expression<String>? address,
    Expression<String>? previousSchool,
    Expression<String>? remarks,
    Expression<String>? status,
    Expression<String>? promotionStatus,
    Expression<DateTime>? struckOffDate,
    Expression<String>? struckOffReason,
    Expression<int>? passOutYear,
    Expression<int>? version,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDeleted,
    Expression<String>? syncState,
    Expression<DateTime>? dirtySince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientGeneratedId != null) 'client_generated_id': clientGeneratedId,
      if (schoolId != null) 'school_id': schoolId,
      if (classId != null) 'class_id': classId,
      if (grNumber != null) 'gr_number': grNumber,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (studentName != null) 'student_name': studentName,
      if (fatherName != null) 'father_name': fatherName,
      if (motherName != null) 'mother_name': motherName,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (dateOfAdmission != null) 'date_of_admission': dateOfAdmission,
      if (fatherCnic != null) 'father_cnic': fatherCnic,
      if (bFormNumber != null) 'b_form_number': bFormNumber,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (address != null) 'address': address,
      if (previousSchool != null) 'previous_school': previousSchool,
      if (remarks != null) 'remarks': remarks,
      if (status != null) 'status': status,
      if (promotionStatus != null) 'promotion_status': promotionStatus,
      if (struckOffDate != null) 'struck_off_date': struckOffDate,
      if (struckOffReason != null) 'struck_off_reason': struckOffReason,
      if (passOutYear != null) 'pass_out_year': passOutYear,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncState != null) 'sync_state': syncState,
      if (dirtySince != null) 'dirty_since': dirtySince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? clientGeneratedId,
      Value<String>? schoolId,
      Value<String>? classId,
      Value<String>? grNumber,
      Value<int?>? serialNumber,
      Value<String>? studentName,
      Value<String?>? fatherName,
      Value<String?>? motherName,
      Value<DateTime>? dateOfBirth,
      Value<DateTime>? dateOfAdmission,
      Value<String?>? fatherCnic,
      Value<String?>? bFormNumber,
      Value<String?>? phoneNumber,
      Value<String?>? address,
      Value<String?>? previousSchool,
      Value<String?>? remarks,
      Value<String>? status,
      Value<String>? promotionStatus,
      Value<DateTime?>? struckOffDate,
      Value<String?>? struckOffReason,
      Value<int?>? passOutYear,
      Value<int>? version,
      Value<DateTime>? updatedAt,
      Value<DateTime>? createdAt,
      Value<String?>? createdBy,
      Value<String?>? updatedBy,
      Value<bool>? isDeleted,
      Value<String>? syncState,
      Value<DateTime?>? dirtySince,
      Value<int>? rowid}) {
    return StudentsTableCompanion(
      id: id ?? this.id,
      clientGeneratedId: clientGeneratedId ?? this.clientGeneratedId,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      grNumber: grNumber ?? this.grNumber,
      serialNumber: serialNumber ?? this.serialNumber,
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
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      syncState: syncState ?? this.syncState,
      dirtySince: dirtySince ?? this.dirtySince,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientGeneratedId.present) {
      map['client_generated_id'] = Variable<String>(clientGeneratedId.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (grNumber.present) {
      map['gr_number'] = Variable<String>(grNumber.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<int>(serialNumber.value);
    }
    if (studentName.present) {
      map['student_name'] = Variable<String>(studentName.value);
    }
    if (fatherName.present) {
      map['father_name'] = Variable<String>(fatherName.value);
    }
    if (motherName.present) {
      map['mother_name'] = Variable<String>(motherName.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (dateOfAdmission.present) {
      map['date_of_admission'] = Variable<DateTime>(dateOfAdmission.value);
    }
    if (fatherCnic.present) {
      map['father_cnic'] = Variable<String>(fatherCnic.value);
    }
    if (bFormNumber.present) {
      map['b_form_number'] = Variable<String>(bFormNumber.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (previousSchool.present) {
      map['previous_school'] = Variable<String>(previousSchool.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (promotionStatus.present) {
      map['promotion_status'] = Variable<String>(promotionStatus.value);
    }
    if (struckOffDate.present) {
      map['struck_off_date'] = Variable<DateTime>(struckOffDate.value);
    }
    if (struckOffReason.present) {
      map['struck_off_reason'] = Variable<String>(struckOffReason.value);
    }
    if (passOutYear.present) {
      map['pass_out_year'] = Variable<int>(passOutYear.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (dirtySince.present) {
      map['dirty_since'] = Variable<DateTime>(dirtySince.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsTableCompanion(')
          ..write('id: $id, ')
          ..write('clientGeneratedId: $clientGeneratedId, ')
          ..write('schoolId: $schoolId, ')
          ..write('classId: $classId, ')
          ..write('grNumber: $grNumber, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('studentName: $studentName, ')
          ..write('fatherName: $fatherName, ')
          ..write('motherName: $motherName, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('dateOfAdmission: $dateOfAdmission, ')
          ..write('fatherCnic: $fatherCnic, ')
          ..write('bFormNumber: $bFormNumber, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('address: $address, ')
          ..write('previousSchool: $previousSchool, ')
          ..write('remarks: $remarks, ')
          ..write('status: $status, ')
          ..write('promotionStatus: $promotionStatus, ')
          ..write('struckOffDate: $struckOffDate, ')
          ..write('struckOffReason: $struckOffReason, ')
          ..write('passOutYear: $passOutYear, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncState: $syncState, ')
          ..write('dirtySince: $dirtySince, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queueIdMeta =
      const VerificationMeta('queueId');
  @override
  late final GeneratedColumn<int> queueId = GeneratedColumn<int>(
      'queue_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        queueId,
        entityType,
        entityId,
        operation,
        payloadJson,
        createdAt,
        attemptCount,
        lastError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('queue_id')) {
      context.handle(_queueIdMeta,
          queueId.isAcceptableOrUnknown(data['queue_id']!, _queueIdMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {queueId};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      queueId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}queue_id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int queueId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final DateTime createdAt;
  final int attemptCount;
  final String? lastError;
  const SyncQueueTableData(
      {required this.queueId,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payloadJson,
      required this.createdAt,
      required this.attemptCount,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['queue_id'] = Variable<int>(queueId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      queueId: Value(queueId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      queueId: serializer.fromJson<int>(json['queueId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'queueId': serializer.toJson<int>(queueId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueTableData copyWith(
          {int? queueId,
          String? entityType,
          String? entityId,
          String? operation,
          String? payloadJson,
          DateTime? createdAt,
          int? attemptCount,
          Value<String?> lastError = const Value.absent()}) =>
      SyncQueueTableData(
        queueId: queueId ?? this.queueId,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payloadJson: payloadJson ?? this.payloadJson,
        createdAt: createdAt ?? this.createdAt,
        attemptCount: attemptCount ?? this.attemptCount,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      queueId: data.queueId.present ? data.queueId.value : this.queueId,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('queueId: $queueId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(queueId, entityType, entityId, operation,
      payloadJson, createdAt, attemptCount, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.queueId == this.queueId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> queueId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  const SyncQueueTableCompanion({
    this.queueId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.queueId = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    this.createdAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payloadJson = Value(payloadJson);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? queueId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (queueId != null) 'queue_id': queueId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<int>? queueId,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payloadJson,
      Value<DateTime>? createdAt,
      Value<int>? attemptCount,
      Value<String?>? lastError}) {
    return SyncQueueTableCompanion(
      queueId: queueId ?? this.queueId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (queueId.present) {
      map['queue_id'] = Variable<int>(queueId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('queueId: $queueId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $StudentPhotosTableTable extends StudentPhotosTable
    with TableInfo<$StudentPhotosTableTable, StudentPhotosTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentPhotosTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoTypeMeta =
      const VerificationMeta('photoType');
  @override
  late final GeneratedColumn<String> photoType = GeneratedColumn<String>(
      'photo_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remoteStoragePathMeta =
      const VerificationMeta('remoteStoragePath');
  @override
  late final GeneratedColumn<String> remoteStoragePath =
      GeneratedColumn<String>('remote_storage_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        studentId,
        photoType,
        localPath,
        remoteStoragePath,
        version,
        syncState,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'student_photos_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<StudentPhotosTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('photo_type')) {
      context.handle(_photoTypeMeta,
          photoType.isAcceptableOrUnknown(data['photo_type']!, _photoTypeMeta));
    } else if (isInserting) {
      context.missing(_photoTypeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('remote_storage_path')) {
      context.handle(
          _remoteStoragePathMeta,
          remoteStoragePath.isAcceptableOrUnknown(
              data['remote_storage_path']!, _remoteStoragePathMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentPhotosTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentPhotosTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      photoType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_type'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      remoteStoragePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}remote_storage_path']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StudentPhotosTableTable createAlias(String alias) {
    return $StudentPhotosTableTable(attachedDatabase, alias);
  }
}

class StudentPhotosTableData extends DataClass
    implements Insertable<StudentPhotosTableData> {
  final String id;
  final String studentId;
  final String photoType;
  final String? localPath;
  final String? remoteStoragePath;
  final int version;
  final String syncState;
  final DateTime createdAt;
  const StudentPhotosTableData(
      {required this.id,
      required this.studentId,
      required this.photoType,
      this.localPath,
      this.remoteStoragePath,
      required this.version,
      required this.syncState,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['student_id'] = Variable<String>(studentId);
    map['photo_type'] = Variable<String>(photoType);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || remoteStoragePath != null) {
      map['remote_storage_path'] = Variable<String>(remoteStoragePath);
    }
    map['version'] = Variable<int>(version);
    map['sync_state'] = Variable<String>(syncState);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StudentPhotosTableCompanion toCompanion(bool nullToAbsent) {
    return StudentPhotosTableCompanion(
      id: Value(id),
      studentId: Value(studentId),
      photoType: Value(photoType),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      remoteStoragePath: remoteStoragePath == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteStoragePath),
      version: Value(version),
      syncState: Value(syncState),
      createdAt: Value(createdAt),
    );
  }

  factory StudentPhotosTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentPhotosTableData(
      id: serializer.fromJson<String>(json['id']),
      studentId: serializer.fromJson<String>(json['studentId']),
      photoType: serializer.fromJson<String>(json['photoType']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      remoteStoragePath:
          serializer.fromJson<String?>(json['remoteStoragePath']),
      version: serializer.fromJson<int>(json['version']),
      syncState: serializer.fromJson<String>(json['syncState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studentId': serializer.toJson<String>(studentId),
      'photoType': serializer.toJson<String>(photoType),
      'localPath': serializer.toJson<String?>(localPath),
      'remoteStoragePath': serializer.toJson<String?>(remoteStoragePath),
      'version': serializer.toJson<int>(version),
      'syncState': serializer.toJson<String>(syncState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StudentPhotosTableData copyWith(
          {String? id,
          String? studentId,
          String? photoType,
          Value<String?> localPath = const Value.absent(),
          Value<String?> remoteStoragePath = const Value.absent(),
          int? version,
          String? syncState,
          DateTime? createdAt}) =>
      StudentPhotosTableData(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        photoType: photoType ?? this.photoType,
        localPath: localPath.present ? localPath.value : this.localPath,
        remoteStoragePath: remoteStoragePath.present
            ? remoteStoragePath.value
            : this.remoteStoragePath,
        version: version ?? this.version,
        syncState: syncState ?? this.syncState,
        createdAt: createdAt ?? this.createdAt,
      );
  StudentPhotosTableData copyWithCompanion(StudentPhotosTableCompanion data) {
    return StudentPhotosTableData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      photoType: data.photoType.present ? data.photoType.value : this.photoType,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      remoteStoragePath: data.remoteStoragePath.present
          ? data.remoteStoragePath.value
          : this.remoteStoragePath,
      version: data.version.present ? data.version.value : this.version,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentPhotosTableData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('photoType: $photoType, ')
          ..write('localPath: $localPath, ')
          ..write('remoteStoragePath: $remoteStoragePath, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studentId, photoType, localPath,
      remoteStoragePath, version, syncState, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentPhotosTableData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.photoType == this.photoType &&
          other.localPath == this.localPath &&
          other.remoteStoragePath == this.remoteStoragePath &&
          other.version == this.version &&
          other.syncState == this.syncState &&
          other.createdAt == this.createdAt);
}

class StudentPhotosTableCompanion
    extends UpdateCompanion<StudentPhotosTableData> {
  final Value<String> id;
  final Value<String> studentId;
  final Value<String> photoType;
  final Value<String?> localPath;
  final Value<String?> remoteStoragePath;
  final Value<int> version;
  final Value<String> syncState;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StudentPhotosTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.photoType = const Value.absent(),
    this.localPath = const Value.absent(),
    this.remoteStoragePath = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentPhotosTableCompanion.insert({
    required String id,
    required String studentId,
    required String photoType,
    this.localPath = const Value.absent(),
    this.remoteStoragePath = const Value.absent(),
    this.version = const Value.absent(),
    this.syncState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        studentId = Value(studentId),
        photoType = Value(photoType);
  static Insertable<StudentPhotosTableData> custom({
    Expression<String>? id,
    Expression<String>? studentId,
    Expression<String>? photoType,
    Expression<String>? localPath,
    Expression<String>? remoteStoragePath,
    Expression<int>? version,
    Expression<String>? syncState,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (photoType != null) 'photo_type': photoType,
      if (localPath != null) 'local_path': localPath,
      if (remoteStoragePath != null) 'remote_storage_path': remoteStoragePath,
      if (version != null) 'version': version,
      if (syncState != null) 'sync_state': syncState,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentPhotosTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? studentId,
      Value<String>? photoType,
      Value<String?>? localPath,
      Value<String?>? remoteStoragePath,
      Value<int>? version,
      Value<String>? syncState,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return StudentPhotosTableCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      photoType: photoType ?? this.photoType,
      localPath: localPath ?? this.localPath,
      remoteStoragePath: remoteStoragePath ?? this.remoteStoragePath,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (photoType.present) {
      map['photo_type'] = Variable<String>(photoType.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (remoteStoragePath.present) {
      map['remote_storage_path'] = Variable<String>(remoteStoragePath.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentPhotosTableCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('photoType: $photoType, ')
          ..write('localPath: $localPath, ')
          ..write('remoteStoragePath: $remoteStoragePath, ')
          ..write('version: $version, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTableTable extends AuditLogsTable
    with TableInfo<$AuditLogsTableTable, AuditLogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _oldValueJsonMeta =
      const VerificationMeta('oldValueJson');
  @override
  late final GeneratedColumn<String> oldValueJson = GeneratedColumn<String>(
      'old_value_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newValueJsonMeta =
      const VerificationMeta('newValueJson');
  @override
  late final GeneratedColumn<String> newValueJson = GeneratedColumn<String>(
      'new_value_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendingCreate'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        schoolId,
        userId,
        studentId,
        action,
        oldValueJson,
        newValueJson,
        createdAt,
        syncState
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs_table';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLogsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('old_value_json')) {
      context.handle(
          _oldValueJsonMeta,
          oldValueJson.isAcceptableOrUnknown(
              data['old_value_json']!, _oldValueJsonMeta));
    }
    if (data.containsKey('new_value_json')) {
      context.handle(
          _newValueJsonMeta,
          newValueJson.isAcceptableOrUnknown(
              data['new_value_json']!, _newValueJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id']),
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      oldValueJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}old_value_json']),
      newValueJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_value_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
    );
  }

  @override
  $AuditLogsTableTable createAlias(String alias) {
    return $AuditLogsTableTable(attachedDatabase, alias);
  }
}

class AuditLogsTableData extends DataClass
    implements Insertable<AuditLogsTableData> {
  final String id;
  final String schoolId;
  final String? userId;
  final String? studentId;
  final String action;
  final String? oldValueJson;
  final String? newValueJson;
  final DateTime createdAt;
  final String syncState;
  const AuditLogsTableData(
      {required this.id,
      required this.schoolId,
      this.userId,
      this.studentId,
      required this.action,
      this.oldValueJson,
      this.newValueJson,
      required this.createdAt,
      required this.syncState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || oldValueJson != null) {
      map['old_value_json'] = Variable<String>(oldValueJson);
    }
    if (!nullToAbsent || newValueJson != null) {
      map['new_value_json'] = Variable<String>(newValueJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  AuditLogsTableCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsTableCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      action: Value(action),
      oldValueJson: oldValueJson == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValueJson),
      newValueJson: newValueJson == null && nullToAbsent
          ? const Value.absent()
          : Value(newValueJson),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
    );
  }

  factory AuditLogsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogsTableData(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      userId: serializer.fromJson<String?>(json['userId']),
      studentId: serializer.fromJson<String?>(json['studentId']),
      action: serializer.fromJson<String>(json['action']),
      oldValueJson: serializer.fromJson<String?>(json['oldValueJson']),
      newValueJson: serializer.fromJson<String?>(json['newValueJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'userId': serializer.toJson<String?>(userId),
      'studentId': serializer.toJson<String?>(studentId),
      'action': serializer.toJson<String>(action),
      'oldValueJson': serializer.toJson<String?>(oldValueJson),
      'newValueJson': serializer.toJson<String?>(newValueJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  AuditLogsTableData copyWith(
          {String? id,
          String? schoolId,
          Value<String?> userId = const Value.absent(),
          Value<String?> studentId = const Value.absent(),
          String? action,
          Value<String?> oldValueJson = const Value.absent(),
          Value<String?> newValueJson = const Value.absent(),
          DateTime? createdAt,
          String? syncState}) =>
      AuditLogsTableData(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        userId: userId.present ? userId.value : this.userId,
        studentId: studentId.present ? studentId.value : this.studentId,
        action: action ?? this.action,
        oldValueJson:
            oldValueJson.present ? oldValueJson.value : this.oldValueJson,
        newValueJson:
            newValueJson.present ? newValueJson.value : this.newValueJson,
        createdAt: createdAt ?? this.createdAt,
        syncState: syncState ?? this.syncState,
      );
  AuditLogsTableData copyWithCompanion(AuditLogsTableCompanion data) {
    return AuditLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      userId: data.userId.present ? data.userId.value : this.userId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      action: data.action.present ? data.action.value : this.action,
      oldValueJson: data.oldValueJson.present
          ? data.oldValueJson.value
          : this.oldValueJson,
      newValueJson: data.newValueJson.present
          ? data.newValueJson.value
          : this.newValueJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsTableData(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('userId: $userId, ')
          ..write('studentId: $studentId, ')
          ..write('action: $action, ')
          ..write('oldValueJson: $oldValueJson, ')
          ..write('newValueJson: $newValueJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, schoolId, userId, studentId, action,
      oldValueJson, newValueJson, createdAt, syncState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogsTableData &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.userId == this.userId &&
          other.studentId == this.studentId &&
          other.action == this.action &&
          other.oldValueJson == this.oldValueJson &&
          other.newValueJson == this.newValueJson &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState);
}

class AuditLogsTableCompanion extends UpdateCompanion<AuditLogsTableData> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<String?> userId;
  final Value<String?> studentId;
  final Value<String> action;
  final Value<String?> oldValueJson;
  final Value<String?> newValueJson;
  final Value<DateTime> createdAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const AuditLogsTableCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.userId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.action = const Value.absent(),
    this.oldValueJson = const Value.absent(),
    this.newValueJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsTableCompanion.insert({
    required String id,
    required String schoolId,
    this.userId = const Value.absent(),
    this.studentId = const Value.absent(),
    required String action,
    this.oldValueJson = const Value.absent(),
    this.newValueJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        schoolId = Value(schoolId),
        action = Value(action);
  static Insertable<AuditLogsTableData> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<String>? userId,
    Expression<String>? studentId,
    Expression<String>? action,
    Expression<String>? oldValueJson,
    Expression<String>? newValueJson,
    Expression<DateTime>? createdAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (userId != null) 'user_id': userId,
      if (studentId != null) 'student_id': studentId,
      if (action != null) 'action': action,
      if (oldValueJson != null) 'old_value_json': oldValueJson,
      if (newValueJson != null) 'new_value_json': newValueJson,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? schoolId,
      Value<String?>? userId,
      Value<String?>? studentId,
      Value<String>? action,
      Value<String?>? oldValueJson,
      Value<String?>? newValueJson,
      Value<DateTime>? createdAt,
      Value<String>? syncState,
      Value<int>? rowid}) {
    return AuditLogsTableCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      userId: userId ?? this.userId,
      studentId: studentId ?? this.studentId,
      action: action ?? this.action,
      oldValueJson: oldValueJson ?? this.oldValueJson,
      newValueJson: newValueJson ?? this.newValueJson,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (oldValueJson.present) {
      map['old_value_json'] = Variable<String>(oldValueJson.value);
    }
    if (newValueJson.present) {
      map['new_value_json'] = Variable<String>(newValueJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('userId: $userId, ')
          ..write('studentId: $studentId, ')
          ..write('action: $action, ')
          ..write('oldValueJson: $oldValueJson, ')
          ..write('newValueJson: $newValueJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromotionBatchesTableTable extends PromotionBatchesTable
    with TableInfo<$PromotionBatchesTableTable, PromotionBatchesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromotionBatchesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromClassIdMeta =
      const VerificationMeta('fromClassId');
  @override
  late final GeneratedColumn<String> fromClassId = GeneratedColumn<String>(
      'from_class_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toClassIdMeta =
      const VerificationMeta('toClassId');
  @override
  late final GeneratedColumn<String> toClassId = GeneratedColumn<String>(
      'to_class_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _promotionDateMeta =
      const VerificationMeta('promotionDate');
  @override
  late final GeneratedColumn<DateTime> promotionDate =
      GeneratedColumn<DateTime>('promotion_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _academicYearMeta =
      const VerificationMeta('academicYear');
  @override
  late final GeneratedColumn<int> academicYear = GeneratedColumn<int>(
      'academic_year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _performedByMeta =
      const VerificationMeta('performedBy');
  @override
  late final GeneratedColumn<String> performedBy = GeneratedColumn<String>(
      'performed_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isUndoneMeta =
      const VerificationMeta('isUndone');
  @override
  late final GeneratedColumn<bool> isUndone = GeneratedColumn<bool>(
      'is_undone', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_undone" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _undoneAtMeta =
      const VerificationMeta('undoneAt');
  @override
  late final GeneratedColumn<DateTime> undoneAt = GeneratedColumn<DateTime>(
      'undone_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _undoneByMeta =
      const VerificationMeta('undoneBy');
  @override
  late final GeneratedColumn<String> undoneBy = GeneratedColumn<String>(
      'undone_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendingCreate'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        schoolId,
        fromClassId,
        toClassId,
        promotionDate,
        academicYear,
        performedBy,
        isUndone,
        undoneAt,
        undoneBy,
        createdAt,
        syncState
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promotion_batches_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<PromotionBatchesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('from_class_id')) {
      context.handle(
          _fromClassIdMeta,
          fromClassId.isAcceptableOrUnknown(
              data['from_class_id']!, _fromClassIdMeta));
    } else if (isInserting) {
      context.missing(_fromClassIdMeta);
    }
    if (data.containsKey('to_class_id')) {
      context.handle(
          _toClassIdMeta,
          toClassId.isAcceptableOrUnknown(
              data['to_class_id']!, _toClassIdMeta));
    }
    if (data.containsKey('promotion_date')) {
      context.handle(
          _promotionDateMeta,
          promotionDate.isAcceptableOrUnknown(
              data['promotion_date']!, _promotionDateMeta));
    } else if (isInserting) {
      context.missing(_promotionDateMeta);
    }
    if (data.containsKey('academic_year')) {
      context.handle(
          _academicYearMeta,
          academicYear.isAcceptableOrUnknown(
              data['academic_year']!, _academicYearMeta));
    } else if (isInserting) {
      context.missing(_academicYearMeta);
    }
    if (data.containsKey('performed_by')) {
      context.handle(
          _performedByMeta,
          performedBy.isAcceptableOrUnknown(
              data['performed_by']!, _performedByMeta));
    }
    if (data.containsKey('is_undone')) {
      context.handle(_isUndoneMeta,
          isUndone.isAcceptableOrUnknown(data['is_undone']!, _isUndoneMeta));
    }
    if (data.containsKey('undone_at')) {
      context.handle(_undoneAtMeta,
          undoneAt.isAcceptableOrUnknown(data['undone_at']!, _undoneAtMeta));
    }
    if (data.containsKey('undone_by')) {
      context.handle(_undoneByMeta,
          undoneBy.isAcceptableOrUnknown(data['undone_by']!, _undoneByMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromotionBatchesTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromotionBatchesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id'])!,
      fromClassId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_class_id'])!,
      toClassId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_class_id']),
      promotionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}promotion_date'])!,
      academicYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}academic_year'])!,
      performedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}performed_by']),
      isUndone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_undone'])!,
      undoneAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}undone_at']),
      undoneBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}undone_by']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
    );
  }

  @override
  $PromotionBatchesTableTable createAlias(String alias) {
    return $PromotionBatchesTableTable(attachedDatabase, alias);
  }
}

class PromotionBatchesTableData extends DataClass
    implements Insertable<PromotionBatchesTableData> {
  final String id;
  final String schoolId;
  final String fromClassId;
  final String? toClassId;
  final DateTime promotionDate;
  final int academicYear;
  final String? performedBy;
  final bool isUndone;
  final DateTime? undoneAt;
  final String? undoneBy;
  final DateTime createdAt;
  final String syncState;
  const PromotionBatchesTableData(
      {required this.id,
      required this.schoolId,
      required this.fromClassId,
      this.toClassId,
      required this.promotionDate,
      required this.academicYear,
      this.performedBy,
      required this.isUndone,
      this.undoneAt,
      this.undoneBy,
      required this.createdAt,
      required this.syncState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    map['from_class_id'] = Variable<String>(fromClassId);
    if (!nullToAbsent || toClassId != null) {
      map['to_class_id'] = Variable<String>(toClassId);
    }
    map['promotion_date'] = Variable<DateTime>(promotionDate);
    map['academic_year'] = Variable<int>(academicYear);
    if (!nullToAbsent || performedBy != null) {
      map['performed_by'] = Variable<String>(performedBy);
    }
    map['is_undone'] = Variable<bool>(isUndone);
    if (!nullToAbsent || undoneAt != null) {
      map['undone_at'] = Variable<DateTime>(undoneAt);
    }
    if (!nullToAbsent || undoneBy != null) {
      map['undone_by'] = Variable<String>(undoneBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  PromotionBatchesTableCompanion toCompanion(bool nullToAbsent) {
    return PromotionBatchesTableCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      fromClassId: Value(fromClassId),
      toClassId: toClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(toClassId),
      promotionDate: Value(promotionDate),
      academicYear: Value(academicYear),
      performedBy: performedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(performedBy),
      isUndone: Value(isUndone),
      undoneAt: undoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(undoneAt),
      undoneBy: undoneBy == null && nullToAbsent
          ? const Value.absent()
          : Value(undoneBy),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
    );
  }

  factory PromotionBatchesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromotionBatchesTableData(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      fromClassId: serializer.fromJson<String>(json['fromClassId']),
      toClassId: serializer.fromJson<String?>(json['toClassId']),
      promotionDate: serializer.fromJson<DateTime>(json['promotionDate']),
      academicYear: serializer.fromJson<int>(json['academicYear']),
      performedBy: serializer.fromJson<String?>(json['performedBy']),
      isUndone: serializer.fromJson<bool>(json['isUndone']),
      undoneAt: serializer.fromJson<DateTime?>(json['undoneAt']),
      undoneBy: serializer.fromJson<String?>(json['undoneBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'fromClassId': serializer.toJson<String>(fromClassId),
      'toClassId': serializer.toJson<String?>(toClassId),
      'promotionDate': serializer.toJson<DateTime>(promotionDate),
      'academicYear': serializer.toJson<int>(academicYear),
      'performedBy': serializer.toJson<String?>(performedBy),
      'isUndone': serializer.toJson<bool>(isUndone),
      'undoneAt': serializer.toJson<DateTime?>(undoneAt),
      'undoneBy': serializer.toJson<String?>(undoneBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  PromotionBatchesTableData copyWith(
          {String? id,
          String? schoolId,
          String? fromClassId,
          Value<String?> toClassId = const Value.absent(),
          DateTime? promotionDate,
          int? academicYear,
          Value<String?> performedBy = const Value.absent(),
          bool? isUndone,
          Value<DateTime?> undoneAt = const Value.absent(),
          Value<String?> undoneBy = const Value.absent(),
          DateTime? createdAt,
          String? syncState}) =>
      PromotionBatchesTableData(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        fromClassId: fromClassId ?? this.fromClassId,
        toClassId: toClassId.present ? toClassId.value : this.toClassId,
        promotionDate: promotionDate ?? this.promotionDate,
        academicYear: academicYear ?? this.academicYear,
        performedBy: performedBy.present ? performedBy.value : this.performedBy,
        isUndone: isUndone ?? this.isUndone,
        undoneAt: undoneAt.present ? undoneAt.value : this.undoneAt,
        undoneBy: undoneBy.present ? undoneBy.value : this.undoneBy,
        createdAt: createdAt ?? this.createdAt,
        syncState: syncState ?? this.syncState,
      );
  PromotionBatchesTableData copyWithCompanion(
      PromotionBatchesTableCompanion data) {
    return PromotionBatchesTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      fromClassId:
          data.fromClassId.present ? data.fromClassId.value : this.fromClassId,
      toClassId: data.toClassId.present ? data.toClassId.value : this.toClassId,
      promotionDate: data.promotionDate.present
          ? data.promotionDate.value
          : this.promotionDate,
      academicYear: data.academicYear.present
          ? data.academicYear.value
          : this.academicYear,
      performedBy:
          data.performedBy.present ? data.performedBy.value : this.performedBy,
      isUndone: data.isUndone.present ? data.isUndone.value : this.isUndone,
      undoneAt: data.undoneAt.present ? data.undoneAt.value : this.undoneAt,
      undoneBy: data.undoneBy.present ? data.undoneBy.value : this.undoneBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromotionBatchesTableData(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('fromClassId: $fromClassId, ')
          ..write('toClassId: $toClassId, ')
          ..write('promotionDate: $promotionDate, ')
          ..write('academicYear: $academicYear, ')
          ..write('performedBy: $performedBy, ')
          ..write('isUndone: $isUndone, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('undoneBy: $undoneBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      schoolId,
      fromClassId,
      toClassId,
      promotionDate,
      academicYear,
      performedBy,
      isUndone,
      undoneAt,
      undoneBy,
      createdAt,
      syncState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromotionBatchesTableData &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.fromClassId == this.fromClassId &&
          other.toClassId == this.toClassId &&
          other.promotionDate == this.promotionDate &&
          other.academicYear == this.academicYear &&
          other.performedBy == this.performedBy &&
          other.isUndone == this.isUndone &&
          other.undoneAt == this.undoneAt &&
          other.undoneBy == this.undoneBy &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState);
}

class PromotionBatchesTableCompanion
    extends UpdateCompanion<PromotionBatchesTableData> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<String> fromClassId;
  final Value<String?> toClassId;
  final Value<DateTime> promotionDate;
  final Value<int> academicYear;
  final Value<String?> performedBy;
  final Value<bool> isUndone;
  final Value<DateTime?> undoneAt;
  final Value<String?> undoneBy;
  final Value<DateTime> createdAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const PromotionBatchesTableCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.fromClassId = const Value.absent(),
    this.toClassId = const Value.absent(),
    this.promotionDate = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.performedBy = const Value.absent(),
    this.isUndone = const Value.absent(),
    this.undoneAt = const Value.absent(),
    this.undoneBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromotionBatchesTableCompanion.insert({
    required String id,
    required String schoolId,
    required String fromClassId,
    this.toClassId = const Value.absent(),
    required DateTime promotionDate,
    required int academicYear,
    this.performedBy = const Value.absent(),
    this.isUndone = const Value.absent(),
    this.undoneAt = const Value.absent(),
    this.undoneBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        schoolId = Value(schoolId),
        fromClassId = Value(fromClassId),
        promotionDate = Value(promotionDate),
        academicYear = Value(academicYear);
  static Insertable<PromotionBatchesTableData> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<String>? fromClassId,
    Expression<String>? toClassId,
    Expression<DateTime>? promotionDate,
    Expression<int>? academicYear,
    Expression<String>? performedBy,
    Expression<bool>? isUndone,
    Expression<DateTime>? undoneAt,
    Expression<String>? undoneBy,
    Expression<DateTime>? createdAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (fromClassId != null) 'from_class_id': fromClassId,
      if (toClassId != null) 'to_class_id': toClassId,
      if (promotionDate != null) 'promotion_date': promotionDate,
      if (academicYear != null) 'academic_year': academicYear,
      if (performedBy != null) 'performed_by': performedBy,
      if (isUndone != null) 'is_undone': isUndone,
      if (undoneAt != null) 'undone_at': undoneAt,
      if (undoneBy != null) 'undone_by': undoneBy,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromotionBatchesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? schoolId,
      Value<String>? fromClassId,
      Value<String?>? toClassId,
      Value<DateTime>? promotionDate,
      Value<int>? academicYear,
      Value<String?>? performedBy,
      Value<bool>? isUndone,
      Value<DateTime?>? undoneAt,
      Value<String?>? undoneBy,
      Value<DateTime>? createdAt,
      Value<String>? syncState,
      Value<int>? rowid}) {
    return PromotionBatchesTableCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      fromClassId: fromClassId ?? this.fromClassId,
      toClassId: toClassId ?? this.toClassId,
      promotionDate: promotionDate ?? this.promotionDate,
      academicYear: academicYear ?? this.academicYear,
      performedBy: performedBy ?? this.performedBy,
      isUndone: isUndone ?? this.isUndone,
      undoneAt: undoneAt ?? this.undoneAt,
      undoneBy: undoneBy ?? this.undoneBy,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (fromClassId.present) {
      map['from_class_id'] = Variable<String>(fromClassId.value);
    }
    if (toClassId.present) {
      map['to_class_id'] = Variable<String>(toClassId.value);
    }
    if (promotionDate.present) {
      map['promotion_date'] = Variable<DateTime>(promotionDate.value);
    }
    if (academicYear.present) {
      map['academic_year'] = Variable<int>(academicYear.value);
    }
    if (performedBy.present) {
      map['performed_by'] = Variable<String>(performedBy.value);
    }
    if (isUndone.present) {
      map['is_undone'] = Variable<bool>(isUndone.value);
    }
    if (undoneAt.present) {
      map['undone_at'] = Variable<DateTime>(undoneAt.value);
    }
    if (undoneBy.present) {
      map['undone_by'] = Variable<String>(undoneBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromotionBatchesTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('fromClassId: $fromClassId, ')
          ..write('toClassId: $toClassId, ')
          ..write('promotionDate: $promotionDate, ')
          ..write('academicYear: $academicYear, ')
          ..write('performedBy: $performedBy, ')
          ..write('isUndone: $isUndone, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('undoneBy: $undoneBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromotionRecordsTableTable extends PromotionRecordsTable
    with TableInfo<$PromotionRecordsTableTable, PromotionRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromotionRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _batchIdMeta =
      const VerificationMeta('batchId');
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
      'batch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _previousClassIdMeta =
      const VerificationMeta('previousClassId');
  @override
  late final GeneratedColumn<String> previousClassId = GeneratedColumn<String>(
      'previous_class_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _newClassIdMeta =
      const VerificationMeta('newClassId');
  @override
  late final GeneratedColumn<String> newClassId = GeneratedColumn<String>(
      'new_class_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _previousStatusMeta =
      const VerificationMeta('previousStatus');
  @override
  late final GeneratedColumn<String> previousStatus = GeneratedColumn<String>(
      'previous_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _newStatusMeta =
      const VerificationMeta('newStatus');
  @override
  late final GeneratedColumn<String> newStatus = GeneratedColumn<String>(
      'new_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
      'result', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _academicYearMeta =
      const VerificationMeta('academicYear');
  @override
  late final GeneratedColumn<int> academicYear = GeneratedColumn<int>(
      'academic_year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        batchId,
        studentId,
        previousClassId,
        newClassId,
        previousStatus,
        newStatus,
        result,
        academicYear,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'promotion_records_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<PromotionRecordsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(_batchIdMeta,
          batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta));
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('previous_class_id')) {
      context.handle(
          _previousClassIdMeta,
          previousClassId.isAcceptableOrUnknown(
              data['previous_class_id']!, _previousClassIdMeta));
    } else if (isInserting) {
      context.missing(_previousClassIdMeta);
    }
    if (data.containsKey('new_class_id')) {
      context.handle(
          _newClassIdMeta,
          newClassId.isAcceptableOrUnknown(
              data['new_class_id']!, _newClassIdMeta));
    }
    if (data.containsKey('previous_status')) {
      context.handle(
          _previousStatusMeta,
          previousStatus.isAcceptableOrUnknown(
              data['previous_status']!, _previousStatusMeta));
    } else if (isInserting) {
      context.missing(_previousStatusMeta);
    }
    if (data.containsKey('new_status')) {
      context.handle(_newStatusMeta,
          newStatus.isAcceptableOrUnknown(data['new_status']!, _newStatusMeta));
    } else if (isInserting) {
      context.missing(_newStatusMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta,
          result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('academic_year')) {
      context.handle(
          _academicYearMeta,
          academicYear.isAcceptableOrUnknown(
              data['academic_year']!, _academicYearMeta));
    } else if (isInserting) {
      context.missing(_academicYearMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromotionRecordsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromotionRecordsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      batchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      previousClassId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}previous_class_id'])!,
      newClassId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_class_id']),
      previousStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}previous_status'])!,
      newStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_status'])!,
      result: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result'])!,
      academicYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}academic_year'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PromotionRecordsTableTable createAlias(String alias) {
    return $PromotionRecordsTableTable(attachedDatabase, alias);
  }
}

class PromotionRecordsTableData extends DataClass
    implements Insertable<PromotionRecordsTableData> {
  final String id;
  final String batchId;
  final String studentId;
  final String previousClassId;
  final String? newClassId;
  final String previousStatus;
  final String newStatus;
  final String result;
  final int academicYear;
  final DateTime createdAt;
  const PromotionRecordsTableData(
      {required this.id,
      required this.batchId,
      required this.studentId,
      required this.previousClassId,
      this.newClassId,
      required this.previousStatus,
      required this.newStatus,
      required this.result,
      required this.academicYear,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['batch_id'] = Variable<String>(batchId);
    map['student_id'] = Variable<String>(studentId);
    map['previous_class_id'] = Variable<String>(previousClassId);
    if (!nullToAbsent || newClassId != null) {
      map['new_class_id'] = Variable<String>(newClassId);
    }
    map['previous_status'] = Variable<String>(previousStatus);
    map['new_status'] = Variable<String>(newStatus);
    map['result'] = Variable<String>(result);
    map['academic_year'] = Variable<int>(academicYear);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PromotionRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return PromotionRecordsTableCompanion(
      id: Value(id),
      batchId: Value(batchId),
      studentId: Value(studentId),
      previousClassId: Value(previousClassId),
      newClassId: newClassId == null && nullToAbsent
          ? const Value.absent()
          : Value(newClassId),
      previousStatus: Value(previousStatus),
      newStatus: Value(newStatus),
      result: Value(result),
      academicYear: Value(academicYear),
      createdAt: Value(createdAt),
    );
  }

  factory PromotionRecordsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromotionRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      batchId: serializer.fromJson<String>(json['batchId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      previousClassId: serializer.fromJson<String>(json['previousClassId']),
      newClassId: serializer.fromJson<String?>(json['newClassId']),
      previousStatus: serializer.fromJson<String>(json['previousStatus']),
      newStatus: serializer.fromJson<String>(json['newStatus']),
      result: serializer.fromJson<String>(json['result']),
      academicYear: serializer.fromJson<int>(json['academicYear']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'batchId': serializer.toJson<String>(batchId),
      'studentId': serializer.toJson<String>(studentId),
      'previousClassId': serializer.toJson<String>(previousClassId),
      'newClassId': serializer.toJson<String?>(newClassId),
      'previousStatus': serializer.toJson<String>(previousStatus),
      'newStatus': serializer.toJson<String>(newStatus),
      'result': serializer.toJson<String>(result),
      'academicYear': serializer.toJson<int>(academicYear),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PromotionRecordsTableData copyWith(
          {String? id,
          String? batchId,
          String? studentId,
          String? previousClassId,
          Value<String?> newClassId = const Value.absent(),
          String? previousStatus,
          String? newStatus,
          String? result,
          int? academicYear,
          DateTime? createdAt}) =>
      PromotionRecordsTableData(
        id: id ?? this.id,
        batchId: batchId ?? this.batchId,
        studentId: studentId ?? this.studentId,
        previousClassId: previousClassId ?? this.previousClassId,
        newClassId: newClassId.present ? newClassId.value : this.newClassId,
        previousStatus: previousStatus ?? this.previousStatus,
        newStatus: newStatus ?? this.newStatus,
        result: result ?? this.result,
        academicYear: academicYear ?? this.academicYear,
        createdAt: createdAt ?? this.createdAt,
      );
  PromotionRecordsTableData copyWithCompanion(
      PromotionRecordsTableCompanion data) {
    return PromotionRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      previousClassId: data.previousClassId.present
          ? data.previousClassId.value
          : this.previousClassId,
      newClassId:
          data.newClassId.present ? data.newClassId.value : this.newClassId,
      previousStatus: data.previousStatus.present
          ? data.previousStatus.value
          : this.previousStatus,
      newStatus: data.newStatus.present ? data.newStatus.value : this.newStatus,
      result: data.result.present ? data.result.value : this.result,
      academicYear: data.academicYear.present
          ? data.academicYear.value
          : this.academicYear,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromotionRecordsTableData(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('studentId: $studentId, ')
          ..write('previousClassId: $previousClassId, ')
          ..write('newClassId: $newClassId, ')
          ..write('previousStatus: $previousStatus, ')
          ..write('newStatus: $newStatus, ')
          ..write('result: $result, ')
          ..write('academicYear: $academicYear, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, batchId, studentId, previousClassId,
      newClassId, previousStatus, newStatus, result, academicYear, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromotionRecordsTableData &&
          other.id == this.id &&
          other.batchId == this.batchId &&
          other.studentId == this.studentId &&
          other.previousClassId == this.previousClassId &&
          other.newClassId == this.newClassId &&
          other.previousStatus == this.previousStatus &&
          other.newStatus == this.newStatus &&
          other.result == this.result &&
          other.academicYear == this.academicYear &&
          other.createdAt == this.createdAt);
}

class PromotionRecordsTableCompanion
    extends UpdateCompanion<PromotionRecordsTableData> {
  final Value<String> id;
  final Value<String> batchId;
  final Value<String> studentId;
  final Value<String> previousClassId;
  final Value<String?> newClassId;
  final Value<String> previousStatus;
  final Value<String> newStatus;
  final Value<String> result;
  final Value<int> academicYear;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PromotionRecordsTableCompanion({
    this.id = const Value.absent(),
    this.batchId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.previousClassId = const Value.absent(),
    this.newClassId = const Value.absent(),
    this.previousStatus = const Value.absent(),
    this.newStatus = const Value.absent(),
    this.result = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromotionRecordsTableCompanion.insert({
    required String id,
    required String batchId,
    required String studentId,
    required String previousClassId,
    this.newClassId = const Value.absent(),
    required String previousStatus,
    required String newStatus,
    required String result,
    required int academicYear,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        batchId = Value(batchId),
        studentId = Value(studentId),
        previousClassId = Value(previousClassId),
        previousStatus = Value(previousStatus),
        newStatus = Value(newStatus),
        result = Value(result),
        academicYear = Value(academicYear);
  static Insertable<PromotionRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? batchId,
    Expression<String>? studentId,
    Expression<String>? previousClassId,
    Expression<String>? newClassId,
    Expression<String>? previousStatus,
    Expression<String>? newStatus,
    Expression<String>? result,
    Expression<int>? academicYear,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (batchId != null) 'batch_id': batchId,
      if (studentId != null) 'student_id': studentId,
      if (previousClassId != null) 'previous_class_id': previousClassId,
      if (newClassId != null) 'new_class_id': newClassId,
      if (previousStatus != null) 'previous_status': previousStatus,
      if (newStatus != null) 'new_status': newStatus,
      if (result != null) 'result': result,
      if (academicYear != null) 'academic_year': academicYear,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromotionRecordsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? batchId,
      Value<String>? studentId,
      Value<String>? previousClassId,
      Value<String?>? newClassId,
      Value<String>? previousStatus,
      Value<String>? newStatus,
      Value<String>? result,
      Value<int>? academicYear,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PromotionRecordsTableCompanion(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      studentId: studentId ?? this.studentId,
      previousClassId: previousClassId ?? this.previousClassId,
      newClassId: newClassId ?? this.newClassId,
      previousStatus: previousStatus ?? this.previousStatus,
      newStatus: newStatus ?? this.newStatus,
      result: result ?? this.result,
      academicYear: academicYear ?? this.academicYear,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (previousClassId.present) {
      map['previous_class_id'] = Variable<String>(previousClassId.value);
    }
    if (newClassId.present) {
      map['new_class_id'] = Variable<String>(newClassId.value);
    }
    if (previousStatus.present) {
      map['previous_status'] = Variable<String>(previousStatus.value);
    }
    if (newStatus.present) {
      map['new_status'] = Variable<String>(newStatus.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (academicYear.present) {
      map['academic_year'] = Variable<int>(academicYear.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromotionRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('studentId: $studentId, ')
          ..write('previousClassId: $previousClassId, ')
          ..write('newClassId: $newClassId, ')
          ..write('previousStatus: $previousStatus, ')
          ..write('newStatus: $newStatus, ')
          ..write('result: $result, ')
          ..write('academicYear: $academicYear, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StruckOffRecordsTableTable extends StruckOffRecordsTable
    with TableInfo<$StruckOffRecordsTableTable, StruckOffRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StruckOffRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _struckOffDateMeta =
      const VerificationMeta('struckOffDate');
  @override
  late final GeneratedColumn<DateTime> struckOffDate =
      GeneratedColumn<DateTime>('struck_off_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reAdmittedMeta =
      const VerificationMeta('reAdmitted');
  @override
  late final GeneratedColumn<bool> reAdmitted = GeneratedColumn<bool>(
      're_admitted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("re_admitted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _reAdmittedDateMeta =
      const VerificationMeta('reAdmittedDate');
  @override
  late final GeneratedColumn<DateTime> reAdmittedDate =
      GeneratedColumn<DateTime>('re_admitted_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _reAdmittedByMeta =
      const VerificationMeta('reAdmittedBy');
  @override
  late final GeneratedColumn<String> reAdmittedBy = GeneratedColumn<String>(
      're_admitted_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendingCreate'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        schoolId,
        studentId,
        struckOffDate,
        reason,
        reAdmitted,
        reAdmittedDate,
        reAdmittedBy,
        createdBy,
        createdAt,
        syncState
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'struck_off_records_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<StruckOffRecordsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('struck_off_date')) {
      context.handle(
          _struckOffDateMeta,
          struckOffDate.isAcceptableOrUnknown(
              data['struck_off_date']!, _struckOffDateMeta));
    } else if (isInserting) {
      context.missing(_struckOffDateMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('re_admitted')) {
      context.handle(
          _reAdmittedMeta,
          reAdmitted.isAcceptableOrUnknown(
              data['re_admitted']!, _reAdmittedMeta));
    }
    if (data.containsKey('re_admitted_date')) {
      context.handle(
          _reAdmittedDateMeta,
          reAdmittedDate.isAcceptableOrUnknown(
              data['re_admitted_date']!, _reAdmittedDateMeta));
    }
    if (data.containsKey('re_admitted_by')) {
      context.handle(
          _reAdmittedByMeta,
          reAdmittedBy.isAcceptableOrUnknown(
              data['re_admitted_by']!, _reAdmittedByMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StruckOffRecordsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StruckOffRecordsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      struckOffDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}struck_off_date'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      reAdmitted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}re_admitted'])!,
      reAdmittedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}re_admitted_date']),
      reAdmittedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}re_admitted_by']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
    );
  }

  @override
  $StruckOffRecordsTableTable createAlias(String alias) {
    return $StruckOffRecordsTableTable(attachedDatabase, alias);
  }
}

class StruckOffRecordsTableData extends DataClass
    implements Insertable<StruckOffRecordsTableData> {
  final String id;
  final String schoolId;
  final String studentId;
  final DateTime struckOffDate;
  final String reason;
  final bool reAdmitted;
  final DateTime? reAdmittedDate;
  final String? reAdmittedBy;
  final String? createdBy;
  final DateTime createdAt;
  final String syncState;
  const StruckOffRecordsTableData(
      {required this.id,
      required this.schoolId,
      required this.studentId,
      required this.struckOffDate,
      required this.reason,
      required this.reAdmitted,
      this.reAdmittedDate,
      this.reAdmittedBy,
      this.createdBy,
      required this.createdAt,
      required this.syncState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    map['student_id'] = Variable<String>(studentId);
    map['struck_off_date'] = Variable<DateTime>(struckOffDate);
    map['reason'] = Variable<String>(reason);
    map['re_admitted'] = Variable<bool>(reAdmitted);
    if (!nullToAbsent || reAdmittedDate != null) {
      map['re_admitted_date'] = Variable<DateTime>(reAdmittedDate);
    }
    if (!nullToAbsent || reAdmittedBy != null) {
      map['re_admitted_by'] = Variable<String>(reAdmittedBy);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  StruckOffRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return StruckOffRecordsTableCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      studentId: Value(studentId),
      struckOffDate: Value(struckOffDate),
      reason: Value(reason),
      reAdmitted: Value(reAdmitted),
      reAdmittedDate: reAdmittedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(reAdmittedDate),
      reAdmittedBy: reAdmittedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reAdmittedBy),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
    );
  }

  factory StruckOffRecordsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StruckOffRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      struckOffDate: serializer.fromJson<DateTime>(json['struckOffDate']),
      reason: serializer.fromJson<String>(json['reason']),
      reAdmitted: serializer.fromJson<bool>(json['reAdmitted']),
      reAdmittedDate: serializer.fromJson<DateTime?>(json['reAdmittedDate']),
      reAdmittedBy: serializer.fromJson<String?>(json['reAdmittedBy']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'studentId': serializer.toJson<String>(studentId),
      'struckOffDate': serializer.toJson<DateTime>(struckOffDate),
      'reason': serializer.toJson<String>(reason),
      'reAdmitted': serializer.toJson<bool>(reAdmitted),
      'reAdmittedDate': serializer.toJson<DateTime?>(reAdmittedDate),
      'reAdmittedBy': serializer.toJson<String?>(reAdmittedBy),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  StruckOffRecordsTableData copyWith(
          {String? id,
          String? schoolId,
          String? studentId,
          DateTime? struckOffDate,
          String? reason,
          bool? reAdmitted,
          Value<DateTime?> reAdmittedDate = const Value.absent(),
          Value<String?> reAdmittedBy = const Value.absent(),
          Value<String?> createdBy = const Value.absent(),
          DateTime? createdAt,
          String? syncState}) =>
      StruckOffRecordsTableData(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        studentId: studentId ?? this.studentId,
        struckOffDate: struckOffDate ?? this.struckOffDate,
        reason: reason ?? this.reason,
        reAdmitted: reAdmitted ?? this.reAdmitted,
        reAdmittedDate:
            reAdmittedDate.present ? reAdmittedDate.value : this.reAdmittedDate,
        reAdmittedBy:
            reAdmittedBy.present ? reAdmittedBy.value : this.reAdmittedBy,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        syncState: syncState ?? this.syncState,
      );
  StruckOffRecordsTableData copyWithCompanion(
      StruckOffRecordsTableCompanion data) {
    return StruckOffRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      struckOffDate: data.struckOffDate.present
          ? data.struckOffDate.value
          : this.struckOffDate,
      reason: data.reason.present ? data.reason.value : this.reason,
      reAdmitted:
          data.reAdmitted.present ? data.reAdmitted.value : this.reAdmitted,
      reAdmittedDate: data.reAdmittedDate.present
          ? data.reAdmittedDate.value
          : this.reAdmittedDate,
      reAdmittedBy: data.reAdmittedBy.present
          ? data.reAdmittedBy.value
          : this.reAdmittedBy,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StruckOffRecordsTableData(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('studentId: $studentId, ')
          ..write('struckOffDate: $struckOffDate, ')
          ..write('reason: $reason, ')
          ..write('reAdmitted: $reAdmitted, ')
          ..write('reAdmittedDate: $reAdmittedDate, ')
          ..write('reAdmittedBy: $reAdmittedBy, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      schoolId,
      studentId,
      struckOffDate,
      reason,
      reAdmitted,
      reAdmittedDate,
      reAdmittedBy,
      createdBy,
      createdAt,
      syncState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StruckOffRecordsTableData &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.studentId == this.studentId &&
          other.struckOffDate == this.struckOffDate &&
          other.reason == this.reason &&
          other.reAdmitted == this.reAdmitted &&
          other.reAdmittedDate == this.reAdmittedDate &&
          other.reAdmittedBy == this.reAdmittedBy &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState);
}

class StruckOffRecordsTableCompanion
    extends UpdateCompanion<StruckOffRecordsTableData> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<String> studentId;
  final Value<DateTime> struckOffDate;
  final Value<String> reason;
  final Value<bool> reAdmitted;
  final Value<DateTime?> reAdmittedDate;
  final Value<String?> reAdmittedBy;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const StruckOffRecordsTableCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.struckOffDate = const Value.absent(),
    this.reason = const Value.absent(),
    this.reAdmitted = const Value.absent(),
    this.reAdmittedDate = const Value.absent(),
    this.reAdmittedBy = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StruckOffRecordsTableCompanion.insert({
    required String id,
    required String schoolId,
    required String studentId,
    required DateTime struckOffDate,
    required String reason,
    this.reAdmitted = const Value.absent(),
    this.reAdmittedDate = const Value.absent(),
    this.reAdmittedBy = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        schoolId = Value(schoolId),
        studentId = Value(studentId),
        struckOffDate = Value(struckOffDate),
        reason = Value(reason);
  static Insertable<StruckOffRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<String>? studentId,
    Expression<DateTime>? struckOffDate,
    Expression<String>? reason,
    Expression<bool>? reAdmitted,
    Expression<DateTime>? reAdmittedDate,
    Expression<String>? reAdmittedBy,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (studentId != null) 'student_id': studentId,
      if (struckOffDate != null) 'struck_off_date': struckOffDate,
      if (reason != null) 'reason': reason,
      if (reAdmitted != null) 're_admitted': reAdmitted,
      if (reAdmittedDate != null) 're_admitted_date': reAdmittedDate,
      if (reAdmittedBy != null) 're_admitted_by': reAdmittedBy,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StruckOffRecordsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? schoolId,
      Value<String>? studentId,
      Value<DateTime>? struckOffDate,
      Value<String>? reason,
      Value<bool>? reAdmitted,
      Value<DateTime?>? reAdmittedDate,
      Value<String?>? reAdmittedBy,
      Value<String?>? createdBy,
      Value<DateTime>? createdAt,
      Value<String>? syncState,
      Value<int>? rowid}) {
    return StruckOffRecordsTableCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      struckOffDate: struckOffDate ?? this.struckOffDate,
      reason: reason ?? this.reason,
      reAdmitted: reAdmitted ?? this.reAdmitted,
      reAdmittedDate: reAdmittedDate ?? this.reAdmittedDate,
      reAdmittedBy: reAdmittedBy ?? this.reAdmittedBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (struckOffDate.present) {
      map['struck_off_date'] = Variable<DateTime>(struckOffDate.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (reAdmitted.present) {
      map['re_admitted'] = Variable<bool>(reAdmitted.value);
    }
    if (reAdmittedDate.present) {
      map['re_admitted_date'] = Variable<DateTime>(reAdmittedDate.value);
    }
    if (reAdmittedBy.present) {
      map['re_admitted_by'] = Variable<String>(reAdmittedBy.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StruckOffRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('studentId: $studentId, ')
          ..write('struckOffDate: $struckOffDate, ')
          ..write('reason: $reason, ')
          ..write('reAdmitted: $reAdmitted, ')
          ..write('reAdmittedDate: $reAdmittedDate, ')
          ..write('reAdmittedBy: $reAdmittedBy, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PassOutYearsTableTable extends PassOutYearsTable
    with TableInfo<$PassOutYearsTableTable, PassOutYearsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PassOutYearsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schoolIdMeta =
      const VerificationMeta('schoolId');
  @override
  late final GeneratedColumn<String> schoolId = GeneratedColumn<String>(
      'school_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendingCreate'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, schoolId, year, createdAt, syncState];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pass_out_years_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<PassOutYearsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('school_id')) {
      context.handle(_schoolIdMeta,
          schoolId.isAcceptableOrUnknown(data['school_id']!, _schoolIdMeta));
    } else if (isInserting) {
      context.missing(_schoolIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PassOutYearsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PassOutYearsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      schoolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}school_id'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
    );
  }

  @override
  $PassOutYearsTableTable createAlias(String alias) {
    return $PassOutYearsTableTable(attachedDatabase, alias);
  }
}

class PassOutYearsTableData extends DataClass
    implements Insertable<PassOutYearsTableData> {
  final String id;
  final String schoolId;
  final int year;
  final DateTime createdAt;
  final String syncState;
  const PassOutYearsTableData(
      {required this.id,
      required this.schoolId,
      required this.year,
      required this.createdAt,
      required this.syncState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['school_id'] = Variable<String>(schoolId);
    map['year'] = Variable<int>(year);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  PassOutYearsTableCompanion toCompanion(bool nullToAbsent) {
    return PassOutYearsTableCompanion(
      id: Value(id),
      schoolId: Value(schoolId),
      year: Value(year),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
    );
  }

  factory PassOutYearsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PassOutYearsTableData(
      id: serializer.fromJson<String>(json['id']),
      schoolId: serializer.fromJson<String>(json['schoolId']),
      year: serializer.fromJson<int>(json['year']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'schoolId': serializer.toJson<String>(schoolId),
      'year': serializer.toJson<int>(year),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  PassOutYearsTableData copyWith(
          {String? id,
          String? schoolId,
          int? year,
          DateTime? createdAt,
          String? syncState}) =>
      PassOutYearsTableData(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        year: year ?? this.year,
        createdAt: createdAt ?? this.createdAt,
        syncState: syncState ?? this.syncState,
      );
  PassOutYearsTableData copyWithCompanion(PassOutYearsTableCompanion data) {
    return PassOutYearsTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolId: data.schoolId.present ? data.schoolId.value : this.schoolId,
      year: data.year.present ? data.year.value : this.year,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PassOutYearsTableData(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('year: $year, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, schoolId, year, createdAt, syncState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PassOutYearsTableData &&
          other.id == this.id &&
          other.schoolId == this.schoolId &&
          other.year == this.year &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState);
}

class PassOutYearsTableCompanion
    extends UpdateCompanion<PassOutYearsTableData> {
  final Value<String> id;
  final Value<String> schoolId;
  final Value<int> year;
  final Value<DateTime> createdAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const PassOutYearsTableCompanion({
    this.id = const Value.absent(),
    this.schoolId = const Value.absent(),
    this.year = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PassOutYearsTableCompanion.insert({
    required String id,
    required String schoolId,
    required int year,
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        schoolId = Value(schoolId),
        year = Value(year);
  static Insertable<PassOutYearsTableData> custom({
    Expression<String>? id,
    Expression<String>? schoolId,
    Expression<int>? year,
    Expression<DateTime>? createdAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolId != null) 'school_id': schoolId,
      if (year != null) 'year': year,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PassOutYearsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? schoolId,
      Value<int>? year,
      Value<DateTime>? createdAt,
      Value<String>? syncState,
      Value<int>? rowid}) {
    return PassOutYearsTableCompanion(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (schoolId.present) {
      map['school_id'] = Variable<String>(schoolId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PassOutYearsTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolId: $schoolId, ')
          ..write('year: $year, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SchoolsTableTable schoolsTable = $SchoolsTableTable(this);
  late final $ClassesTableTable classesTable = $ClassesTableTable(this);
  late final $StudentsTableTable studentsTable = $StudentsTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $StudentPhotosTableTable studentPhotosTable =
      $StudentPhotosTableTable(this);
  late final $AuditLogsTableTable auditLogsTable = $AuditLogsTableTable(this);
  late final $PromotionBatchesTableTable promotionBatchesTable =
      $PromotionBatchesTableTable(this);
  late final $PromotionRecordsTableTable promotionRecordsTable =
      $PromotionRecordsTableTable(this);
  late final $StruckOffRecordsTableTable struckOffRecordsTable =
      $StruckOffRecordsTableTable(this);
  late final $PassOutYearsTableTable passOutYearsTable =
      $PassOutYearsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        schoolsTable,
        classesTable,
        studentsTable,
        syncQueueTable,
        studentPhotosTable,
        auditLogsTable,
        promotionBatchesTable,
        promotionRecordsTable,
        struckOffRecordsTable,
        passOutYearsTable
      ];
}

typedef $$SchoolsTableTableCreateCompanionBuilder = SchoolsTableCompanion
    Function({
  required String id,
  required String schoolName,
  Value<String?> semisCode,
  Value<String?> uc,
  Value<String?> taluka,
  Value<String?> district,
  required String createdBy,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SchoolsTableTableUpdateCompanionBuilder = SchoolsTableCompanion
    Function({
  Value<String> id,
  Value<String> schoolName,
  Value<String?> semisCode,
  Value<String?> uc,
  Value<String?> taluka,
  Value<String?> district,
  Value<String> createdBy,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SchoolsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SchoolsTableTable> {
  $$SchoolsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schoolName => $composableBuilder(
      column: $table.schoolName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get semisCode => $composableBuilder(
      column: $table.semisCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uc => $composableBuilder(
      column: $table.uc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taluka => $composableBuilder(
      column: $table.taluka, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get district => $composableBuilder(
      column: $table.district, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SchoolsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SchoolsTableTable> {
  $$SchoolsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schoolName => $composableBuilder(
      column: $table.schoolName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get semisCode => $composableBuilder(
      column: $table.semisCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uc => $composableBuilder(
      column: $table.uc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taluka => $composableBuilder(
      column: $table.taluka, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get district => $composableBuilder(
      column: $table.district, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SchoolsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchoolsTableTable> {
  $$SchoolsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get schoolName => $composableBuilder(
      column: $table.schoolName, builder: (column) => column);

  GeneratedColumn<String> get semisCode =>
      $composableBuilder(column: $table.semisCode, builder: (column) => column);

  GeneratedColumn<String> get uc =>
      $composableBuilder(column: $table.uc, builder: (column) => column);

  GeneratedColumn<String> get taluka =>
      $composableBuilder(column: $table.taluka, builder: (column) => column);

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SchoolsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SchoolsTableTable,
    SchoolsTableData,
    $$SchoolsTableTableFilterComposer,
    $$SchoolsTableTableOrderingComposer,
    $$SchoolsTableTableAnnotationComposer,
    $$SchoolsTableTableCreateCompanionBuilder,
    $$SchoolsTableTableUpdateCompanionBuilder,
    (
      SchoolsTableData,
      BaseReferences<_$AppDatabase, $SchoolsTableTable, SchoolsTableData>
    ),
    SchoolsTableData,
    PrefetchHooks Function()> {
  $$SchoolsTableTableTableManager(_$AppDatabase db, $SchoolsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchoolsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchoolsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchoolsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> schoolName = const Value.absent(),
            Value<String?> semisCode = const Value.absent(),
            Value<String?> uc = const Value.absent(),
            Value<String?> taluka = const Value.absent(),
            Value<String?> district = const Value.absent(),
            Value<String> createdBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SchoolsTableCompanion(
            id: id,
            schoolName: schoolName,
            semisCode: semisCode,
            uc: uc,
            taluka: taluka,
            district: district,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String schoolName,
            Value<String?> semisCode = const Value.absent(),
            Value<String?> uc = const Value.absent(),
            Value<String?> taluka = const Value.absent(),
            Value<String?> district = const Value.absent(),
            required String createdBy,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SchoolsTableCompanion.insert(
            id: id,
            schoolName: schoolName,
            semisCode: semisCode,
            uc: uc,
            taluka: taluka,
            district: district,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SchoolsTableTable, SchoolsTableData>(table),
                    BaseReferences<_$AppDatabase, $SchoolsTableTable,
                        SchoolsTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SchoolsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SchoolsTableTable,
    SchoolsTableData,
    $$SchoolsTableTableFilterComposer,
    $$SchoolsTableTableOrderingComposer,
    $$SchoolsTableTableAnnotationComposer,
    $$SchoolsTableTableCreateCompanionBuilder,
    $$SchoolsTableTableUpdateCompanionBuilder,
    (
      SchoolsTableData,
      BaseReferences<_$AppDatabase, $SchoolsTableTable, SchoolsTableData>
    ),
    SchoolsTableData,
    PrefetchHooks Function()>;
typedef $$ClassesTableTableCreateCompanionBuilder = ClassesTableCompanion
    Function({
  required String id,
  required String schoolId,
  required String classCode,
  required String displayName,
  Value<int> sortOrder,
  Value<int?> minAdmissionAgeMonths,
  Value<int?> minPromotionAgeMonths,
  Value<String?> promotesToClassId,
  Value<bool> isTerminal,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$ClassesTableTableUpdateCompanionBuilder = ClassesTableCompanion
    Function({
  Value<String> id,
  Value<String> schoolId,
  Value<String> classCode,
  Value<String> displayName,
  Value<int> sortOrder,
  Value<int?> minAdmissionAgeMonths,
  Value<int?> minPromotionAgeMonths,
  Value<String?> promotesToClassId,
  Value<bool> isTerminal,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$ClassesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClassesTableTable> {
  $$ClassesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get classCode => $composableBuilder(
      column: $table.classCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minAdmissionAgeMonths => $composableBuilder(
      column: $table.minAdmissionAgeMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minPromotionAgeMonths => $composableBuilder(
      column: $table.minPromotionAgeMonths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promotesToClassId => $composableBuilder(
      column: $table.promotesToClassId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTerminal => $composableBuilder(
      column: $table.isTerminal, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$ClassesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassesTableTable> {
  $$ClassesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classCode => $composableBuilder(
      column: $table.classCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minAdmissionAgeMonths => $composableBuilder(
      column: $table.minAdmissionAgeMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minPromotionAgeMonths => $composableBuilder(
      column: $table.minPromotionAgeMonths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promotesToClassId => $composableBuilder(
      column: $table.promotesToClassId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTerminal => $composableBuilder(
      column: $table.isTerminal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$ClassesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassesTableTable> {
  $$ClassesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<String> get classCode =>
      $composableBuilder(column: $table.classCode, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get minAdmissionAgeMonths => $composableBuilder(
      column: $table.minAdmissionAgeMonths, builder: (column) => column);

  GeneratedColumn<int> get minPromotionAgeMonths => $composableBuilder(
      column: $table.minPromotionAgeMonths, builder: (column) => column);

  GeneratedColumn<String> get promotesToClassId => $composableBuilder(
      column: $table.promotesToClassId, builder: (column) => column);

  GeneratedColumn<bool> get isTerminal => $composableBuilder(
      column: $table.isTerminal, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$ClassesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClassesTableTable,
    ClassesTableData,
    $$ClassesTableTableFilterComposer,
    $$ClassesTableTableOrderingComposer,
    $$ClassesTableTableAnnotationComposer,
    $$ClassesTableTableCreateCompanionBuilder,
    $$ClassesTableTableUpdateCompanionBuilder,
    (
      ClassesTableData,
      BaseReferences<_$AppDatabase, $ClassesTableTable, ClassesTableData>
    ),
    ClassesTableData,
    PrefetchHooks Function()> {
  $$ClassesTableTableTableManager(_$AppDatabase db, $ClassesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> schoolId = const Value.absent(),
            Value<String> classCode = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> minAdmissionAgeMonths = const Value.absent(),
            Value<int?> minPromotionAgeMonths = const Value.absent(),
            Value<String?> promotesToClassId = const Value.absent(),
            Value<bool> isTerminal = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClassesTableCompanion(
            id: id,
            schoolId: schoolId,
            classCode: classCode,
            displayName: displayName,
            sortOrder: sortOrder,
            minAdmissionAgeMonths: minAdmissionAgeMonths,
            minPromotionAgeMonths: minPromotionAgeMonths,
            promotesToClassId: promotesToClassId,
            isTerminal: isTerminal,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String schoolId,
            required String classCode,
            required String displayName,
            Value<int> sortOrder = const Value.absent(),
            Value<int?> minAdmissionAgeMonths = const Value.absent(),
            Value<int?> minPromotionAgeMonths = const Value.absent(),
            Value<String?> promotesToClassId = const Value.absent(),
            Value<bool> isTerminal = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClassesTableCompanion.insert(
            id: id,
            schoolId: schoolId,
            classCode: classCode,
            displayName: displayName,
            sortOrder: sortOrder,
            minAdmissionAgeMonths: minAdmissionAgeMonths,
            minPromotionAgeMonths: minPromotionAgeMonths,
            promotesToClassId: promotesToClassId,
            isTerminal: isTerminal,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ClassesTableTable, ClassesTableData>(table),
                    BaseReferences<_$AppDatabase, $ClassesTableTable,
                        ClassesTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ClassesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClassesTableTable,
    ClassesTableData,
    $$ClassesTableTableFilterComposer,
    $$ClassesTableTableOrderingComposer,
    $$ClassesTableTableAnnotationComposer,
    $$ClassesTableTableCreateCompanionBuilder,
    $$ClassesTableTableUpdateCompanionBuilder,
    (
      ClassesTableData,
      BaseReferences<_$AppDatabase, $ClassesTableTable, ClassesTableData>
    ),
    ClassesTableData,
    PrefetchHooks Function()>;
typedef $$StudentsTableTableCreateCompanionBuilder = StudentsTableCompanion
    Function({
  required String id,
  required String clientGeneratedId,
  required String schoolId,
  required String classId,
  required String grNumber,
  Value<int?> serialNumber,
  required String studentName,
  Value<String?> fatherName,
  Value<String?> motherName,
  required DateTime dateOfBirth,
  required DateTime dateOfAdmission,
  Value<String?> fatherCnic,
  Value<String?> bFormNumber,
  Value<String?> phoneNumber,
  Value<String?> address,
  Value<String?> previousSchool,
  Value<String?> remarks,
  Value<String> status,
  Value<String> promotionStatus,
  Value<DateTime?> struckOffDate,
  Value<String?> struckOffReason,
  Value<int?> passOutYear,
  Value<int> version,
  required DateTime updatedAt,
  required DateTime createdAt,
  Value<String?> createdBy,
  Value<String?> updatedBy,
  Value<bool> isDeleted,
  Value<String> syncState,
  Value<DateTime?> dirtySince,
  Value<int> rowid,
});
typedef $$StudentsTableTableUpdateCompanionBuilder = StudentsTableCompanion
    Function({
  Value<String> id,
  Value<String> clientGeneratedId,
  Value<String> schoolId,
  Value<String> classId,
  Value<String> grNumber,
  Value<int?> serialNumber,
  Value<String> studentName,
  Value<String?> fatherName,
  Value<String?> motherName,
  Value<DateTime> dateOfBirth,
  Value<DateTime> dateOfAdmission,
  Value<String?> fatherCnic,
  Value<String?> bFormNumber,
  Value<String?> phoneNumber,
  Value<String?> address,
  Value<String?> previousSchool,
  Value<String?> remarks,
  Value<String> status,
  Value<String> promotionStatus,
  Value<DateTime?> struckOffDate,
  Value<String?> struckOffReason,
  Value<int?> passOutYear,
  Value<int> version,
  Value<DateTime> updatedAt,
  Value<DateTime> createdAt,
  Value<String?> createdBy,
  Value<String?> updatedBy,
  Value<bool> isDeleted,
  Value<String> syncState,
  Value<DateTime?> dirtySince,
  Value<int> rowid,
});

class $$StudentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientGeneratedId => $composableBuilder(
      column: $table.clientGeneratedId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grNumber => $composableBuilder(
      column: $table.grNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serialNumber => $composableBuilder(
      column: $table.serialNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fatherName => $composableBuilder(
      column: $table.fatherName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motherName => $composableBuilder(
      column: $table.motherName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateOfAdmission => $composableBuilder(
      column: $table.dateOfAdmission,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fatherCnic => $composableBuilder(
      column: $table.fatherCnic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bFormNumber => $composableBuilder(
      column: $table.bFormNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get previousSchool => $composableBuilder(
      column: $table.previousSchool,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remarks => $composableBuilder(
      column: $table.remarks, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promotionStatus => $composableBuilder(
      column: $table.promotionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get struckOffDate => $composableBuilder(
      column: $table.struckOffDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get struckOffReason => $composableBuilder(
      column: $table.struckOffReason,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get passOutYear => $composableBuilder(
      column: $table.passOutYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedBy => $composableBuilder(
      column: $table.updatedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dirtySince => $composableBuilder(
      column: $table.dirtySince, builder: (column) => ColumnFilters(column));
}

class $$StudentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientGeneratedId => $composableBuilder(
      column: $table.clientGeneratedId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grNumber => $composableBuilder(
      column: $table.grNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serialNumber => $composableBuilder(
      column: $table.serialNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fatherName => $composableBuilder(
      column: $table.fatherName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motherName => $composableBuilder(
      column: $table.motherName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateOfAdmission => $composableBuilder(
      column: $table.dateOfAdmission,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fatherCnic => $composableBuilder(
      column: $table.fatherCnic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bFormNumber => $composableBuilder(
      column: $table.bFormNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get previousSchool => $composableBuilder(
      column: $table.previousSchool,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remarks => $composableBuilder(
      column: $table.remarks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promotionStatus => $composableBuilder(
      column: $table.promotionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get struckOffDate => $composableBuilder(
      column: $table.struckOffDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get struckOffReason => $composableBuilder(
      column: $table.struckOffReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get passOutYear => $composableBuilder(
      column: $table.passOutYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedBy => $composableBuilder(
      column: $table.updatedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dirtySince => $composableBuilder(
      column: $table.dirtySince, builder: (column) => ColumnOrderings(column));
}

class $$StudentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientGeneratedId => $composableBuilder(
      column: $table.clientGeneratedId, builder: (column) => column);

  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<String> get classId =>
      $composableBuilder(column: $table.classId, builder: (column) => column);

  GeneratedColumn<String> get grNumber =>
      $composableBuilder(column: $table.grNumber, builder: (column) => column);

  GeneratedColumn<int> get serialNumber => $composableBuilder(
      column: $table.serialNumber, builder: (column) => column);

  GeneratedColumn<String> get studentName => $composableBuilder(
      column: $table.studentName, builder: (column) => column);

  GeneratedColumn<String> get fatherName => $composableBuilder(
      column: $table.fatherName, builder: (column) => column);

  GeneratedColumn<String> get motherName => $composableBuilder(
      column: $table.motherName, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfAdmission => $composableBuilder(
      column: $table.dateOfAdmission, builder: (column) => column);

  GeneratedColumn<String> get fatherCnic => $composableBuilder(
      column: $table.fatherCnic, builder: (column) => column);

  GeneratedColumn<String> get bFormNumber => $composableBuilder(
      column: $table.bFormNumber, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get previousSchool => $composableBuilder(
      column: $table.previousSchool, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get promotionStatus => $composableBuilder(
      column: $table.promotionStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get struckOffDate => $composableBuilder(
      column: $table.struckOffDate, builder: (column) => column);

  GeneratedColumn<String> get struckOffReason => $composableBuilder(
      column: $table.struckOffReason, builder: (column) => column);

  GeneratedColumn<int> get passOutYear => $composableBuilder(
      column: $table.passOutYear, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get dirtySince => $composableBuilder(
      column: $table.dirtySince, builder: (column) => column);
}

class $$StudentsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudentsTableTable,
    StudentsTableData,
    $$StudentsTableTableFilterComposer,
    $$StudentsTableTableOrderingComposer,
    $$StudentsTableTableAnnotationComposer,
    $$StudentsTableTableCreateCompanionBuilder,
    $$StudentsTableTableUpdateCompanionBuilder,
    (
      StudentsTableData,
      BaseReferences<_$AppDatabase, $StudentsTableTable, StudentsTableData>
    ),
    StudentsTableData,
    PrefetchHooks Function()> {
  $$StudentsTableTableTableManager(_$AppDatabase db, $StudentsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> clientGeneratedId = const Value.absent(),
            Value<String> schoolId = const Value.absent(),
            Value<String> classId = const Value.absent(),
            Value<String> grNumber = const Value.absent(),
            Value<int?> serialNumber = const Value.absent(),
            Value<String> studentName = const Value.absent(),
            Value<String?> fatherName = const Value.absent(),
            Value<String?> motherName = const Value.absent(),
            Value<DateTime> dateOfBirth = const Value.absent(),
            Value<DateTime> dateOfAdmission = const Value.absent(),
            Value<String?> fatherCnic = const Value.absent(),
            Value<String?> bFormNumber = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> previousSchool = const Value.absent(),
            Value<String?> remarks = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> promotionStatus = const Value.absent(),
            Value<DateTime?> struckOffDate = const Value.absent(),
            Value<String?> struckOffReason = const Value.absent(),
            Value<int?> passOutYear = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String?> updatedBy = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<DateTime?> dirtySince = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudentsTableCompanion(
            id: id,
            clientGeneratedId: clientGeneratedId,
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
            status: status,
            promotionStatus: promotionStatus,
            struckOffDate: struckOffDate,
            struckOffReason: struckOffReason,
            passOutYear: passOutYear,
            version: version,
            updatedAt: updatedAt,
            createdAt: createdAt,
            createdBy: createdBy,
            updatedBy: updatedBy,
            isDeleted: isDeleted,
            syncState: syncState,
            dirtySince: dirtySince,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String clientGeneratedId,
            required String schoolId,
            required String classId,
            required String grNumber,
            Value<int?> serialNumber = const Value.absent(),
            required String studentName,
            Value<String?> fatherName = const Value.absent(),
            Value<String?> motherName = const Value.absent(),
            required DateTime dateOfBirth,
            required DateTime dateOfAdmission,
            Value<String?> fatherCnic = const Value.absent(),
            Value<String?> bFormNumber = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> previousSchool = const Value.absent(),
            Value<String?> remarks = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> promotionStatus = const Value.absent(),
            Value<DateTime?> struckOffDate = const Value.absent(),
            Value<String?> struckOffReason = const Value.absent(),
            Value<int?> passOutYear = const Value.absent(),
            Value<int> version = const Value.absent(),
            required DateTime updatedAt,
            required DateTime createdAt,
            Value<String?> createdBy = const Value.absent(),
            Value<String?> updatedBy = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<DateTime?> dirtySince = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudentsTableCompanion.insert(
            id: id,
            clientGeneratedId: clientGeneratedId,
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
            status: status,
            promotionStatus: promotionStatus,
            struckOffDate: struckOffDate,
            struckOffReason: struckOffReason,
            passOutYear: passOutYear,
            version: version,
            updatedAt: updatedAt,
            createdAt: createdAt,
            createdBy: createdBy,
            updatedBy: updatedBy,
            isDeleted: isDeleted,
            syncState: syncState,
            dirtySince: dirtySince,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$StudentsTableTable, StudentsTableData>(table),
                    BaseReferences<_$AppDatabase, $StudentsTableTable,
                        StudentsTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StudentsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StudentsTableTable,
    StudentsTableData,
    $$StudentsTableTableFilterComposer,
    $$StudentsTableTableOrderingComposer,
    $$StudentsTableTableAnnotationComposer,
    $$StudentsTableTableCreateCompanionBuilder,
    $$StudentsTableTableUpdateCompanionBuilder,
    (
      StudentsTableData,
      BaseReferences<_$AppDatabase, $StudentsTableTable, StudentsTableData>
    ),
    StudentsTableData,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> queueId,
  required String entityType,
  required String entityId,
  required String operation,
  required String payloadJson,
  Value<DateTime> createdAt,
  Value<int> attemptCount,
  Value<String?> lastError,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> queueId,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payloadJson,
  Value<DateTime> createdAt,
  Value<int> attemptCount,
  Value<String?> lastError,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get queueId => $composableBuilder(
      column: $table.queueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get queueId => $composableBuilder(
      column: $table.queueId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get queueId =>
      $composableBuilder(column: $table.queueId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(
      _$AppDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> queueId = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            queueId: queueId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            createdAt: createdAt,
            attemptCount: attemptCount,
            lastError: lastError,
          ),
          createCompanionCallback: ({
            Value<int> queueId = const Value.absent(),
            required String entityType,
            required String entityId,
            required String operation,
            required String payloadJson,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              SyncQueueTableCompanion.insert(
            queueId: queueId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            createdAt: createdAt,
            attemptCount: attemptCount,
            lastError: lastError,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncQueueTableTable, SyncQueueTableData>(
                        table),
                    BaseReferences<_$AppDatabase, $SyncQueueTableTable,
                        SyncQueueTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()>;
typedef $$StudentPhotosTableTableCreateCompanionBuilder
    = StudentPhotosTableCompanion Function({
  required String id,
  required String studentId,
  required String photoType,
  Value<String?> localPath,
  Value<String?> remoteStoragePath,
  Value<int> version,
  Value<String> syncState,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$StudentPhotosTableTableUpdateCompanionBuilder
    = StudentPhotosTableCompanion Function({
  Value<String> id,
  Value<String> studentId,
  Value<String> photoType,
  Value<String?> localPath,
  Value<String?> remoteStoragePath,
  Value<int> version,
  Value<String> syncState,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$StudentPhotosTableTableFilterComposer
    extends Composer<_$AppDatabase, $StudentPhotosTableTable> {
  $$StudentPhotosTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoType => $composableBuilder(
      column: $table.photoType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteStoragePath => $composableBuilder(
      column: $table.remoteStoragePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$StudentPhotosTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentPhotosTableTable> {
  $$StudentPhotosTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoType => $composableBuilder(
      column: $table.photoType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteStoragePath => $composableBuilder(
      column: $table.remoteStoragePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$StudentPhotosTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentPhotosTableTable> {
  $$StudentPhotosTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get photoType =>
      $composableBuilder(column: $table.photoType, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get remoteStoragePath => $composableBuilder(
      column: $table.remoteStoragePath, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StudentPhotosTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudentPhotosTableTable,
    StudentPhotosTableData,
    $$StudentPhotosTableTableFilterComposer,
    $$StudentPhotosTableTableOrderingComposer,
    $$StudentPhotosTableTableAnnotationComposer,
    $$StudentPhotosTableTableCreateCompanionBuilder,
    $$StudentPhotosTableTableUpdateCompanionBuilder,
    (
      StudentPhotosTableData,
      BaseReferences<_$AppDatabase, $StudentPhotosTableTable,
          StudentPhotosTableData>
    ),
    StudentPhotosTableData,
    PrefetchHooks Function()> {
  $$StudentPhotosTableTableTableManager(
      _$AppDatabase db, $StudentPhotosTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentPhotosTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentPhotosTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentPhotosTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String> photoType = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> remoteStoragePath = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudentPhotosTableCompanion(
            id: id,
            studentId: studentId,
            photoType: photoType,
            localPath: localPath,
            remoteStoragePath: remoteStoragePath,
            version: version,
            syncState: syncState,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String studentId,
            required String photoType,
            Value<String?> localPath = const Value.absent(),
            Value<String?> remoteStoragePath = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudentPhotosTableCompanion.insert(
            id: id,
            studentId: studentId,
            photoType: photoType,
            localPath: localPath,
            remoteStoragePath: remoteStoragePath,
            version: version,
            syncState: syncState,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$StudentPhotosTableTable,
                        StudentPhotosTableData>(table),
                    BaseReferences<_$AppDatabase, $StudentPhotosTableTable,
                        StudentPhotosTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StudentPhotosTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StudentPhotosTableTable,
    StudentPhotosTableData,
    $$StudentPhotosTableTableFilterComposer,
    $$StudentPhotosTableTableOrderingComposer,
    $$StudentPhotosTableTableAnnotationComposer,
    $$StudentPhotosTableTableCreateCompanionBuilder,
    $$StudentPhotosTableTableUpdateCompanionBuilder,
    (
      StudentPhotosTableData,
      BaseReferences<_$AppDatabase, $StudentPhotosTableTable,
          StudentPhotosTableData>
    ),
    StudentPhotosTableData,
    PrefetchHooks Function()>;
typedef $$AuditLogsTableTableCreateCompanionBuilder = AuditLogsTableCompanion
    Function({
  required String id,
  required String schoolId,
  Value<String?> userId,
  Value<String?> studentId,
  required String action,
  Value<String?> oldValueJson,
  Value<String?> newValueJson,
  Value<DateTime> createdAt,
  Value<String> syncState,
  Value<int> rowid,
});
typedef $$AuditLogsTableTableUpdateCompanionBuilder = AuditLogsTableCompanion
    Function({
  Value<String> id,
  Value<String> schoolId,
  Value<String?> userId,
  Value<String?> studentId,
  Value<String> action,
  Value<String?> oldValueJson,
  Value<String?> newValueJson,
  Value<DateTime> createdAt,
  Value<String> syncState,
  Value<int> rowid,
});

class $$AuditLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oldValueJson => $composableBuilder(
      column: $table.oldValueJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newValueJson => $composableBuilder(
      column: $table.newValueJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));
}

class $$AuditLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oldValueJson => $composableBuilder(
      column: $table.oldValueJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newValueJson => $composableBuilder(
      column: $table.newValueJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));
}

class $$AuditLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get oldValueJson => $composableBuilder(
      column: $table.oldValueJson, builder: (column) => column);

  GeneratedColumn<String> get newValueJson => $composableBuilder(
      column: $table.newValueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$AuditLogsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogsTableTable,
    AuditLogsTableData,
    $$AuditLogsTableTableFilterComposer,
    $$AuditLogsTableTableOrderingComposer,
    $$AuditLogsTableTableAnnotationComposer,
    $$AuditLogsTableTableCreateCompanionBuilder,
    $$AuditLogsTableTableUpdateCompanionBuilder,
    (
      AuditLogsTableData,
      BaseReferences<_$AppDatabase, $AuditLogsTableTable, AuditLogsTableData>
    ),
    AuditLogsTableData,
    PrefetchHooks Function()> {
  $$AuditLogsTableTableTableManager(
      _$AppDatabase db, $AuditLogsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> schoolId = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> studentId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String?> oldValueJson = const Value.absent(),
            Value<String?> newValueJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogsTableCompanion(
            id: id,
            schoolId: schoolId,
            userId: userId,
            studentId: studentId,
            action: action,
            oldValueJson: oldValueJson,
            newValueJson: newValueJson,
            createdAt: createdAt,
            syncState: syncState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String schoolId,
            Value<String?> userId = const Value.absent(),
            Value<String?> studentId = const Value.absent(),
            required String action,
            Value<String?> oldValueJson = const Value.absent(),
            Value<String?> newValueJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogsTableCompanion.insert(
            id: id,
            schoolId: schoolId,
            userId: userId,
            studentId: studentId,
            action: action,
            oldValueJson: oldValueJson,
            newValueJson: newValueJson,
            createdAt: createdAt,
            syncState: syncState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AuditLogsTableTable, AuditLogsTableData>(
                        table),
                    BaseReferences<_$AppDatabase, $AuditLogsTableTable,
                        AuditLogsTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AuditLogsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuditLogsTableTable,
    AuditLogsTableData,
    $$AuditLogsTableTableFilterComposer,
    $$AuditLogsTableTableOrderingComposer,
    $$AuditLogsTableTableAnnotationComposer,
    $$AuditLogsTableTableCreateCompanionBuilder,
    $$AuditLogsTableTableUpdateCompanionBuilder,
    (
      AuditLogsTableData,
      BaseReferences<_$AppDatabase, $AuditLogsTableTable, AuditLogsTableData>
    ),
    AuditLogsTableData,
    PrefetchHooks Function()>;
typedef $$PromotionBatchesTableTableCreateCompanionBuilder
    = PromotionBatchesTableCompanion Function({
  required String id,
  required String schoolId,
  required String fromClassId,
  Value<String?> toClassId,
  required DateTime promotionDate,
  required int academicYear,
  Value<String?> performedBy,
  Value<bool> isUndone,
  Value<DateTime?> undoneAt,
  Value<String?> undoneBy,
  Value<DateTime> createdAt,
  Value<String> syncState,
  Value<int> rowid,
});
typedef $$PromotionBatchesTableTableUpdateCompanionBuilder
    = PromotionBatchesTableCompanion Function({
  Value<String> id,
  Value<String> schoolId,
  Value<String> fromClassId,
  Value<String?> toClassId,
  Value<DateTime> promotionDate,
  Value<int> academicYear,
  Value<String?> performedBy,
  Value<bool> isUndone,
  Value<DateTime?> undoneAt,
  Value<String?> undoneBy,
  Value<DateTime> createdAt,
  Value<String> syncState,
  Value<int> rowid,
});

class $$PromotionBatchesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PromotionBatchesTableTable> {
  $$PromotionBatchesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromClassId => $composableBuilder(
      column: $table.fromClassId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toClassId => $composableBuilder(
      column: $table.toClassId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get promotionDate => $composableBuilder(
      column: $table.promotionDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get academicYear => $composableBuilder(
      column: $table.academicYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get performedBy => $composableBuilder(
      column: $table.performedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUndone => $composableBuilder(
      column: $table.isUndone, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get undoneAt => $composableBuilder(
      column: $table.undoneAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get undoneBy => $composableBuilder(
      column: $table.undoneBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));
}

class $$PromotionBatchesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PromotionBatchesTableTable> {
  $$PromotionBatchesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromClassId => $composableBuilder(
      column: $table.fromClassId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toClassId => $composableBuilder(
      column: $table.toClassId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get promotionDate => $composableBuilder(
      column: $table.promotionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get academicYear => $composableBuilder(
      column: $table.academicYear,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get performedBy => $composableBuilder(
      column: $table.performedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUndone => $composableBuilder(
      column: $table.isUndone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get undoneAt => $composableBuilder(
      column: $table.undoneAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get undoneBy => $composableBuilder(
      column: $table.undoneBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));
}

class $$PromotionBatchesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromotionBatchesTableTable> {
  $$PromotionBatchesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<String> get fromClassId => $composableBuilder(
      column: $table.fromClassId, builder: (column) => column);

  GeneratedColumn<String> get toClassId =>
      $composableBuilder(column: $table.toClassId, builder: (column) => column);

  GeneratedColumn<DateTime> get promotionDate => $composableBuilder(
      column: $table.promotionDate, builder: (column) => column);

  GeneratedColumn<int> get academicYear => $composableBuilder(
      column: $table.academicYear, builder: (column) => column);

  GeneratedColumn<String> get performedBy => $composableBuilder(
      column: $table.performedBy, builder: (column) => column);

  GeneratedColumn<bool> get isUndone =>
      $composableBuilder(column: $table.isUndone, builder: (column) => column);

  GeneratedColumn<DateTime> get undoneAt =>
      $composableBuilder(column: $table.undoneAt, builder: (column) => column);

  GeneratedColumn<String> get undoneBy =>
      $composableBuilder(column: $table.undoneBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$PromotionBatchesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PromotionBatchesTableTable,
    PromotionBatchesTableData,
    $$PromotionBatchesTableTableFilterComposer,
    $$PromotionBatchesTableTableOrderingComposer,
    $$PromotionBatchesTableTableAnnotationComposer,
    $$PromotionBatchesTableTableCreateCompanionBuilder,
    $$PromotionBatchesTableTableUpdateCompanionBuilder,
    (
      PromotionBatchesTableData,
      BaseReferences<_$AppDatabase, $PromotionBatchesTableTable,
          PromotionBatchesTableData>
    ),
    PromotionBatchesTableData,
    PrefetchHooks Function()> {
  $$PromotionBatchesTableTableTableManager(
      _$AppDatabase db, $PromotionBatchesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromotionBatchesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PromotionBatchesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromotionBatchesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> schoolId = const Value.absent(),
            Value<String> fromClassId = const Value.absent(),
            Value<String?> toClassId = const Value.absent(),
            Value<DateTime> promotionDate = const Value.absent(),
            Value<int> academicYear = const Value.absent(),
            Value<String?> performedBy = const Value.absent(),
            Value<bool> isUndone = const Value.absent(),
            Value<DateTime?> undoneAt = const Value.absent(),
            Value<String?> undoneBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PromotionBatchesTableCompanion(
            id: id,
            schoolId: schoolId,
            fromClassId: fromClassId,
            toClassId: toClassId,
            promotionDate: promotionDate,
            academicYear: academicYear,
            performedBy: performedBy,
            isUndone: isUndone,
            undoneAt: undoneAt,
            undoneBy: undoneBy,
            createdAt: createdAt,
            syncState: syncState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String schoolId,
            required String fromClassId,
            Value<String?> toClassId = const Value.absent(),
            required DateTime promotionDate,
            required int academicYear,
            Value<String?> performedBy = const Value.absent(),
            Value<bool> isUndone = const Value.absent(),
            Value<DateTime?> undoneAt = const Value.absent(),
            Value<String?> undoneBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PromotionBatchesTableCompanion.insert(
            id: id,
            schoolId: schoolId,
            fromClassId: fromClassId,
            toClassId: toClassId,
            promotionDate: promotionDate,
            academicYear: academicYear,
            performedBy: performedBy,
            isUndone: isUndone,
            undoneAt: undoneAt,
            undoneBy: undoneBy,
            createdAt: createdAt,
            syncState: syncState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PromotionBatchesTableTable,
                        PromotionBatchesTableData>(table),
                    BaseReferences<_$AppDatabase, $PromotionBatchesTableTable,
                        PromotionBatchesTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PromotionBatchesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PromotionBatchesTableTable,
        PromotionBatchesTableData,
        $$PromotionBatchesTableTableFilterComposer,
        $$PromotionBatchesTableTableOrderingComposer,
        $$PromotionBatchesTableTableAnnotationComposer,
        $$PromotionBatchesTableTableCreateCompanionBuilder,
        $$PromotionBatchesTableTableUpdateCompanionBuilder,
        (
          PromotionBatchesTableData,
          BaseReferences<_$AppDatabase, $PromotionBatchesTableTable,
              PromotionBatchesTableData>
        ),
        PromotionBatchesTableData,
        PrefetchHooks Function()>;
typedef $$PromotionRecordsTableTableCreateCompanionBuilder
    = PromotionRecordsTableCompanion Function({
  required String id,
  required String batchId,
  required String studentId,
  required String previousClassId,
  Value<String?> newClassId,
  required String previousStatus,
  required String newStatus,
  required String result,
  required int academicYear,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$PromotionRecordsTableTableUpdateCompanionBuilder
    = PromotionRecordsTableCompanion Function({
  Value<String> id,
  Value<String> batchId,
  Value<String> studentId,
  Value<String> previousClassId,
  Value<String?> newClassId,
  Value<String> previousStatus,
  Value<String> newStatus,
  Value<String> result,
  Value<int> academicYear,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PromotionRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PromotionRecordsTableTable> {
  $$PromotionRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get batchId => $composableBuilder(
      column: $table.batchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get previousClassId => $composableBuilder(
      column: $table.previousClassId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newClassId => $composableBuilder(
      column: $table.newClassId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get previousStatus => $composableBuilder(
      column: $table.previousStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newStatus => $composableBuilder(
      column: $table.newStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get academicYear => $composableBuilder(
      column: $table.academicYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PromotionRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PromotionRecordsTableTable> {
  $$PromotionRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get batchId => $composableBuilder(
      column: $table.batchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get previousClassId => $composableBuilder(
      column: $table.previousClassId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newClassId => $composableBuilder(
      column: $table.newClassId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get previousStatus => $composableBuilder(
      column: $table.previousStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newStatus => $composableBuilder(
      column: $table.newStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get academicYear => $composableBuilder(
      column: $table.academicYear,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PromotionRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromotionRecordsTableTable> {
  $$PromotionRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get previousClassId => $composableBuilder(
      column: $table.previousClassId, builder: (column) => column);

  GeneratedColumn<String> get newClassId => $composableBuilder(
      column: $table.newClassId, builder: (column) => column);

  GeneratedColumn<String> get previousStatus => $composableBuilder(
      column: $table.previousStatus, builder: (column) => column);

  GeneratedColumn<String> get newStatus =>
      $composableBuilder(column: $table.newStatus, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<int> get academicYear => $composableBuilder(
      column: $table.academicYear, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PromotionRecordsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PromotionRecordsTableTable,
    PromotionRecordsTableData,
    $$PromotionRecordsTableTableFilterComposer,
    $$PromotionRecordsTableTableOrderingComposer,
    $$PromotionRecordsTableTableAnnotationComposer,
    $$PromotionRecordsTableTableCreateCompanionBuilder,
    $$PromotionRecordsTableTableUpdateCompanionBuilder,
    (
      PromotionRecordsTableData,
      BaseReferences<_$AppDatabase, $PromotionRecordsTableTable,
          PromotionRecordsTableData>
    ),
    PromotionRecordsTableData,
    PrefetchHooks Function()> {
  $$PromotionRecordsTableTableTableManager(
      _$AppDatabase db, $PromotionRecordsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromotionRecordsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PromotionRecordsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromotionRecordsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> batchId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String> previousClassId = const Value.absent(),
            Value<String?> newClassId = const Value.absent(),
            Value<String> previousStatus = const Value.absent(),
            Value<String> newStatus = const Value.absent(),
            Value<String> result = const Value.absent(),
            Value<int> academicYear = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PromotionRecordsTableCompanion(
            id: id,
            batchId: batchId,
            studentId: studentId,
            previousClassId: previousClassId,
            newClassId: newClassId,
            previousStatus: previousStatus,
            newStatus: newStatus,
            result: result,
            academicYear: academicYear,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String batchId,
            required String studentId,
            required String previousClassId,
            Value<String?> newClassId = const Value.absent(),
            required String previousStatus,
            required String newStatus,
            required String result,
            required int academicYear,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PromotionRecordsTableCompanion.insert(
            id: id,
            batchId: batchId,
            studentId: studentId,
            previousClassId: previousClassId,
            newClassId: newClassId,
            previousStatus: previousStatus,
            newStatus: newStatus,
            result: result,
            academicYear: academicYear,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PromotionRecordsTableTable,
                        PromotionRecordsTableData>(table),
                    BaseReferences<_$AppDatabase, $PromotionRecordsTableTable,
                        PromotionRecordsTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PromotionRecordsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PromotionRecordsTableTable,
        PromotionRecordsTableData,
        $$PromotionRecordsTableTableFilterComposer,
        $$PromotionRecordsTableTableOrderingComposer,
        $$PromotionRecordsTableTableAnnotationComposer,
        $$PromotionRecordsTableTableCreateCompanionBuilder,
        $$PromotionRecordsTableTableUpdateCompanionBuilder,
        (
          PromotionRecordsTableData,
          BaseReferences<_$AppDatabase, $PromotionRecordsTableTable,
              PromotionRecordsTableData>
        ),
        PromotionRecordsTableData,
        PrefetchHooks Function()>;
typedef $$StruckOffRecordsTableTableCreateCompanionBuilder
    = StruckOffRecordsTableCompanion Function({
  required String id,
  required String schoolId,
  required String studentId,
  required DateTime struckOffDate,
  required String reason,
  Value<bool> reAdmitted,
  Value<DateTime?> reAdmittedDate,
  Value<String?> reAdmittedBy,
  Value<String?> createdBy,
  Value<DateTime> createdAt,
  Value<String> syncState,
  Value<int> rowid,
});
typedef $$StruckOffRecordsTableTableUpdateCompanionBuilder
    = StruckOffRecordsTableCompanion Function({
  Value<String> id,
  Value<String> schoolId,
  Value<String> studentId,
  Value<DateTime> struckOffDate,
  Value<String> reason,
  Value<bool> reAdmitted,
  Value<DateTime?> reAdmittedDate,
  Value<String?> reAdmittedBy,
  Value<String?> createdBy,
  Value<DateTime> createdAt,
  Value<String> syncState,
  Value<int> rowid,
});

class $$StruckOffRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StruckOffRecordsTableTable> {
  $$StruckOffRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get struckOffDate => $composableBuilder(
      column: $table.struckOffDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get reAdmitted => $composableBuilder(
      column: $table.reAdmitted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reAdmittedDate => $composableBuilder(
      column: $table.reAdmittedDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reAdmittedBy => $composableBuilder(
      column: $table.reAdmittedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));
}

class $$StruckOffRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StruckOffRecordsTableTable> {
  $$StruckOffRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get struckOffDate => $composableBuilder(
      column: $table.struckOffDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get reAdmitted => $composableBuilder(
      column: $table.reAdmitted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reAdmittedDate => $composableBuilder(
      column: $table.reAdmittedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reAdmittedBy => $composableBuilder(
      column: $table.reAdmittedBy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));
}

class $$StruckOffRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StruckOffRecordsTableTable> {
  $$StruckOffRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<DateTime> get struckOffDate => $composableBuilder(
      column: $table.struckOffDate, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get reAdmitted => $composableBuilder(
      column: $table.reAdmitted, builder: (column) => column);

  GeneratedColumn<DateTime> get reAdmittedDate => $composableBuilder(
      column: $table.reAdmittedDate, builder: (column) => column);

  GeneratedColumn<String> get reAdmittedBy => $composableBuilder(
      column: $table.reAdmittedBy, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$StruckOffRecordsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StruckOffRecordsTableTable,
    StruckOffRecordsTableData,
    $$StruckOffRecordsTableTableFilterComposer,
    $$StruckOffRecordsTableTableOrderingComposer,
    $$StruckOffRecordsTableTableAnnotationComposer,
    $$StruckOffRecordsTableTableCreateCompanionBuilder,
    $$StruckOffRecordsTableTableUpdateCompanionBuilder,
    (
      StruckOffRecordsTableData,
      BaseReferences<_$AppDatabase, $StruckOffRecordsTableTable,
          StruckOffRecordsTableData>
    ),
    StruckOffRecordsTableData,
    PrefetchHooks Function()> {
  $$StruckOffRecordsTableTableTableManager(
      _$AppDatabase db, $StruckOffRecordsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StruckOffRecordsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$StruckOffRecordsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StruckOffRecordsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> schoolId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<DateTime> struckOffDate = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<bool> reAdmitted = const Value.absent(),
            Value<DateTime?> reAdmittedDate = const Value.absent(),
            Value<String?> reAdmittedBy = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StruckOffRecordsTableCompanion(
            id: id,
            schoolId: schoolId,
            studentId: studentId,
            struckOffDate: struckOffDate,
            reason: reason,
            reAdmitted: reAdmitted,
            reAdmittedDate: reAdmittedDate,
            reAdmittedBy: reAdmittedBy,
            createdBy: createdBy,
            createdAt: createdAt,
            syncState: syncState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String schoolId,
            required String studentId,
            required DateTime struckOffDate,
            required String reason,
            Value<bool> reAdmitted = const Value.absent(),
            Value<DateTime?> reAdmittedDate = const Value.absent(),
            Value<String?> reAdmittedBy = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StruckOffRecordsTableCompanion.insert(
            id: id,
            schoolId: schoolId,
            studentId: studentId,
            struckOffDate: struckOffDate,
            reason: reason,
            reAdmitted: reAdmitted,
            reAdmittedDate: reAdmittedDate,
            reAdmittedBy: reAdmittedBy,
            createdBy: createdBy,
            createdAt: createdAt,
            syncState: syncState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$StruckOffRecordsTableTable,
                        StruckOffRecordsTableData>(table),
                    BaseReferences<_$AppDatabase, $StruckOffRecordsTableTable,
                        StruckOffRecordsTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StruckOffRecordsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $StruckOffRecordsTableTable,
        StruckOffRecordsTableData,
        $$StruckOffRecordsTableTableFilterComposer,
        $$StruckOffRecordsTableTableOrderingComposer,
        $$StruckOffRecordsTableTableAnnotationComposer,
        $$StruckOffRecordsTableTableCreateCompanionBuilder,
        $$StruckOffRecordsTableTableUpdateCompanionBuilder,
        (
          StruckOffRecordsTableData,
          BaseReferences<_$AppDatabase, $StruckOffRecordsTableTable,
              StruckOffRecordsTableData>
        ),
        StruckOffRecordsTableData,
        PrefetchHooks Function()>;
typedef $$PassOutYearsTableTableCreateCompanionBuilder
    = PassOutYearsTableCompanion Function({
  required String id,
  required String schoolId,
  required int year,
  Value<DateTime> createdAt,
  Value<String> syncState,
  Value<int> rowid,
});
typedef $$PassOutYearsTableTableUpdateCompanionBuilder
    = PassOutYearsTableCompanion Function({
  Value<String> id,
  Value<String> schoolId,
  Value<int> year,
  Value<DateTime> createdAt,
  Value<String> syncState,
  Value<int> rowid,
});

class $$PassOutYearsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PassOutYearsTableTable> {
  $$PassOutYearsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));
}

class $$PassOutYearsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PassOutYearsTableTable> {
  $$PassOutYearsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schoolId => $composableBuilder(
      column: $table.schoolId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));
}

class $$PassOutYearsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PassOutYearsTableTable> {
  $$PassOutYearsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get schoolId =>
      $composableBuilder(column: $table.schoolId, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$PassOutYearsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PassOutYearsTableTable,
    PassOutYearsTableData,
    $$PassOutYearsTableTableFilterComposer,
    $$PassOutYearsTableTableOrderingComposer,
    $$PassOutYearsTableTableAnnotationComposer,
    $$PassOutYearsTableTableCreateCompanionBuilder,
    $$PassOutYearsTableTableUpdateCompanionBuilder,
    (
      PassOutYearsTableData,
      BaseReferences<_$AppDatabase, $PassOutYearsTableTable,
          PassOutYearsTableData>
    ),
    PassOutYearsTableData,
    PrefetchHooks Function()> {
  $$PassOutYearsTableTableTableManager(
      _$AppDatabase db, $PassOutYearsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PassOutYearsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PassOutYearsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PassOutYearsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> schoolId = const Value.absent(),
            Value<int> year = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PassOutYearsTableCompanion(
            id: id,
            schoolId: schoolId,
            year: year,
            createdAt: createdAt,
            syncState: syncState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String schoolId,
            required int year,
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PassOutYearsTableCompanion.insert(
            id: id,
            schoolId: schoolId,
            year: year,
            createdAt: createdAt,
            syncState: syncState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PassOutYearsTableTable, PassOutYearsTableData>(
                        table),
                    BaseReferences<_$AppDatabase, $PassOutYearsTableTable,
                        PassOutYearsTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PassOutYearsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PassOutYearsTableTable,
    PassOutYearsTableData,
    $$PassOutYearsTableTableFilterComposer,
    $$PassOutYearsTableTableOrderingComposer,
    $$PassOutYearsTableTableAnnotationComposer,
    $$PassOutYearsTableTableCreateCompanionBuilder,
    $$PassOutYearsTableTableUpdateCompanionBuilder,
    (
      PassOutYearsTableData,
      BaseReferences<_$AppDatabase, $PassOutYearsTableTable,
          PassOutYearsTableData>
    ),
    PassOutYearsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SchoolsTableTableTableManager get schoolsTable =>
      $$SchoolsTableTableTableManager(_db, _db.schoolsTable);
  $$ClassesTableTableTableManager get classesTable =>
      $$ClassesTableTableTableManager(_db, _db.classesTable);
  $$StudentsTableTableTableManager get studentsTable =>
      $$StudentsTableTableTableManager(_db, _db.studentsTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$StudentPhotosTableTableTableManager get studentPhotosTable =>
      $$StudentPhotosTableTableTableManager(_db, _db.studentPhotosTable);
  $$AuditLogsTableTableTableManager get auditLogsTable =>
      $$AuditLogsTableTableTableManager(_db, _db.auditLogsTable);
  $$PromotionBatchesTableTableTableManager get promotionBatchesTable =>
      $$PromotionBatchesTableTableTableManager(_db, _db.promotionBatchesTable);
  $$PromotionRecordsTableTableTableManager get promotionRecordsTable =>
      $$PromotionRecordsTableTableTableManager(_db, _db.promotionRecordsTable);
  $$StruckOffRecordsTableTableTableManager get struckOffRecordsTable =>
      $$StruckOffRecordsTableTableTableManager(_db, _db.struckOffRecordsTable);
  $$PassOutYearsTableTableTableManager get passOutYearsTable =>
      $$PassOutYearsTableTableTableManager(_db, _db.passOutYearsTable);
}
