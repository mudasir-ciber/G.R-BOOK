import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../repositories/student_photo_repository.dart';
import 'photo_picker_sheet.dart';

class ProfilePhotoAvatar extends StatelessWidget {
  const ProfilePhotoAvatar({
    super.key,
    required this.photo,
    required this.fallbackInitial,
    required this.onPicked,
    required this.resolveSignedUrl,
    this.radius = 52,
  });

  final StudentPhoto? photo;
  final String fallbackInitial;
  final ValueChanged<File> onPicked;
  final Future<String> Function(StudentPhoto photo) resolveSignedUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: GrBookTheme.primary.withOpacity(0.10),
          child: ClipOval(
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: _buildImageContent(),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final file = await showPhotoPickerSheet(context);
              if (file != null) onPicked(file);
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: GrBookTheme.primary,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (photo == null || !photo!.hasContent) {
      return Center(
        child: Text(
          fallbackInitial,
          style: TextStyle(fontSize: radius * 0.6, color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold),
        ),
      );
    }
    if (photo!.localPath != null) {
      return Image.file(File(photo!.localPath!), fit: BoxFit.cover);
    }
    // No local copy (e.g. viewing on a different device after sync) —
    // fetch via a private signed URL only, never a public one.
    return FutureBuilder<String>(
      future: resolveSignedUrl(photo!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        return CachedNetworkImage(imageUrl: snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
