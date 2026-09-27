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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildContent(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final file = await showPhotoPickerSheet(context);
              if (file != null) onPicked(file);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: GrBookTheme.primaryDark,
              side: const BorderSide(color: GrBookTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 16),
            label: const Text('Add Photo', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (photo == null || !photo!.hasContent) {
      return const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 32));
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
