import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/data_tools_providers.dart';
import '../../providers/photo_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/complaint_repository.dart';
import '../../repositories/student_photo_repository.dart';
import '../../services/document_share_service.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../students/widgets/photo_picker_sheet.dart';

class StudentComplaintScreen extends ConsumerStatefulWidget {
  const StudentComplaintScreen({super.key, this.preselectedStudent});

  final Student? preselectedStudent;

  @override
  ConsumerState<StudentComplaintScreen> createState() => _StudentComplaintScreenState();
}

class _StudentComplaintScreenState extends ConsumerState<StudentComplaintScreen> {
  Student? _student;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final _complaintController = TextEditingController();
  File? _attachedPhoto;

  @override
  void initState() {
    super.initState();
    _student = widget.preselectedStudent;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await showPhotoPickerSheet(context);
    if (file != null) {
      setState(() => _attachedPhoto = file);
    }
  }

  void _onProceedToPreview(School school, String className) {
    final text = _complaintController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your complaint or note first.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ComplaintPreviewScreen(
          school: school,
          student: _student!,
          className: className,
          complaintText: text,
          attachedPhoto: _attachedPhoto,
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
              GrBookPageHeader(
                title: 'Student Complaint',
                subtitle: _student == null
                    ? 'Step 1: Select Student'
                    : 'Step 2: Write Note & Attach Picture',
              ),
              Expanded(
                child: schoolAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (school) {
                    if (school == null) {
                      return const Center(child: Text('No school profile found.'));
                    }

                    if (_student == null) {
                      return _buildStudentSelector(school.id);
                    }

                    final classesAsync = ref.watch(classesStreamProvider(school.id));
                    final classes = classesAsync.valueOrNull ?? [];
                    final matchedClass = classes.where((c) => c.id == _student!.classId).firstOrNull;
                    final className = matchedClass?.displayName ?? 'Class';

                    return _buildComplaintForm(school, className);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSelector(String schoolId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search student name or G.R number...',
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
                  schoolId: schoolId,
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
                        ? 'Type a student name or G.R number to select.'
                        : 'No students found matching "$_searchQuery".',
                    style: const TextStyle(color: GrBookTheme.textSecondary),
                  ),
                );
              }

              final classesAsync = ref.watch(classesStreamProvider(schoolId));
              final classes = classesAsync.valueOrNull ?? [];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  final matched = classes.where((c) => c.id == s.classId).firstOrNull;
                  final className = matched?.displayName ?? 'Class';

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
                      subtitle: Text('G.R: ${s.grNumber} • Class: $className\nParent: ${s.fatherName ?? '-'} • Phone: ${s.phoneNumber ?? '-'}', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: GrBookTheme.primary),
                      onTap: () => setState(() => _student = s),
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

  Widget _buildComplaintForm(School school, String className) {
    final s = _student!;
    final photoAsync = ref.watch(studentPhotosProvider(s.id));
    final studentPhoto = photoAsync.valueOrNull?[PhotoType.student];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Change student link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Selected Student Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.textSecondary)),
            if (widget.preselectedStudent == null)
              TextButton.icon(
                onPressed: () => setState(() => _student = null),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Change Student'),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Student Info Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GrBookTheme.borderColor),
            boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildAvatar(studentPhoto),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: GrBookTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('G.R No: ${s.grNumber}  •  Class: $className', style: const TextStyle(fontSize: 12.5, color: GrBookTheme.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Parent: ${s.fatherName ?? '-'}  •  Phone: ${s.phoneNumber ?? 'Not provided'}', style: const TextStyle(fontSize: 12, color: GrBookTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Complaint Multiline Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GrBookTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Complaint / Notice Details *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _complaintController,
                maxLines: 5,
                style: const TextStyle(fontSize: 14, color: GrBookTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Write your complaint or note here...\n(e.g. attendance issue, homework concern, discipline notice, parent meeting request)',
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Attached JPG Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GrBookTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attach Picture (Optional JPG):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.textPrimary)),
                  if (_attachedPhoto != null)
                    TextButton(
                      onPressed: () => setState(() => _attachedPhoto = null),
                      child: const Text('REMOVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_attachedPhoto != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_attachedPhoto!, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('REPLACE PHOTO'),
                  ),
                ),
              ] else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GrBookTheme.primary,
                    side: const BorderSide(color: GrBookTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('ADD JPG PICTURE (Camera / Gallery)'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Proceed to Preview Button
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: GrBookTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _onProceedToPreview(school, className),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Preview Note & Send', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildAvatar(StudentPhoto? photo) {
    if (photo == null || !photo.hasContent) {
      return Center(
        child: Text(
          _student!.studentName.isNotEmpty ? _student!.studentName[0].toUpperCase() : '?',
          style: const TextStyle(color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }
    if (photo.localPath != null) {
      return Image.file(File(photo.localPath!), fit: BoxFit.cover);
    }
    return FutureBuilder<String>(
      future: ref.read(studentPhotoRepositoryProvider).signedUrlFor(photo),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return CachedNetworkImage(imageUrl: snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}

class _ComplaintPreviewScreen extends ConsumerStatefulWidget {
  const _ComplaintPreviewScreen({
    required this.school,
    required this.student,
    required this.className,
    required this.complaintText,
    required this.attachedPhoto,
  });

  final School school;
  final Student student;
  final String className;
  final String complaintText;
  final File? attachedPhoto;

  @override
  ConsumerState<_ComplaintPreviewScreen> createState() => _ComplaintPreviewScreenState();
}

class _ComplaintPreviewScreenState extends ConsumerState<_ComplaintPreviewScreen> {
  bool _isSending = false;

  String _formatMessage() {
    return '''
*School Notice / Complaint*
School: ${widget.school.schoolName}
Student: ${widget.student.studentName} (GR: ${widget.student.grNumber}, Class: ${widget.className})
Parent: ${widget.student.fatherName ?? '-'}

Notice:
${widget.complaintText}

Date: ${DateTime.now().toLocal().toString().split(' ').first}
''';
  }

  Future<void> _shareVia(String channel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Complaint Note'),
        content: Text('Send this complaint note to ${widget.student.fatherName ?? 'parent'} via $channel?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      final msg = _formatMessage();
      final phone = widget.student.phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      String actualMethod = 'Shared via Share';

      if (channel == 'WhatsApp') {
        actualMethod = 'Shared via WhatsApp';
        // Try direct WhatsApp URL or fall back to Share
        final cleanPhone = phone.startsWith('0') ? '92${phone.substring(1)}' : phone;
        final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(msg)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } else {
          final webUri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
          } else {
            if (widget.attachedPhoto != null) {
              await Share.shareXFiles([XFile(widget.attachedPhoto!.path)], text: msg);
            } else {
              await Share.share(msg);
            }
          }
        }
      } else if (channel == 'SMS') {
        actualMethod = 'Shared via SMS';
        final smsUri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': msg});
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          if (widget.attachedPhoto != null) {
            await Share.shareXFiles([XFile(widget.attachedPhoto!.path)], text: msg);
          } else {
            await Share.share(msg);
          }
        }
      } else {
        actualMethod = 'Shared via Share';
        if (widget.attachedPhoto != null) {
          await Share.shareXFiles([XFile(widget.attachedPhoto!.path)], text: msg);
        } else {
          await Share.share(msg);
        }
      }

      // Save complaint history accurately in SQLite database
      await ref.read(complaintRepositoryProvider).createComplaint(
            schoolId: widget.school.id,
            studentId: widget.student.id,
            studentName: widget.student.studentName,
            grNumber: widget.student.grNumber,
            className: widget.className,
            parentName: widget.student.fatherName ?? '-',
            parentMobile: widget.student.phoneNumber ?? '-',
            complaintText: widget.complaintText,
            attachedPhoto: widget.attachedPhoto,
            communicationMethod: actualMethod,
            communicationStatus: 'SENT',
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complaint recorded ($actualMethod).')),
      );

      // Return back to Home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _shareNoteDocument() async {
    await DocumentShareService.showShareOptions(
      context,
      title: 'Share Note Document',
      baseFileName: 'Note_${widget.student.studentName}',
      getPdfFile: () async {
        final pdfService = ref.read(pdfExportServiceProvider);
        return pdfService.generateNoticePdf(
          school: widget.school,
          student: widget.student,
          className: widget.className,
          noticeText: widget.complaintText,
          attachedPhoto: widget.attachedPhoto,
        );
      },
    );

    // Record the note in complaint history
    try {
      await ref.read(complaintRepositoryProvider).createComplaint(
            schoolId: widget.school.id,
            studentId: widget.student.id,
            studentName: widget.student.studentName,
            grNumber: widget.student.grNumber,
            className: widget.className,
            parentName: widget.student.fatherName ?? '-',
            parentMobile: widget.student.phoneNumber ?? '-',
            complaintText: widget.complaintText,
            attachedPhoto: widget.attachedPhoto,
            communicationMethod: 'Shared as PDF/JPG Document',
            communicationStatus: 'SENT',
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Complaint Note Preview')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GrBookTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Student', widget.student.studentName),
                  _row('G.R Number', widget.student.grNumber),
                  _row('Class', widget.className),
                  _row('Parent / Guardian', widget.student.fatherName ?? '-'),
                  _row('Parent Mobile', widget.student.phoneNumber ?? '-'),
                  const Divider(height: 24),
                  const Text('Complaint / Notice Content:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(widget.complaintText, style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, height: 1.4)),
                  if (widget.attachedPhoto != null) ...[
                    const SizedBox(height: 14),
                    const Text('Attached JPG:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.textSecondary)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(widget.attachedPhoto!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isSending)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Primary PDF / JPG document share button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _shareNoteDocument,
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text('Share Note Document (PDF / JPG)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              ),
              const SizedBox(height: 12),

              // WhatsApp button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _shareVia('WhatsApp'),
                icon: const Icon(Icons.chat_outlined, color: Colors.white),
                label: const Text('Share Text via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: GrBookTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _shareVia('SMS'),
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Share via SMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GrBookTheme.primaryDark,
                  side: const BorderSide(color: GrBookTheme.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.white,
                ),
                onPressed: () => _shareVia('Share'),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Other Share Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: GrBookTheme.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: GrBookTheme.textPrimary))),
        ],
      ),
    );
  }
}
