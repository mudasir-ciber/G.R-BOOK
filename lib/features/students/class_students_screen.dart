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
import '../../widgets/sync_status_banner.dart';
import '../promotion/promote_students_screen.dart';
import '../struck_off/struck_off_dialog.dart';
import 'student_form_screen.dart';

/// Screen 7: Class Students Page matching reference UI image 7 exactly.
class ClassStudentsScreen extends ConsumerStatefulWidget {
  const ClassStudentsScreen({super.key, required this.schoolClass});

  final SchoolClass schoolClass;

  @override
  ConsumerState<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends ConsumerState<ClassStudentsScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = _searchText.isEmpty
        ? ref.watch(_activeStudentsProvider(widget.schoolClass.id))
        : ref.watch(_searchProvider((classId: widget.schoolClass.id, query: _searchText)));

    final totalCount = studentsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(),
              GrBookPageHeader(
                title: widget.schoolClass.displayName,
                subtitle: 'Students ($totalCount)',
              ),
              const SyncStatusBanner(),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search student name or GR No...',
                    prefixIcon: const Icon(Icons.search, color: GrBookTheme.primary, size: 20),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchText = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _searchText = v),
                ),
              ),

              // Table Header Row ("Sr. No. | G.R No. | Student Name")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF2E4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          'Sr. No.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: GrBookTheme.primaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'G.R No.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: GrBookTheme.primaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          'Student Name',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: GrBookTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Student List
              Expanded(
                child: studentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (students) {
                    if (students.isEmpty) {
                      return const Center(child: Text('No students found in this class.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _StudentItemRow(
                        index: index + 1,
                        student: students[index],
                        schoolClass: widget.schoolClass,
                      ),
                    );
                  },
                ),
              ),

              // Bottom Action Buttons ("+ Add Student" and "Promote")
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: GrBookTheme.borderColor, width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GrBookGradientButton(
                      text: 'Add Student',
                      icon: Icons.add_circle_outline_rounded,
                      trailingIcon: null,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentFormScreen(schoolClass: widget.schoolClass),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    GrBookOutlinedButton(
                      text: 'Promote',
                      icon: Icons.move_up_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PromoteStudentsScreen(schoolClass: widget.schoolClass),
                          ),
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _StudentItemRow extends ConsumerWidget {
  const _StudentItemRow({
    required this.index,
    required this.student,
    required this.schoolClass,
  });

  final int index;
  final Student student;
  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(studentPhotosProvider(student.id));
    final studentPhoto = photosAsync.valueOrNull?[PhotoType.student];

    final displaySerial = student.serialNumber != null ? '${student.serialNumber}' : '$index';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrBookTheme.borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentFormScreen(
                  schoolClass: schoolClass,
                  existingStudent: student,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Serial Number
                SizedBox(
                  width: 44,
                  child: Text(
                    displaySerial,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GrBookTheme.textPrimary,
                    ),
                  ),
                ),

                // GR Number Pill
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GrBookTheme.borderColor, width: 0.8),
                  ),
                  child: Text(
                    student.grNumber,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: GrBookTheme.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: GrBookTheme.primaryLight,
                  child: ClipOval(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: _buildAvatarContent(ref, studentPhoto),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Student Name
                Expanded(
                  child: Text(
                    student.studentName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GrBookTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Trailing Arrow or Action Menu
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudentFormScreen(
                                      schoolClass: schoolClass,
                                      existingStudent: student,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.person_off_outlined, color: Colors.red),
                              title: const Text('Mark as Struck Off', style: TextStyle(color: Colors.red)),
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                final done = await showStruckOffDialog(
                                  context,
                                  ref,
                                  schoolId: student.schoolId,
                                  student: student,
                                );
                                if (done && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${student.studentName} struck off.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GrBookTheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(WidgetRef ref, StudentPhoto? studentPhoto) {
    if (studentPhoto == null || !studentPhoto.hasContent) {
      return Center(
        child: Text(
          student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: GrBookTheme.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
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

final _activeStudentsProvider = StreamProvider.family((ref, String classId) {
  return ref.watch(studentRepositoryProvider).watchActiveStudentsForClass(classId);
});

typedef _SearchArgs = ({String classId, String query});

final _searchProvider = StreamProvider.family((ref, _SearchArgs args) {
  return ref.watch(studentRepositoryProvider).watchSearch(classId: args.classId, queryText: args.query);
});
