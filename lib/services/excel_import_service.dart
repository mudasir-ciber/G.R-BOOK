import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';

import '../models/school.dart';

enum ImportRowStatus { valid, duplicateGr, error }

class ImportRow {
  final int rowNumber; // 1-based spreadsheet row (header is row 1)
  final String grNumber;
  final String studentName;
  final String? fatherName;
  final SchoolClass? schoolClass;
  final DateTime? dateOfBirth;
  final DateTime? dateOfAdmission;
  final String? fatherCnic;
  final String? bFormNumber;
  final String? phoneNumber;
  final String? address;
  final String? previousSchool;
  final String? remarks;
  final ImportRowStatus status;
  final List<String> problems;

  const ImportRow({
    required this.rowNumber,
    required this.grNumber,
    required this.studentName,
    this.fatherName,
    this.schoolClass,
    this.dateOfBirth,
    this.dateOfAdmission,
    this.fatherCnic,
    this.bFormNumber,
    this.phoneNumber,
    this.address,
    this.previousSchool,
    this.remarks,
    required this.status,
    required this.problems,
  });

  /// Rows that can actually be imported: clean rows, and rows whose
  /// only issue is a duplicate GR number (a warning, not a blocker —
  /// matches the app-wide rule that duplicate GR warns but never blocks).
  bool get isImportable => status != ImportRowStatus.error;
}

class ImportPreview {
  final List<ImportRow> rows;
  final List<String> missingRequiredColumns;
  const ImportPreview({required this.rows, required this.missingRequiredColumns});

  int get validCount => rows.where((r) => r.status == ImportRowStatus.valid).length;
  int get duplicateCount => rows.where((r) => r.status == ImportRowStatus.duplicateGr).length;
  int get errorCount => rows.where((r) => r.status == ImportRowStatus.error).length;
  List<ImportRow> get importable => rows.where((r) => r.isImportable).toList();
}

/// Requirement #32. Columns are matched by header name (case- and
/// spacing-insensitive, with a few common aliases), so a register laid
/// out in any column order imports correctly. Nothing is saved here —
/// this only produces a preview; the UI commits it after confirmation,
/// so an import is never partial-and-silent.
class ExcelImportService {
  static const _aliases = <String, List<String>>{
    'grNumber': ['grnumber', 'grno', 'gr', 'g.r.no', 'grnum', 'registerno'],
    'serialNumber': ['serialnumber', 'serialno', 'srno', 'sno', 'serial'],
    'studentName': ['studentname', 'name', 'nameofstudent'],
    'fatherName': ['fathername', 'father', 'fathersname'],
    'className': ['class', 'classname'],
    'dob': ['dob', 'dateofbirth', 'birthdate'],
    'admission': ['dateofadmission', 'admissiondate', 'doa', 'admission'],
    'cnic': ['cnic', 'fathercnic', 'fathercnicnumber'],
    'bform': ['bform', 'bformnumber', 'bformno'],
    'phone': ['phone', 'phonenumber', 'mobile', 'mobileno', 'contact'],
    'address': ['address'],
    'previousSchool': ['previousschool', 'lastschool'],
    'remarks': ['remarks', 'remark', 'notes'],
  };

  static const _required = ['grNumber', 'studentName', 'className', 'dob', 'admission'];

  static const _requiredLabels = {
    'grNumber': 'GR Number',
    'studentName': 'Student Name',
    'className': 'Class',
    'dob': 'Date of Birth',
    'admission': 'Date of Admission',
  };

  String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<ImportPreview> buildPreview({
    required File file,
    required List<SchoolClass> classes,
    required Set<String> existingGrNumbers,
  }) async {
    final bytes = await file.readAsBytes();
    final workbook = xl.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw const FormatException('The Excel file has no sheets.');
    }
    final sheet = workbook.tables.values.first;
    if (sheet.rows.isEmpty) {
      throw const FormatException('The first sheet is empty.');
    }

