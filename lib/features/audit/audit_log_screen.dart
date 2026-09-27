import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/audit_log_providers.dart';
import '../../repositories/audit_log_repository.dart';

/// [studentId] narrows the log to one student (e.g. opened from a
/// student's profile); leave null for the school-wide log.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key, required this.schoolId, this.studentId, this.title});

  final String schoolId;
  final String? studentId;
  final String? title;

  IconData _iconFor(String action) {
    if (action.contains('CREATED')) return Icons.add_circle_outline;
    if (action.contains('EDITED') || action.contains('UPDATED')) return Icons.edit_outlined;
    if (action.contains('CONFLICT')) return Icons.warning_amber_rounded;
    if (action.contains('PROMOTED') || action.contains('PROMOTION')) return Icons.arrow_upward;
    if (action.contains('FAILED')) return Icons.remove_circle_outline;
    if (action.contains('STRUCK_OFF')) return Icons.person_off_outlined;
    if (action.contains('RE_ADMITTED')) return Icons.person_add_alt_1;
    if (action.contains('PHOTO')) return Icons.photo_camera_outlined;
    return Icons.history;
  }

  Color _colorFor(String action) {
    if (action.contains('CONFLICT') || action.contains('FAILED') || action.contains('STRUCK_OFF')) {
      return Colors.red.shade600;
    }
    if (action.contains('UNDONE')) return Colors.orange.shade700;
    return GrBookTheme.primaryDark;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider((schoolId: schoolId, studentId: studentId)));
    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: Text(title ?? 'Audit Log')),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No activity recorded yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                child: ExpansionTile(
                  leading: Icon(_iconFor(log.action), color: _colorFor(log.action)),
                  title: Text(log.displayAction, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${log.studentName != null ? '${log.studentName}  •  ' : ''}${dateFormat.format(log.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    if (log.oldValue != null) _ValueBlock(label: 'Before', value: log.oldValue!),
                    if (log.newValue != null) _ValueBlock(label: 'After', value: log.newValue!),
                    if (log.oldValue == null && log.newValue == null)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No additional details recorded.', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.label, required this.value});
  final String label;
  final Map<String, dynamic> value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 2),
            ...value.entries.map(
              (e) => Text('${e.key}: ${e.value}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
