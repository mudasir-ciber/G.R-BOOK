import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/age_calculator.dart';
import '../../core/theme.dart';
import '../../providers/data_tools_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/excel_import_service.dart';

class ExcelImportScreen extends ConsumerStatefulWidget {
  const ExcelImportScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  ImportPreview? _preview;
  bool _isLoading = false;
  bool _isImporting = false;
  String? _error;
  String? _fileName;

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _preview = null;
    });
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _isLoading = true;
      _fileName = result!.files.single.name;
    });
    try {
      final classes = await ref.read(classRepositoryProvider).watchClasses(widget.schoolId).first;
      final existing = await ref.read(studentRepositoryProvider).getStudents(schoolId: widget.schoolId);
      final preview = await ref.read(excelImportServiceProvider).buildPreview(
            file: File(path),
            classes: classes,
            existingGrNumbers: existing.map((s) => s.grNumber).toSet(),
          );
      setState(() => _preview = preview);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not read this file. Make sure it is a valid .xlsx workbook.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;

    // Requirement #32: duplicate GR warns but never blocks — ask once,
    // explicitly, before importing rows flagged as duplicates.
    if (preview.duplicateCount > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate GR Numbers'),
          content: Text('${preview.duplicateCount} row(s) use a GR number that already exists. Import them anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isImporting = true);
    final repo = ref.read(studentRepositoryProvider);
    var imported = 0;
    final failures = <String>[];

    for (final row in preview.importable) {
      try {
        await repo.createStudent(
          schoolId: widget.schoolId,
          classId: row.schoolClass!.id,
          grNumber: row.grNumber,
          studentName: row.studentName,
          fatherName: row.fatherName,
          dateOfBirth: row.dateOfBirth!,
          dateOfAdmission: row.dateOfAdmission!,
          fatherCnic: row.fatherCnic,
          bFormNumber: row.bFormNumber,
          phoneNumber: row.phoneNumber,
          address: row.address,
          previousSchool: row.previousSchool,
          previousGrNumber: row.previousGrNumber,
          remarks: row.remarks,
        );
        imported++;
      } catch (e) {
        failures.add('Row ${row.rowNumber}: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isImporting = false);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Finished'),
        content: Text(
          '$imported student(s) imported.'
          '${preview.errorCount > 0 ? '\n${preview.errorCount} row(s) were skipped because of errors.' : ''}'
          '${failures.isNotEmpty ? '\n${failures.length} row(s) failed while saving.' : ''}',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Import from Excel')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Your sheet needs a header row. Required columns: GR Number, Student Name, Class, '
                    'Date of Birth, Date of Admission. Optional: Serial Number, Father Name, CNIC, B-Form, '
                    'Phone, Address, Previous School, Previous GR, Remarks.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GrBookTheme.primaryDark,
                        side: const BorderSide(color: GrBookTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading || _isImporting ? null : _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_fileName ?? 'Choose Excel file (.xlsx)'),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) const Expanded(child: Center(child: CircularProgressIndicator())),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            if (preview != null && preview.missingRequiredColumns.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'These required columns were not found: ${preview.missingRequiredColumns.join(', ')}.',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            if (preview != null && preview.missingRequiredColumns.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _CountChip(label: 'Valid', count: preview.validCount, color: GrBookTheme.primary),
                    const SizedBox(width: 8),
                    _CountChip(label: 'Duplicate GR', count: preview.duplicateCount, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    _CountChip(label: 'Errors', count: preview.errorCount, color: Colors.red.shade600),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: preview.rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = preview.rows[index];
                    final color = switch (row.status) {
                      ImportRowStatus.valid => GrBookTheme.primary,
                      ImportRowStatus.duplicateGr => Colors.orange.shade700,
                      ImportRowStatus.error => Colors.red.shade600,
                    };
                    String ageText = '';
                    if (row.dateOfBirth != null && row.dateOfAdmission != null && !row.dateOfAdmission!.isBefore(row.dateOfBirth!)) {
                      ageText = '  •  ${AgeCalculator.calculate(dateOfBirth: row.dateOfBirth!, asOf: row.dateOfAdmission!).formatShort()} at admission';
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        row.status == ImportRowStatus.error ? Icons.error_outline : Icons.check_circle_outline,
                        color: color,
                      ),
                      title: Text('Row ${row.rowNumber}: ${row.studentName.isEmpty ? '(no name)' : row.studentName}'),
                      subtitle: Text(
                        row.problems.isEmpty
                            ? 'GR ${row.grNumber}  •  ${row.schoolClass?.displayName ?? ''}$ageText'
                            : row.problems.join('; '),
                        style: TextStyle(color: row.problems.isEmpty ? null : color, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: GrBookTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: (_isImporting || preview.importable.isEmpty) ? null : _import,
                    icon: _isImporting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_done),
                    label: Text('Import ${preview.importable.length} Student(s)'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
      child: Text('$label: $count', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
