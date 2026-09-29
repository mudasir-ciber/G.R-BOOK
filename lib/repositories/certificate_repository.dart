import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

class CertificateTypeItem {
  const CertificateTypeItem({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.description,
    this.isDefault = false,
  });

  final String id;
  final String schoolId;
  final String title;
  final String description;
  final bool isDefault;

  Map<String, dynamic> toMap() => {
        'id': id,
        'school_id': schoolId,
        'title': title,
        'description': description,
        'is_default': isDefault ? 1 : 0,
      };

  factory CertificateTypeItem.fromMap(Map<String, dynamic> map) => CertificateTypeItem(
        id: map['id'] as String,
        schoolId: map['school_id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        isDefault: (map['is_default'] as int? ?? 0) == 1,
      );
}

class CertificateRepository {
  CertificateRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();
  bool _tableInitialized = false;

  Future<void> _ensureTable() async {
    if (_tableInitialized) return;
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS certificate_types (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      );
    ''');
    _tableInitialized = true;
  }

  static const List<(String title, String desc)> defaultTemplates = [
    ('School Leaving Certificate', 'Formal certificate issued when a student leaves the school'),
    ('Character Certificate', 'Certifies the student\'s moral character and conduct'),
    ('Birth Certificate', 'Extract of student birth record from school register'),
  ];

  Future<List<CertificateTypeItem>> getCertificateTypes(String schoolId) async {
    await _ensureTable();

    // Query custom types from local DB
    final rows = await _db.customSelect(
      'SELECT * FROM certificate_types WHERE school_id = ? ORDER BY created_at ASC',
      variables: [Variable.withString(schoolId)],
    ).get();

    final customTypes = rows.map((r) => CertificateTypeItem.fromMap(r.data)).toList();

    // Build complete list: defaults first, then custom
    final results = <CertificateTypeItem>[
      ...defaultTemplates.map((d) => CertificateTypeItem(
            id: 'default_${d.$1.toLowerCase().replaceAll(' ', '_')}',
            schoolId: schoolId,
            title: d.$1,
            description: d.$2,
            isDefault: true,
          )),
      ...customTypes,
    ];

    return results;
  }

  Stream<List<CertificateTypeItem>> watchCertificateTypes(String schoolId) async* {
    await _ensureTable();
    yield* _db
        .customSelect(
          'SELECT * FROM certificate_types WHERE school_id = ? ORDER BY created_at ASC',
          variables: [Variable.withString(schoolId)],
        )
        .watch()
        .map((rows) {
      final customTypes = rows.map((r) => CertificateTypeItem.fromMap(r.data)).toList();
      return <CertificateTypeItem>[
        ...defaultTemplates.map((d) => CertificateTypeItem(
              id: 'default_${d.$1.toLowerCase().replaceAll(' ', '_')}',
              schoolId: schoolId,
              title: d.$1,
              description: d.$2,
              isDefault: true,
            )),
        ...customTypes,
      ];
    });
  }

  Future<CertificateTypeItem> addCertificateType({
    required String schoolId,
    required String title,
    required String description,
  }) async {
    await _ensureTable();
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.customInsert(
      '''
      INSERT INTO certificate_types (id, school_id, title, description, is_default, created_at)
      VALUES (?, ?, ?, ?, 0, ?)
      ''',
      variables: [
        Variable.withString(id),
        Variable.withString(schoolId),
        Variable.withString(title),
        Variable.withString(description),
        Variable.withString(now),
      ],
    );

    return CertificateTypeItem(
      id: id,
      schoolId: schoolId,
      title: title,
      description: description,
      isDefault: false,
    );
  }
}

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepository(ref.watch(appDatabaseProvider));
});

final certificateTypesStreamProvider =
    StreamProvider.family<List<CertificateTypeItem>, String>((ref, schoolId) {
  return ref.watch(certificateRepositoryProvider).watchCertificateTypes(schoolId);
});
