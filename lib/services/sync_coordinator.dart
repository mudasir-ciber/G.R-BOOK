import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  Timer? _periodicTimer;
  bool _wasOnline = true;

  @override
  void initState() {
    super.initState();

    // Fire an initial sync attempt shortly after launch (covers changes
    // queued while the app was closed).
    WidgetsBinding.instance.addPostFrameCallback((_) => triggerSync(ref));

    _connectivitySub = ref.read(connectivityServiceProvider).onStatusChange.listen((online) {
      if (online && !_wasOnline) {
        triggerSync(ref);
      }
      _wasOnline = online;
    });

    _periodicTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      triggerSync(ref);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
