import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small local preference store for the backup feature. Nothing
/// sensitive lives here — just a toggle and a timestamp.
class BackupPreferences {
  BackupPreferences(this._storage);

  final FlutterSecureStorage _storage;

  static const _autoBackupKey = 'grbook_auto_backup_enabled';
  static const _lastBackupAtKey = 'grbook_last_backup_at';

  Future<bool> isAutoBackupEnabled() async {
    final value = await _storage.read(key: _autoBackupKey);
    return value == 'true';
  }

  Future<void> setAutoBackupEnabled(bool enabled) {
    return _storage.write(key: _autoBackupKey, value: enabled.toString());
  }

  Future<DateTime?> getLastBackupAt() async {
    final value = await _storage.read(key: _lastBackupAtKey);
    return value != null ? DateTime.tryParse(value) : null;
  }

  Future<void> setLastBackupAt(DateTime time) {
    return _storage.write(key: _lastBackupAtKey, value: time.toIso8601String());
  }
}
