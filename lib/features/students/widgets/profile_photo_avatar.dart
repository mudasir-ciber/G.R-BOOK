import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../repositories/student_photo_repository.dart';
import '../../../widgets/full_screen_image_viewer.dart';
import 'photo_picker_sheet.dart';

class ProfilePhotoAvatar extends StatelessWidget {
  const ProfilePhotoAvatar({
    super.key,
    this.photo,
    this.pickedFile,
    required this.fallbackInitial,
    required this.onPicked,
    required this.resolveSignedUrl,
    this.radius = 48,
  });

  final StudentPhoto? photo;
  final File? pickedFile;
  final String fallbackInitial;
  final ValueChanged<File> onPicked;
  final Future<String> Function(StudentPhoto photo) resolveSignedUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () async {
            final hasImage = pickedFile != null || (photo != null && photo!.hasContent);
            if (hasImage) {
              File? localFile = pickedFile;
              if (localFile == null && photo?.localPath != null) {
                final f = File(photo!.localPath!);
                if (await f.exists()) localFile = f;
              }
              String? netUrl;
              if (localFile == null && photo != null) {
                try {
                  netUrl = await resolveSignedUrl(photo!);
                } catch (_) {}
              }
              if (!context.mounted) return;
              await FullScreenImageViewer.open(
                context,
                file: localFile,
                networkUrl: netUrl,
                title: 'Student Profile Picture',
                onImageChanged: onPicked,
                aspectRatio: 1.0,
              );
            } else {
              final file = await showPhotoPickerSheet(context, preferredAspectRatio: 1.0);
              if (file != null) onPicked(file);
            }
          },
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImageContent(),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final file = await showPhotoPickerSheet(context, preferredAspectRatio: 1.0);
              if (file != null) onPicked(file);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GrBookTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (pickedFile != null) {
      return Image.file(pickedFile!, fit: BoxFit.cover);
    }
    if (photo == null || !photo!.hasContent) {
      return const Center(
        child: Icon(Icons.person_rounded, size: 52, color: Color(0xFF94A3B8)),
      );
    }
    if (photo!.localPath != null) {
      return Image.file(File(photo!.localPath!), fit: BoxFit.cover);
    }
    return FutureBuilder<String>(
      future: resolveSignedUrl(photo!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        return CachedNetworkImage(imageUrl: snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
