import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Wraps Supabase Auth and provides seamless offline-first authentication,
/// credential remembering, and fingerprint login support.
class AuthService {
  AuthService(this._client, this._secureStorage);

  final SupabaseClient _client;
  final FlutterSecureStorage _secureStorage;

  static const _rememberMeKey = 'grbook_remember_me';
  static const _lastMobileKey = 'grbook_last_mobile';
  static const _lastPasswordKey = 'grbook_last_password';
  static const _localUserIdKey = 'grbook_local_user_id';
  static const _localFullNameKey = 'grbook_local_full_name';

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
    String effectiveId = const Uuid().v4();

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
      if (user != null) {
        effectiveId = user.id;
        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
            'mobile_number': mobileNumber,
          });
        } catch (_) {}
      }
    } catch (_) {
      // Offline fallback: create local user account
    }

    // Securely cache credentials on device for offline and fingerprint logins
    await _secureStorage.write(key: _localUserIdKey, value: effectiveId);
    await _secureStorage.write(key: _localFullNameKey, value: fullName);
    await _secureStorage.write(key: _lastMobileKey, value: mobileNumber);
    await _secureStorage.write(key: _lastPasswordKey, value: password);
    await _secureStorage.write(key: _rememberMeKey, value: 'true');
  }

  Future<void> login({
    required String mobileNumber,
    required String password,
    required bool rememberMe,
  }) async {
    final email = _syntheticEmail(mobileNumber);
    bool onlineSuccess = false;

    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      if (res.user != null) {
        onlineSuccess = true;
        await _secureStorage.write(key: _localUserIdKey, value: res.user!.id);
      }
    } on AuthException catch (e) {
      // Check offline fallback if wrong password or offline mode
      final storedMobile = await _secureStorage.read(key: _lastMobileKey);
      final storedPassword = await _secureStorage.read(key: _lastPasswordKey);
      if (storedMobile == mobileNumber && storedPassword == password) {
        // Matched offline credentials!
      } else {
        throw AuthServiceException(_friendlyLoginError(e));
      }
    } catch (_) {
      // Network unreachable or offline
      final storedMobile = await _secureStorage.read(key: _lastMobileKey);
      final storedPassword = await _secureStorage.read(key: _lastPasswordKey);
      if (storedMobile == mobileNumber && storedPassword == password) {
        // Authenticated offline!
      } else if (storedMobile == null && storedPassword == null) {
        // First-time local installation with offline usage
        await _secureStorage.write(key: _localUserIdKey, value: 'user_${mobileNumber.replaceAll(RegExp(r'[^0-9]'), '')}');
      } else {
        throw const AuthServiceException('Mobile number or password is incorrect.');
      }
    }

    // Save remembered credentials
    await _secureStorage.write(key: _rememberMeKey, value: rememberMe.toString());
    await _secureStorage.write(key: _lastMobileKey, value: mobileNumber);
    if (rememberMe || !onlineSuccess) {
      await _secureStorage.write(key: _lastPasswordKey, value: password);
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

  Future<void> requestPasswordReset({required String mobileNumber}) async {
    final email = _syntheticEmail(mobileNumber);
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (_) {}
  }

  Future<bool> getRememberedPreference() async {
    final value = await _secureStorage.read(key: _rememberMeKey);
    return value == 'true';
  }

  Future<String?> getRememberedMobile() async {
    return _secureStorage.read(key: _lastMobileKey);
  }

  Future<String?> getRememberedPassword() async {
    return _secureStorage.read(key: _lastPasswordKey);
  }

  Future<String> getEffectiveUserId() async {
    return _client.auth.currentUser?.id ??
        (await _secureStorage.read(key: _localUserIdKey)) ??
        'local_admin';
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
