import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../../widgets/sync_status_banner.dart';
import '../dashboard/dashboard_screen.dart';
import '../passout/pass_out_years_screen.dart';
import '../school/school_profile_screen.dart';
import '../search/global_search_screen.dart';
import '../settings/settings_screen.dart';
import '../struck_off/struck_off_screen.dart';
import '../students/class_students_screen.dart';

/// Screen 4: Classes Page matching reference UI image 4 exactly.
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    final isDark = GrBookTheme.isDark(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GrBookTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Settings on Left, Book Logo in Center, Actions on Right
              GrBookTopBar(
                showBack: false,
                leadingIcon: Icons.settings_outlined,
                onLeadingPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.search, color: isDark ? const Color(0xFF68D391) : GrBookTheme.primary, size: 22),
                      tooltip: 'Search',
                      onPressed: schoolAsync.valueOrNull == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GlobalSearchScreen(schoolId: schoolAsync.value!.id),
                                ),
                              );
                            },
                    ),
                    IconButton(
                      icon: Icon(Icons.dashboard_outlined, color: isDark ? const Color(0xFF68D391) : GrBookTheme.primary, size: 22),
                      tooltip: 'Dashboard',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SyncStatusBanner(),

              Expanded(
                child: schoolAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (school) {
                    if (school == null) {
                      return const Center(child: Text('No school set up on this device yet.'));
                    }

                    final classesAsync = ref.watch(classesWithCountsProvider(school.id));

                    return RefreshIndicator(
                      color: GrBookTheme.primary,
                      onRefresh: () => ref.read(schoolRepositoryProvider).bootstrapFromServer(),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          // 1. School Info Card (Reference image 4 top card)
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SchoolProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: GrBookTheme.getCardBackground(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF22382B) : GrBookTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.apartment_rounded,
                                      color: isDark ? const Color(0xFF68D391) : GrBookTheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          school.schoolName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: GrBookTheme.getTextPrimary(context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'SEMIS: ${school.semisCode ?? 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: GrBookTheme.getTextSecondary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: isDark ? const Color(0xFF68D391) : GrBookTheme.primary,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. Classes Header
                          Text(
                            'Classes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: GrBookTheme.getTextPrimary(context),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Select a class to manage student records',
                            style: TextStyle(
                              fontSize: 13,
                              color: GrBookTheme.getTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Classes List Cards
                          classesAsync.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => Center(child: Text('Error: $e')),
                            data: (classes) {
                              return Column(
                                children: [
                                  ...classes.map((entry) {
                                    return _buildClassCard(
                                      context,
                                      title: entry.schoolClass.displayName,
                                      subtitle: 'Manage students',
                                      icon: Icons.groups_rounded,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ClassStudentsScreen(
                                              schoolClass: entry.schoolClass,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }),

                                  // PASS OUT Card
                                  _buildClassCard(
                                    context,
                                    title: 'PASS OUT',
                                    subtitle: 'Manage pass out students',
                                    icon: Icons.school_rounded,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PassOutYearsScreen(schoolId: school.id),
                                        ),
                                      );
                                    },
                                  ),

                                  // STRUCK OFF Card
                                  _buildClassCard(
                                    context,
                                    title: 'STRUCK OFF',
                                    subtitle: 'Manage struck off students',
                                    icon: Icons.person_off_rounded,
                                    badgeColor: isDark ? const Color(0xFF3B1818) : Colors.red.shade50,
                                    iconColor: isDark ? const Color(0xFFF87171) : Colors.red.shade700,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => StruckOffScreen(schoolId: school.id),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? badgeColor,
    Color? iconColor,
  }) {
    final isDark = GrBookTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GrBookTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.04),
            blurRadius: 6,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GrBookIconBadge(
                  icon: icon,
                  backgroundColor: badgeColor ?? (isDark ? const Color(0xFF22382B) : GrBookTheme.primaryLight),
                  iconColor: iconColor ?? (isDark ? const Color(0xFF68D391) : GrBookTheme.primary),
                ),
                const SizedBox(width: 14),
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: GrBookTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF68D391) : GrBookTheme.primary,
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
