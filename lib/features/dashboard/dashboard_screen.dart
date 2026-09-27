import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/dashboard_repository.dart';
import '../../widgets/sync_status_banner.dart';
import 'class_age_stats_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _pickCustomDate(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(customAgeDateProvider) ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(customAgeDateProvider.notifier).state = picked;
      ref.read(ageReferenceProvider.notifier).state = AgeReference.custom;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final ageReference = ref.watch(ageReferenceProvider);
    final customDate = ref.watch(customAgeDateProvider);
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Dashboard')),
      body: schoolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (school) {
          if (school == null) {
            return const Center(child: Text('No school set up on this device yet.'));
          }

          final totalAsync = ref.watch(totalActiveStudentsProvider(school.id));
          final classesAsync = ref.watch(classesWithCountsProvider(school.id));

          return SafeArea(
            child: Column(
              children: [
                const SyncStatusBanner(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ---- Total Active Students hero card ----
                      Card(
                        color: GrBookTheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Icon(Icons.groups, color: Colors.white, size: 36),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Active Students', style: TextStyle(color: Colors.white70)),
                                  Text(
                                    totalAsync.valueOrNull?.toString() ?? '-',
                                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---- Age reference selector ----
                      Text('Age Calculated As Of', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Today'),
                            selected: ageReference == AgeReference.today,
                            onSelected: (_) => ref.read(ageReferenceProvider.notifier).state = AgeReference.today,
                          ),
                          ChoiceChip(
                            label: const Text('Admission Date'),
                            selected: ageReference == AgeReference.admissionDate,
                            onSelected: (_) =>
                                ref.read(ageReferenceProvider.notifier).state = AgeReference.admissionDate,
                          ),
                          ChoiceChip(
                            label: Text(ageReference == AgeReference.custom && customDate != null
                                ? dateFormat.format(customDate)
                                : 'Custom Date'),
                            selected: ageReference == AgeReference.custom,
                            onSelected: (_) => _pickCustomDate(context, ref),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text('Classes', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),

                      classesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Error: $e'),
                        data: (classes) {
                          if (classes.isEmpty) return const Text('No classes configured yet.');
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: classes.length,
                            itemBuilder: (context, index) {
                              final entry = classes[index];
                              return Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ClassAgeStatsScreen(schoolClass: entry.schoolClass),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                                          child: Text(
                                            entry.schoolClass.classCode,
                                            style: const TextStyle(fontSize: 11, color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(entry.schoolClass.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text('${entry.activeStudentCount} active', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
