import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/enums.dart';
import '../providers/sync_providers.dart';

/// Small persistent status strip (requirement #27: "Show sync status
/// somewhere appropriate — Synced / Syncing / Offline / Pending
/// changes"). Designed to sit just below the AppBar on any data screen.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncBannerStateProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;

    // "Synced" with nothing pending is the steady-state, happy path —
    // keep it visually quiet (a thin line) instead of a loud banner.
    if (state == SyncBannerState.synced) {
      return const SizedBox(height: 0);
    }

    final (color, icon, label) = switch (state) {
      SyncBannerState.offline => (
          Colors.grey.shade700,
          Icons.cloud_off_outlined,
          pendingCount > 0
              ? '$pendingCount change${pendingCount == 1 ? '' : 's'} saved offline (will auto-sync when online)'
              : 'Offline — working from local data',
        ),
      SyncBannerState.syncing => (GrBookTheme.primary, Icons.sync, 'Auto-syncing changes with cloud…'),
      SyncBannerState.pendingChanges => (
          Colors.orange.shade700,
          Icons.cloud_upload_outlined,
          '$pendingCount change${pendingCount == 1 ? '' : 's'} (Auto-syncing…)',
        ),
      SyncBannerState.synced => (GrBookTheme.primary, Icons.cloud_done_outlined, 'All changes synced'),
    };

    return InkWell(
      onTap: () => triggerSync(ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: color.withValues(alpha: 0.10),
        child: Row(
          children: [
            state == SyncBannerState.syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: GrBookTheme.primary),
                  )
                : Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600))),
            if (state == SyncBannerState.pendingChanges)
              Text('Sync now', style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
