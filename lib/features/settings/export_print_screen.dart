import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/age_calculator.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/data_tools_providers.dart';
import '../../providers/pass_out_providers.dart';
import '../../providers/repository_providers.dart';
import '../data_tools/excel_import_screen.dart';

enum _Scope { completeRegister, class_, passOutYear, struckOff }

class ExportPrintScreen extends ConsumerStatefulWidget {
  const ExportPrintScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<ExportPrintScreen> createState() => _ExportPrintScreenState();
}

class _ExportPrintScreenState extends ConsumerState<ExportPrintScreen> {
  _Scope _scope = _Scope.completeRegister;
  String? _classId;
  int? _year;
  bool _busy = false;

  Future<List<(Student, String)>> _collectStudents(List<SchoolClass> classes) async {
    final repo = ref.read(studentRepositoryProvider);
    final classNames = {for (final c in classes) c.id: c.displayName};

    final List<Student> students = switch (_scope) {
      _Scope.completeRegister => await repo.getStudents(schoolId: widget.schoolId),
      _Scope.class_ => await repo.getStudents(schoolId: widget.schoolId, classId: _classId, status: StudentStatus.active),
      _Scope.passOutYear =>
        await repo.getStudents(schoolId: widget.schoolId, status: StudentStatus.passedOut, passOutYear: _year),
      _Scope.struckOff => await repo.getStudents(schoolId: widget.schoolId, status: StudentStatus.struckOff),
    };
    return students.map((s) => (s, classNames[s.classId] ?? '-')).toList();
  }

  String _title(List<SchoolClass> classes) => switch (_scope) {
        _Scope.completeRegister => 'Complete Register',
        _Scope.class_ => 'Class ${classes.where((c) => c.id == _classId).firstOrNull?.displayName ?? ''}',
        _Scope.passOutYear => 'Pass Out $_year',
        _Scope.struckOff => 'Struck Off Students',
      };

  bool get _scopeReady =>
      (_scope != _Scope.class_ || _classId != null) && (_scope != _Scope.passOutYear || _year != null);

  Future<void> _export({required bool pdf, required List<SchoolClass> classes}) async {
    if (!_scopeReady) {
      _snack('Please choose a ${_scope == _Scope.class_ ? 'class' : 'year'} first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final students = await _collectStudents(classes);
      if (students.isEmpty) {
        _snack('There are no students to export for this selection.');
        return;
      }
      final title = _title(classes);
      File file;
      if (pdf) {
        final school = await ref.read(schoolRepositoryProvider).getLocalSchool();
        if (school == null) {
          _snack('School profile is missing.');
          return;
        }
        file = await ref.read(pdfExportServiceProvider).exportRegisterPdf(school: school, title: title, students: students);
      } else {
        file = await ref.read(excelExportServiceProvider).exportStudents(sheetTitle: title, students: students);
      }
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportAgeReport(List<SchoolClass> classes) async {
    if (_classId == null) {
      _snack('Choose a class first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final school = await ref.read(schoolRepositoryProvider).getLocalSchool();
      final schoolClass = classes.firstWhere((c) => c.id == _classId);
      final students = await ref
          .read(studentRepositoryProvider)
          .getStudents(schoolId: widget.schoolId, classId: _classId, status: StudentStatus.active);
      if (school == null || students.isEmpty) {
        _snack('No active students in this class.');
        return;
      }

      final now = DateTime.now();
      final ages = {for (final s in students) s: AgeCalculator.calculate(dateOfBirth: s.dateOfBirth, asOf: now)};
      final counts = <int, int>{};
      for (final a in ages.values) {
        counts[a.years] = (counts[a.years] ?? 0) + 1;
      }
      final buckets = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      bool younger(AgeResult a, AgeResult b) => a.years != b.years
          ? a.years < b.years
          : a.months != b.months
              ? a.months < b.months
              : a.days < b.days;
      Student? youngest, oldest;
      for (final e in ages.entries) {
        if (youngest == null || younger(e.value, ages[youngest]!)) youngest = e.key;
        if (oldest == null || younger(ages[oldest]!, e.value)) oldest = e.key;
      }

      final file = await ref.read(pdfExportServiceProvider).exportAgeReportPdf(
            school: school,
            className: schoolClass.displayName,
            ageBuckets: buckets,
            youngest: youngest,
            oldest: oldest,
          );
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      _snack('Export failed: $e');
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
    final classes = ref.watch(classesStreamProvider(widget.schoolId)).valueOrNull ?? [];
    final years = ref.watch(passOutYearsProvider(widget.schoolId)).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Export & Print')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.upload_file, color: GrBookTheme.primaryDark),
                title: const Text('Import from Excel', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Bring in an old register'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ExcelImportScreen(schoolId: widget.schoolId)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('What to export', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Complete Register'), selected: _scope == _Scope.completeRegister, onSelected: (_) => setState(() => _scope = _Scope.completeRegister)),
                ChoiceChip(label: const Text('One Class'), selected: _scope == _Scope.class_, onSelected: (_) => setState(() => _scope = _Scope.class_)),
                ChoiceChip(label: const Text('Pass Out Year'), selected: _scope == _Scope.passOutYear, onSelected: (_) => setState(() => _scope = _Scope.passOutYear)),
                ChoiceChip(label: const Text('Struck Off'), selected: _scope == _Scope.struckOff, onSelected: (_) => setState(() => _scope = _Scope.struckOff)),
              ],
            ),
            const SizedBox(height: 12),
            if (_scope == _Scope.class_)
              DropdownButtonFormField<String>(
                value: _classId,
                decoration: const InputDecoration(labelText: 'Class'),
                items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))).toList(),
                onChanged: (v) => setState(() => _classId = v),
              ),
            if (_scope == _Scope.passOutYear)
              DropdownButtonFormField<int>(
                value: _year,
                decoration: const InputDecoration(labelText: 'Year'),
                items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) => setState(() => _year = v),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _busy ? null : () => _export(pdf: false, classes: classes),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Excel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _busy ? null : () => _export(pdf: true, classes: classes),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                ),
              ],
            ),
            if (_scope == _Scope.class_) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GrBookTheme.primaryDark,
                    side: const BorderSide(color: GrBookTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _busy ? null : () => _exportAgeReport(classes),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Age Report (PDF)'),
                ),
              ),
            ],
            if (_busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
