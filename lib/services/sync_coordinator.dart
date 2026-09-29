import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_providers.dart';
import '../providers/backup_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_providers.dart';
import '../services/connectivity_service.dart';

/// Wraps the authenticated part of the app. Two triggers keep the
/// offline outbox draining without the user ever having to think about
/// it (requirement #27):
///  1. A connectivity listener fires a sync the moment the device goes
///     from offline -> online.
///  2. A periodic timer (every 3 minutes) catches anything the
///     connectivity transition missed — e.g. the network interface was
///     "up" but Supabase itself was briefly unreachable.
///
/// A manual "tap to sync now" is also exposed via [triggerSync] from
/// the sync status banner for cases where the person doesn't want to
/// wait.
class SyncCoordinator extends ConsumerStatefulWidget {
  const SyncCoordinator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncCoordinator> createState() => _SyncCoordinatorState();
}

class _SyncCoordinatorState extends ConsumerState<SyncCoordinator> {
  StreamSubscription<bool>? _connectivitySub;
  ProviderSubscription<AsyncValue<int>>? _pendingSyncSub;
  Timer? _periodicTimer;
  Timer? _autoSyncDebounce;

  @override
  void initState() {
    super.initState();

    // Fire an initial sync attempt shortly after launch (covers changes
    // queued while the app was closed), then check whether the
    // automatic backup is due.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await triggerSync(ref);
      await _maybeRunAutoBackup();
      try {
        await ref.read(offlineStorageServiceProvider).exportCurrentStateToStorage();
      } catch (_) {}
    });

    // Auto-sync immediately whenever local database has pending changes
    _pendingSyncSub = ref.listenManual(pendingSyncCountProvider, (previous, next) {
      final count = next.valueOrNull ?? 0;
      if (count > 0) {
        _triggerAutoSyncDebounced();
      }
    });

    // Auto-sync whenever device reconnects to internet
    _connectivitySub = ref.read(connectivityServiceProvider).onStatusChange.listen((online) {
      if (online) {
        _triggerAutoSyncDebounced();
      }
    });

    // Periodic safety check every 1 minute
    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _triggerAutoSyncDebounced();
    });
  }

  void _triggerAutoSyncDebounced() {
    _autoSyncDebounce?.cancel();
    _autoSyncDebounce = Timer(const Duration(milliseconds: 500), () async {
      final isOnline = await ref.read(connectivityServiceProvider).isOnline();
      if (isOnline) {
        await triggerSync(ref);
      }
      try {
        await ref.read(offlineStorageServiceProvider).exportCurrentStateToStorage();
      } catch (_) {}
    });
  }

  /// Automatic Backup (requirement #29). Honest scope: Android does not
  /// let a normal app run an exact daily job without extra
  /// background-work infrastructure, so this runs when the app is
  /// opened, if the toggle is on, ≥24h have passed since the last
  /// backup, the device is online, and Google sign-in can be restored
  /// silently (no popup). Any failure is swallowed — a backup problem
  /// must never disturb normal use; the manual Backup screen shows
  /// real errors.
  Future<void> _maybeRunAutoBackup() async {
    try {
      final prefs = ref.read(backupPreferencesProvider);
      if (!await prefs.isAutoBackupEnabled()) return;

      final last = await prefs.getLastBackupAt();
      if (last != null && DateTime.now().difference(last) < const Duration(hours: 24)) return;

      if (!await ref.read(connectivityServiceProvider).isOnline()) return;

      final service = ref.read(googleDriveBackupServiceProvider);
      final account = await service.signInSilently();
      if (account == null) return;

      final school = await ref.read(schoolRepositoryProvider).getLocalSchool();
      if (school == null) return;

      await service.backupNow(schoolId: school.id, userId: ref.read(currentUserProvider)?.id);
      await prefs.setLastBackupAt(DateTime.now());
    } catch (_) {
      // Intentionally silent — see doc comment.
    }
  }

  @override
  void dispose() {
    _pendingSyncSub?.close();
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _autoSyncDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
