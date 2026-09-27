import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';

/// Shows a Camera / Gallery choice and returns the picked file, or null
/// if the user cancelled. Used for all 4 photo slots (requirement #9).
Future<File?> showPhotoPickerSheet(BuildContext context) async {
  final picker = ImagePicker();

  return showModalBottomSheet<File?>(
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
                title: const Text('Take Photo'),
                onTap: () async {
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop(picked == null ? null : File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: GrBookTheme.primary),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop(picked == null ? null : File(picked.path));
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
