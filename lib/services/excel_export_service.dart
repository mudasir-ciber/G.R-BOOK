import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/enums.dart';
import '../models/student.dart';

/// Requirement #33: Excel export for the complete register, class-wise
/// lists, pass-out students, and struck-off students.
class ExcelExportService {
  final _dateFormat = DateFormat('dd-MM-yyyy');

  static const _headers = [
    'Serial No', 'GR Number', 'Student Name', 'Father Name', 'Class',
    'Date of Birth', 'Date of Admission', 'Father CNIC', 'B-Form Number',
    'Phone Number', 'Address', 'Previous School', 'Previous GR', 'Status', 'Remarks',
  ];

  /// [students] paired with each one's class display name (already
  /// resolved by the caller, since the repository layer doesn't know
  /// about class names).
  Future<File> exportStudents({
    required String sheetTitle,
    required List<(Student, String className)> students,
  }) async {
    final workbook = xl.Excel.createExcel();
    final sheet = workbook[sheetTitle.length > 31 ? sheetTitle.substring(0, 31) : sheetTitle];
    workbook.setDefaultSheet(sheet.sheetName);
    // Remove the default "Sheet1" if we created a differently-named one.
    if (workbook.sheets.containsKey('Sheet1') && sheet.sheetName != 'Sheet1') {
      workbook.delete('Sheet1');
    }

    sheet.appendRow(_headers.map((h) => xl.TextCellValue(h)).toList());

    for (final (student, className) in students) {
      sheet.appendRow([
        xl.IntCellValue(student.serialNumber ?? 0),
        xl.TextCellValue(student.grNumber),
        xl.TextCellValue(student.studentName),
        xl.TextCellValue(student.fatherName ?? ''),
        xl.TextCellValue(className),
        xl.TextCellValue(_dateFormat.format(student.dateOfBirth)),
        xl.TextCellValue(_dateFormat.format(student.dateOfAdmission)),
        xl.TextCellValue(student.fatherCnic ?? ''),
        xl.TextCellValue(student.bFormNumber ?? ''),
        xl.TextCellValue(student.phoneNumber ?? ''),
        xl.TextCellValue(student.address ?? ''),
        xl.TextCellValue(student.previousSchool ?? ''),
        xl.TextCellValue(student.previousGrNumber ?? ''),
        xl.TextCellValue(student.status.dbValue),
        xl.TextCellValue(student.remarks ?? ''),
      ]);
    }

    final bytes = workbook.encode();
    if (bytes == null) {
      throw StateError('Could not generate the Excel file.');
    }
    return _saveBytes(bytes, sheetTitle);
  }

  Future<File> _saveBytes(List<int> bytes, String baseName) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
    final safeName = baseName.replaceAll(RegExp(r'[^A-Za-z0-9_\- ]'), '_');
    final file = File(p.join(exportsDir.path, '${safeName}_${DateTime.now().millisecondsSinceEpoch}.xlsx'));
    await file.writeAsBytes(Uint8List.fromList(bytes));
    return file;
  }
}
