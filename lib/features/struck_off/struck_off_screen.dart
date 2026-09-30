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
      backgroundColor: GrBookTheme.isDark(context) ? GrBookTheme.darkBackground : GrBookTheme.background,
      appBar: AppBar(title: const Text('Struck Off Students')),
      body: SafeArea(
        child: studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (students) {
            if (students.isEmpty) {
              return Center(child: Text('No struck-off students.', style: TextStyle(color: GrBookTheme.getTextSecondary(context))));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = students[index];
                return Container(
                  decoration: BoxDecoration(
                    color: GrBookTheme.getCardBackground(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: GrBookTheme.primary.withValues(alpha: 0.15),
                          child: Text(
                            s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                            style: const TextStyle(color: GrBookTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.studentName, style: TextStyle(fontWeight: FontWeight.w600, color: GrBookTheme.getTextPrimary(context))),
                              Text('GR: ${s.grNumber}', style: TextStyle(color: GrBookTheme.getTextSecondary(context), fontSize: 12)),
                              const SizedBox(height: 4),
                              if (s.struckOffDate != null)
                                Text('Struck off: ${dateFormat.format(s.struckOffDate!)}',
                                    style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                              if (s.struckOffReason != null)
                                Text('Reason: ${s.struckOffReason}', style: TextStyle(color: GrBookTheme.getTextSecondary(context), fontSize: 12)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: GrBookTheme.isDark(context) ? Colors.white : GrBookTheme.primaryDark,
                            side: BorderSide(color: GrBookTheme.getBorderColor(context)),
                          ),
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
