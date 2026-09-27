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

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search name, GR number, or class...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: resultsAsync == null
          ? const Center(child: Text('Search across every class — works offline.'))
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) {
                if (students.isEmpty) {
                  return const Center(child: Text('No matching students.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return FutureBuilder(
                      future: ref.read(classRepositoryProvider).getClassById(s.classId),
                      builder: (context, snapshot) {
                        final schoolClass = snapshot.data;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: GrBookTheme.primary.withOpacity(0.12),
                            child: Text(s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?'),
                          ),
                          title: Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'GR: ${s.grNumber}'
                            '${schoolClass != null ? '  •  ${schoolClass.displayName}' : ''}'
                            '${s.status != StudentStatus.active ? '  •  ${s.status.dbValue}' : ''}',
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
