import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/app_lock_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entered = '';
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricFirst());
  }

  Future<void> _tryBiometricFirst() async {
    final service = ref.read(appLockServiceProvider);
    if (await service.isBiometricEnabled() && await service.deviceSupportsBiometrics()) {
      final ok = await service.authenticateWithBiometrics();
      if (ok) _unlock();
    }
  }

  void _unlock() {
    ref.read(isLockedProvider.notifier).state = false;
  }

  Future<void> _onDigit(String digit) async {
    if (_checking) return;
    setState(() {
      _error = null;
      _entered += digit;
    });
    if (_entered.length >= 4) {
      setState(() => _checking = true);
      final ok = await ref.read(appLockServiceProvider).verifyPin(_entered);
      if (ok) {
        _unlock();
        return;
      }
      if (mounted) {
        setState(() {
          _error = 'Incorrect PIN';
          _entered = '';
          _checking = false;
        });
      }
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // can't back out of the lock screen
      child: Scaffold(
        backgroundColor: GrBookTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.lock_outline, size: 48, color: GrBookTheme.primary),
              const SizedBox(height: 12),
              const Text('G.R. Book Locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Enter your PIN', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? GrBookTheme.primary : Colors.transparent,
                      border: Border.all(color: GrBookTheme.primary),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ],
              const Spacer(),
              _NumPad(onDigit: _onDigit, onBackspace: _backspace),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumPad extends ConsumerWidget {
  const _NumPad({required this.onDigit, required this.onBackspace});
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(child: child ?? Text(label, style: const TextStyle(fontSize: 22))),
          ),
        ),
      );
    }

    Widget row(List<Widget> children) => Row(children: children);

    return Column(
      children: [
        row([key('1', onTap: () => onDigit('1')), key('2', onTap: () => onDigit('2')), key('3', onTap: () => onDigit('3'))]),
        row([key('4', onTap: () => onDigit('4')), key('5', onTap: () => onDigit('5')), key('6', onTap: () => onDigit('6'))]),
        row([key('7', onTap: () => onDigit('7')), key('8', onTap: () => onDigit('8')), key('9', onTap: () => onDigit('9'))]),
        row([
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.fingerprint),
              iconSize: 28,
              color: GrBookTheme.primary,
              onPressed: () async {
                final service = ref.read(appLockServiceProvider);
                if (await service.isBiometricEnabled() && await service.deviceSupportsBiometrics()) {
                  final ok = await service.authenticateWithBiometrics();
                  if (ok) ref.read(isLockedProvider.notifier).state = false;
                }
              },
            ),
          ),
          key('0', onTap: () => onDigit('0')),
          key('', child: const Icon(Icons.backspace_outlined), onTap: onBackspace),
        ]),
      ],
    );
  }
}
