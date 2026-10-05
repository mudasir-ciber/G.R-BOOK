import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../providers/theme_provider.dart';
import '../../services/app_update_service.dart';
import '../../widgets/app_update_dialog.dart';
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
  static bool _hasCheckedForUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_hasCheckedForUpdate) {
      _hasCheckedForUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _silentCheckForUpdate());
    }
  }

  Future<void> _silentCheckForUpdate() async {
    try {
      final update = await ref.read(appUpdateServiceProvider).checkForUpdate();
      if (mounted && update != null) {
        await AppUpdateDialog.show(context, update);
      }
    } catch (_) {}
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


  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final user = ref.watch(currentUserProvider);

    final schoolName = schoolAsync.valueOrNull?.schoolName ?? 'Govt. Boys High School';
    final userFullName = user?.userMetadata?['full_name'] as String? ?? '';
    final userInitial = userFullName.trim().isNotEmpty ? userFullName.trim()[0].toUpperCase() : 'U';

    final isDark = GrBookTheme.isDark(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GrBookTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP HEADER (Logo Badge on left, Theme Toggle + Profile on right)
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
                            color: isDark ? const Color(0xFF18261E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF24382B) : const Color(0xFFD6E8DC),
                              width: 1.2,
                            ),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'G.R BOOK',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: GrBookTheme.getTextPrimary(context),
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              'School Management System',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: GrBookTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right: Theme Toggle (Moon Icon) + User Profile Avatar
                    Row(
                      children: [
                        // Theme Toggle Icon
                        InkWell(
                          onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/theme_moon.png',
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                                  color: isDark ? const Color(0xFFFBBF24) : GrBookTheme.primary,
                                  size: 24,
                                ),
                              ),
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
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF68D391) : const Color(0xFF2E6348),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schoolName,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: GrBookTheme.getTextPrimary(context),
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

  /// Clean feature card matching reference UI image with dark mode support
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    final isDark = GrBookTheme.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: GrBookTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.2),
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
                    color: isDark ? iconColor.withValues(alpha: 0.2) : iconBgColor,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GrBookTheme.getTextPrimary(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
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

                // Subtle chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
