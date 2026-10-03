import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/app_lock_providers.dart';

class AppLockSetupScreen extends ConsumerStatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  ConsumerState<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends ConsumerState<AppLockSetupScreen> {
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _hasPin = false;
  int _autoLockMinutes = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(appLockServiceProvider);
    final results = await Future.wait([
      service.isAppLockEnabled(),
      service.isBiometricEnabled(),
      service.deviceSupportsBiometrics(),
      service.hasPinSet(),
      service.getAutoLockMinutes(),
    ]);
    if (!mounted) return;
    setState(() {
      _lockEnabled = results[0] as bool;
      _biometricEnabled = results[1] as bool;
      _biometricAvailable = results[2] as bool;
      _hasPin = results[3] as bool;
      _autoLockMinutes = results[4] as int;
      _loading = false;
    });
  }

  Future<void> _toggleLock(bool enable) async {
    final service = ref.read(appLockServiceProvider);
    if (enable && !_hasPin) {
      final pin = await _promptSetPin();
      if (pin == null) return; // user cancelled — don't enable without a PIN
      await service.setPin(pin);
      _hasPin = true;
    }
    await service.setAppLockEnabled(enable);
    setState(() => _lockEnabled = enable);
  }

  Future<String?> _promptSetPin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Set a PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'New PIN (4–6 digits)'),
                ),
                TextField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Confirm PIN'),
                ),
                if (error != null) Text(error!, style: TextStyle(color: Colors.red.shade700)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
                onPressed: () {
                  final pin = pinController.text.trim();
                  if (pin.length < 4) {
                    setState(() => error = 'PIN must be at least 4 digits.');
                    return;
                  }
                  if (pin != confirmController.text.trim()) {
                    setState(() => error = 'PINs do not match.');
                    return;
                  }
                  Navigator.of(context).pop(pin);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changePin() async {
    final pin = await _promptSetPin();
    if (pin != null) {
      await ref.read(appLockServiceProvider).setPin(pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('App Security')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                activeThumbColor: GrBookTheme.primary,
                value: _lockEnabled,
                title: const Text('Enable App Lock'),
                subtitle: const Text('Require a PIN (and optionally fingerprint) to open the app'),
                onChanged: _toggleLock,
              ),
            ),
            if (_lockEnabled) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.pin_outlined, color: GrBookTheme.primaryDark),
                  title: const Text('Change PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePin,
                ),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    activeThumbColor: GrBookTheme.primary,
                    value: _biometricEnabled,
                    title: const Text('Use Fingerprint / Face Unlock'),
                    subtitle: const Text('Falls back to your PIN if biometric fails'),
                    onChanged: (v) async {
                      await ref.read(appLockServiceProvider).setBiometricEnabled(v);
                      setState(() => _biometricEnabled = v);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.timer_outlined, color: GrBookTheme.primaryDark),
                  title: const Text('Auto-Lock'),
                  subtitle: Text(_autoLockLabel(_autoLockMinutes)),
                  trailing: DropdownButton<int>(
                    value: _autoLockMinutes,
                    underline: const SizedBox.shrink(),
                    items: const [0, 1, 5, 15]
                        .map((m) => DropdownMenuItem(value: m, child: Text(_autoLockLabel(m))))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      await ref.read(appLockServiceProvider).setAutoLockMinutes(v);
                      setState(() => _autoLockMinutes = v);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _autoLockLabel(int minutes) {
    if (minutes == 0) return 'Immediately';
    return 'After $minutes minute${minutes == 1 ? '' : 's'}';
  }
}
