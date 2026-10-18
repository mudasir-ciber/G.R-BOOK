import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../features/students/widgets/photo_picker_sheet.dart';
import '../services/gallery_saver_service.dart';
import 'gallery_save_success_dialog.dart';

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

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late File? _currentFile;
  late String? _currentNetworkUrl;
  late Uint8List? _currentMemoryBytes;
  bool _isSaving = false;

  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;
  Offset _doubleTapPosition = Offset.zero;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
    _currentNetworkUrl = widget.networkUrl;
    _currentMemoryBytes = widget.memoryBytes;

    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() => _currentScale = scale);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateToMatrix(Matrix4 target) {
    _animation?.removeListener(_animationListener);
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.reset();
    _animation!.addListener(_animationListener);
    _animationController.forward();
  }

  void _animationListener() {
    if (_animation != null) {
      _transformationController.value = _animation!.value;
    }
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.25) {
      // Animate back to original scale
      _animateToMatrix(Matrix4.identity());
    } else {
      // Zoom in to 3.0x focused on tapped point
      const targetScale = 3.0;
      final tapPos = _doubleTapPosition;
      final newX = -tapPos.dx * (targetScale - 1);
      final newY = -tapPos.dy * (targetScale - 1);

      final targetMatrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0)
        ..setTranslationRaw(newX, newY, 0.0);

      _animateToMatrix(targetMatrix);
    }
  }

  void _zoomBy(double factor) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(1.0, 10.0);

    if (targetScale <= 1.05) {
      _animateToMatrix(Matrix4.identity());
      return;
    }

    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);

    final translation = currentMatrix.getTranslation();
    final newX = center.dx - (center.dx - translation.x) * (targetScale / currentScale);
    final newY = center.dy - (center.dy - translation.y) * (targetScale / currentScale);

    final targetMatrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0)
      ..setTranslationRaw(newX, newY, 0.0);

    _animateToMatrix(targetMatrix);
  }

  void _resetZoom() {
    _animateToMatrix(Matrix4.identity());
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
        GallerySaveSuccessDialog.show(
          context,
          title: 'Saved to Gallery!',
          message: 'Image successfully saved in Pictures/GR_Book',
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
      _resetZoom();
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
        backgroundColor: Colors.black.withValues(alpha: 0.85),
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
          // 1. Gesture detector + InteractiveViewer for pinch-to-zoom and double-tap zoom
          GestureDetector(
            onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.8,
              maxScale: 10.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              clipBehavior: Clip.none,
              child: SizedBox.expand(
                child: Center(
                  child: _buildImageWidget(),
                ),
              ),
            ),
          ),

          // 2. Floating On-Screen Zoom Controls (Right side)
          Positioned(
            right: 16,
            bottom: widget.onImageChanged != null ? 100 : 36,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom In Button (+)
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      tooltip: 'Zoom In',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () => _zoomBy(1.5),
                    ),
                    const SizedBox(height: 2),

                    // Current Scale Badge (Tapping also resets)
                    InkWell(
                      onTap: _resetZoom,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        child: Text(
                          '${_currentScale.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: _currentScale > 1.1 ? const Color(0xFF4ADE80) : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Zoom Out Button (-)
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 24),
                      tooltip: 'Zoom Out',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () => _zoomBy(1 / 1.5),
                    ),

                    // Reset Button (visible when zoomed in)
                    if (_currentScale > 1.1) ...[
                      const Divider(color: Colors.white24, height: 8, indent: 6, endIndent: 6),
                      IconButton(
                        icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFF4ADE80), size: 22),
                        tooltip: 'Reset Zoom (1.0x)',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: _resetZoom,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Bar for Change Image (if callback provided)
          if (widget.onImageChanged != null)
            Positioned(
              left: 20,
              right: 80, // Leaves room for the zoom controls on the right
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
    } else if (_currentMemoryBytes != null) {
      return Image.memory(_currentMemoryBytes!, fit: BoxFit.contain);
    } else if (_currentNetworkUrl != null && _currentNetworkUrl!.isNotEmpty) {
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
    } else {
      return const Center(
        child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 64),
      );
    }
  }
}
