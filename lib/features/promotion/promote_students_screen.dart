import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../features/auth/auth_providers.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/promotion_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/promotion_repository.dart';
import 'promotion_preview_screen.dart';

class PromoteStudentsScreen extends ConsumerStatefulWidget {
  const PromoteStudentsScreen({super.key, required this.schoolClass});

  final SchoolClass schoolClass;

  @override
  ConsumerState<PromoteStudentsScreen> createState() => _PromoteStudentsScreenState();
}

class _PromoteStudentsScreenState extends ConsumerState<PromoteStudentsScreen> {
  final _dateFormat = DateFormat('dd-MM-yyyy');
  final _searchController = TextEditingController();
  String _searchText = '';

  DateTime _promotionDate = DateTime.now();
  String? _targetClassId; // null once resolved means "Passed Out"
  bool _targetIsPassOut = false;
  final Set<String> _selectedIds = {};

  List<PromotionCandidate>? _candidates;
  bool _isLoadingCandidates = true;

  @override
  void initState() {
    super.initState();
    _targetClassId = widget.schoolClass.promotesToClassId;
    _targetIsPassOut = widget.schoolClass.isTerminal && widget.schoolClass.promotesToClassId == null;
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() => _isLoadingCandidates = true);
    final candidates = await ref.read(promotionRepositoryProvider).getCandidates(
          fromClass: widget.schoolClass,
          promotionDate: _promotionDate,
        );
    _selectedIds.clear();
    if (widget.schoolClass.minPromotionAgeMonths != null) {
      // Age-gated class (ECE -> Class 1): preselect eligible students.
      for (final c in candidates) {
        if (c.isAgeEligible) _selectedIds.add(c.student.id);
      }
    }
    if (mounted) {
      setState(() {
        _candidates = candidates;
        _isLoadingCandidates = false;
      });
    }
  }

  Future<void> _pickPromotionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _promotionDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _promotionDate = picked);
      await _loadCandidates(); // ECE eligibility depends on the chosen date
    }
  }

  Future<void> _confirmFail(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Failed'),
        content: Text('${student.studentName} will stay in ${widget.schoolClass.displayName} and this will be recorded in their promotion history.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mark Failed'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final userId = ref.read(currentUserProvider)?.id;
    await ref.read(promotionRepositoryProvider).markStudentFailed(
          schoolId: widget.schoolClass.schoolId,
          student: student,
          asOfDate: DateTime.now(),
          performedBy: userId,
        );
    _selectedIds.remove(student.id);
    await _loadCandidates();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.studentName} marked as failed.')),
      );
    }
  }

  Future<void> _undoLastPromotion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo Last Promotion'),
        content: const Text('This restores every affected student\'s previous class and status. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final userId = ref.read(currentUserProvider)?.id;
    final undone = await ref.read(promotionRepositoryProvider).undoLastPromotion(
          schoolId: widget.schoolClass.schoolId,
          fromClassId: widget.schoolClass.id,
          performedBy: userId,
        );
    await _loadCandidates();
    ref.invalidate(hasUndoableBatchProvider(widget.schoolClass.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(undone ? 'Last promotion undone.' : 'Nothing to undo.')),
      );
    }
  }

  Future<void> _goToPreview(List<SchoolClass> allClasses) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one student to promote.')),
      );
      return;
    }
    final targetClass = _targetIsPassOut
        ? null
        : allClasses.firstWhere((c) => c.id == _targetClassId, orElse: () => widget.schoolClass);

    final selectedStudents = _candidates!
        .where((c) => _selectedIds.contains(c.student.id))
        .map((c) => c.student)
        .toList();

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PromotionPreviewScreen(
          fromClass: widget.schoolClass,
          toClass: targetClass,
          students: selectedStudents,
          promotionDate: _promotionDate,
        ),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(); // back out of Promote Students to the class list
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesStreamProvider(widget.schoolClass.schoolId));
    final undoableAsync = ref.watch(hasUndoableBatchProvider(widget.schoolClass.id));

    final visibleCandidates = (_candidates ?? [])
        .where((c) =>
            _searchText.isEmpty ||
            c.student.studentName.toLowerCase().contains(_searchText.toLowerCase()) ||
            c.student.grNumber.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(
        title: const Text('Promote Students'),
        actions: [
          if (undoableAsync.valueOrNull == true)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo Last Promotion',
              onPressed: _undoLastPromotion,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _LabelledBox(
                          label: 'Current Class',
                          child: Text(widget.schoolClass.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 18)),
                      Expanded(
                        child: classesAsync.when(
                          loading: () => const _LabelledBox(label: 'Promote To', child: SizedBox(height: 20)),
                          error: (_, __) => const _LabelledBox(label: 'Promote To', child: Text('Error')),
                          data: (classes) {
                            final otherClasses = classes.where((c) => c.id != widget.schoolClass.id).toList();
                            return _LabelledBox(
                              label: 'Promote To',
                              child: DropdownButton<String>(
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                value: _targetIsPassOut ? '__PASSOUT__' : _targetClassId,
                                items: [
                                  ...otherClasses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))),
                                  if (widget.schoolClass.isTerminal)
                                    const DropdownMenuItem(value: '__PASSOUT__', child: Text('Passed Out')),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _targetIsPassOut = v == '__PASSOUT__';
                                    _targetClassId = _targetIsPassOut ? null : v;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickPromotionDate,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: GrBookTheme.primaryDark),
                        const SizedBox(width: 6),
                        Text('Promotion Date: ${_dateFormat.format(_promotionDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Search student name or GR No...', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _searchText = v),
              ),
            ),
            const SizedBox(height: 8),
            if (!_isLoadingCandidates && _candidates != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectedIds.length == visibleCandidates.length && visibleCandidates.isNotEmpty,
                      tristate: true,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.addAll(visibleCandidates.map((c) => c.student.id));
                          } else {
                            for (final c in visibleCandidates) {
                              _selectedIds.remove(c.student.id);
                            }
                          }
                        });
                      },
                    ),
                    Text('Select All (${visibleCandidates.length} Students)'),
                    const Spacer(),
                    Text('Selected: ${_selectedIds.length}', style: const TextStyle(fontWeight: FontWeight.w600, color: GrBookTheme.primaryDark)),
                  ],
                ),
              ),
            Expanded(
              child: _isLoadingCandidates
                  ? const Center(child: CircularProgressIndicator())
                  : visibleCandidates.isEmpty
                      ? const Center(child: Text('No active students in this class.'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: visibleCandidates.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final candidate = visibleCandidates[index];
                            final selected = _selectedIds.contains(candidate.student.id);
                            return CheckboxListTile(
                              value: selected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedIds.add(candidate.student.id);
                                  } else {
                                    _selectedIds.remove(candidate.student.id);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(candidate.student.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                'GR: ${candidate.student.grNumber}'
                                '${!candidate.isAgeEligible ? '  •  Underage for this promotion' : ''}',
                                style: TextStyle(color: candidate.isAgeEligible ? null : Colors.orange.shade800),
                              ),
                              secondary: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                tooltip: 'Mark as Failed',
                                onPressed: () => _confirmFail(candidate.student),
                              ),
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
                  onPressed: (classesAsync.valueOrNull == null || _isLoadingCandidates || _candidates == null)
                      ? null
                      : () => _goToPreview(classesAsync.value!),
                  icon: const Icon(Icons.school),
                  label: Text(
                    _targetIsPassOut
                        ? 'Promote to Passed Out'
                        : 'Promote to ${classesAsync.valueOrNull?.firstWhere(
                              (c) => c.id == _targetClassId,
                              orElse: () => widget.schoolClass,
                            ).displayName ?? '...'}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _LabelledBox extends StatelessWidget {
  const _LabelledBox({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}
