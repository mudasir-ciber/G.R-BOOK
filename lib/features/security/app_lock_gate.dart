import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_lock_providers.dart';
import 'lock_screen.dart';

/// Sits above [child] (the rest of the authenticated app). Requirement
/// #30's auto-lock: records the moment the app is backgrounded, and on
/// resume, locks if the configured auto-lock window has elapsed. A
/// timeout of 0 minutes means "lock immediately on backgrounding".
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // If app lock is enabled, require unlocking once right at launch too.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = ref.read(appLockServiceProvider);
      if (await service.isAppLockEnabled() && await service.hasPinSet()) {
        ref.read(isLockedProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeLockOnResume();
    }
  }

  Future<void> _maybeLockOnResume() async {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return;

    final service = ref.read(appLockServiceProvider);
    if (!await service.isAppLockEnabled() || !await service.hasPinSet()) return;

    final autoLockMinutes = await service.getAutoLockMinutes();
    final elapsed = DateTime.now().difference(backgroundedAt);
    if (elapsed >= Duration(minutes: autoLockMinutes)) {
      ref.read(isLockedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(isLockedProvider);
    return Stack(
      children: [
        widget.child,
        if (locked) const LockScreen(),
      ],
    );
  }
}
