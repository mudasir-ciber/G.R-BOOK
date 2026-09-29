import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../repositories/student_photo_repository.dart';
import 'photo_picker_sheet.dart';

class DocumentPhotoTile extends StatelessWidget {
  const DocumentPhotoTile({
    super.key,
    required this.label,
    required this.photo,
    required this.onPicked,
    required this.resolveSignedUrl,
  });

  final String label;
  final StudentPhoto? photo;
  final ValueChanged<File> onPicked;
  final Future<String> Function(StudentPhoto photo) resolveSignedUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: GrBookTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          height: 85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildContent(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: FilledButton.icon(
            onPressed: () async {
              final file = await showPhotoPickerSheet(context);
              if (file != null) onPicked(file);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDCF2E4),
              foregroundColor: GrBookTheme.primaryDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 16, color: GrBookTheme.primary),
            label: const Text('Add Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (photo == null || !photo!.hasContent) {
      return const Center(child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 32));
    }
    if (photo!.localPath != null) {
      return Image.file(File(photo!.localPath!), fit: BoxFit.cover, width: double.infinity);
    }
    return FutureBuilder<String>(
      future: resolveSignedUrl(photo!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        return CachedNetworkImage(imageUrl: snapshot.data!, fit: BoxFit.cover, width: double.infinity);
      },
    );
  }
}
