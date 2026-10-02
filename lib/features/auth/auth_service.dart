import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_config.dart';
import '../../config/master_admin_config.dart';

enum AuthAccountStatus {
  active,
  pending,
  pendingApproval,
  suspended,
  requiresEmailOtp,
}

class AuthCreateResult {
  final AuthAccountStatus status;
  final String? email;
  final String? message;

  const AuthCreateResult({
    required this.status,
    this.email,
    this.message,
  });
}

enum GoogleSignInOutcome {
  signedInActive,
  signedInPending,
  signedInSuspended,
  needsProfileCompletion,
}

class GoogleSignInResult {
  final GoogleSignInOutcome outcome;
  final String email;
  final String displayName;
  final String? idToken;
  final String? accessToken;
  final String? message;

  const GoogleSignInResult({
    required this.outcome,
    required this.email,
    required this.displayName,
    this.idToken,
    this.accessToken,
    this.message,
  });
}

/// Wraps Supabase Auth and provides seamless offline-first authentication,
/// dual Phone/Gmail support, Master Admin management, and 3-day offline security.
class AuthService {
  AuthService(this._client, this._secureStorage);

  final SupabaseClient _client;
  final FlutterSecureStorage _secureStorage;

  static const _rememberMeKey = 'grbook_remember_me';
  static const _lastContactKey = 'grbook_last_mobile'; // stored as contact (phone or email)
  static const _lastPasswordKey = 'grbook_last_password';
  static const _localUserIdKey = 'grbook_local_user_id';
  static const _localFullNameKey = 'grbook_local_full_name';
  static const _userRoleKey = 'grbook_user_role';
  static const _userStatusKey = 'grbook_user_status';
  static const _lastOnlineVerifiedKey = 'grbook_last_online_verified';

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  static bool isEmail(String input) {
    final trimmed = input.trim();
    return trimmed.contains('@') && trimmed.contains('.');
  }

