import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../main.dart';
import '../../providers/app_lock_providers.dart';
import '../../widgets/gr_book_ui_components.dart';
import 'auth_providers.dart';
import 'auth_service.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'google_complete_profile_screen.dart';

/// Screen 1: Login Page with Fingerprint & Remembered Credential support.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _hasSavedCredentials = false;
  bool _supportsBiometrics = false;
  String? _errorMessage;

  late final AnimationController _logoAnimController;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeOutBack),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeIn),
    );
    _logoAnimController.forward();

    _restoreRememberedCredentials();
  }

  Future<void> _restoreRememberedCredentials() async {
    final auth = ref.read(authServiceProvider);
    final lockService = ref.read(appLockServiceProvider);
    final supportsBio = await lockService.deviceSupportsBiometrics();

    // Check if user explicitly logged out
    final wasExplicitlyLoggedOut =
        (await ref.read(secureStorageProvider).read(key: 'grbook_logged_out')) == 'true';
    if (wasExplicitlyLoggedOut) {
      if (!mounted) return;
      setState(() {
        _rememberMe = false;
        _mobileController.clear();
        _passwordController.clear();
        _hasSavedCredentials = false;
        _supportsBiometrics = supportsBio;
      });
      return;
    }

    final remembered = await auth.getRememberedPreference();
    final mobile = await auth.getRememberedMobile();
    final password = await auth.getRememberedPassword();

    if (!mounted) return;
    final hasCreds = (mobile != null && mobile.isNotEmpty && password != null && password.isNotEmpty);

    setState(() {
      _rememberMe = remembered || (mobile != null);
      if (mobile != null) _mobileController.text = mobile;
      // CRITICAL: NEVER pre-fill password into text field for security!
      _passwordController.clear();
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
      await ref.read(secureStorageProvider).delete(key: 'grbook_logged_out');
      ref.read(appUnlockedProvider.notifier).state = true;
      ref.invalidate(isSuperAdminProvider);
      ref.invalidate(currentUserProvider);
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
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
      await ref.read(secureStorageProvider).delete(key: 'grbook_logged_out');
      ref.read(appUnlockedProvider.notifier).state = true;
      ref.invalidate(isSuperAdminProvider);
      ref.invalidate(currentUserProvider);
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Login error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _forgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Future<void> _loginWithGoogle() async {
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
        await ref.read(secureStorageProvider).delete(key: 'grbook_logged_out');
        ref.read(appUnlockedProvider.notifier).state = true;
        ref.invalidate(isSuperAdminProvider);
        ref.invalidate(currentUserProvider);
        rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Google sign-in error: $e');
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0C823B), // Rich emerald green matching app logo
              Color(0xFF08682F), // Deep lush forest green
              Color(0xFF04481F), // Dark deep base green
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Animated Brand Logo matching the official app logo
                Center(
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.menu_book_rounded,
                              size: 54,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'G.R. BOOK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'School Management System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Rounded Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: isDark ? GrBookTheme.darkCardBackground : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: isDark ? Border(top: BorderSide(color: borderColor)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
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
                          onPressed: _isSubmitting ? null : _loginWithGoogle,
                        ),
                        const SizedBox(height: 12),

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
    _logoAnimController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
