import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../main.dart';
import '../../providers/app_lock_providers.dart';
import '../../services/sync_coordinator.dart';
import '../../widgets/gr_book_ui_components.dart';
import 'auth_providers.dart';
import 'auth_service.dart';
import 'create_account_screen.dart';

/// Screen 1: Login Page with Fingerprint & Remembered Credential support.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _hasSavedCredentials = false;
  bool _supportsBiometrics = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreRememberedCredentials();
  }

  Future<void> _restoreRememberedCredentials() async {
    final auth = ref.read(authServiceProvider);
    final lockService = ref.read(appLockServiceProvider);
    final remembered = await auth.getRememberedPreference();
    final mobile = await auth.getRememberedMobile();
    final password = await auth.getRememberedPassword();
    final supportsBio = await lockService.deviceSupportsBiometrics();

    if (!mounted) return;
    final hasCreds = (mobile != null && mobile.isNotEmpty && password != null && password.isNotEmpty);

    setState(() {
      _rememberMe = remembered || (mobile != null);
      if (mobile != null) _mobileController.text = mobile;
      if (password != null) _passwordController.text = password;
      _hasSavedCredentials = hasCreds;
      _supportsBiometrics = supportsBio;
    });

    // Auto-prompt fingerprint authentication on app launch if user has saved credentials!
    if (hasCreds && supportsBio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateBiometricAndLogin();
      });
    }
  }

  Future<void> _authenticateBiometricAndLogin() async {
    final lockService = ref.read(appLockServiceProvider);
    final auth = ref.read(authServiceProvider);
    final mobile = (await auth.getRememberedMobile()) ?? _mobileController.text.trim();
    final password = (await auth.getRememberedPassword()) ?? _passwordController.text;

    if (mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in once with mobile number and password to enable fingerprint login.')),
      );
      return;
    }

    final authenticated = await lockService.authenticateWithBiometrics();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fingerprint authentication cancelled.')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await auth.login(
        phoneOrEmail: mobile,
        password: password,
        rememberMe: true,
      );
      ref.read(appUnlockedProvider.notifier).state = true;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SyncCoordinator(child: SchoolGate()),
        ),
        (route) => false,
      );
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Login failed. Please enter your password manually.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).login(
            phoneOrEmail: _mobileController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
      ref.read(appUnlockedProvider.notifier).state = true;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SyncCoordinator(child: SchoolGate()),
        ),
        (route) => false,
      );
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Login error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final contact = _mobileController.text.trim();
    if (contact.isEmpty) {
      setState(() => _errorMessage = 'Enter your phone number or email first, then tap Forgot Password.');
      return;
    }
    try {
      await ref.read(authServiceProvider).requestPasswordReset(phoneOrEmail: contact);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('If this account exists, a reset link has been sent.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not process the request. Check your connection.')),
      );
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
                const SizedBox(height: 12),
                // Illustration Header
                Center(
                  child: Image.asset(
                    'assets/images/auth_header.png',
                    width: 290,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Column(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 54, color: GrBookTheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          'G.R BOOK',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark,
                          ),
                        ),
                        Text(
                          'Digital School Record System',
                          style: TextStyle(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Rounded Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                          'Login to Your Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your phone number or email and password',
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
                          const SizedBox(height: 16),
                        ],

                        // Phone Number or Email Field
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Phone Number or Email',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: GrBookTheme.primary, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Phone number or email is required';
                            final val = value.trim();
                            if (val.contains('@')) {
                              if (!val.contains('.') || val.length < 5) return 'Enter a valid email address';
                            } else {
                              final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                              if (digits.length < 10) return 'Enter a valid phone number (at least 10 digits)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password Field
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
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: TextStyle(fontSize: 13, color: textSecondary),
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
                        const SizedBox(height: 18),

                        // Login Button & Fingerprint Row
                        Row(
                          children: [
                            Expanded(
                              child: GrBookGradientButton(
                                text: 'Login',
                                isLoading: _isSubmitting,
                                onPressed: _submit,
                                trailingIcon: Icons.arrow_forward_rounded,
                              ),
                            ),
                            if (_supportsBiometrics || _hasSavedCredentials) ...[
                              const SizedBox(width: 12),
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  gradient: GrBookTheme.primaryButtonGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x330F7A42),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: _isSubmitting ? null : _authenticateBiometricAndLogin,
                                    child: const Center(
                                      child: Icon(Icons.fingerprint_rounded, color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        if (_hasSavedCredentials) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton.icon(
                              onPressed: _isSubmitting ? null : _authenticateBiometricAndLogin,
                              icon: const Icon(Icons.fingerprint_rounded, color: GrBookTheme.primary, size: 20),
                              label: Text(
                                'Tap to unlock with Fingerprint',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

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
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 16),
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
