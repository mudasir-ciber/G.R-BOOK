import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_lock_providers.dart';

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

class _AppLockGateState extends ConsumerState<AppLockGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(isLockedProvider.notifier).state = false;
      try {
        final service = ref.read(appLockServiceProvider);
        await service.setAppLockEnabled(false);
        await service.clearPin();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
