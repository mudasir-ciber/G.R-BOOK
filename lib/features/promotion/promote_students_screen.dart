import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../features/auth/auth_providers.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/promotion_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/promotion_repository.dart';
import '../../widgets/gr_book_ui_components.dart';
import 'promotion_preview_screen.dart';

/// Screen 9: Promote Students Page matching reference UI image 9 exactly.
class PromoteStudentsScreen extends ConsumerStatefulWidget {
  const PromoteStudentsScreen({super.key, required this.schoolClass});

  final SchoolClass schoolClass;

  @override
  ConsumerState<PromoteStudentsScreen> createState() => _PromoteStudentsScreenState();
}

class _PromoteStudentsScreenState extends ConsumerState<PromoteStudentsScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

  DateTime _promotionDate = DateTime.now();
  String? _targetClassId;
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

  Future<void> _goToPreview(List<SchoolClass> allClasses) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one student to promote.')),
      );
      return;
    }

    final selectedCandidates = (_candidates ?? []).where((c) => _selectedIds.contains(c.student.id)).toList();

    SchoolClass? targetClass;
    if (!_targetIsPassOut && _targetClassId != null) {
      targetClass = allClasses.firstWhere((c) => c.id == _targetClassId);
    }

    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PromotionPreviewScreen(
          fromClass: widget.schoolClass,
          toClass: targetClass,
          students: selectedCandidates.map((c) => c.student).toList(),
          promotionDate: _promotionDate,
        ),
      ),
    );

    if (success == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesStreamProvider(widget.schoolClass.schoolId));

    final visibleCandidates = (_candidates ?? []).where((c) {
      if (_searchText.isEmpty) return true;
      final query = _searchText.toLowerCase();
      return c.student.studentName.toLowerCase().contains(query) ||
          c.student.grNumber.toLowerCase().contains(query);
    }).toList();

    String targetLabel = 'Next Class';
    if (_targetIsPassOut) {
      targetLabel = 'Passed Out';
    } else if (classesAsync.valueOrNull != null && _targetClassId != null) {
      final match = classesAsync.value!.where((c) => c.id == _targetClassId).firstOrNull;
      if (match != null) targetLabel = match.displayName;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GrBookTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(),
              GrBookPageHeader(
                title: 'Promote Students',
                subtitle: 'Select students to promote from ${widget.schoolClass.displayName} to next class',
              ),

              // Transition Card (Current Class ──> Promote To)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GrBookTheme.getCardBackground(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Current Class Box
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Class',
                              style: TextStyle(fontSize: 11, color: GrBookTheme.getTextSecondary(context)),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const GrBookIconBadge(icon: Icons.groups_rounded, size: 30, iconSize: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.schoolClass.displayName,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: GrBookTheme.getTextPrimary(context)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, color: GrBookTheme.primary, size: 20),
                      ),

                      // Promote To Dropdown Box
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Promote To',
                              style: TextStyle(fontSize: 11, color: GrBookTheme.getTextSecondary(context)),
                            ),
                            const SizedBox(height: 2),
                            classesAsync.when(
                              loading: () => const SizedBox(height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                              error: (_, __) => const Text('Error'),
                              data: (classes) {
                                final otherClasses = classes.where((c) => c.id != widget.schoolClass.id).toList();
                                return DropdownButton<String>(
                                  isExpanded: true,
                                  underline: const SizedBox.shrink(),
                                  dropdownColor: GrBookTheme.getCardBackground(context),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: GrBookTheme.primary),
                                  value: _targetIsPassOut ? '__PASSOUT__' : _targetClassId,
                                  items: [
                                    ...otherClasses.map((c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.getTextPrimary(context))),
                                        )),
                                    if (widget.schoolClass.isTerminal)
                                      DropdownMenuItem(
                                        value: '__PASSOUT__',
                                        child: Text('Passed Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GrBookTheme.getTextPrimary(context))),
                                      ),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _targetIsPassOut = v == '__PASSOUT__';
                                      _targetClassId = _targetIsPassOut ? null : v;
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: GrBookTheme.getTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Search student name or GR No...',
                    hintStyle: TextStyle(color: GrBookTheme.getTextSecondary(context)),
                    prefixIcon: const Icon(Icons.search, color: GrBookTheme.primary, size: 20),
                  ),
                  onChanged: (v) => setState(() => _searchText = v),
                ),
              ),

              // Selection Header Row
              if (!_isLoadingCandidates && _candidates != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _selectedIds.length == visibleCandidates.length && visibleCandidates.isNotEmpty,
                          tristate: true,
                          activeColor: GrBookTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select All (${visibleCandidates.length} Students)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GrBookTheme.getTextPrimary(context)),
                      ),
                      const Spacer(),
                      Text(
                        'Selected: ${_selectedIds.length}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: GrBookTheme.isDark(context) ? const Color(0xFF4ADE80) : GrBookTheme.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ),

              // Candidate List
              Expanded(
                child: _isLoadingCandidates
                    ? const Center(child: CircularProgressIndicator())
                    : visibleCandidates.isEmpty
                        ? Center(child: Text('No active students in this class.', style: TextStyle(color: GrBookTheme.getTextSecondary(context))))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: visibleCandidates.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final candidate = visibleCandidates[index];
                              final selected = _selectedIds.contains(candidate.student.id);

                              return Container(
                                decoration: BoxDecoration(
                                  color: GrBookTheme.getCardBackground(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected ? GrBookTheme.primary : GrBookTheme.getBorderColor(context),
                                    width: selected ? 1.4 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        _selectedIds.remove(candidate.student.id);
                                      } else {
                                        _selectedIds.add(candidate.student.id);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Checkbox(
                                            value: selected,
                                            activeColor: GrBookTheme.primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  _selectedIds.add(candidate.student.id);
                                                } else {
                                                  _selectedIds.remove(candidate.student.id);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: GrBookTheme.isDark(context) ? const Color(0xFF1B2A20) : GrBookTheme.primaryLight,
                                          child: Text(
                                            candidate.student.studentName.isNotEmpty ? candidate.student.studentName[0].toUpperCase() : '?',
                                            style: TextStyle(color: GrBookTheme.isDark(context) ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: GrBookTheme.isDark(context) ? const Color(0xFF1B2A20) : const Color(0xFFF1F8F4),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            candidate.student.grNumber,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: GrBookTheme.isDark(context) ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                candidate.student.studentName,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: GrBookTheme.getTextPrimary(context)),
                                              ),
                                              if (!candidate.isAgeEligible)
                                                Text(
                                                  'Underage for promotion',
                                                  style: TextStyle(color: Colors.orange.shade400, fontSize: 11),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                          tooltip: 'Mark as Failed',
                                          onPressed: () => _confirmFail(candidate.student),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Bottom Button: "Promote to [TargetClass] →"
              Padding(
                padding: const EdgeInsets.all(16),
                child: GrBookGradientButton(
                  text: 'Promote to $targetLabel',
                  icon: Icons.school_rounded,
                  onPressed: (classesAsync.valueOrNull == null || _isLoadingCandidates || _candidates == null)
                      ? null
                      : () => _goToPreview(classesAsync.value!),
                ),
              ),
            ],
          ),
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
