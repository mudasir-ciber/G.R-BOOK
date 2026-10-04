import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../main.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_coordinator.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../security/access_control_gate.dart';
import '../security/app_lock_gate.dart';
import 'auth_providers.dart';
import 'auth_service.dart';
import 'google_complete_profile_screen.dart';
import 'verify_email_otp_screen.dart';

/// Screen 2: Create Account Page matching reference UI image 2 exactly.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // RULE: Online connection is strictly required for creating an account!
    final isOnline = await ref.read(connectivityServiceProvider).isOnline();
    if (!isOnline) {
      setState(() {
        _errorMessage = 'An internet connection is required to create an account. Please turn on Mobile Data or Wi-Fi.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final mobile = _mobileController.text.trim();
      final password = _passwordController.text;

      final result = await auth.createAccount(
        fullName: fullName,
        email: email,
        mobileNumber: mobile,
        password: password,
      );

      if (!mounted) return;

      if (result.status == AuthAccountStatus.requiresEmailOtp) {
        // Go to Gmail OTP Verification Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyEmailOtpScreen(
              email: result.email ?? email,
              fullName: fullName,
            ),
          ),
        );
        return;
      }

      // Route through AccessControlGate to enforce Master Admin Approval!
      ref.read(appUnlockedProvider.notifier).state = true;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AppLockGate(
            child: SyncCoordinator(
              child: AccessControlGate(
                child: SchoolGate(),
              ),
            ),
          ),
        ),
        (route) => false,
      );
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    final isOnline = await ref.read(connectivityServiceProvider).isOnline();
    if (!isOnline) {
      setState(() {
        _errorMessage = 'An internet connection is required to continue with Google.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(authServiceProvider).handleGoogleSignIn();
      if (result == null) {
        // User dismissed Google account chooser
        return;
      }

      if (!mounted) return;

      if (result.outcome == GoogleSignInOutcome.needsProfileCompletion) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GoogleCompleteProfileScreen(
              googleEmail: result.email,
              googleDisplayName: result.displayName,
              idToken: result.idToken,
              accessToken: result.accessToken,
            ),
          ),
        );
      } else {
        ref.read(appUnlockedProvider.notifier).state = true;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const AppLockGate(
              child: SyncCoordinator(
                child: AccessControlGate(
                  child: SchoolGate(),
                ),
              ),
            ),
          ),
          (route) => false,
        );
      }
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Google sign-up error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      body: Container(
        decoration: BoxDecoration(
          gradient: GrBookTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar with Back Button
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black26 : const Color(0x0A000000),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GrBookTheme.primary, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),

                // Illustration Header
                Center(
                  child: Image.asset(
                    'assets/images/auth_header.png',
                    width: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Column(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 48, color: GrBookTheme.primary),
                        const SizedBox(height: 6),
                        Text(
                          'G.R. Book',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Rounded Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    border: isDark ? Border(top: BorderSide(color: borderColor)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black38 : const Color(0x140F7A42),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create New Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill in your details to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

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
                          const SizedBox(height: 14),
                        ],

                        // 1. Full Name
                        TextFormField(
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(color: textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline, color: GrBookTheme.primary, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Full Name is required';
                            if (v.trim().length < 3) return 'Full Name must be at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 2. Email Address
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Email Address (e.g. user@gmail.com)',
                            prefixIcon: Icon(Icons.email_outlined, color: GrBookTheme.primary, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email Address is required';
                            final val = v.trim();
                            final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
                            if (!emailRegex.hasMatch(val)) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 3. Mobile Number (Pakistani: 92XXXXXXXXXX, exactly 12 digits)
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Mobile Number (e.g. 923394865097)',
                            prefixIcon: Icon(Icons.phone_android_rounded, color: GrBookTheme.primary, size: 20),
                          ),
                          onChanged: (val) {
                            // Helpful auto-format: convert leading 0 to 92 (e.g. 03394865097 -> 923394865097)
                            if (val.startsWith('0') && val.length >= 2) {
                              final converted = '92${val.substring(1)}';
                              if (converted.length <= 12) {
                                _mobileController.value = TextEditingValue(
                                  text: converted,
                                  selection: TextSelection.collapsed(offset: converted.length),
                                );
                              }
                            }
                          },
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Mobile Number is required';
                            final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                            if (!digits.startsWith('92')) {
                              return 'Mobile number must start with 92 (e.g. 923394865097)';
                            }
                            if (digits.length < 12) {
                              return 'Invalid mobile number. Must be exactly 12 digits (e.g. 923394865097)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 4. Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Password',
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
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 5. Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: GrBookTheme.primary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: textSecondary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirm Password is required';
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),

                        // Create Account Button
                        GrBookGradientButton(
                          text: 'Create Account',
                          isLoading: _isSubmitting,
                          onPressed: _submit,
                          trailingIcon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: 18),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: borderColor, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: borderColor, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Continue with Google Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: cardBg,
                          ),
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.blue),
                          label: Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _signUpWithGoogle,
                        ),
                        const SizedBox(height: 12),

                        // Back to Login Button
                        GrBookOutlinedButton(
                          text: 'Back to Login',
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
