import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/gr_book_ui_components.dart';
import 'auth_providers.dart';
import 'auth_service.dart';
import 'create_account_screen.dart';

/// Screen 1: Login Page matching reference UI image 1 exactly.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreRememberedMobile();
  }

  Future<void> _restoreRememberedMobile() async {
    final auth = ref.read(authServiceProvider);
    final remembered = await auth.getRememberedPreference();
    final mobile = await auth.getRememberedMobile();
    if (!mounted) return;
    setState(() {
      _rememberMe = remembered;
      if (mobile != null) _mobileController.text = mobile;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).login(
            mobileNumber: _mobileController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      setState(() => _errorMessage = 'Enter your mobile number first, then tap Forgot Password.');
      return;
    }
    try {
      await ref.read(authServiceProvider).requestPasswordReset(mobileNumber: mobile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('If this account exists, a reset link has been sent.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not process the request. Check your internet connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Illustration Header from reference image 1
                Center(
                  child: Image.asset(
                    'assets/images/auth_header.png',
                    width: 290,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Column(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 54, color: GrBookTheme.primary),
                        SizedBox(height: 8),
                        Text(
                          'G.R. Book',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: GrBookTheme.primaryDark,
                          ),
                        ),
                        Text(
                          'Digital School Record System',
                          style: TextStyle(color: GrBookTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // White Rounded Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x140F7A42),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Login to Your Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: GrBookTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter your mobile number and password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: GrBookTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Mobile Number Field
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Mobile Number',
                            prefixIcon: Icon(Icons.phone_outlined, color: GrBookTheme.primary, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Mobile number is required';
                            final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits.length < 10) return 'Enter a valid mobile number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: GrBookTheme.primary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.isEmpty) ? 'Password is required' : null,
                        ),
                        const SizedBox(height: 8),

                        // Remember Me & Forgot Password Row
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: GrBookTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Remember me',
                              style: TextStyle(fontSize: 13, color: GrBookTheme.textSecondary),
                            ),
                            const Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _forgotPassword,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: GrBookTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Login Button
                        GrBookGradientButton(
                          text: 'Login',
                          isLoading: _isSubmitting,
                          onPressed: _submit,
                          trailingIcon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: 20),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Create Account Outlined Button
                        GrBookOutlinedButton(
                          text: 'Create New Account',
                          icon: Icons.person_add_alt_1_outlined,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                            );
                          },
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
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
