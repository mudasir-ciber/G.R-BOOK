import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../providers/sync_providers.dart';
import '../auth/auth_providers.dart';
import '../certificates/certificates_hub_screen.dart';
import '../complaints/student_complaint_screen.dart';
import '../settings/backup_restore_screen.dart';
import '../settings/my_account_screen.dart';
import '../students/all_students_screen.dart';
import '../students/student_form_screen.dart';

/// Screen: Final Homepage matching reference UI image exactly.
/// Features:
/// - Top header with G.R. Book logo badge, Notifications bell with red badge, and User profile avatar.
/// - Dynamic greeting based on device current local time with auto-updates on app resume.
/// - Dynamic school name.
/// - Exactly 5 vertical feature cards:
///   1. Add New Student (Emerald green hero card)
///   2. View All Students
///   3. Certificates
///   4. Student Complaint
///   5. Backup Google Drive
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.onNavigateToClasses,
    this.onNavigateToAccount,
  });

  final VoidCallback? onNavigateToClasses;
  final VoidCallback? onNavigateToAccount;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-evaluate current local time greeting when user returns to app
      setState(() {});
    }
  }

  /// Calculates dynamic greeting according to device current local time:
  /// - 05:00 AM – 11:59 AM: Good Morning ☀️
  /// - 12:00 PM – 04:59 PM: Good Afternoon 🌤️
  /// - 05:00 PM – 08:59 PM: Good Evening 🌅
  /// - 09:00 PM – 04:59 AM: Good Night 🌙
  String _getDynamicGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;

    if (totalMinutes >= 5 * 60 && totalMinutes < 12 * 60) {
      return 'Good Morning ☀️';
    } else if (totalMinutes >= 12 * 60 && totalMinutes < 17 * 60) {
      return 'Good Afternoon 🌤️';
    } else if (totalMinutes >= 17 * 60 && totalMinutes < 21 * 60) {
      return 'Good Evening 🌅';
    } else {
      return 'Good Night 🌙';
    }
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final pendingCountAsync = ref.watch(pendingSyncCountProvider);
            final isSyncing = ref.watch(isSyncingProvider);
            final pendingCount = pendingCountAsync.valueOrNull ?? 0;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF0F9D58), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Notifications & Status',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GrBookTheme.textPrimary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GrBookTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                pendingCount == 0 ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                                color: pendingCount == 0 ? const Color(0xFF0F9D58) : const Color(0xFFE65100),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pendingCount == 0 ? 'All Changes Synced' : '$pendingCount Items Pending Sync',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isSyncing
                                          ? 'Syncing changes to cloud...'
                                          : (pendingCount == 0
                                              ? 'Local database is fully updated.'
                                              : 'Changes will sync automatically when online.'),
                                      style: const TextStyle(fontSize: 12, color: GrBookTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F9D58),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  triggerSync(ref);
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sync triggered...')),
                                  );
                                },
                                child: const Text('Sync Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.cloud_sync_rounded, color: Color(0xFF0284C7), size: 24),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Google Drive Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    SizedBox(height: 2),
                                    Text('Keep your school data safe', style: TextStyle(fontSize: 12, color: GrBookTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0284C7),
                                  side: const BorderSide(color: Color(0xFF0284C7)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
                                  );
                                },
                                child: const Text('Open Backup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final user = ref.watch(currentUserProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final pendingCount = pendingCountAsync.valueOrNull ?? 0;

    final schoolName = schoolAsync.valueOrNull?.schoolName ?? 'Govt. Boys High School';
    final userFullName = user?.userMetadata?['full_name'] as String? ?? '';
    final userInitial = userFullName.trim().isNotEmpty ? userFullName.trim()[0].toUpperCase() : 'U';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP HEADER (Logo Badge on left, Notifications + Profile on right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Logo Badge
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD6E8DC), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.auto_stories_rounded,
                                color: GrBookTheme.primary,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'G.R. Book',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F2D1F),
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              'School Management System',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4A7A60),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right: Notifications Bell + User Profile Avatar
                    Row(
                      children: [
                        // Notification Bell with Red Badge
                        InkWell(
                          onTap: () => _showNotificationsSheet(context),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD6E8DC), width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: Color(0xFF0F2D1F),
                                  size: 22,
                                ),
                                if (pendingCount > 0)
                                  Positioned(
                                    top: 9,
                                    right: 9,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // User Profile Avatar
                        InkWell(
                          onTap: () {
                            if (widget.onNavigateToAccount != null) {
                              widget.onNavigateToAccount!();
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MyAccountScreen()),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D58),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A0F9D58),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              userInitial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 2. DYNAMIC GREETING & SCHOOL NAME
                Text(
                  _getDynamicGreeting(),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E6348),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schoolName,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2D1F),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),

                // 3. EXACTLY 5 VERTICAL FEATURE CARDS

                // Card 1: Add New Student (Hero Card)
                _buildHeroCard(
                  title: 'Add New Student',
                  subtitle: 'Register a new student into the G.R. Book',
                  icon: Icons.person_add_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StudentFormScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Card 2: View All Students
                _buildFeatureCard(
                  title: 'View All Students',
                  subtitle: 'View, filter, and search across all classes',
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF0F9D58),
                  iconBgColor: const Color(0xFFE8F5E9),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AllStudentsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Card 3: Certificates
                _buildFeatureCard(
                  title: 'Certificates',
                  subtitle: 'Generate and print official certificates',
                  icon: Icons.workspace_premium_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBgColor: const Color(0xFFFEF3C7),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CertificatesHubScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Card 4: Student Complaint
                _buildFeatureCard(
                  title: 'Student Complaint',
                  subtitle: 'Record notes & share directly with parents',
                  icon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBgColor: const Color(0xFFE0F2FE),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StudentComplaintScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Card 5: Backup Google Drive
                _buildFeatureCard(
                  title: 'Backup Google Drive',
                  subtitle: 'Secure cloud backup & restore data',
                  icon: Icons.cloud_sync_rounded,
                  iconColor: const Color(0xFF16A34A),
                  iconBgColor: const Color(0xFFDCFCE7),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hero card for "Add New Student" with prominent emerald green gradient
  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9D58), Color(0xFF075E33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F9D58),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow circle button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Clean white feature card matching reference UI image
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // Rounded icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
