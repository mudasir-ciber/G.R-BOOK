import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth. Supabase itself owns password hashing, session
/// tokens, and refresh — this class never touches or stores a raw
/// password anywhere (requirement #4 / #30: no manual password storage).
///
/// Mobile numbers are used as the user-facing identifier, but Supabase
/// Auth is keyed by email internally; we derive a stable synthetic email
/// (`<digits-only-mobile>@grbook.local`) so a single Supabase Auth
/// project can serve mobile-number login without needing SMS OTP
/// infrastructure. This mapping is deterministic and never exposed to
/// the user.
class AuthService {
  AuthService(this._client, this._secureStorage);

  final SupabaseClient _client;
  final FlutterSecureStorage _secureStorage;

  static const _rememberMeKey = 'grbook_remember_me';
  static const _lastMobileKey = 'grbook_last_mobile';

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  String _syntheticEmail(String mobileNumber) {
    final digits = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      throw ArgumentError('Mobile number must contain digits.');
    }
    return '$digits@grbook.local';
  }

  Future<void> createAccount({
    required String fullName,
    required String mobileNumber,
    required String password,
  }) async {
    final email = _syntheticEmail(mobileNumber);

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'mobile_number': mobileNumber,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthServiceException(
          'Account creation failed. Please try again.',
        );
      }

      // Populate public.profiles (id, full_name, mobile_number). RLS on
      // profiles restricts this insert to the authenticated user's own id.
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
          'mobile_number': mobileNumber,
        });
      } catch (_) {
        // Ignore if unconfirmed session prevents immediate profile write
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit')) {
        throw const AuthServiceException(
          'Rate limit reached. Please disable "Confirm email" in Supabase Authentication settings.',
        );
      }
      throw AuthServiceException(e.message);
    }
  }

  Future<void> login({
    required String mobileNumber,
    required String password,
    required bool rememberMe,
  }) async {
    final email = _syntheticEmail(mobileNumber);

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthServiceException(_friendlyLoginError(e));
    }

    await _secureStorage.write(key: _rememberMeKey, value: rememberMe.toString());
    if (rememberMe) {
      await _secureStorage.write(key: _lastMobileKey, value: mobileNumber);
    } else {
      await _secureStorage.delete(key: _lastMobileKey);
    }
  }

  String _friendlyLoginError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Mobile number or password is incorrect.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Account is not verified yet. Please contact your administrator.';
    }
    return 'Login failed: ${e.message}';
  }

  /// Supabase's native password recovery is email-based. Since G.R. Book
  /// authenticates by mobile number, "Forgot Password" routes through an
  /// admin-assisted reset: an owner/admin of the school can trigger a
  /// reset link to the synthetic email address on file, or reset the
  /// account directly from the Supabase dashboard for now. This keeps
  /// the client free of any privileged reset capability.
  Future<void> requestPasswordReset({required String mobileNumber}) async {
    final email = _syntheticEmail(mobileNumber);
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<bool> getRememberedPreference() async {
    final value = await _secureStorage.read(key: _rememberMeKey);
    return value == 'true';
  }

  Future<String?> getRememberedMobile() async {
    return _secureStorage.read(key: _lastMobileKey);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}

class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
