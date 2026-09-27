import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/school.dart';
import '../../providers/dashboard_providers.dart';
import 'dashboard_class_students_screen.dart';

class ClassAgeStatsScreen extends ConsumerWidget {
  const ClassAgeStatsScreen({super.key, required this.schoolClass});

  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = ref.watch(ageReferenceProvider);
    final customDate = ref.watch(customAgeDateProvider);
    final statsAsync = ref.watch(
      classAgeStatsProvider((classId: schoolClass.id, reference: reference, customDate: customDate)),
    );
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: Text('${schoolClass.displayName} — Age Stats')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          if (stats.totalStudents == 0) {
            return const Center(child: Text('No active students in this class.'));
          }

          final maxCount = stats.buckets.map((b) => b.count).fold(0, (a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Age Distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${stats.totalStudents} active students', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      for (final bucket in stats.buckets)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 64, child: Text('${bucket.years} years')),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: maxCount == 0 ? 0 : bucket.count / maxCount,
                                    minHeight: 18,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation(GrBookTheme.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(width: 70, child: Text('${bucket.count} students', textAlign: TextAlign.end)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ExtremeCard(
                      label: 'Youngest',
                      name: stats.youngest?.studentName,
                      dob: stats.youngest?.dateOfBirth,
                      dateFormat: dateFormat,
                      icon: Icons.arrow_downward,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ExtremeCard(
                      label: 'Oldest',
                      name: stats.oldest?.studentName,
                      dob: stats.oldest?.dateOfBirth,
                      dateFormat: dateFormat,
                      icon: Icons.arrow_upward,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GrBookTheme.primaryDark,
                    side: const BorderSide(color: GrBookTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('View Full List (Name, GR, DOB, Age)'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DashboardClassStudentsScreen(schoolClass: schoolClass)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExtremeCard extends StatelessWidget {
  const _ExtremeCard({
    required this.label,
    required this.name,
    required this.dob,
    required this.dateFormat,
    required this.icon,
    required this.color,
  });

  final String label;
  final String? name;
  final DateTime? dob;
  final DateFormat dateFormat;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))]),
            const SizedBox(height: 8),
            Text(name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            if (dob != null) Text('DOB: ${dateFormat.format(dob!)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
