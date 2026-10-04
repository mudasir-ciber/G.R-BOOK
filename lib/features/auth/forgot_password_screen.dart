import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/master_admin_config.dart';
import '../../core/theme.dart';

/// Password Recovery Screen:
/// Password recovery is handled directly via Master Admin Mudasir Ahmed
/// for verified identity, security, and immediate assistance.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestWhatsAppReset() async {
    if (!_formKey.currentState!.validate()) return;
    final cleanPhone = _phoneController.text.trim();
    final phoneText = cleanPhone.isNotEmpty ? ' ($cleanPhone)' : '';
    final msg = Uri.encodeComponent(
      'Assalam-o-Alaikum Mudasir Bhai, my registered mobile number is$phoneText. I forgot my G.R. BOOK password. Please reset my account password.',
    );
    final uri = Uri.parse('https://wa.me/${MasterAdminConfig.founderPhone}?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please call Admin directly.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp. Please call Admin directly.')),
      );
    }
  }

  Future<void> _callAdmin() async {
    final uri = Uri.parse('tel:+${MasterAdminConfig.founderPhone}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start call. Dial 0336-8456907 manually.')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);
    final cardBg = GrBookTheme.getCardBackground(context);
    final borderColor = GrBookTheme.getBorderColor(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Card Container
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon & Title
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F9D58).withValues(alpha: 0.12),
                            border: Border.all(
                              color: const Color(0xFF0F9D58).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_reset_rounded,
                              size: 36,
                              color: Color(0xFF0F9D58),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Password Recovery',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Account passwords are reset directly by Master Admin Mudasir Ahmed for account security.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Input Label
                      Text(
                        'Enter Registered Mobile Number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Phone input with Pakistani format auto-prefix
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: InputDecoration(
                          hintText: '923394865097',
                          prefixIcon: const Icon(
                            Icons.phone_android_rounded,
                            color: Color(0xFF0F9D58),
                            size: 20,
                          ),
                          helperText: 'Must start with 92 (12 digits, e.g. 923394865097)',
                          helperStyle: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                        onChanged: (val) {
                          if (val.startsWith('0') && val.length >= 2) {
                            final converted = '92${val.substring(1)}';
                            if (converted.length <= 12) {
                              _phoneController.value = TextEditingValue(
                                text: converted,
                                selection: TextSelection.collapsed(offset: converted.length),
                              );
                            }
                          }
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Mobile number is required';
                          }
                          final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                          if (!digits.startsWith('92')) {
                            return 'Mobile number must start with 92 (e.g. 923394865097)';
                          }
                          if (digits.length < 12) {
                            return 'Invalid number. Must be exactly 12 digits (e.g. 923394865097)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      // Request on WhatsApp Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const _WhatsAppBubbleIcon(size: 20),
                        label: const Text(
                          'Request Reset on WhatsApp',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _requestWhatsAppReset,
                      ),
                      const SizedBox(height: 12),

                      // Direct Phone Call Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.phone_forwarded_rounded, size: 20, color: Color(0xFF0F9D58)),
                        label: const Text(
                          'Call Mudasir Ahmed: 0336-8456907',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: _callAdmin,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // How It Works Guide Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: GrBookTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'How Password Reset Works',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildStepRow('1', 'Enter your registered mobile number above and tap WhatsApp or Call.', textSecondary),
                    const SizedBox(height: 6),
                    _buildStepRow('2', 'Master Admin Mudasir Ahmed will verify your account in the Portal.', textSecondary),
                    const SizedBox(height: 6),
                    _buildStepRow('3', 'Your password will be reset instantly and provided to you.', textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Back to Login Button
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 1, right: 8),
          decoration: BoxDecoration(
            color: GrBookTheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: GrBookTheme.primary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: textColor, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _WhatsAppBubbleIcon extends StatelessWidget {
  final double size;

  const _WhatsAppBubbleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: const _WhatsAppBubblePainter(),
          ),
          Transform.rotate(
            angle: -0.35,
            child: Icon(
              Icons.phone,
              color: Colors.white,
              size: size * 0.52,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppBubblePainter extends CustomPainter {
  const _WhatsAppBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.46;

    final greenPaint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bubblePath = Path();
    bubblePath.addOval(Rect.fromCircle(center: center, radius: radius));

    final tailPath = Path()
      ..moveTo(w * 0.22, h * 0.70)
      ..lineTo(w * 0.05, h * 0.95)
      ..lineTo(w * 0.42, h * 0.86)
      ..close();

    bubblePath.addPath(tailPath, Offset.zero);
    canvas.drawPath(bubblePath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
