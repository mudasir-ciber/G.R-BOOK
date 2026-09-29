import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';
import 'image_crop_screen.dart';

/// Shows a Camera / Gallery choice, then automatically routes to [ImageCropScreen]
/// so the user can crop, adjust, or rotate the image before returning.
Future<File?> showPhotoPickerSheet(BuildContext context, {double? preferredAspectRatio}) async {
  final picker = ImagePicker();

  final source = await showModalBottomSheet<ImageSource?>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: GrBookTheme.primary),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: GrBookTheme.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return null;

  final picked = await picker.pickImage(source: source, imageQuality: 95);
  if (picked == null) return null;

  if (!context.mounted) return null;

  // Open Image Crop screen
  final cropped = await Navigator.of(context).push<File?>(
    MaterialPageRoute(
      builder: (_) => ImageCropScreen(
        imageFile: File(picked.path),
        initialAspectRatio: preferredAspectRatio,
      ),
    ),
  );

  return cropped;
}
