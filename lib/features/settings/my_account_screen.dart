import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../auth/auth_providers.dart';

/// Requirement #35's "My Account" — full name, mobile number. These
/// come from the Supabase Auth session's user_metadata (set at sign-up
/// in AuthService.createAccount), so this screen works with no network.
/// Editing name/mobile/password is deferred — flagged honestly below
/// rather than wired to a button that doesn't actually save anything.
class MyAccountScreen extends ConsumerWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final fullName = user?.userMetadata?['full_name'] as String? ?? '-';
    final mobileNumber = user?.userMetadata?['mobile_number'] as String? ?? '-';

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('My Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                        child: Text(
                          fullName.isNotEmpty && fullName != '-' ? fullName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28, color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: 'Full Name', value: fullName),
                      const Divider(height: 24),
                      _InfoRow(label: 'Mobile Number', value: mobileNumber),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing your name, mobile number, or password isn\'t available yet.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
