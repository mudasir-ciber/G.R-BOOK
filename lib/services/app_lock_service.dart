import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Requirement #30: App lock, PIN, fingerprint/biometric, auto-lock.
///
/// The PIN is stored in [FlutterSecureStorage], which on Android backs
/// onto EncryptedSharedPreferences / the Android Keystore — the value
/// is encrypted at rest on-device. It is never sent anywhere, never
/// logged, and is unrelated to the account password (which Supabase
/// Auth owns entirely).
class AppLockService {
  AppLockService(this._storage, this._localAuth);

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _pinKey = 'grbook_app_lock_pin';
  static const _lockEnabledKey = 'grbook_app_lock_enabled';
  static const _biometricEnabledKey = 'grbook_app_lock_biometric_enabled';
  static const _autoLockMinutesKey = 'grbook_app_lock_auto_minutes';

  Future<bool> hasPinSet() async => (await _storage.read(key: _pinKey)) != null;

  Future<void> setPin(String pin) => _storage.write(key: _pinKey, value: pin);

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == pin;
  }

  Future<void> clearPin() => _storage.delete(key: _pinKey);

  Future<bool> isAppLockEnabled() async => (await _storage.read(key: _lockEnabledKey)) == 'true';

  Future<void> setAppLockEnabled(bool enabled) =>
      _storage.write(key: _lockEnabledKey, value: enabled.toString());

  Future<bool> isBiometricEnabled() async => (await _storage.read(key: _biometricEnabledKey)) == 'true';

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  /// Minutes of background time before the app re-locks. `0` means
  /// "lock immediately on backgrounding".
  Future<int> getAutoLockMinutes() async {
    final value = await _storage.read(key: _autoLockMinutesKey);
    return value != null ? int.tryParse(value) ?? 1 : 1;
  }

  Future<void> setAutoLockMinutes(int minutes) =>
      _storage.write(key: _autoLockMinutesKey, value: minutes.toString());

  Future<bool> deviceSupportsBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final enrolled = await _localAuth.getAvailableBiometrics();
      return canCheck || isSupported || enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to unlock G.R. Book',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
