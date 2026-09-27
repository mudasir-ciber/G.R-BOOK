import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../features/auth/auth_providers.dart';
import '../../models/student.dart';
import '../../providers/struck_off_providers.dart';

class StruckOffScreen extends ConsumerWidget {
  const StruckOffScreen({super.key, required this.schoolId});

  final String schoolId;

  Future<void> _confirmReAdmit(BuildContext context, WidgetRef ref, Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-admit Student'),
        content: Text('${student.studentName} will be restored as an active student in their class. The struck-off record stays in their history.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Re-admit'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final userId = ref.read(currentUserProvider)?.id;
    final ok = await ref.read(struckOffRepositoryProvider).reAdmitStudent(
          schoolId: schoolId,
          student: student,
          performedBy: userId,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '${student.studentName} re-admitted.' : 'Could not re-admit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(struckOffStudentsProvider(schoolId));
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Struck Off Students')),
      body: SafeArea(
        child: studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (students) {
            if (students.isEmpty) {
              return const Center(child: Text('No struck-off students.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = students[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                          child: Text(s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('GR: ${s.grNumber}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 4),
                              if (s.struckOffDate != null)
                                Text('Struck off: ${dateFormat.format(s.struckOffDate!)}',
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                              if (s.struckOffReason != null)
                                Text('Reason: ${s.struckOffReason}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: GrBookTheme.primaryDark),
                          onPressed: () => _confirmReAdmit(context, ref, s),
                          child: const Text('Re-admit'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