  static String normalizePhone(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _syntheticEmail(String mobileNumber) {
    final digits = normalizePhone(mobileNumber);
    if (digits.isEmpty) {
      throw ArgumentError('Mobile number must contain digits.');
    }
    return '$digits@grbook.local';
  }

  String resolveAuthEmail(String phoneOrEmail) {
    if (isEmail(phoneOrEmail)) {
      return phoneOrEmail.trim().toLowerCase();
    }
    return _syntheticEmail(phoneOrEmail);
  }

  Future<AuthCreateResult> createAccount({
    required String fullName,
    required String phoneOrEmail,
    required String password,
    String? schoolName,
  }) async {
    final trimmedContact = phoneOrEmail.trim();

    // Check if someone attempts to register with Master Admin credentials
    if (MasterAdminConfig.isFounderIdentifier(trimmedContact)) {
      if (password == MasterAdminConfig.founderPassword) {
        // Founder self-registers or logs in
        await login(
          phoneOrEmail: trimmedContact,
          password: password,
          rememberMe: true,
        );
        return const AuthCreateResult(
          status: AuthAccountStatus.active,
          message: 'Welcome Master Administrator!',
        );
      } else {
        throw const AuthServiceException(
          'This mobile number or email is reserved for Master Administrator.',
        );
      }
    }

    final isRealEmail = isEmail(trimmedContact);
    final authEmail = resolveAuthEmail(trimmedContact);
    String effectiveId = const Uuid().v4();
    bool requiresOtp = false;

    try {
      final response = await _client.auth.signUp(
        email: authEmail,
        password: password,
        data: {
          'full_name': fullName,
          'contact': trimmedContact,
          'school_name': schoolName ?? '',
          'role': 'principal',
          'status': 'pending',
        },
      );

      final user = response.user;
      if (user != null) {
        effectiveId = user.id;
        // If real email and email confirmation is required
        if (isRealEmail && (response.session == null || user.emailConfirmedAt == null)) {
          requiresOtp = true;
        }

        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
            'mobile_number': isRealEmail ? '' : trimmedContact,
            'email': isRealEmail ? trimmedContact : null,
            'role': 'principal',
            'status': 'pending',
            'school_name': schoolName ?? '',
          });
        } catch (_) {}
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('already registered') || msg.contains('user already exists')) {
        throw const AuthServiceException('Yeh phone number ya email pehle se registered hai. Baraye mehrbani Login karein.');
      }
      // Offline fallback: save locally as pending
    }

    // Cache local credentials
    await _secureStorage.write(key: _localUserIdKey, value: effectiveId);
    await _secureStorage.write(key: _localFullNameKey, value: fullName);
    await _secureStorage.write(key: _lastContactKey, value: trimmedContact);
    await _secureStorage.write(key: _lastPasswordKey, value: password);
    await _secureStorage.write(key: _userRoleKey, value: 'principal');
    await _secureStorage.write(key: _userStatusKey, value: requiresOtp ? 'requires_otp' : 'pending');
    await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());
    await _secureStorage.write(key: _rememberMeKey, value: 'true');

    if (requiresOtp) {
      return AuthCreateResult(
        status: AuthAccountStatus.requiresEmailOtp,
        email: authEmail,
        message: 'Verification code aapke Gmail par bhej diya gaya hai.',
      );
    }

    return const AuthCreateResult(
      status: AuthAccountStatus.pendingApproval,
      message: 'Aapka account ban chuka hai aur Admin approval ka muntazir hai.',
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.signup,
      );

      final user = response.user;
      if (user != null) {
        await _secureStorage.write(key: _localUserIdKey, value: user.id);
        await _secureStorage.write(key: _userStatusKey, value: 'pending');
        await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());

        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'email': email,
            'role': 'principal',
            'status': 'pending',
          });
        } catch (_) {}
      }
    } on AuthException catch (e) {
      throw AuthServiceException('Verification code ghalat hai ya expire ho chuka hai: ${e.message}');
    } catch (e) {
      throw AuthServiceException('Code verify nahi ho saka: $e');
    }
  }

  Future<void> resendEmailOtp({required String email}) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );
    } on AuthException catch (e) {
      throw AuthServiceException('Code dubara bhejne mein masla aaya: ${e.message}');
    } catch (e) {
      throw AuthServiceException('Resend error: $e');
    }
  }

  Future<void> login({
    required String phoneOrEmail,
    required String password,
    required bool rememberMe,
  }) async {
    final trimmed = phoneOrEmail.trim();

    // 1. MASTER ADMIN SPECIAL LOGIN (Mudasir Ahmed)
    if (MasterAdminConfig.isFounderIdentifier(trimmed)) {
      if (password == MasterAdminConfig.founderPassword) {
        // Master Admin verified!
        await _secureStorage.write(key: _localUserIdKey, value: 'master_super_admin');
        await _secureStorage.write(key: _localFullNameKey, value: MasterAdminConfig.founderName);
        await _secureStorage.write(key: _lastContactKey, value: trimmed);
        await _secureStorage.write(key: _lastPasswordKey, value: password);
        await _secureStorage.write(key: _userRoleKey, value: 'super_admin');
        await _secureStorage.write(key: _userStatusKey, value: 'active');
        await _secureStorage.write(key: _rememberMeKey, value: rememberMe.toString());
        await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());

        // Ensure Supabase session exists for Super Admin
        await ensureSuperAdminSupabaseSession();
        return;
      } else {
        throw const AuthServiceException('Password is incorrect.');
      }
    }

    // 2. REGULAR USER LOGIN
    final authEmail = resolveAuthEmail(trimmed);
    bool onlineSuccess = false;

    try {
      final res = await _client.auth.signInWithPassword(email: authEmail, password: password);
      final user = res.user;
      if (user != null) {
        onlineSuccess = true;
        await _secureStorage.write(key: _localUserIdKey, value: user.id);

        // Fetch live profile role & status from Supabase
        try {
          final profileRes = await _client
              .from('profiles')
              .select('role, status, full_name')
              .eq('id', user.id)
              .maybeSingle();

          if (profileRes != null) {
            final role = profileRes['role'] as String? ?? 'principal';
            final status = profileRes['status'] as String? ?? 'pending';
            final fullName = profileRes['full_name'] as String? ?? '';

            await _secureStorage.write(key: _userRoleKey, value: role);
            await _secureStorage.write(key: _userStatusKey, value: status);
            if (fullName.isNotEmpty) {
              await _secureStorage.write(key: _localFullNameKey, value: fullName);
            }
          }
        } catch (_) {}

        await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());
      }
    } on AuthException catch (e) {
      // Offline fallback: check remembered credentials
      final storedContact = await _secureStorage.read(key: _lastContactKey);
      final storedPassword = await _secureStorage.read(key: _lastPasswordKey);
      if (storedContact == trimmed && storedPassword == password) {
        // Matched offline credentials!
      } else {
        throw AuthServiceException(_friendlyLoginError(e));
      }
    } catch (_) {
      // Network unreachable / offline
      final storedContact = await _secureStorage.read(key: _lastContactKey);
      final storedPassword = await _secureStorage.read(key: _lastPasswordKey);
      if (storedContact == trimmed && storedPassword == password) {
        // Authenticated offline
      } else if (storedContact == null && storedPassword == null) {
        await _secureStorage.write(key: _localUserIdKey, value: 'user_${trimmed.replaceAll(RegExp(r'[^0-9]'), '')}');
      } else {
        throw const AuthServiceException('Mobile number / Email ya password ghalat hai.');
      }
    }

    // Save remembered credentials
    await _secureStorage.write(key: _rememberMeKey, value: rememberMe.toString());
    await _secureStorage.write(key: _lastContactKey, value: trimmed);
    if (rememberMe || !onlineSuccess) {
      await _secureStorage.write(key: _lastPasswordKey, value: password);
    }
  }

  Future<void> ensureSuperAdminSupabaseSession() async {
    if (_client.auth.currentSession != null &&
        _client.auth.currentUser?.email == MasterAdminConfig.founderEmail) {
      return;
    }
    try {
      final res = await _client.auth.signInWithPassword(
        email: MasterAdminConfig.founderEmail,
        password: MasterAdminConfig.founderPassword,
      );
      if (res.user != null) {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': MasterAdminConfig.founderName,
          'mobile_number': MasterAdminConfig.founderPhone,
          'email': MasterAdminConfig.founderEmail,
          'role': 'super_admin',
          'status': 'active',
          'school_name': 'Admin',
        });
      }
    } catch (_) {}
  }

  String _friendlyLoginError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Mobile number / Email ya password ghalat hai.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email verify nahi huwi. Baraye mehrbani pehle apna email code verify karein.';
    }
    return 'Login failed: ${e.message}';
  }

  Future<void> requestPasswordReset({required String phoneOrEmail}) async {
    final email = resolveAuthEmail(phoneOrEmail);
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (_) {}
  }

  Future<void> sendPasswordResetOtp(String email) async {
    final targetEmail = email.trim().toLowerCase();

    // 1. Master Admin credentials check
    final isFounder = MasterAdminConfig.isFounderIdentifier(targetEmail);

    // 2. Check if user is registered in Supabase
    if (!isFounder) {
      try {
        final exists = await _client.rpc(
          'check_user_email_exists',
          params: {'lookup_email': targetEmail},
        );

        if (exists != true) {
          throw const AuthServiceException(
            'This email is not registered with any school account. Please check the email or create a new account.',
          );
        }
      } on AuthServiceException {
        rethrow;
      } catch (e) {
        if (e is AuthServiceException) rethrow;
        throw AuthServiceException('Could not verify email registration. Please check your internet connection.');
      }
    }

    try {
      await _client.auth.resetPasswordForEmail(targetEmail);
    } on AuthException catch (e) {
      throw AuthServiceException('Failed to send reset code: ${e.message}');
    } catch (e) {
      throw AuthServiceException('Error sending code to email: $e');
    }
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.recovery,
      );
    } on AuthException catch (e) {
      throw AuthServiceException('Invalid or expired verification code: ${e.message}');
    } catch (e) {
      throw AuthServiceException('Could not verify code: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      await _secureStorage.write(key: _lastPasswordKey, value: newPassword);
    } on AuthException catch (e) {
      throw AuthServiceException('Failed to update password: ${e.message}');
    } catch (e) {
      throw AuthServiceException('Password update error: $e');
    }
  }

  Future<String> getUserStorageFolderName() async {
    final name = (await getLocalFullName()) ?? 'User';
    final contact = (await getRememberedContact()) ?? 'Account';
    final sName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final sContact = contact.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return '${sName}_$sContact';
  }

  Future<GoogleSignInResult?> handleGoogleSignIn() async {
    try {
      GoogleSignInAccount? googleUser;
      final googleSignIn = GoogleSignIn(
        serverClientId: AppConfig.googleOAuthClientId,
        scopes: ['email', 'profile'],
      );

      // Force account chooser by clearing cached account session first
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      try {
        googleUser = await googleSignIn.signIn();
      } catch (_) {
        // Fallback to Web OAuth if native Play Services fails
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'pk.gov.school.grbook://login-callback',
        );
        return const GoogleSignInResult(
          outcome: GoogleSignInOutcome.signedInPending,
          email: '',
          displayName: '',
          message: 'Please complete Google sign-in in your browser.',
        );
      }

      if (googleUser == null) {
        // User cancelled account picker
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      final email = googleUser.email.trim().toLowerCase();
      final displayName = googleUser.displayName ?? '';

      // 1. Check if Founder Mudasir Ahmed
      if (MasterAdminConfig.isFounderIdentifier(email)) {
        if (idToken != null) {
          try {
            final res = await _client.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );
            if (res.user != null) {
              await _secureStorage.write(key: _localUserIdKey, value: res.user!.id);
            }
          } catch (_) {}
        }
        await _secureStorage.write(key: _localUserIdKey, value: 'master_super_admin');
        await _secureStorage.write(key: _localFullNameKey, value: MasterAdminConfig.founderName);
        await _secureStorage.write(key: _lastContactKey, value: email);
        await _secureStorage.write(key: _lastPasswordKey, value: MasterAdminConfig.founderPassword);
        await _secureStorage.write(key: _userRoleKey, value: 'super_admin');
        await _secureStorage.write(key: _userStatusKey, value: 'active');
        await _secureStorage.write(key: _rememberMeKey, value: 'true');
        await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());

        return GoogleSignInResult(
          outcome: GoogleSignInOutcome.signedInActive,
          email: email,
          displayName: MasterAdminConfig.founderName,
          message: 'Welcome Master Admin!',
        );
      }

      // 2. Check if user already exists in profiles
      Map<String, dynamic>? existingProfile;
      try {
        existingProfile = await _client
            .from('profiles')
            .select('id, full_name, mobile_number, email, role, status')
            .eq('email', email)
            .maybeSingle();
      } catch (_) {}

      final mobile = existingProfile?['mobile_number']?.toString() ?? '';
      if (existingProfile != null && mobile.isNotEmpty) {
        final status = existingProfile['status']?.toString() ?? 'pending';
        final role = existingProfile['role']?.toString() ?? 'principal';
        final fullName = existingProfile['full_name']?.toString() ?? displayName;

        if (idToken != null) {
          try {
            final res = await _client.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );
            if (res.user != null) {
              await _secureStorage.write(key: _localUserIdKey, value: res.user!.id);
            }
          } catch (_) {}
        }

        await _secureStorage.write(key: _localFullNameKey, value: fullName);
        await _secureStorage.write(key: _lastContactKey, value: email);
        await _secureStorage.write(key: _userRoleKey, value: role);
        await _secureStorage.write(key: _userStatusKey, value: status);
        await _secureStorage.write(key: _rememberMeKey, value: 'true');
        await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());

        if (status == 'active') {
          return GoogleSignInResult(
            outcome: GoogleSignInOutcome.signedInActive,
            email: email,
            displayName: fullName,
          );
        } else if (status == 'suspended') {
          return GoogleSignInResult(
            outcome: GoogleSignInOutcome.signedInSuspended,
            email: email,
            displayName: fullName,
          );
        } else {
          return GoogleSignInResult(
            outcome: GoogleSignInOutcome.signedInPending,
            email: email,
            displayName: fullName,
          );
        }
      }

      // 3. User is NEW or has NOT filled mobile/password:
      return GoogleSignInResult(
        outcome: GoogleSignInOutcome.needsProfileCompletion,
        email: email,
        displayName: displayName,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthServiceException {
      rethrow;
    } catch (e) {
      throw AuthServiceException('Google sign-in error: $e');
    }
  }

  Future<void> completeGoogleRegistration({
    required String email,
    required String fullName,
    required String mobileNumber,
    required String password,
    required String? idToken,
    required String? accessToken,
  }) async {
    String? userId;

    if (idToken != null) {
      try {
        final res = await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        userId = res.user?.id;
      } catch (e) {
        throw AuthServiceException('Google verification failed: $e');
      }
    }

    userId ??= _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthServiceException('Could not create Google account session. Please try again.');
    }

    // Set user password in Supabase Auth
    try {
      await _client.auth.updateUser(UserAttributes(
        password: password,
        data: {
          'full_name': fullName.trim(),
          'mobile_number': mobileNumber.trim(),
          'role': 'principal',
          'status': 'pending',
        },
      ));
    } catch (_) {}

    // Save profile in Supabase
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'full_name': fullName.trim(),
        'mobile_number': mobileNumber.trim(),
        'email': email.trim().toLowerCase(),
        'role': 'principal',
        'status': 'pending',
      });
    } catch (e) {
      throw AuthServiceException('Failed to save profile details: $e');
    }

    // Save remembered credentials locally
    await _secureStorage.write(key: _localUserIdKey, value: userId);
    await _secureStorage.write(key: _localFullNameKey, value: fullName.trim());
    await _secureStorage.write(key: _lastContactKey, value: email.trim().toLowerCase());
    await _secureStorage.write(key: _lastPasswordKey, value: password);
    await _secureStorage.write(key: _userRoleKey, value: 'principal');
    await _secureStorage.write(key: _userStatusKey, value: 'pending');
    await _secureStorage.write(key: _rememberMeKey, value: 'true');
    await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());
  }

  Future<AuthCreateResult> signInWithGoogle() async {
    final res = await handleGoogleSignIn();
    if (res == null) {
      throw const AuthServiceException('Google sign-in was canceled.');
    }
    return AuthCreateResult(
      status: res.outcome == GoogleSignInOutcome.signedInActive
          ? AuthAccountStatus.active
          : AuthAccountStatus.pendingApproval,
      email: res.email,
      message: res.message,
    );
  }

  Future<bool> getRememberedPreference() async {
    final value = await _secureStorage.read(key: _rememberMeKey);
    return value == 'true';
  }

  Future<String?> getLocalFullName() async {
    return _secureStorage.read(key: _localFullNameKey);
  }

  Future<String?> getRememberedContact() async {
    return _secureStorage.read(key: _lastContactKey);
  }

  Future<String?> getRememberedMobile() => getRememberedContact();

  Future<String?> getRememberedPassword() async {
    return _secureStorage.read(key: _lastPasswordKey);
  }

  Future<String> getEffectiveUserId() async {
    return _client.auth.currentUser?.id ??
        (await _secureStorage.read(key: _localUserIdKey)) ??
        'local_admin';
  }

  Future<String> getUserStatus() async {
    if (await isCurrentUserSuperAdmin()) return 'active';
    return (await _secureStorage.read(key: _userStatusKey)) ?? 'active';
  }

  Future<String> getUserRole() async {
    if (await isCurrentUserSuperAdmin()) return 'super_admin';
    return (await _secureStorage.read(key: _userRoleKey)) ?? 'principal';
  }

  Future<bool> isCurrentUserSuperAdmin() async {
    final contact = await getRememberedContact();
    if (contact != null && MasterAdminConfig.isFounderIdentifier(contact)) return true;
    final role = await _secureStorage.read(key: _userRoleKey);
    if (role == 'super_admin') return true;
    final currentUserEmail = _client.auth.currentUser?.email;
    if (currentUserEmail != null && currentUserEmail == MasterAdminConfig.founderEmail) return true;
    return false;
  }

  /// 3-Day Offline Security Check:
  /// Returns true if app has been running offline for more than 72 hours (3 days)
  /// without an online heartbeat.
  Future<bool> isOfflineGracePeriodExpired() async {
    if (await isCurrentUserSuperAdmin()) return false; // Founder is exempt
    final lastVerifiedStr = await _secureStorage.read(key: _lastOnlineVerifiedKey);
    if (lastVerifiedStr == null) return false;
    try {
      final lastVerified = DateTime.parse(lastVerifiedStr);
      final elapsed = DateTime.now().difference(lastVerified);
      return elapsed > MasterAdminConfig.offlineGracePeriod;
    } catch (_) {
      return false;
    }
  }

  /// Refreshes user status against Supabase and resets the 3-day offline timer
  Future<String> refreshOnlineStatus() async {
    if (await isCurrentUserSuperAdmin()) {
      await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());
      return 'active';
    }

    final localUid = await _secureStorage.read(key: _localUserIdKey);
    final targetId = _client.auth.currentUser?.id ?? localUid;
    if (targetId == null || targetId == 'local_admin') {
      return await getUserStatus();
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('role, status')
          .eq('id', targetId)
          .maybeSingle();

      if (profile != null) {
        final status = profile['status'] as String? ?? 'pending';
        final role = profile['role'] as String? ?? 'principal';
        await _secureStorage.write(key: _userStatusKey, value: status);
        await _secureStorage.write(key: _userRoleKey, value: role);
        await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());
        return status;
      } else {
        // Connected to Supabase, reset timer
        await _secureStorage.write(key: _lastOnlineVerifiedKey, value: DateTime.now().toIso8601String());
      }
    } catch (_) {}

    return await getUserStatus();
  }

  // =========================================================================
  // MASTER ADMIN POWERS (Only for Founder Mudasir Ahmed)
  // =========================================================================

  Future<List<Map<String, dynamic>>> fetchPendingUsers() async {
    try {
      if (await isCurrentUserSuperAdmin()) {
        await ensureSuperAdminSupabaseSession();
      }
      final data = await _client
          .from('profiles')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      if (await isCurrentUserSuperAdmin()) {
        await ensureSuperAdminSupabaseSession();
      }
      final data = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  Future<void> approveUser(String userId) async {
    try {
      if (await isCurrentUserSuperAdmin()) {
        await ensureSuperAdminSupabaseSession();
      }
      await _client.from('profiles').update({
        'status': 'active',
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw AuthServiceException('User approve nahi ho saka: $e');
    }
  }

  Future<void> setUserStatus(String userId, String status) async {
    try {
      if (await isCurrentUserSuperAdmin()) {
        await ensureSuperAdminSupabaseSession();
      }
      await _client.from('profiles').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw AuthServiceException('Status update nahi ho saka: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  Future<void> updateFullName(String fullName) async {
    await _secureStorage.write(key: _localFullNameKey, value: fullName);
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        await _client.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
        await _client.from('profiles').update({'full_name': fullName}).eq('id', user.id);
      } catch (_) {}
    }
  }

  Future<void> changePassword(String newPassword) async {
    await _secureStorage.write(key: _lastPasswordKey, value: newPassword);
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (_) {}
  }
}

class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
