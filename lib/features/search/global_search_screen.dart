import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/repository_providers.dart';
import '../students/student_form_screen.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final resultsAsync = _query.trim().isEmpty
        ? null
        : ref.watch(globalSearchProvider((schoolId: widget.schoolId, query: _query)));
    final isDark = GrBookTheme.isDark(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);
    final borderColor = GrBookTheme.getBorderColor(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: TextStyle(color: textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search name, GR number, or class...',
            hintStyle: TextStyle(color: textSecondary),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: resultsAsync == null
          ? Center(child: Text('Search across every class — works offline.', style: TextStyle(color: textSecondary)))
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: textPrimary))),
              data: (students) {
                if (students.isEmpty) {
                  return Center(child: Text('No matching students.', style: TextStyle(color: textSecondary)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return FutureBuilder(
                      future: ref.read(classRepositoryProvider).getClassById(s.classId),
                      builder: (context, snapshot) {
                        final schoolClass = snapshot.data;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: CircleAvatar(
                            backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                            child: Text(
                              s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                              style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : GrBookTheme.primaryDark),
                            ),
                          ),
                          title: Text(s.studentName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                          subtitle: Text(
                            'GR: ${s.grNumber}'
                            '${schoolClass != null ? '  •  ${schoolClass.displayName}' : ''}'
                            '${s.status != StudentStatus.active ? '  •  ${s.status.dbValue}' : ''}',
                            style: TextStyle(color: textSecondary),
                          ),
                          onTap: schoolClass == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StudentFormScreen(schoolClass: schoolClass, existingStudent: s),
                                    ),
                                  );
                                },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
