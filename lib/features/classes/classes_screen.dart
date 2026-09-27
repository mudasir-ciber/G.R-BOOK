import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/sync_status_banner.dart';
import '../dashboard/dashboard_screen.dart';
import '../passout/pass_out_years_screen.dart';
import '../search/global_search_screen.dart';
import '../settings/settings_screen.dart';
import '../struck_off/struck_off_screen.dart';
import '../students/class_students_screen.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),
        title: const Text('Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: schoolAsync.valueOrNull == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => GlobalSearchScreen(schoolId: schoolAsync.value!.id)),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
            },
          ),
        ],
      ),
      body: Column(children: [
        const SyncStatusBanner(),
        Expanded(child: schoolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (school) {
          if (school == null) {
            return const Center(child: Text('No school set up on this device yet.'));
          }
          final classesAsync = ref.watch(classesWithCountsProvider(school.id));
          return classesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (classes) {
              if (classes.isEmpty) {
                return const Center(child: Text('No classes configured yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: classes.length + 2, // + PASS OUT + STRUCK OFF
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == classes.length) {
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                          child: const Icon(Icons.school, color: GrBookTheme.primaryDark),
                        ),
                        title: const Text('PASS OUT', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Manage pass out students'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PassOutYearsScreen(schoolId: school.id)),
                          );
                        },
                      ),
                    );
                  }
                  if (index == classes.length + 1) {
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.10),
                          child: const Icon(Icons.person_off_outlined, color: Colors.red),
                        ),
                        title: const Text('STRUCK OFF', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Manage struck off students'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StruckOffScreen(schoolId: school.id)),
                          );
                        },
                      ),
                    );
                  }

                  final entry = classes[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                        child: Text(
                          entry.schoolClass.classCode,
                          style: const TextStyle(color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(entry.schoolClass.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${entry.activeStudentCount} active students'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClassStudentsScreen(schoolClass: entry.schoolClass),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      )),
      ]),
    );
  }
}
