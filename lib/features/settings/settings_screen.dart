import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../audit/audit_log_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/login_screen.dart';
import '../classes/manage_classes_screen.dart';
import '../passout/pass_out_years_screen.dart';
import '../school/school_profile_screen.dart';
import '../security/app_lock_setup_screen.dart';
import 'about_screen.dart';
import 'backup_restore_screen.dart';
import 'export_print_screen.dart';
import 'my_account_screen.dart';

/// Screen 5: Settings Page matching reference UI image 5 exactly.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.showBack = true});

  final bool showBack;

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
      ref.read(appUnlockedProvider.notifier).state = false;
      await ref.read(authServiceProvider).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B7E73),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GrBookIconBadge(
                  icon: icon,
                  backgroundColor: badgeColor,
                  iconColor: iconColor,
                  size: 42,
                  iconSize: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: GrBookTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: GrBookTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GrBookTheme.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final schoolId = schoolAsync.valueOrNull?.id;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GrBookTopBar(showBack: showBack),
              const GrBookPageHeader(
                title: 'Settings',
                subtitle: 'Manage your school, account and app settings',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: [
                    _buildSectionHeader('ACCOUNT'),
                    _buildTile(
                      icon: Icons.person_rounded,
                      title: 'My Account',
                      subtitle: 'View and update your name, mobile number and password',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyAccountScreen()),
                      ),
                    ),

                    _buildSectionHeader('SCHOOL'),
                    _buildTile(
                      icon: Icons.apartment_rounded,
                      title: 'School Profile',
                      subtitle: 'View and edit your school information',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SchoolProfileScreen()),
                      ),
                    ),
                    _buildTile(
                      icon: Icons.groups_rounded,
                      title: 'Manage Classes',
                      subtitle: 'Add, rename or remove classes',
                      onTap: schoolId == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ManageClassesScreen(schoolId: schoolId),
                                ),
                              ),
                    ),
                    _buildTile(
                      icon: Icons.school_rounded,
                      title: 'Pass Out Years',
                      subtitle: 'Add or manage pass out years',
                      onTap: schoolId == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PassOutYearsScreen(schoolId: schoolId),
                                ),
                              ),
                    ),

                    _buildSectionHeader('DATA'),
                    _buildTile(
                      icon: Icons.cloud_sync_rounded,
                      title: 'Backup & Restore',
                      subtitle: 'Backup your data and restore when needed',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
                      ),
                    ),
                    _buildTile(
                      icon: Icons.description_rounded,
                      title: 'Export & Print',
                      subtitle: 'Export student records or generate PDF',
                      onTap: schoolId == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExportPrintScreen(schoolId: schoolId),
                                ),
                              ),
                    ),

                    _buildSectionHeader('SECURITY'),
                    _buildTile(
                      icon: Icons.shield_rounded,
                      title: 'App Security',
                      subtitle: 'App lock, PIN, fingerprint and auto-lock',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppLockSetupScreen()),
                      ),
                    ),

                    _buildSectionHeader('OTHER'),
                    _buildTile(
                      icon: Icons.history_rounded,
                      title: 'Audit Log',
                      subtitle: 'See every change made to your records',
                      onTap: schoolId == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AuditLogScreen(schoolId: schoolId),
                                ),
                              ),
                    ),
                    _buildTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About G.R. Book',
                      subtitle: 'App version, help and support',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                    _buildTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out from your account',
                      iconColor: Colors.red.shade600,
                      badgeColor: Colors.red.shade50,
                      onTap: () => _confirmLogout(context, ref),
                    ),
                    const SizedBox(height: 24),
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
