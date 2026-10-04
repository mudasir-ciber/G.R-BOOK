import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/age_calculator.dart';
import '../models/enums.dart';
import '../models/school.dart';
import '../models/student.dart';
import 'signature_processing_service.dart';

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
          pw.TableHelper.fromTextArray(
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
            pw.TableHelper.fromTextArray(
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

  Future<File> exportStudentProfilePdf({
    required School school,
    required Student student,
    required String className,
    Uint8List? studentPhotoBytes,
  }) async {
    final doc = pw.Document();
    final age = AgeCalculator.calculate(dateOfBirth: student.dateOfBirth, asOf: DateTime.now());
    final signatureImage = await _loadPrincipalSignature();
    final issueDate = _dateFormat.format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Header: School Info + Student Picture
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        formatSchoolName(school.schoolName),
                        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
                      ),
                      if (buildSchoolSubheader(school).isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          buildSchoolSubheader(school),
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                      ],
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        child: pw.Text(
                          'GENERAL REGISTER - STUDENT PROFILE (A4)',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                // Student Picture Box (Circular)
                pw.Container(
                  width: 90,
                  height: 90,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: studentPhotoBytes != null && studentPhotoBytes.isNotEmpty ? null : PdfColors.grey100,
                    border: studentPhotoBytes != null && studentPhotoBytes.isNotEmpty
                        ? null
                        : pw.Border.all(color: PdfColors.grey400, width: 1.0),
                  ),
                  alignment: pw.Alignment.center,
                  child: studentPhotoBytes != null && studentPhotoBytes.isNotEmpty
                      ? pw.ClipOval(
                          child: pw.Image(
                            pw.MemoryImage(studentPhotoBytes),
                            width: 90,
                            height: 90,
                            fit: pw.BoxFit.cover,
                          ),
                        )
                      : pw.Text('Student\nPhoto', textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(thickness: 1.2),
            pw.SizedBox(height: 10),

            // Profile Details Rows
            _profileRow('Student Full Name', student.studentName),
            _profileRow('G.R. Number', student.grNumber),
            _profileRow('Serial Number', '${student.serialNumber ?? '-'}'),
            _profileRow('Enrolled Class', className),
            _profileRow('Gender', student.isFemale ? 'Female (Daughter of)' : 'Male (Son of)'),
            _profileRow('Father Name', student.fatherName ?? '-'),
            _profileRow('Mother Name', student.motherName ?? '-'),
            _profileRow('Date of Birth', _dateFormat.format(student.dateOfBirth)),
            _profileRow('Current Age', age.format()),
            _profileRow('Date of Admission', _dateFormat.format(student.dateOfAdmission)),
            _profileRow('Father CNIC', student.fatherCnic ?? '-'),
            _profileRow('B-Form Number', student.bFormNumber ?? '-'),
            _profileRow('Contact Number', student.phoneNumber ?? '-'),
            _profileRow('Residential Address', student.address ?? '-'),
            _profileRow('Previous School Attended', student.previousSchool ?? '-'),
            _profileRow('Enrollment Status', student.status.dbValue),
            if (student.cleanRemarks != null) _profileRow('Remarks / Notes', student.cleanRemarks!),

            pw.Spacer(),

            // Verification & Signatures Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date of Issue: $issueDate', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 28),
                    pw.SizedBox(width: 140, child: pw.Divider()),
                    pw.Text('Class Teacher Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (signatureImage != null)
                      pw.Container(
                        height: 42,
                        width: 130,
                        alignment: pw.Alignment.bottomCenter,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      ),
                    pw.SizedBox(width: 140, child: pw.Divider()),
                    pw.Text('Head Teacher / Principal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return _save(await doc.save(), 'Profile_${student.grNumber}');
  }

  static final List<(RegExp, String)> _schoolAcronymPatterns = [
    // 5-letter abbreviations (longest first)
    (_makeAcronymRegex('GBHSS'), 'Government Boys Higher Secondary School'),
    (_makeAcronymRegex('GGHSS'), 'Government Girls Higher Secondary School'),
    (_makeAcronymRegex('GBELS'), 'Government Boys Elementary School'),
    (_makeAcronymRegex('GGELS'), 'Government Girls Elementary School'),
    (_makeAcronymRegex('GBLSS'), 'Government Boys Lower Secondary School'),
    (_makeAcronymRegex('GGLSS'), 'Government Girls Lower Secondary School'),
    // 4-letter abbreviations
    (_makeAcronymRegex('GBHS'), 'Government Boys High School'),
    (_makeAcronymRegex('GGHS'), 'Government Girls High School'),
    (_makeAcronymRegex('GHSS'), 'Government Higher Secondary School'),
    (_makeAcronymRegex('GBPS'), 'Government Boys Primary School'),
    (_makeAcronymRegex('GGPS'), 'Government Girls Primary School'),
    (_makeAcronymRegex('GELS'), 'Government Elementary School'),
    (_makeAcronymRegex('GLSS'), 'Government Lower Secondary School'),
    // 3-letter abbreviations
    (_makeAcronymRegex('GBH'), 'Government Boys High School'),
    (_makeAcronymRegex('GGH'), 'Government Girls High School'),
    (_makeAcronymRegex('GHS'), 'Government High School'),
    (_makeAcronymRegex('GPS'), 'Government Primary School'),
  ];

  static RegExp _makeAcronymRegex(String acronym) {
    final lettersPattern = acronym.split('').map(RegExp.escape).join(r'[\.\s]*');
    return RegExp('^\\s*$lettersPattern[\\.\\s]*(?:[\\s\\-–—:]+|\$)', caseSensitive: false);
  }

  /// Automatically expands any school acronym prefix (e.g. GBPS, GGPS, GPS, GBHS, etc.)
  /// into its official full title (e.g. "Government Boys Primary School Mehar Ghanghro").
  static String formatSchoolName(String name) {
    var trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;

    // Normalize leading "Govt." or "Govt " to "Government "
    if (RegExp(r'^govt\.?\s+', caseSensitive: false).hasMatch(trimmed)) {
      trimmed = trimmed.replaceFirst(RegExp(r'^govt\.?\s+', caseSensitive: false), 'Government ');
    }

    // Check if starts with "Government " followed by an acronym (e.g. "Government GBPS Mehar")
    if (RegExp(r'^government\s+', caseSensitive: false).hasMatch(trimmed)) {
      final afterGovt = trimmed.replaceFirst(RegExp(r'^government\s+', caseSensitive: false), '');
      for (final (regex, fullForm) in _schoolAcronymPatterns) {
        final match = regex.firstMatch(afterGovt);
        if (match != null) {
          final remainder = afterGovt.substring(match.end).trim();
          return remainder.isNotEmpty ? '$fullForm $remainder' : fullForm;
        }
      }
      return trimmed;
    }

    // Check directly against acronym patterns
    for (final (regex, fullForm) in _schoolAcronymPatterns) {
      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final remainder = trimmed.substring(match.end).trim();
        return remainder.isNotEmpty ? '$fullForm $remainder' : fullForm;
      }
    }

    return trimmed;
  }

  /// Formats the official secondary sub-header line:
  /// "SEMIS CODE: [Code]   |   DISTRICT: [District]   |   CITY / TALUKA: [Taluka]"
  static String buildSchoolSubheader(School school) {
    final parts = <String>[];
    if (school.semisCode != null && school.semisCode!.trim().isNotEmpty) {
      parts.add('SEMIS CODE: ${school.semisCode!.trim()}');
    }
    if (school.district != null && school.district!.trim().isNotEmpty) {
      parts.add('DISTRICT: ${school.district!.trim()}');
    }
    if (school.taluka != null && school.taluka!.trim().isNotEmpty) {
      parts.add('CITY / TALUKA: ${school.taluka!.trim()}');
    } else if (school.uc != null && school.uc!.trim().isNotEmpty) {
      parts.add('UC: ${school.uc!.trim()}');
    }
    return parts.join('   |   ');
  }

  Future<String?> _loadPrincipalName() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final nameFile = File('${docDir.path}/principal_name.txt');
      if (await nameFile.exists()) {
        final text = (await nameFile.readAsString()).trim();
        if (text.isNotEmpty) return text;
      }
    } catch (_) {}
    return null;
  }

  Future<pw.MemoryImage?> _loadPrincipalSignature() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final sigFile = File('${docDir.path}/principal_signature.png');
      if (await sigFile.exists()) {
        final bytes = await sigFile.readAsBytes();
        if (bytes.isNotEmpty) {
          final cleanBytes = await SignatureProcessingService.ensureTransparentBackground(bytes);
          return pw.MemoryImage(cleanBytes);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Requirement #34: clean, printable certificate templates.
  Future<File> generateCertificate({
    required CertificateType type,
    required School school,
    required Student student,
    required String className,
    String? additionalNote,
    String? customBodyText,
  }) async {
    final doc = pw.Document();
    final issueDate = _dateFormat.format(DateTime.now());
    final age = AgeCalculator.calculate(dateOfBirth: student.dateOfBirth, asOf: DateTime.now());
    final signatureImage = await _loadPrincipalSignature();

    final body = (customBodyText != null && customBodyText.trim().isNotEmpty)
        ? customBodyText.trim()
        : _certificateBody(type, student, className, age, additionalNote);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) {
          final subheader = buildSchoolSubheader(school);
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                formatSchoolName(school.schoolName),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              if (subheader.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  subheader,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              pw.SizedBox(height: 20),
            pw.Text(type.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 32),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(body, style: const pw.TextStyle(fontSize: 13, lineSpacing: 4)),
            ),
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date: $issueDate'),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (signatureImage != null)
                      pw.Container(
                        height: 42,
                        width: 130,
                        alignment: pw.Alignment.bottomCenter,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      ),
                    pw.SizedBox(width: 140, child: pw.Divider()),
                    pw.Text('Head Teacher / Principal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        );
      },
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
    String? customBodyText,
  }) async {
    final doc = pw.Document();
    final issueDate = _dateFormat.format(DateTime.now());
    final signatureImage = await _loadPrincipalSignature();
    final relation = student.isFemale ? 'daughter of' : 'son of';

    final bodyText = (customBodyText != null && customBodyText.trim().isNotEmpty)
        ? customBodyText.trim()
        : ('This is to certify that ${student.studentName}, $relation '
            '${student.fatherName ?? '_______'}, GR Number ${student.grNumber}, was admitted on '
            'the school register on ${DateFormat('dd-MM-yyyy').format(student.dateOfAdmission)} '
            'and enrolled in $className.\n\n'
            'This $certificateTitle is issued on request for lawful purposes and records.'
            '${additionalNote != null ? '\n\nRemarks / Details: $additionalNote' : ''}');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) {
          final subheader = buildSchoolSubheader(school);
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                formatSchoolName(school.schoolName),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              if (subheader.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  subheader,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              pw.SizedBox(height: 20),
            pw.Text(certificateTitle, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 32),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(bodyText, style: const pw.TextStyle(fontSize: 13, lineSpacing: 4)),
            ),
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date: $issueDate'),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (signatureImage != null)
                      pw.Container(
                        height: 42,
                        width: 130,
                        alignment: pw.Alignment.bottomCenter,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      ),
                    pw.SizedBox(width: 140, child: pw.Divider()),
                    pw.Text('Head Teacher / Principal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

    final safeTitle = certificateTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return _save(await doc.save(), '${safeTitle}_${student.grNumber}');
  }

  Future<File> generateNoticePdf({
    required School school,
    required Student student,
    required String className,
    required String noticeText,
    File? attachedPhoto,
  }) async {
    final doc = pw.Document();
    final issueDate = _dateFormat.format(DateTime.now());
    final signatureImage = await _loadPrincipalSignature();
    final principalName = await _loadPrincipalName();
    List<int>? photoBytes;
    if (attachedPhoto != null && await attachedPhoto.exists()) {
      photoBytes = await attachedPhoto.readAsBytes();
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final subheader = buildSchoolSubheader(school);
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                formatSchoolName(school.schoolName),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              if (subheader.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  subheader,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (principalName != null && principalName.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Principal: $principalName',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
              pw.SizedBox(height: 16),
            pw.Text(
              'Complaint Letter',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _profileRow('Student Name', student.studentName),
                  _profileRow('G.R Number', student.grNumber),
                  _profileRow('Class', className),
                  _profileRow('Parent / Guardian', student.fatherName ?? '-'),
                  _profileRow('Contact Number', student.phoneNumber ?? '-'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Note / Notice Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  pw.SizedBox(height: 8),
                  pw.Text(noticeText, style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
                ],
              ),
            ),
            if (photoBytes != null) ...[
              pw.SizedBox(height: 16),
              pw.Container(
                height: 160,
                alignment: pw.Alignment.centerLeft,
                child: pw.Image(pw.MemoryImage(photoBytes as dynamic), fit: pw.BoxFit.contain),
              ),
            ],
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date: $issueDate'),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (signatureImage != null)
                      pw.Container(
                        height: 42,
                        width: 130,
                        alignment: pw.Alignment.bottomCenter,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      ),
                    pw.SizedBox(width: 140, child: pw.Divider()),
                    pw.Text('Head Teacher / Principal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

    return _save(await doc.save(), 'Note_${student.grNumber}');
  }

  String _certificateBody(CertificateType type, Student student, String className, AgeResult age, String? note) {
    final defaultText = buildDefaultCertificateContext(
      type: type,
      student: student,
      className: className,
      age: age,
    );
    if (note != null && note.trim().isNotEmpty) {
      return '$defaultText\n\nRemarks: ${note.trim()}';
    }
    return defaultText;
  }

  static String buildDefaultCertificateContext({
    required CertificateType type,
    required Student student,
    required String className,
    AgeResult? age,
  }) {
    final effectiveAge = age ?? AgeCalculator.calculate(dateOfBirth: student.dateOfBirth, asOf: DateTime.now());
    final relation = student.isFemale ? 'daughter of' : 'son of';
    final father = student.fatherName ?? '_______';
    final dobStr = DateFormat('dd-MM-yyyy').format(student.dateOfBirth);
    final doaStr = DateFormat('dd-MM-yyyy').format(student.dateOfAdmission);

    switch (type) {
      case CertificateType.schoolLeaving:
        return 'This is to certify that ${student.studentName}, $relation $father, bearing G.R. Number ${student.grNumber}, was a bonafide student of $className in this school. The student was admitted on the general register on $doaStr and is leaving the school on satisfactory terms with good moral conduct.';
      case CertificateType.character:
        return 'This is to certify that ${student.studentName}, $relation $father, bearing G.R. Number ${student.grNumber}, enrolled in $className, bears a good moral character and satisfactory conduct during their academic period in this school to the best of our knowledge and records.';
      case CertificateType.birth:
        return 'As per the official school General Register records, ${student.studentName}, $relation $father, bearing G.R. Number ${student.grNumber}, was born on $dobStr (present age: ${effectiveAge.format()}). This certificate is issued upon lawful request for records and official verification.';
    }
  }

  static String buildDefaultCustomCertificateContext({
    required String title,
    required Student student,
    required String className,
  }) {
    final relation = student.isFemale ? 'daughter of' : 'son of';
    final father = student.fatherName ?? '_______';
    final doaStr = DateFormat('dd-MM-yyyy').format(student.dateOfAdmission);
    return 'This is to certify that ${student.studentName}, $relation $father, bearing G.R. Number ${student.grNumber}, was admitted on $doaStr and enrolled in $className.\n\nThis $title is issued on request for lawful purposes and official school records.';
  }

  pw.Widget _header(School school, String title) {
    final subheader = buildSchoolSubheader(school);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(formatSchoolName(school.schoolName), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        if (subheader.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(subheader, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        ],
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
