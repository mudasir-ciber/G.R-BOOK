import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../auth/auth_providers.dart';

class MyAccountScreen extends ConsumerWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final fullName = user?.userMetadata?['full_name'] as String? ?? '-';
    final mobileNumber = user?.userMetadata?['mobile_number'] as String? ?? '-';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(),
              const GrBookPageHeader(
                title: 'My Account',
                subtitle: 'View and update your name, mobile number and password',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: GrBookTheme.primaryLight,
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
        Text(label, style: const TextStyle(color: GrBookTheme.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: GrBookTheme.textPrimary)),
      ],
    );
  }
}
