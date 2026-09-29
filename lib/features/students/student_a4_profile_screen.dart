import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/data_tools_providers.dart';
import '../../providers/photo_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/document_share_service.dart';

class StudentA4ProfileScreen extends ConsumerStatefulWidget {
  const StudentA4ProfileScreen({
    super.key,
    required this.student,
    this.schoolClass,
    this.pickedStudentPhoto,
  });

  final Student student;
  final SchoolClass? schoolClass;
  final File? pickedStudentPhoto;

  @override
  ConsumerState<StudentA4ProfileScreen> createState() => _StudentA4ProfileScreenState();
}

class _StudentA4ProfileScreenState extends ConsumerState<StudentA4ProfileScreen> {
  File? _generatedPdfFile;
  bool _isConverting = false;

  Future<Uint8List> _generatePdfBytes() async {
    final school = await ref.read(schoolRepositoryProvider).getLocalSchool();
    final effectiveSchool = school ??
        School(
          id: 'temp',
          schoolName: 'Primary School',
          createdBy: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    Uint8List? photoBytes;
    if (widget.pickedStudentPhoto != null && await widget.pickedStudentPhoto!.exists()) {
      photoBytes = await widget.pickedStudentPhoto!.readAsBytes();
    } else {
      final photosMap = await ref.read(studentPhotosProvider(widget.student.id).future);
      final studentPhoto = photosMap[PhotoType.student];
      if (studentPhoto?.localPath != null) {
        final f = File(studentPhoto!.localPath!);
        if (await f.exists()) {
          photoBytes = await f.readAsBytes();
        }
      }
    }

    final service = ref.read(pdfExportServiceProvider);
    final file = await service.exportStudentProfilePdf(
      school: effectiveSchool,
      student: widget.student,
      className: widget.schoolClass?.displayName ?? 'Class',
      studentPhotoBytes: photoBytes,
    );

    _generatedPdfFile = file;
    return await file.readAsBytes();
  }

  void _shareAsPdf() {
    if (_generatedPdfFile != null) {
      DocumentShareService.sharePdf(
        _generatedPdfFile!,
        text: 'Student Profile (A4) — ${widget.student.studentName}',
      );
    }
  }

  Future<void> _shareAsJpg() async {
    if (_generatedPdfFile == null) return;
    setState(() => _isConverting = true);
    try {
      await DocumentShareService.shareJpg(
        _generatedPdfFile!,
        text: 'Student Profile (A4) — ${widget.student.studentName}',
        outputFileName: 'Profile_${widget.student.grNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing JPG: $e')));
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  Future<void> _saveJpgToGallery() async {
    if (_generatedPdfFile == null) return;
    setState(() => _isConverting = true);
    try {
      await DocumentShareService.saveJpgToGallery(
        context,
        _generatedPdfFile!,
        fileName: 'Profile_${widget.student.grNumber}',
      );
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(
        title: Text(
          '${widget.student.studentName} — A4 Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
            tooltip: 'Share as PDF',
            onPressed: _shareAsPdf,
          ),
          IconButton(
            icon: const Icon(Icons.image_rounded, color: Colors.green),
            tooltip: 'Share as JPG',
            onPressed: _shareAsJpg,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_rounded, color: GrBookTheme.primary),
            tooltip: 'Save JPG to Gallery',
            onPressed: _saveJpgToGallery,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          PdfPreview(
            build: (_) => _generatePdfBytes(),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            dynamicLayout: false,
            previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            actions: [
              PdfPreviewAction(
                icon: const Icon(Icons.share_rounded),
                onPressed: (ctx, build, pageFormat) {
                  if (_generatedPdfFile != null) {
                    DocumentShareService.showShareOptions(
                      context,
                      pdfFile: _generatedPdfFile!,
                      title: 'Student Profile (A4)',
                      studentName: widget.student.studentName,
                    );
                  }
                },
              ),
            ],
          ),
          if (_isConverting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 14),
                    Text('Processing JPG Image...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Share PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _shareAsPdf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.image_rounded, size: 18),
                  label: const Text('Share JPG', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _shareAsJpg,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: GrBookTheme.primary),
                icon: const Icon(Icons.save_alt_rounded, color: Colors.white, size: 20),
                tooltip: 'Save to Gallery',
                onPressed: _saveJpgToGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
