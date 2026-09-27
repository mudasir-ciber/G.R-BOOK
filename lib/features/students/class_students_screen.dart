import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../../providers/photo_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/student_photo_repository.dart';
import '../../widgets/sync_status_banner.dart';
import '../promotion/promote_students_screen.dart';
import '../struck_off/struck_off_dialog.dart';
import 'student_form_screen.dart';

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

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: Text(widget.schoolClass.displayName)),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or GR number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) {
                if (students.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _StudentRow(student: students[index], schoolClass: widget.schoolClass),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: GrBookTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Student'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => StudentFormScreen(schoolClass: widget.schoolClass)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GrBookTheme.primaryDark,
                    side: const BorderSide(color: GrBookTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.move_up),
                  label: const Text('Promote'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PromoteStudentsScreen(schoolClass: widget.schoolClass)),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

final _activeStudentsProvider = StreamProvider.family((ref, String classId) {
  return ref.watch(studentRepositoryProvider).watchActiveStudentsForClass(classId);
});

typedef _SearchArgs = ({String classId, String query});

final _searchProvider = StreamProvider.family((ref, _SearchArgs args) {
  return ref.watch(studentRepositoryProvider).watchSearch(classId: args.classId, queryText: args.query);
});

class _StudentRow extends ConsumerWidget {
  const _StudentRow({required this.student, required this.schoolClass});
  final Student student;
  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(studentPhotosProvider(student.id));
    final studentPhoto = photosAsync.valueOrNull?[PhotoType.student];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: GrBookTheme.primary.withOpacity(0.12),
        child: ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: _buildAvatarContent(ref, studentPhoto),
          ),
        ),
      ),
      title: Text(student.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        'GR: ${student.grNumber}  •  S.No: ${student.serialNumber?.toString() ?? "Pending"}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (student.syncState) {
            SyncState.conflict => const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
            SyncState.synced => const SizedBox.shrink(),
            _ => const Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.orange),
          },
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) async {
              if (value == 'struck_off') {
                final done = await showStruckOffDialog(context, ref, schoolId: student.schoolId, student: student);
                if (done && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${student.studentName} struck off.')),
                  );
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'struck_off', child: Text('Mark as Struck Off')),
            ],
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentFormScreen(schoolClass: schoolClass, existingStudent: student),
          ),
        );
      },
    );
  }

  Widget _buildAvatarContent(WidgetRef ref, StudentPhoto? studentPhoto) {
    if (studentPhoto == null || !studentPhoto.hasContent) {
      return Center(
        child: Text(
          student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
          style: const TextStyle(color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold),
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
