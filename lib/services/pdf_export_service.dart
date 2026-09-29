import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/age_calculator.dart';
import '../models/enums.dart';
import '../models/school.dart';
import '../models/student.dart';

enum CertificateType { schoolLeaving, character, birth }

extension CertificateTypeX on CertificateType {
  String get title => switch (this) {
        CertificateType.schoolLeaving => 'School Leaving Certificate',
        CertificateType.character => 'Character Certificate',
        CertificateType.birth => 'Birth Certificate',
      };
}

/// Requirement #33-34: PDF register/exports and printable certificate
/// templates. Every document is generated on-device from local data —
/// no network required.
class PdfExportService {
  final _dateFormat = DateFormat('dd-MM-yyyy');

  Future<File> exportRegisterPdf({
    required School school,
    required String title,
    required List<(Student, String className)> students,
  }) async {
    final doc = pw.Document();
    const headers = ['S.No', 'GR No', 'Name', 'Father Name', 'Class', 'DOB', 'Status'];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => _header(school, title),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: students
                .map((e) => [
                      '${e.$1.serialNumber ?? '-'}',
                      e.$1.grNumber,
                      e.$1.studentName,
                      e.$1.fatherName ?? '-',
                      e.$2,
                      _dateFormat.format(e.$1.dateOfBirth),
                      e.$1.status.dbValue,
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
        ],
      ),
    );

