import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../features/auth/auth_providers.dart';
import '../services/backup_preferences.dart';
import '../services/google_drive_backup_service.dart';

final googleDriveBackupServiceProvider = Provider<GoogleDriveBackupService>((ref) {
  return GoogleDriveBackupService(ref.watch(appDatabaseProvider), ref.watch(supabaseClientProvider));
});

final backupPreferencesProvider = Provider<BackupPreferences>((ref) {
  return BackupPreferences(ref.watch(secureStorageProvider));
});
