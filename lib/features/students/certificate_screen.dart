import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/data_tools_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/pdf_export_service.dart';

class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key, required this.student, required this.schoolClass});

  final Student student;
  final SchoolClass schoolClass;

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  CertificateType _type = CertificateType.schoolLeaving;
  final _noteController = TextEditingController();
  bool _busy = false;

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
    return service.generateCertificate(
      type: _type,
      school: school,
      student: widget.student,
      className: widget.schoolClass.displayName,
      additionalNote: note.isEmpty ? null : note,
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
    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: Text('Certificates — ${widget.student.studentName}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...CertificateType.values.map(
              (t) => RadioListTile<CertificateType>(
                value: t,
                groupValue: _type,
                activeColor: GrBookTheme.primary,
                title: Text(t.title),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Remarks (optional)'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _busy ? null : () => _run((f) => Share.shareXFiles([XFile(f.path)])),
                    icon: const Icon(Icons.share),
                    label: const Text('Share / Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GrBookTheme.primaryDark,
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
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _run((f) => Share.shareXFiles([XFile(f.path)]), profileOnly: true),
                icon: const Icon(Icons.person_outline),
                label: const Text('Student Profile (PDF)'),
              ),
            ),
            if (_busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
