import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/dashboard_repository.dart';
import '../../widgets/gr_book_ui_components.dart';
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
                title: 'Dashboard',
                subtitle: 'School and class records overview',
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

                    final totalAsync = ref.watch(totalActiveStudentsProvider(school.id));
                    final classesAsync = ref.watch(classesWithCountsProvider(school.id));

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // Total Active Students Hero Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: GrBookTheme.primaryButtonGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x280F7A42),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Active Students',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    totalAsync.valueOrNull?.toString() ?? '-',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Age Reference Selector
                        const Text(
                          'Age Calculated As Of',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GrBookTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Today'),
                              selected: ageReference == AgeReference.today,
                              selectedColor: const Color(0xFFDCF2E4),
                              labelStyle: TextStyle(
                                color: ageReference == AgeReference.today
                                    ? GrBookTheme.primaryDark
                                    : GrBookTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) =>
                                  ref.read(ageReferenceProvider.notifier).state = AgeReference.today,
                            ),
                            ChoiceChip(
                              label: const Text('Admission Date'),
                              selected: ageReference == AgeReference.admissionDate,
                              selectedColor: const Color(0xFFDCF2E4),
                              labelStyle: TextStyle(
                                color: ageReference == AgeReference.admissionDate
                                    ? GrBookTheme.primaryDark
                                    : GrBookTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) =>
                                  ref.read(ageReferenceProvider.notifier).state = AgeReference.admissionDate,
                            ),
                            ChoiceChip(
                              label: Text(ageReference == AgeReference.custom && customDate != null
                                  ? dateFormat.format(customDate)
                                  : 'Custom Date'),
                              selected: ageReference == AgeReference.custom,
                              selectedColor: const Color(0xFFDCF2E4),
                              labelStyle: TextStyle(
                                color: ageReference == AgeReference.custom
                                    ? GrBookTheme.primaryDark
                                    : GrBookTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) => _pickCustomDate(context, ref),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Classes & Age Distribution',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GrBookTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        classesAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error loading classes: $e'),
                          data: (classes) => Column(
                            children: classes.map((entry) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: const GrBookIconBadge(icon: Icons.groups_rounded),
                                  title: Text(
                                    entry.schoolClass.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: Text(
                                    '${entry.activeStudentCount} active students',
                                    style: const TextStyle(fontSize: 12, color: GrBookTheme.textSecondary),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded, color: GrBookTheme.primary),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ClassAgeStatsScreen(
                                          schoolClass: entry.schoolClass,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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
}
