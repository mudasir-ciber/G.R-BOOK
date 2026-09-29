import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/photo_providers.dart';
import '../../providers/repository_providers.dart';
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
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
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: GrBookTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: GrBookTheme.borderColor),
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

                    return StreamBuilder<List<Student>>(
                      stream: ref.read(studentRepositoryProvider).watchGlobalSearch(
                            schoolId: school.id,
                            queryText: _searchQuery,
                          ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        var students = snapshot.data ?? [];
                        if (_selectedClassId != null) {
                          students = students.where((s) => s.classId == _selectedClassId).toList();
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
                                  style: const TextStyle(color: GrBookTheme.textSecondary, fontSize: 14),
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
          color: isSelected ? GrBookTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GrBookTheme.primary : GrBookTheme.borderColor,
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x200F7A42), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : GrBookTheme.textPrimary,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GrBookTheme.borderColor, width: 1.1),
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
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildAvatar(ref, studentPhoto),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student.studentName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: GrBookTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                className,
                style: const TextStyle(color: GrBookTheme.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                'S.No: ${student.serialNumber ?? '-'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GrBookTheme.textSecondary),
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
                    style: const TextStyle(fontSize: 12, color: GrBookTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: GrBookTheme.primary, size: 24),
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
