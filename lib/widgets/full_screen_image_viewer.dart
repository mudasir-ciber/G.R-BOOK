import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../features/students/widgets/photo_picker_sheet.dart';
import '../services/gallery_saver_service.dart';

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    this.file,
    this.networkUrl,
    this.memoryBytes,
    required this.title,
    this.onImageChanged,
    this.aspectRatio,
  });

  final File? file;
  final String? networkUrl;
  final Uint8List? memoryBytes;
  final String title;
  final ValueChanged<File>? onImageChanged;
  final double? aspectRatio;

  static Future<void> open(
    BuildContext context, {
    File? file,
    String? networkUrl,
    Uint8List? memoryBytes,
    required String title,
    ValueChanged<File>? onImageChanged,
    double? aspectRatio,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          file: file,
          networkUrl: networkUrl,
          memoryBytes: memoryBytes,
          title: title,
          onImageChanged: onImageChanged,
          aspectRatio: aspectRatio,
        ),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late File? _currentFile;
  late String? _currentNetworkUrl;
  late Uint8List? _currentMemoryBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
    _currentNetworkUrl = widget.networkUrl;
    _currentMemoryBytes = widget.memoryBytes;
  }

  Future<Uint8List?> _resolveBytes() async {
    if (_currentMemoryBytes != null) return _currentMemoryBytes;
    if (_currentFile != null && await _currentFile!.exists()) {
      return await _currentFile!.readAsBytes();
    }
    return null;
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _resolveBytes();
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read image data.')),
        );
        return;
      }

      final fileName = 'GR_Book_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ok = await GallerySaverService.saveImageToGallery(bytes: bytes, fileName: fileName);

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F9D58),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Image saved to Mobile Gallery in "Pictures/GR_Book"')),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image to Gallery.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeImage() async {
    final newFile = await showPhotoPickerSheet(context, preferredAspectRatio: widget.aspectRatio);
    if (newFile != null) {
      setState(() {
        _currentFile = newFile;
        _currentNetworkUrl = null;
        _currentMemoryBytes = null;
      });
      widget.onImageChanged?.call(newFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F9D58),
            content: Text('Image updated successfully.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveToGallery,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            label: const Text(
              'Save This Image',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Centered zoomable image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: _buildImageWidget(),
            ),
          ),

          // Bottom Bar for Change Image (if callback provided)
          if (widget.onImageChanged != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: SafeArea(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: GrBookTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _changeImage,
                  icon: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Change This Image',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_currentFile != null) {
      return Image.file(_currentFile!, fit: BoxFit.contain);
    }
    if (_currentMemoryBytes != null) {
      return Image.memory(_currentMemoryBytes!, fit: BoxFit.contain);
    }
    if (_currentNetworkUrl != null && _currentNetworkUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _currentNetworkUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 64),
    );
  }
}
