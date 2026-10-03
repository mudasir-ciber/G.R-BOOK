import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../admin/master_admin_portal_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/login_screen.dart';
import '../classes/manage_classes_screen.dart';
import '../passout/pass_out_years_screen.dart';
import '../school/school_profile_screen.dart';
import 'about_screen.dart';
import 'add_data_storage_screen.dart';
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
      ref.invalidate(isSuperAdminProvider);
      ref.invalidate(currentUserProvider);
      await ref.read(authServiceProvider).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = GrBookTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 18, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF9FB5A6) : const Color(0xFF6B7E73),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? badgeColor,
  }) {
    final isDark = GrBookTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: GrBookTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: GrBookTheme.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: GrBookTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF68D391) : GrBookTheme.primary,
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
    final isSuperAdmin = ref.watch(isSuperAdminProvider).valueOrNull ?? false;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GrBookTheme.getBackgroundGradient(context),
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
                    if (isSuperAdmin) ...[
                      _buildSectionHeader(context, 'MASTER ADMIN CONTROL'),
                      _buildTile(
                        context,
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Master Admin Portal',
                        subtitle: 'Approve new signups, manage & block accounts',
                        iconColor: Colors.amber.shade400,
                        badgeColor: Colors.amber.shade900.withValues(alpha: 0.25),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MasterAdminPortalScreen()),
                        ),
                      ),
                    ],

                    _buildSectionHeader(context, 'ACCOUNT'),
                    _buildTile(
                      context,
                      icon: Icons.person_rounded,
                      title: 'Principal Account',
                      subtitle: 'Name, profile photo, signature & password',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyAccountScreen()),
                      ),
                    ),

                    _buildSectionHeader(context, 'SCHOOL'),
                    _buildTile(
                      context,
                      icon: Icons.apartment_rounded,
                      title: 'School Profile',
                      subtitle: 'View and edit your school information',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SchoolProfileScreen()),
                      ),
                    ),
                    _buildTile(
                      context,
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
                      context,
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

                    _buildSectionHeader(context, 'DATA'),
                    _buildTile(
                      context,
                      icon: Icons.cloud_sync_rounded,
                      title: 'Backup & Restore',
                      subtitle: 'Backup your data and restore when needed',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
                      ),
                    ),
                    _buildTile(
                      context,
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

                    _buildSectionHeader(context, 'STORAGE & RESTORE'),
                    _buildTile(
                      context,
                      icon: Icons.drive_folder_upload_rounded,
                      title: 'Add Data (Restore from Storage)',
                      subtitle: 'Sync records from phone GR BOOK folder',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddDataStorageScreen(),
                        ),
                      ),
                    ),
                    _buildTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About G.R BOOK',
                      subtitle: 'App version, help and support',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                    _buildTile(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out from your account',
                      iconColor: Colors.red.shade400,
                      badgeColor: Colors.red.shade900.withValues(alpha: 0.3),
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
