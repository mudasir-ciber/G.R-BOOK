import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/data_tools_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/certificate_repository.dart';
import '../../services/pdf_export_service.dart';
import '../../widgets/gr_book_ui_components.dart';

/// Screen for managing and generating student certificates.
/// Supports both default templates and teacher-created custom certificate types.
class CertificatesHubScreen extends ConsumerStatefulWidget {
  const CertificatesHubScreen({super.key});

  @override
  ConsumerState<CertificatesHubScreen> createState() => _CertificatesHubScreenState();
}

class _CertificatesHubScreenState extends ConsumerState<CertificatesHubScreen> {
  void _openAddCertificateDialog(String schoolId) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const GrBookIconBadge(icon: Icons.card_membership_rounded, size: 36, iconSize: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Another Certificate',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Certificate Name *',
                hintText: 'e.g. Transfer Certificate, Merit Certificate',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description / Purpose',
                hintText: 'e.g. Issued for student school transfer',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: GrBookTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await ref.read(certificateRepositoryProvider).addCertificateType(
                      schoolId: schoolId,
                      title: name,
                      description: descCtrl.text.trim(),
                    );
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Certificate "$name" added successfully.')),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Save Certificate Type', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _onSelectCertificate(CertificateTypeItem cert, School school) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CertificateStudentPickerScreen(
          certificateType: cert,
          school: school,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(showBack: true),
              const GrBookPageHeader(
                title: 'Certificates',
                subtitle: 'Generate & manage official student certificates',
              ),
              Expanded(
                child: schoolAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (school) {
                    if (school == null) {
                      return const Center(child: Text('No school profile found.'));
                    }

                    final certsAsync = ref.watch(certificateTypesStreamProvider(school.id));

                    return certsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error loading certificates: $e')),
                      data: (certs) => ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          ...certs.map((c) => _CertificateTypeCard(
                                item: c,
                                onTap: () => _onSelectCertificate(c, school),
                              )),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GrBookTheme.primaryDark,
                              side: const BorderSide(color: GrBookTheme.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () => _openAddCertificateDialog(school.id),
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text(
                              '+ ADD ANOTHER CERTIFICATE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateTypeCard extends StatelessWidget {
  const _CertificateTypeCard({required this.item, required this.onTap});

  final CertificateTypeItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GrBookTheme.borderColor, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 26),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: GrBookTheme.textPrimary),
        ),
        subtitle: Text(
          item.description.isNotEmpty ? item.description : 'Official School Certificate',
          style: const TextStyle(fontSize: 12, color: GrBookTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_right_rounded, color: GrBookTheme.primary, size: 22),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _CertificateStudentPickerScreen extends ConsumerStatefulWidget {
  const _CertificateStudentPickerScreen({
    required this.certificateType,
    required this.school,
  });

  final CertificateTypeItem certificateType;
  final School school;

  @override
  ConsumerState<_CertificateStudentPickerScreen> createState() =>
      _CertificateStudentPickerScreenState();
}

class _CertificateStudentPickerScreenState
    extends ConsumerState<_CertificateStudentPickerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Student? _selectedStudent;
  final _remarksController = TextEditingController();
  bool _isGenerating = false;

  Future<void> _generateAndExecute(
    Future<void> Function(File file) action, {
    required String className,
  }) async {
    if (_selectedStudent == null) return;
    setState(() => _isGenerating = true);
    try {
      final pdfService = ref.read(pdfExportServiceProvider);
      final File file;

      if (widget.certificateType.isDefault) {
        final defaultType = switch (widget.certificateType.title) {
          'School Leaving Certificate' => CertificateType.schoolLeaving,
          'Character Certificate' => CertificateType.character,
          _ => CertificateType.birth,
        };
        file = await pdfService.generateCertificate(
          type: defaultType,
          school: widget.school,
          student: _selectedStudent!,
          className: className,
          additionalNote: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        );
      } else {
        file = await pdfService.generateCustomCertificate(
          certificateTitle: widget.certificateType.title,
          school: widget.school,
          student: _selectedStudent!,
          className: className,
          additionalNote: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        );
      }

      await action(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesStreamProvider(widget.school.id));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(showBack: true),
              GrBookPageHeader(
                title: widget.certificateType.title,
                subtitle: _selectedStudent == null
                    ? 'Step 1: Select Student'
                    : 'Step 2: Preview & Generate',
              ),
              Expanded(
                child: _selectedStudent == null
                    ? _buildStudentPicker()
                    : _buildAutoFilledPreview(classesAsync.valueOrNull ?? []),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentPicker() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by student name or G.R number...',
              prefixIcon: const Icon(Icons.search, color: GrBookTheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Student>>(
            stream: ref.read(studentRepositoryProvider).watchGlobalSearch(
                  schoolId: widget.school.id,
                  queryText: _searchQuery,
                ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final students = snapshot.data ?? [];
              if (students.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Type a student name or G.R number above to search.'
                        : 'No students found matching "$_searchQuery".',
                    style: const TextStyle(color: GrBookTheme.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GrBookTheme.borderColor),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: GrBookTheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: GrBookTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('G.R: ${s.grNumber} • Father: ${s.fatherName ?? '-'}', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: GrBookTheme.primary),
                      onTap: () => setState(() => _selectedStudent = s),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutoFilledPreview(List<SchoolClass> classes) {
    final s = _selectedStudent!;
    final matchedClass = classes.where((c) => c.id == s.classId).firstOrNull;
    final className = matchedClass?.displayName ?? 'Class';
    final dateFormat = DateFormat('dd-MM-yyyy');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Change student banner
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Student Information (Auto-Filled):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.textSecondary)),
            TextButton.icon(
              onPressed: () => setState(() => _selectedStudent = null),
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Change Student'),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Auto-Filled Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GrBookTheme.borderColor),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              _infoRow('Student Name', s.studentName),
              _infoRow('G.R Number', s.grNumber),
              _infoRow('Class', className),
              _infoRow('Father Name', s.fatherName ?? '-'),
              _infoRow('Date of Birth', dateFormat.format(s.dateOfBirth)),
              _infoRow('Date of Admission', dateFormat.format(s.dateOfAdmission)),
              _infoRow('Father CNIC', s.fatherCnic ?? '-'),
              _infoRow('B-Form Number', s.bFormNumber ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Additional Remarks Field
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GrBookTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Additional Remarks / Note (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Enter any special conduct note or leaving reason...',
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        if (_isGenerating)
          const Center(child: CircularProgressIndicator())
        else ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: GrBookTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _generateAndExecute((file) async {
              await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
            }, className: className),
            icon: const Icon(Icons.print_rounded),
            label: const Text('Print / Preview PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: GrBookTheme.primaryDark,
              side: const BorderSide(color: GrBookTheme.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.white,
            ),
            onPressed: () => _generateAndExecute((file) async {
              await Share.shareXFiles([XFile(file.path)], text: '${widget.certificateType.title} - ${s.studentName}');
            }, className: className),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share PDF Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: GrBookTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: GrBookTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
