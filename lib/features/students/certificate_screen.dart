import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/data_tools_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/document_share_service.dart';
import '../../services/pdf_export_service.dart';
import 'student_a4_profile_screen.dart';

class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key, required this.student, required this.schoolClass});

  final Student student;
  final SchoolClass schoolClass;

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  CertificateType _type = CertificateType.schoolLeaving;
  final _contextController = TextEditingController();
  final _noteController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initContextText();
  }

  void _initContextText() {
    _contextController.text = PdfExportService.buildDefaultCertificateContext(
      type: _type,
      student: widget.student,
      className: widget.schoolClass.displayName,
    );
  }

  @override
  void dispose() {
    _contextController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<File?> _generate({bool profileOnly = false}) async {
    final school = await ref.read(schoolRepositoryProvider).getLocalSchool();
    if (school == null) {
      _snack('Please complete the school profile first.');
      return null;
    }
    final service = ref.read(pdfExportServiceProvider);
    if (profileOnly) {
      return service.exportStudentProfilePdf(
        school: school,
        student: widget.student,
        className: widget.schoolClass.displayName,
      );
    }
    final note = _noteController.text.trim();
    final customText = _contextController.text.trim();
    return service.generateCertificate(
      type: _type,
      school: school,
      student: widget.student,
      className: widget.schoolClass.displayName,
      additionalNote: note.isEmpty ? null : note,
      customBodyText: customText.isNotEmpty ? customText : null,
    );
  }

  Future<void> _run(Future<void> Function(File file) action, {bool profileOnly = false}) async {
    setState(() => _busy = true);
    try {
      final file = await _generate(profileOnly: profileOnly);
      if (file != null) await action(file);
    } catch (e) {
      _snack('Could not generate the PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);
    final cardBg = GrBookTheme.getCardBackground(context);
    final borderColor = GrBookTheme.getBorderColor(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      appBar: AppBar(title: Text('Certificates — ${widget.student.studentName}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: CertificateType.values.map(
                  (t) => RadioListTile<CertificateType>(
                    value: t,
                    groupValue: _type,
                    activeColor: GrBookTheme.primary,
                    title: Text(t.title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _type = v;
                          _initContextText();
                        });
                      }
                    },
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 22, color: GrBookTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Certificate Context / Body:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                        onPressed: () => setState(_initContextText),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reset Text', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Teacher can write or customize this text freely just like a complaint letter:',
                    style: TextStyle(fontSize: 11.5, color: GrBookTheme.getTextSecondary(context)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contextController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 13.5, color: textPrimary, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Type certificate context here...',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF14221A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: GrBookTheme.primary, width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Remarks (optional)',
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _busy
                        ? null
                        : () => _run((f) => DocumentShareService.showShareOptions(
                              context,
                              pdfFile: f,
                              title: _type.title,
                              studentName: widget.student.studentName,
                            )),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share (PDF / JPG)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark,
                      side: const BorderSide(color: GrBookTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _busy ? null : () => _run((f) => Printing.layoutPdf(onLayout: (_) => f.readAsBytes())),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: borderColor),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark,
                  side: const BorderSide(color: GrBookTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentA4ProfileScreen(
                        student: widget.student,
                        schoolClass: widget.schoolClass,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text('View Student Profile (A4 Sheet & Photos)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (_busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
