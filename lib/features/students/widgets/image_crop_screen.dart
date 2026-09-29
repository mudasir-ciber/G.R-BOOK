import 'dart:io';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme.dart';

/// Screen allowing the user to crop, rotate, and adjust an image before saving.
class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.imageFile,
    this.initialAspectRatio,
  });

  final File imageFile;
  final double? initialAspectRatio;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  late final CropController _cropController;
  bool _isProcessing = false;
  double? _selectedRatio;

  @override
  void initState() {
    super.initState();
    _selectedRatio = widget.initialAspectRatio;
    _cropController = CropController(
      aspectRatio: _selectedRatio,
      defaultCrop: const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9),
    );
  }

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _onSaveCropped() async {
    setState(() => _isProcessing = true);
    try {
      final ui.Image bitmap = await _cropController.croppedBitmap(
        quality: FilterQuality.high,
      );

      final byteData = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Could not encode cropped image.');
      }

      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(targetPath);
      await croppedFile.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      Navigator.of(context).pop(croppedFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _setAspectRatio(double? ratio) {
    setState(() {
      _selectedRatio = ratio;
      _cropController.aspectRatio = ratio;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Crop Photo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: GrBookTheme.primary),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _onSaveCropped,
                icon: const Icon(Icons.check, color: GrBookTheme.primaryLight, size: 22),
                label: const Text(
                  'Done',
                  style: TextStyle(
                    color: GrBookTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Crop Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CropImage(
                  controller: _cropController,
                  image: Image.file(widget.imageFile),
                  paddingSize: 16,
                  alwaysMove: true,
                ),
              ),
            ),

            // Controls Bar
            Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Aspect Ratio Options
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RatioChip(
                          label: 'Free',
                          isSelected: _selectedRatio == null,
                          onTap: () => _setAspectRatio(null),
                        ),
                        const SizedBox(width: 8),
                        _RatioChip(
                          label: '1:1 (Square)',
                          isSelected: _selectedRatio == 1.0,
                          onTap: () => _setAspectRatio(1.0),
                        ),
                        const SizedBox(width: 8),
                        _RatioChip(
                          label: '3:4 (Portrait)',
                          isSelected: _selectedRatio == 3 / 4,
                          onTap: () => _setAspectRatio(3 / 4),
                        ),
                        const SizedBox(width: 8),
                        _RatioChip(
                          label: '4:3',
                          isSelected: _selectedRatio == 4 / 3,
                          onTap: () => _setAspectRatio(4 / 3),
                        ),
                        const SizedBox(width: 8),
                        _RatioChip(
                          label: '16:9',
                          isSelected: _selectedRatio == 16 / 9,
                          onTap: () => _setAspectRatio(16 / 9),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Rotation Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: 'Rotate Left',
                        icon: const Icon(Icons.rotate_left, color: Colors.white, size: 28),
                        onPressed: () => _cropController.rotateLeft(),
                      ),
                      IconButton(
                        tooltip: 'Rotate Right',
                        icon: const Icon(Icons.rotate_right, color: Colors.white, size: 28),
                        onPressed: () => _cropController.rotateRight(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatioChip extends StatelessWidget {
  const _RatioChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? GrBookTheme.primary : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade300,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
