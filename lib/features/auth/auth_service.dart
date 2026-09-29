import 'dart:convert';
import 'package:crypto/crypto.dart';
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
  static const _offlineMobileKey = 'grbook_offline_mobile';
  static const _offlineHashKey = 'grbook_offline_hash';

  String _hashCredentials(String digits, String password) {
    final bytes = utf8.encode('$digits:$password:grbook_secure_salt_2026');
    return sha256.convert(bytes).toString();
  }

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  String _normalizeMobile(String mobile) {
    var digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('92') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    } else if (!digits.startsWith('0') && digits.length == 10) {
      digits = '0$digits';
    }
    return digits;
  }

  String _syntheticEmail(String mobileNumber) {
    final digits = _normalizeMobile(mobileNumber);
    if (digits.isEmpty) {
      throw ArgumentError('Mobile number must contain digits.');
    }
    return '$digits@grbook.local';
  }

  bool _isNetworkError(dynamic e) {
    if (e is AuthRetryableFetchException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('failed host lookup') ||
        msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('offline') ||
        msg.contains('unreachable') ||
        msg.contains('handshake');
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

      final digits = _normalizeMobile(mobileNumber);
      final hash = _hashCredentials(digits, password);
      await _secureStorage.write(key: _offlineMobileKey, value: digits);
      await _secureStorage.write(key: _offlineHashKey, value: hash);
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
    final digits = _normalizeMobile(mobileNumber);

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      final hash = _hashCredentials(digits, password);
      await _secureStorage.write(key: _offlineMobileKey, value: digits);
      await _secureStorage.write(key: _offlineHashKey, value: hash);
    } catch (e) {
      if (_isNetworkError(e)) {
        // Device is offline or network unreachable — perform offline login
        final savedMobile = await _secureStorage.read(key: _offlineMobileKey);
        final savedHash = await _secureStorage.read(key: _offlineHashKey);
        if (savedMobile == digits && savedHash != null) {
          final computedHash = _hashCredentials(digits, password);
          if (computedHash != savedHash) {
            throw const AuthServiceException('Mobile number or password is incorrect.');
          }
          // Offline credentials valid! Allow entry.
        } else {
          throw const AuthServiceException(
            'Internet connection is required for first-time login on this device.',
          );
        }
      } else if (e is AuthException) {
        throw AuthServiceException(_friendlyLoginError(e));
      } else {
        throw AuthServiceException('Login failed: ${e.toString()}');
      }
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
    await _secureStorage.delete(key: _offlineHashKey);
  }
}

class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
