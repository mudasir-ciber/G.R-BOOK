import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../features/auth/auth_providers.dart';
import '../models/enums.dart';
import '../services/connectivity_service.dart';
import '../services/sync_engine.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(ref.watch(supabaseClientProvider), ref.watch(appDatabaseProvider));
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).watchPendingSyncCount();
});

/// True for the short window while a manual/automatic drain is running,
/// so the banner can show "Syncing…" distinctly from "Pending changes".
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// Combines connectivity + queue depth + in-flight state into the single
/// banner state the UI needs (requirement #27).
final syncBannerStateProvider = Provider<SyncBannerState>((ref) {
  final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
  final syncing = ref.watch(isSyncingProvider);
  final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;

  if (!online) return SyncBannerState.offline;
  if (syncing) return SyncBannerState.syncing;
  if (pendingCount > 0) return SyncBannerState.pendingChanges;
  return SyncBannerState.synced;
});

/// Triggers one drain pass and toggles [isSyncingProvider] around it —
/// used by both the automatic coordinator and a manual "tap to sync now".
Future<void> triggerSync(WidgetRef ref) async {
  ref.read(isSyncingProvider.notifier).state = true;
  try {
    await ref.read(syncEngineProvider).syncAll();
  } finally {
    ref.read(isSyncingProvider.notifier).state = false;
  }
}