    // Map header text -> column index.
    final headerRow = sheet.rows.first;
    final columnIndex = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final raw = headerRow[i]?.value?.toString() ?? '';
      final normalized = _normalize(raw);
      if (normalized.isEmpty) continue;
      for (final entry in _aliases.entries) {
        if (entry.value.contains(normalized) && !columnIndex.containsKey(entry.key)) {
          columnIndex[entry.key] = i;
        }
      }
    }

    final missing = _required.where((k) => !columnIndex.containsKey(k)).map((k) => _requiredLabels[k]!).toList();
    if (missing.isNotEmpty) {
      return ImportPreview(rows: const [], missingRequiredColumns: missing);
    }

    String? cell(List<xl.Data?> row, String key) {
      final idx = columnIndex[key];
      if (idx == null || idx >= row.length) return null;
      final v = row[idx]?.value;
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    final classLookup = <String, SchoolClass>{};
    for (final c in classes) {
      classLookup[_normalize(c.displayName)] = c;
      classLookup[_normalize(c.classCode)] = c;
    }
    // Friendly aliases used in real registers ("One Class", "Two Class"...).
    const wordToDigit = {'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5'};
    for (final entry in wordToDigit.entries) {
      final target = classes.where((c) => c.classCode == entry.value).firstOrNull;
      if (target != null) {
        classLookup[_normalize('${entry.key}class')] = target;
        classLookup[_normalize('class${entry.key}')] = target;
      }
    }

    final seenGrInFile = <String>{};
    final rows = <ImportRow>[];

    for (var r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      if (row.every((c) => c?.value == null || c!.value.toString().trim().isEmpty)) continue; // blank line

      final problems = <String>[];
      final gr = cell(row, 'grNumber');
      final name = cell(row, 'studentName');
      final classText = cell(row, 'className');
      final dobText = cell(row, 'dob');
      final admissionText = cell(row, 'admission');

      if (gr == null) problems.add('Missing GR Number');
      if (name == null) problems.add('Missing Student Name');

      SchoolClass? schoolClass;
      if (classText == null) {
        problems.add('Missing Class');
      } else {
        schoolClass = classLookup[_normalize(classText)];
        if (schoolClass == null) problems.add('Unknown class "$classText"');
      }

      final dob = _parseDate(dobText);
      if (dobText == null) {
        problems.add('Missing Date of Birth');
      } else if (dob == null) {
        problems.add('Invalid Date of Birth "$dobText"');
      }

      final admission = _parseDate(admissionText);
      if (admissionText == null) {
        problems.add('Missing Date of Admission');
      } else if (admission == null) {
        problems.add('Invalid Date of Admission "$admissionText"');
      }

      if (dob != null && admission != null && admission.isBefore(dob)) {
        problems.add('Admission date is before date of birth');
      }

      var status = problems.isEmpty ? ImportRowStatus.valid : ImportRowStatus.error;
      if (status == ImportRowStatus.valid && gr != null) {
        if (existingGrNumbers.contains(gr) || !seenGrInFile.add(gr)) {
          status = ImportRowStatus.duplicateGr;
          problems.add('Duplicate GR number "$gr" (can still be imported)');
        }
      }

      rows.add(ImportRow(
        rowNumber: r + 1,
        grNumber: gr ?? '',
        studentName: name ?? '',
        fatherName: cell(row, 'fatherName'),
        schoolClass: schoolClass,
        dateOfBirth: dob,
        dateOfAdmission: admission,
        fatherCnic: cell(row, 'cnic'),
        bFormNumber: cell(row, 'bform'),
        phoneNumber: cell(row, 'phone'),
        address: cell(row, 'address'),
        previousSchool: cell(row, 'previousSchool'),
        remarks: cell(row, 'remarks'),
        status: status,
        problems: problems,
      ));
    }

    return ImportPreview(rows: rows, missingRequiredColumns: const []);
  }

  DateTime? _parseDate(String? text) {
    if (text == null) return null;
    final cleaned = text.trim();

    // Excel may hand back an ISO-like datetime string for real date cells.
    final iso = DateTime.tryParse(cleaned);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    for (final pattern in const ['dd-MM-yyyy', 'dd/MM/yyyy', 'd-M-yyyy', 'd/M/yyyy', 'dd.MM.yyyy', 'yyyy-MM-dd']) {
      try {
        final parsed = DateFormat(pattern).parseStrict(cleaned);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {}
    }
    return null;
  }
}
