import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../audit/audit_log_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/login_screen.dart';
import '../passout/pass_out_years_screen.dart';
import '../school/school_profile_screen.dart';
import 'about_screen.dart';
import 'my_account_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _notAvailableYet(BuildContext context, String feature, String phase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming in $phase — not available yet.')),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final schoolId = schoolAsync.valueOrNull?.id;

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SectionHeader('ACCOUNT'),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'My Account',
              subtitle: 'View your name and mobile number',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAccountScreen())),
            ),
            _SectionHeader('SCHOOL'),
            _SettingsTile(
              icon: Icons.school_outlined,
              title: 'School Profile',
              subtitle: 'View and edit your school information',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SchoolProfileScreen())),
            ),
            _SettingsTile(
              icon: Icons.groups_outlined,
              title: 'Manage Classes',
              subtitle: 'Add, rename or remove classes',
              onTap: () => _notAvailableYet(context, 'Manage Classes', 'a later phase'),
            ),
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Pass Out Years',
              subtitle: 'Add or manage pass out years',
              onTap: schoolId == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PassOutYearsScreen(schoolId: schoolId)),
                      ),
            ),
            _SectionHeader('DATA'),
            _SettingsTile(
              icon: Icons.backup_outlined,
              title: 'Backup & Restore',
              subtitle: 'Backup your data and restore when needed',
              onTap: () => _notAvailableYet(context, 'Backup & Restore', 'Phase 9'),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Export & Print',
              subtitle: 'Export student records or generate PDF',
              onTap: () => _notAvailableYet(context, 'Export & Print', 'Phase 9'),
            ),
            _SectionHeader('SECURITY'),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'App Security',
              subtitle: 'App lock, PIN, fingerprint and auto-lock',
              onTap: () => _notAvailableYet(context, 'App Security', 'Phase 10'),
            ),
            _SectionHeader('OTHER'),
            _SettingsTile(
              icon: Icons.history,
              title: 'Audit Log',
              subtitle: 'See every change made to your records',
              onTap: schoolId == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AuditLogScreen(schoolId: schoolId)),
                      ),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About G.R. Book',
              subtitle: 'App version, help and support',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out from your account',
              iconColor: Colors.red,
              onTap: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (iconColor ?? GrBookTheme.primary).withOpacity(0.12),
            child: Icon(icon, color: iconColor ?? GrBookTheme.primaryDark),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
