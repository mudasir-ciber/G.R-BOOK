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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
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
                      icon: const Icon(Icons.search, color: GrBookTheme.primary, size: 22),
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
                      icon: const Icon(Icons.dashboard_outlined, color: GrBookTheme.primary, size: 22),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: GrBookTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.apartment_rounded,
                                      color: GrBookTheme.primary,
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: GrBookTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'SEMIS: ${school.semisCode ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: GrBookTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: GrBookTheme.primary,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. Classes Header
                          const Text(
                            'Classes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: GrBookTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Select a class to manage student records',
                            style: TextStyle(
                              fontSize: 13,
                              color: GrBookTheme.textSecondary,
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
                                    title: 'STRUCK OFF',
                                    subtitle: 'Manage struck off students',
                                    icon: Icons.person_off_rounded,
                                    badgeColor: Colors.red.shade50,
                                    iconColor: Colors.red.shade700,
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

  Widget _buildClassCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? badgeColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GrBookIconBadge(
                  icon: icon,
                  backgroundColor: badgeColor,
                  iconColor: iconColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GrBookTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: GrBookTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GrBookTheme.primary,
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
