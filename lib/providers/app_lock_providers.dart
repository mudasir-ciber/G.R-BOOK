import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../features/auth/auth_providers.dart';
import '../services/app_lock_service.dart';

final localAuthProvider = Provider<LocalAuthentication>((ref) => LocalAuthentication());

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(ref.watch(secureStorageProvider), ref.watch(localAuthProvider));
});

/// Whether the app is currently showing the lock screen. Toggled by
/// [AppLockGate] on background/foreground transitions and cleared once
/// the person unlocks successfully.
final isLockedProvider = StateProvider<bool>((ref) => false);
