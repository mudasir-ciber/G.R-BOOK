import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/master_admin_config.dart';
import '../../core/theme.dart';
import '../../widgets/gr_book_ui_components.dart';
import 'auth_providers.dart';
import 'auth_service.dart';

/// 3-Step Dedicated Password Recovery:
/// Step 1: Enter Email & Request 6-digit OTP code
/// Step 2: Verify 6-digit OTP code
/// Step 3: Set New Password & Confirm Password
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _currentStep = 1;

  // Step 1 controllers
  final _emailController = TextEditingController();
  final _step1FormKey = GlobalKey<FormState>();

  // Step 2 controllers
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _resendCountdown = 60;
  Timer? _timer;

  // Step 3 controllers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _step3FormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // --- Step 1: Send Code ---
  Future<void> _handleSendCode() async {
    if (!_step1FormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    try {
      await ref.read(authServiceProvider).sendPasswordResetOtp(email);
      _startCountdown();
      if (!mounted) return;
      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to send code: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Step 2: Verify Code ---
  Future<void> _handleVerifyCode() async {
    final token = _otpControllers.map((c) => c.text.trim()).join();
    if (token.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    try {
      await ref.read(authServiceProvider).verifyPasswordResetOtp(
            email: email,
            token: token,
          );
      if (!mounted) return;
      setState(() {
        _currentStep = 3;
        _isLoading = false;
      });
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Verification error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Step 3: Update Password ---
  Future<void> _handleUpdatePassword() async {
    if (!_step3FormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newPass = _passwordController.text;
    try {
      await ref.read(authServiceProvider).updatePassword(newPass);
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF0F9D58), size: 28),
              SizedBox(width: 10),
              Text('Password Updated!'),
            ],
          ),
          content: const Text(
            'Your password has been changed successfully. You can now log in with your new password.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Back to Login
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      );
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Could not update password: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;
    setState(() => _errorMessage = null);
    try {
      await ref.read(authServiceProvider).sendPasswordResetOtp(_emailController.text.trim());
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F9D58),
          content: Text('A new verification code has been sent to your email.'),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Resend error: $e');
    }
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Progress Tracker
              Row(
                children: [
                  _buildStepIndicator(1, 'Email', _currentStep >= 1, _currentStep == 1),
                  Expanded(child: Container(height: 2, color: _currentStep >= 2 ? GrBookTheme.primary : borderColor)),
                  _buildStepIndicator(2, 'Code', _currentStep >= 2, _currentStep == 2),
                  Expanded(child: Container(height: 2, color: _currentStep >= 3 ? GrBookTheme.primary : borderColor)),
                  _buildStepIndicator(3, 'Password', _currentStep >= 3, _currentStep == 3),
                ],
              ),
              const SizedBox(height: 28),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B151A) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.red.shade800 : Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: isDark ? Colors.red.shade200 : Colors.red.shade700, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Card Container
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
                child: _buildCurrentStepContent(textPrimary, textSecondary, borderColor, isDark),
              ),
              const SizedBox(height: 24),

              // WhatsApp Help for Phone Number Users
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      'Account created with a mobile number?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'If you do not have an email address, contact Master Admin Mudasir Ahmed for a direct password reset.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('Contact Founder on WhatsApp'),
                      onPressed: () async {
                        final msg = Uri.encodeComponent(
                          'Assalam-o-Alaikum Mudasir Bhai, I forgot my G.R. BOOK password. Please help me reset my account password.',
                        );
                        final uri = Uri.parse('https://wa.me/${MasterAdminConfig.founderPhone}?text=$msg');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isDone, bool isCurrent) {
    Color bg = isCurrent
        ? GrBookTheme.primary
        : (isDone ? const Color(0xFF0F9D58) : Colors.grey.shade400);
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: bg,
          child: Text(
            '$step',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? GrBookTheme.primary : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent(
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    bool isDark,
  ) {
    switch (_currentStep) {
      case 1:
        return Form(
          key: _step1FormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Registered Email',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your registered Gmail address. We will send you a 6-digit verification code.',
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textPrimary),
                decoration: const InputDecoration(
                  hintText: 'name@gmail.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded, color: GrBookTheme.primary, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              GrBookGradientButton(
                text: 'Send Code',
                isLoading: _isLoading,
                onPressed: _handleSendCode,
                trailingIcon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter 6-Digit Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'We sent a 6-digit verification code to ${_emailController.text.trim()}.',
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // 6 OTP Input Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: GrBookTheme.primary, width: 2),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                      if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                        _handleVerifyCode();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Resend timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_resendCountdown > 0)
                  Text(
                    'Resend code in $_resendCountdown seconds',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  )
                else
                  TextButton(
                    onPressed: _resendCode,
                    child: const Text('Resend Code', style: TextStyle(fontWeight: FontWeight.bold, color: GrBookTheme.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            GrBookGradientButton(
              text: 'Verify Code',
              isLoading: _isLoading,
              onPressed: _handleVerifyCode,
              trailingIcon: Icons.check_circle_outline_rounded,
            ),
          ],
        );

      case 3:
      default:
        return Form(
          key: _step3FormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set New Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a strong new password for your account.',
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),

              // New Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: GrBookTheme.primary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 14),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: GrBookTheme.primary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 22),

              GrBookGradientButton(
                text: 'Update Password',
                isLoading: _isLoading,
                onPressed: _handleUpdatePassword,
                trailingIcon: Icons.save_rounded,
              ),
            ],
          ),
        );
    }
  }
}
