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
    this.photo,
    this.pickedFile,
    required this.onPicked,
    required this.resolveSignedUrl,
  });

  final String label;
  final StudentPhoto? photo;
  final File? pickedFile;
  final ValueChanged<File> onPicked;
  final Future<String> Function(StudentPhoto photo) resolveSignedUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedFile != null || (photo != null && photo!.hasContent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: GrBookTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final file = await showPhotoPickerSheet(context);
            if (file != null) onPicked(file);
          },
          child: Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildContent(),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final file = await showPhotoPickerSheet(context);
              if (file != null) onPicked(file);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF2E4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA3D9B5), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 14, color: GrBookTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    hasImage ? 'Change Photo' : 'Add Photo',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: GrBookTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (pickedFile != null) {
      return Image.file(pickedFile!, fit: BoxFit.cover, width: double.infinity);
    }
    if (photo == null || !photo!.hasContent) {
      return const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 32),
      );
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
