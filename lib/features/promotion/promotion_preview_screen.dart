import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../features/auth/auth_providers.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/promotion_providers.dart';

class PromotionPreviewScreen extends ConsumerStatefulWidget {
  const PromotionPreviewScreen({
    super.key,
    required this.fromClass,
    required this.toClass,
    required this.students,
    required this.promotionDate,
  });

  final SchoolClass fromClass;
  final SchoolClass? toClass; // null => Pass Out
  final List<Student> students;
  final DateTime promotionDate;

  @override
  ConsumerState<PromotionPreviewScreen> createState() => _PromotionPreviewScreenState();
}

class _PromotionPreviewScreenState extends ConsumerState<PromotionPreviewScreen> {
  bool _isConfirming = false;

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);
    try {
      final userId = ref.read(currentUserProvider)?.id;
      await ref.read(promotionRepositoryProvider).promoteStudents(
            schoolId: widget.fromClass.schoolId,
            fromClass: widget.fromClass,
            selectedStudentIds: widget.students.map((s) => s.id).toList(),
            promotionDate: widget.promotionDate,
            performedBy: userId,
          );
      ref.invalidate(hasUndoableBatchProvider(widget.fromClass.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.students.length} student(s) promoted.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promotion failed: $e')));
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final targetName = widget.toClass?.displayName ?? 'Passed Out';

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Confirm Promotion')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryRow(label: 'From Class', value: widget.fromClass.displayName),
                      _SummaryRow(label: 'To', value: targetName),
                      _SummaryRow(label: 'Promotion Date', value: dateFormat.format(widget.promotionDate)),
                      _SummaryRow(label: 'Students', value: '${widget.students.length}'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = widget.students[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                      child: Text(s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?'),
                    ),
                    title: Text(s.studentName),
                    subtitle: Text('GR: ${s.grNumber}'),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: GrBookTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isConfirming ? null : _confirm,
                  icon: _isConfirming
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Confirm Promotion'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
