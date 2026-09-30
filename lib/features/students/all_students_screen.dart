import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/age_calculator.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/photo_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/sync_providers.dart';
import '../../repositories/student_photo_repository.dart';
import '../../widgets/gr_book_ui_components.dart';
import 'student_form_screen.dart';

class AllStudentsScreen extends ConsumerStatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  ConsumerState<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends ConsumerState<AllStudentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClassId; // null => All Classes

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    final isDark = GrBookTheme.isDark(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GrBookTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(showBack: true),
              const GrBookPageHeader(
                title: 'All Students',
                subtitle: 'Search & manage all registered students',
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: GrBookTheme.getTextPrimary(context)),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by student name or G.R number...',
                    prefixIcon: const Icon(Icons.search, color: GrBookTheme.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF14221A) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: GrBookTheme.getBorderColor(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: GrBookTheme.getBorderColor(context)),
                    ),
                  ),
                ),
              ),

              // Class Filter Chips
              schoolAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (school) {
                  if (school == null) return const SizedBox.shrink();
                  final classesAsync = ref.watch(classesStreamProvider(school.id));
                  return classesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (classes) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All Classes',
                              isSelected: _selectedClassId == null,
                              onTap: () => setState(() => _selectedClassId = null),
                            ),
                            const SizedBox(width: 8),
                            ...classes.map((c) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _FilterChip(
                                    label: c.displayName,
                                    isSelected: _selectedClassId == c.id,
                                    onTap: () => setState(() => _selectedClassId = c.id),
                                  ),
                                )),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 6),

              // Student List
              Expanded(
                child: schoolAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (school) {
                    if (school == null) {
                      return const Center(child: Text('No school profile found.'));
                    }

                    final searchAsync = ref.watch(globalSearchProvider((schoolId: school.id, query: _searchQuery)));

                    return searchAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (rawStudents) {
                        var students = rawStudents;
                        if (_selectedClassId != null) {
                          students = students.where((s) => s.classId.trim() == _selectedClassId!.trim()).toList();
                        }

                        if (students.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty ? 'No students found in this class.' : 'No students found matching "$_searchQuery".',
                                  style: TextStyle(color: GrBookTheme.getTextSecondary(context), fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        final classesAsync = ref.watch(classesStreamProvider(school.id));
                        final classes = classesAsync.valueOrNull ?? [];

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final s = students[index];
                            final matchedClass = classes.where((c) => c.id == s.classId).firstOrNull;
                            final className = matchedClass?.displayName ?? 'Class';

                            return _StudentRowCard(
                              student: s,
                              className: className,
                              matchedClass: matchedClass,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? GrBookTheme.primary : GrBookTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GrBookTheme.primary : GrBookTheme.getBorderColor(context),
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x200F7A42), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : GrBookTheme.getTextPrimary(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _StudentRowCard extends ConsumerWidget {
  const _StudentRowCard({
    required this.student,
    required this.className,
    required this.matchedClass,
  });

  final Student student;
  final String className;
  final SchoolClass? matchedClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(studentPhotosProvider(student.id));
    final studentPhoto = photoAsync.valueOrNull?[PhotoType.student];
    final isDark = GrBookTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GrBookTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.1),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: studentPhoto != null && studentPhoto.hasContent
                ? Colors.transparent
                : (isDark ? const Color(0xFF14221A) : const Color(0xFFF1F5F9)),
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? const Color(0xFF24382B) : const Color(0xFFCBD5E1), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: ClipOval(
            child: _buildAvatar(ref, studentPhoto),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student.studentName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: GrBookTheme.getTextPrimary(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF133622) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                className,
                style: TextStyle(color: isDark ? const Color(0xFF68D391) : GrBookTheme.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'S.No: ${student.serialNumber ?? '-'}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GrBookTheme.getTextSecondary(context)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'G.R: ${student.grNumber}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GrBookTheme.primary),
                  ),
                  if (student.fatherName != null && student.fatherName!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '• ${student.fatherName}',
                        style: TextStyle(fontSize: 12, color: GrBookTheme.getTextSecondary(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Builder(
                builder: (_) {
                  final age = AgeCalculator.calculate(
                    dateOfBirth: student.dateOfBirth,
                    asOf: DateTime.now(),
                  );
                  final dobStr = DateFormat('dd-MM-yyyy').format(student.dateOfBirth);
                  return Text(
                    'Age: ${age.formatShort()} • DOB: $dobStr',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: GrBookTheme.getTextSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined, color: GrBookTheme.primary),
                          title: const Text('Edit Student Profile'),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            if (matchedClass != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudentFormScreen(
                                    schoolClass: matchedClass!,
                                    existingStudent: student,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                          title: const Text('Delete Student Permanently', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                                    SizedBox(width: 10),
                                    Expanded(child: Text('Delete Student?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                content: Text(
                                  'Are you sure you want to delete ${student.studentName} (G.R: ${student.grNumber}) permanently?\n\nAll records, photos, complaints, and history will be permanently deleted from this device and Supabase cloud. This action cannot be undone.',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dCtx).pop(false),
                                    child: const Text('NO, CANCEL', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => Navigator.of(dCtx).pop(true),
                                    child: const Text('YES, DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              try {
                                await ref.read(studentRepositoryProvider).deleteStudentPermanently(
                                  studentId: student.id,
                                  schoolId: student.schoolId,
                                );
                                triggerSync(ref);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${student.studentName} permanently deleted.')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error deleting student: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Icon(Icons.chevron_right_rounded, color: GrBookTheme.primary, size: 22),
          ],
        ),
        onTap: () {
          if (matchedClass != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentFormScreen(
                  schoolClass: matchedClass!,
                  existingStudent: student,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAvatar(WidgetRef ref, StudentPhoto? studentPhoto) {
    if (studentPhoto == null || !studentPhoto.hasContent) {
      return Center(
        child: Text(
          student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
          style: const TextStyle(color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }
    if (studentPhoto.localPath != null) {
      return Image.file(File(studentPhoto.localPath!), fit: BoxFit.cover);
    }
    return FutureBuilder<String>(
      future: ref.read(studentPhotoRepositoryProvider).signedUrlFor(studentPhoto),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return CachedNetworkImage(imageUrl: snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
