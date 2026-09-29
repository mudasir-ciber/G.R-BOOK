import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../providers/sync_providers.dart';

/// Small non-intrusive status banner.
/// Auto-sync operates completely in the background without cluttering the screen.
/// Only surfaces if the device is currently offline.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncBannerStateProvider);

    // Auto-sync happens silently in the background; do not show a banner
    // on top during syncing, pending changes, or synced states.
    if (state != SyncBannerState.offline) {
      return const SizedBox.shrink();
    }

    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey.shade800,
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 15, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pendingCount > 0
                  ? 'Offline — $pendingCount change${pendingCount == 1 ? '' : 's'} saved locally'
                  : 'Offline — working from local data',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
