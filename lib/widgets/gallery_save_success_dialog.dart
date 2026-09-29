import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Animated mid-screen dialog shown when a document or image is successfully
/// saved to the user's mobile gallery. Auto-dismisses after 2.5 seconds or on tap.
class GallerySaveSuccessDialog extends StatefulWidget {
  const GallerySaveSuccessDialog({
    super.key,
    this.title = 'Saved to Gallery!',
    this.message = 'Saved in Pictures/GR_Book folder',
    this.autoDismissDuration = const Duration(milliseconds: 2500),
  });

  final String title;
  final String message;
  final Duration autoDismissDuration;

  /// Static helper to trigger the dialog easily from any screen or service.
  static Future<void> show(
    BuildContext context, {
    String title = 'Saved to Gallery!',
    String message = 'Saved in Pictures/GR_Book folder',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => GallerySaveSuccessDialog(
        title: title,
        message: message,
      ),
    );
  }

  @override
  State<GallerySaveSuccessDialog> createState() => _GallerySaveSuccessDialogState();
}

class _GallerySaveSuccessDialogState extends State<GallerySaveSuccessDialog>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    _dismissTimer = Timer(widget.autoDismissDuration, () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);
    final cardBg = isDark ? const Color(0xFF18261E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E4536) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Download Success GIF
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/save_success.gif',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981), width: 3),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),

              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GrBookTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