    return _save(await doc.save(), title);
  }

  Future<File> exportAgeReportPdf({
    required School school,
    required String className,
    required List<MapEntry<int, int>> ageBuckets, // years -> count
    required Student? youngest,
    required Student? oldest,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(school, 'Age Report — $className'),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: const ['Age (years)', 'Students'],
              data: ageBuckets.map((e) => ['${e.key}', '${e.value}']).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            ),
            pw.SizedBox(height: 16),
            if (youngest != null) pw.Text('Youngest: ${youngest.studentName} (DOB: ${_dateFormat.format(youngest.dateOfBirth)})'),
            if (oldest != null) pw.Text('Oldest: ${oldest.studentName} (DOB: ${_dateFormat.format(oldest.dateOfBirth)})'),
          ],
        ),
      ),
    );

    return _save(await doc.save(), 'Age_Report_$className');
  }

  Future<File> exportStudentProfilePdf({required School school, required Student student, required String className}) async {
    final doc = pw.Document();
    final age = AgeCalculator.calculate(dateOfBirth: student.dateOfBirth, asOf: DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(school, 'Student Profile'),
            pw.SizedBox(height: 20),
            _profileRow('Student Name', student.studentName),
            _profileRow('GR Number', student.grNumber),
            _profileRow('Serial Number', '${student.serialNumber ?? '-'}'),
            _profileRow('Class', className),
            _profileRow('Father Name', student.fatherName ?? '-'),
            _profileRow('Mother Name', student.motherName ?? '-'),
            _profileRow('Date of Birth', _dateFormat.format(student.dateOfBirth)),
            _profileRow('Age', age.format()),
            _profileRow('Date of Admission', _dateFormat.format(student.dateOfAdmission)),
            _profileRow('Father CNIC', student.fatherCnic ?? '-'),
            _profileRow('B-Form Number', student.bFormNumber ?? '-'),
            _profileRow('Phone Number', student.phoneNumber ?? '-'),
            _profileRow('Address', student.address ?? '-'),
            _profileRow('Previous School', student.previousSchool ?? '-'),
            _profileRow('Status', student.status.dbValue),
          ],
        ),
      ),
    );

    return _save(await doc.save(), 'Profile_${student.grNumber}');
  }

  /// Requirement #34: clean, printable certificate templates.
  Future<File> generateCertificate({
    required CertificateType type,
    required School school,
    required Student student,
    required String className,
    String? additionalNote,
  }) async {
    final doc = pw.Document();
    final issueDate = _dateFormat.format(DateTime.now());
    final age = AgeCalculator.calculate(dateOfBirth: student.dateOfBirth, asOf: DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(school.schoolName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            if (school.semisCode != null) pw.Text('SEMIS: ${school.semisCode}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 24),
            pw.Text(type.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 32),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(_certificateBody(type, student, className, age, additionalNote), style: const pw.TextStyle(fontSize: 13)),
            ),
            pw.SizedBox(height: 48),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date: $issueDate'),
                pw.Column(children: [pw.SizedBox(width: 140, child: pw.Divider()), pw.Text('Head Teacher / Principal')]),
              ],
            ),
          ],
        ),
      ),
    );

    return _save(await doc.save(), '${type.name}_${student.grNumber}');
  }

  Future<File> generateCustomCertificate({
    required String certificateTitle,
    required School school,
    required Student student,
    required String className,
    String? additionalNote,
  }) async {
    final doc = pw.Document();
    final issueDate = _dateFormat.format(DateTime.now());

    final bodyText = 'This is to certify that ${student.studentName}, son/daughter of '
        '${student.fatherName ?? '_______'}, GR Number ${student.grNumber}, was admitted on '
        'the school register on ${DateFormat('dd-MM-yyyy').format(student.dateOfAdmission)} '
        'and enrolled in $className.\n\n'
        'This $certificateTitle is issued on request for lawful purposes and records.'
        '${additionalNote != null ? '\n\nRemarks / Details: $additionalNote' : ''}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(school.schoolName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            if (school.semisCode != null) pw.Text('SEMIS: ${school.semisCode}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 24),
            pw.Text(certificateTitle, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 32),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(bodyText, style: const pw.TextStyle(fontSize: 13, lineSpacing: 4)),
            ),
            pw.SizedBox(height: 48),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date: $issueDate'),
                pw.Column(children: [pw.SizedBox(width: 140, child: pw.Divider()), pw.Text('Head Teacher / Principal')]),
              ],
            ),
          ],
        ),
      ),
    );

    final safeTitle = certificateTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return _save(await doc.save(), '${safeTitle}_${student.grNumber}');
  }

  String _certificateBody(CertificateType type, Student student, String className, AgeResult age, String? note) {
    switch (type) {
      case CertificateType.schoolLeaving:
        return 'This is to certify that ${student.studentName}, son/daughter of '
            '${student.fatherName ?? '_______'}, GR Number ${student.grNumber}, was a '
            'student of $className in this school and was admitted on the register on '
            '${DateFormat('dd-MM-yyyy').format(student.dateOfAdmission)}. '
            'The student is leaving the school.${note != null ? '\n\nRemarks: $note' : ''}';
      case CertificateType.character:
        return 'This is to certify that ${student.studentName}, son/daughter of '
            '${student.fatherName ?? '_______'}, GR Number ${student.grNumber}, a student '
            'of $className, bears a good moral character to the best of the school\'s '
            'knowledge during their time here.${note != null ? '\n\nRemarks: $note' : ''}';
      case CertificateType.birth:
        return 'As per the school admission register, ${student.studentName}, son/daughter '
            'of ${student.fatherName ?? '_______'}, GR Number ${student.grNumber}, was born on '
            '${DateFormat('dd-MM-yyyy').format(student.dateOfBirth)} '
            '(present age: ${age.format()}).${note != null ? '\n\nRemarks: $note' : ''}';
    }
  }

  pw.Widget _header(School school, String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(school.schoolName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        if (school.semisCode != null) pw.Text('SEMIS: ${school.semisCode}', style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 6),
        pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _profileRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 150, child: pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700))),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<File> _save(List<int> bytes, String baseName) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
    final safeName = baseName.replaceAll(RegExp(r'[^A-Za-z0-9_\- ]'), '_');
    final file = File(p.join(exportsDir.path, '${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf'));
    await file.writeAsBytes(bytes);
    return file;
  }
}
