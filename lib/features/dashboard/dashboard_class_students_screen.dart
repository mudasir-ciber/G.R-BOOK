import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/age_calculator.dart';
import '../../core/theme.dart';
import '../../models/school.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/dashboard_repository.dart';

/// Requirement #24: tapping a class from the Dashboard shows Student
/// Name, GR Number, Date of Birth, and Full Age — distinct from the
/// regular Class Students screen (which is Serial/GR/Photo/Name and is
/// the CRUD entry point, not a reporting view).
class DashboardClassStudentsScreen extends ConsumerWidget {
  const DashboardClassStudentsScreen({super.key, required this.schoolClass});

  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_activeStudentsProvider(schoolClass.id));
    final reference = ref.watch(ageReferenceProvider);
    final customDate = ref.watch(customAgeDateProvider);
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: Text('${schoolClass.displayName} — Details')),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No active students in this class.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = students[index];
              final asOf = switch (reference) {
                AgeReference.today => DateTime.now(),
                AgeReference.admissionDate => s.dateOfAdmission,
                AgeReference.custom => customDate ?? DateTime.now(),
              };
              final age = AgeCalculator.calculate(dateOfBirth: s.dateOfBirth, asOf: asOf);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('GR: ${s.grNumber}  •  DOB: ${dateFormat.format(s.dateOfBirth)}'),
                trailing: Text(age.formatShort(), style: const TextStyle(fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark)),
              );
            },
          );
        },
      ),
    );
  }
}

final _activeStudentsProvider = StreamProvider.family((ref, String classId) {
  return ref.watch(studentRepositoryProvider).watchActiveStudentsForClass(classId);
});
