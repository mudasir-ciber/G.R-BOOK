import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/auth/auth_providers.dart';
import '../../models/student.dart';
import '../../providers/struck_off_providers.dart';

/// Requirement #21's reason categories: Long absence, Transfer, Leaving
/// school, Other. Shows a date + reason picker, then performs the
/// strike-off. Returns true if it went through.
Future<bool> showStruckOffDialog(BuildContext context, WidgetRef ref, {required String schoolId, required Student student}) async {
  const reasons = ['Long Absence', 'Transfer', 'Leaving School', 'Other'];
  String selectedReason = reasons.first;
  DateTime selectedDate = DateTime.now();
  final otherController = TextEditingController();
  final dateFormat = DateFormat('dd-MM-yyyy');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text('Strike Off ${student.studentName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Struck Off Date'),
                    child: Text(dateFormat.format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => selectedReason = v ?? selectedReason),
                ),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otherController,
                    decoration: const InputDecoration(labelText: 'Specify reason'),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Strike Off'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true) return false;

  final finalReason = selectedReason == 'Other' && otherController.text.trim().isNotEmpty
      ? otherController.text.trim()
      : selectedReason;

  final userId = ref.read(currentUserProvider)?.id;
  await ref.read(struckOffRepositoryProvider).struckOffStudent(
        schoolId: schoolId,
        student: student,
        struckOffDate: selectedDate,
        reason: finalReason,
        performedBy: userId,
      );
  return true;
}
