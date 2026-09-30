import 'dart:io';

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
import '../complaints/complaint_history_screen.dart';
import 'certificate_screen.dart';
import 'student_a4_profile_screen.dart';
import 'widgets/document_photo_tile.dart';
import 'widgets/profile_photo_avatar.dart';

/// Screen 8: Student Profile / Add Student matching reference UI image 8 exactly.
/// Serves both as "Add Student" and "Student Profile" with full photo picker support
/// for Student Photo, B-Form, Father CNIC, and Token Picture.
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.schoolClass, this.existingStudent});

  final SchoolClass? schoolClass;
  final Student? existingStudent;

  bool get isEditing => existingStudent != null;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd-MM-yyyy');

  late final TextEditingController _nameController;
  late final TextEditingController _grController;
  late final TextEditingController _fatherNameController;
  late final TextEditingController _motherNameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _lastSchoolController;
  late final TextEditingController _addressController;
  late final TextEditingController _cnicController;
  late final TextEditingController _bFormController;
  late final TextEditingController _remarksController;
  late String _selectedGender;

  DateTime? _dateOfBirth;
  DateTime? _dateOfAdmission;
  late String _selectedClassId;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _showAdditionalFields = false;

  final Map<PhotoType, File> _pickedFiles = {};

  @override
  void initState() {
    super.initState();
    final s = widget.existingStudent;
    _nameController = TextEditingController(text: s?.studentName ?? '');
    _grController = TextEditingController(text: s?.grNumber ?? '');
    _fatherNameController = TextEditingController(text: s?.fatherName ?? '');
    _motherNameController = TextEditingController(text: s?.motherName ?? '');
    _mobileController = TextEditingController(text: s?.phoneNumber ?? '');
    _lastSchoolController = TextEditingController(text: s?.previousSchool ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _cnicController = TextEditingController(text: s?.fatherCnic ?? '');
    _bFormController = TextEditingController(text: s?.bFormNumber ?? '');
    _remarksController = TextEditingController(text: s?.cleanRemarks ?? s?.remarks ?? '');
    _selectedGender = (s?.isFemale == true) ? 'FEMALE' : 'MALE';
    _dateOfBirth = s?.dateOfBirth;
    _dateOfAdmission = s?.dateOfAdmission ?? DateTime.now();
    _selectedClassId = s?.classId ?? widget.schoolClass?.id ?? '';
  }

  Future<void> _pickDate({required bool isDob}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDob ? _dateOfBirth : _dateOfAdmission) ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _dateOfBirth = picked;
        } else {
          _dateOfAdmission = picked;
        }
      });
    }
  }

  String? _validateEceAdmissionAge(SchoolClass targetClass) {
    final minMonths = targetClass.minAdmissionAgeMonths;
    if (minMonths == null || _dateOfBirth == null || _dateOfAdmission == null) return null;

    final eligible = AgeCalculator.isAtLeastMonths(
      dateOfBirth: _dateOfBirth!,
      asOf: _dateOfAdmission!,
      minMonths: minMonths,
    );
    if (!eligible) {
      final age = AgeCalculator.calculate(dateOfBirth: _dateOfBirth!, asOf: _dateOfAdmission!);
      final minYears = (minMonths / 12).floor();
      final minRemMonths = minMonths % 12;
      return 'Student is only ${age.format()} old on admission date. '
          '${targetClass.displayName} requires at least '
          '$minYears years${minRemMonths > 0 ? ' $minRemMonths months' : ''}.';
    }
    return null;
  }

  Future<bool?> _showDuplicateGrWarning(String grNumber) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate GR Number'),
        content: Text(
          'GR number "$grNumber" is already used by another student in this school. '
          'Do you still want to proceed?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    );
  }

  String? _emptyToNull(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() => _errorMessage = 'Date of Birth is required.');
      return;
    }
    if (_dateOfAdmission == null) {
      setState(() => _errorMessage = 'Date of Admission is required.');
      return;
    }
    if (_dateOfAdmission!.isBefore(_dateOfBirth!)) {
      setState(() => _errorMessage = 'Date of Admission cannot be before Date of Birth.');
      return;
    }

    final schoolId = widget.schoolClass?.schoolId ?? ref.read(currentSchoolProvider).value?.id;
    if (schoolId == null) {
      setState(() => _errorMessage = 'School not found.');
      return;
    }

    final classRepo = ref.read(classRepositoryProvider);
    final targetClass = await classRepo.getClassById(_selectedClassId) ?? widget.schoolClass;
    if (targetClass == null) {
      setState(() => _errorMessage = 'Please select a valid class.');
      return;
    }

    final ageError = _validateEceAdmissionAge(targetClass);
    if (ageError != null) {
      setState(() => _errorMessage = ageError);
      return;
    }

    final grNumber = _grController.text.trim();
    final isDuplicate = await ref.read(studentRepositoryProvider).checkDuplicateGrNumber(
          schoolId: schoolId,
          grNumber: grNumber,
          excludingStudentId: widget.existingStudent?.id,
        );
    if (isDuplicate && mounted) {
      final proceed = await _showDuplicateGrWarning(grNumber);
      if (proceed != true) return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(studentRepositoryProvider);
      final Student targetStudent;
      final userText = _remarksController.text.trim();
      final combinedRemarks = userText.isEmpty
          ? '[GENDER:$_selectedGender]'
          : '$userText [GENDER:$_selectedGender]';

      if (widget.isEditing) {
        final updated = widget.existingStudent!.copyWith(
          classId: _selectedClassId,
          grNumber: grNumber,
          studentName: _nameController.text.trim(),
          fatherName: _emptyToNull(_fatherNameController.text),
          motherName: _emptyToNull(_motherNameController.text),
          dateOfBirth: _dateOfBirth,
          dateOfAdmission: _dateOfAdmission,
          fatherCnic: _emptyToNull(_cnicController.text),
          bFormNumber: _emptyToNull(_bFormController.text),
          phoneNumber: _emptyToNull(_mobileController.text),
          address: _emptyToNull(_addressController.text),
          previousSchool: _emptyToNull(_lastSchoolController.text),
          remarks: combinedRemarks,
        );
        await repo.updateStudent(updated);
        targetStudent = updated;
      } else {
        targetStudent = await repo.createStudent(
          schoolId: schoolId,
          classId: _selectedClassId,
          grNumber: grNumber,
          studentName: _nameController.text.trim(),
          fatherName: _emptyToNull(_fatherNameController.text),
          motherName: _emptyToNull(_motherNameController.text),
          dateOfBirth: _dateOfBirth!,
          dateOfAdmission: _dateOfAdmission!,
          fatherCnic: _emptyToNull(_cnicController.text),
          bFormNumber: _emptyToNull(_bFormController.text),
          phoneNumber: _emptyToNull(_mobileController.text),
          address: _emptyToNull(_addressController.text),
          previousSchool: _emptyToNull(_lastSchoolController.text),
          remarks: combinedRemarks,
        );
      }

      // Save all picked photos immediately (works online and offline)
      final photoRepo = ref.read(studentPhotoRepositoryProvider);
      for (final entry in _pickedFiles.entries) {
        await photoRepo.captureAndSave(
          schoolId: targetStudent.schoolId,
          studentId: targetStudent.id,
          photoType: entry.key,
          rawFile: entry.value,
        );
      }

      // Auto-sync changes immediately to cloud in background
      triggerSync(ref);

      if (!mounted) return;

      if (widget.isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully.')),
        );
        Navigator.of(context).pop();
      } else {
        // Show post-save action dialog with VIEW PROFILE, ADD ANOTHER STUDENT, GO HOME
        final action = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF0F9D58), size: 28),
                SizedBox(width: 10),
                Text('Student Added', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              '${targetStudent.studentName} has been successfully registered.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D58),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person, size: 18),
                    label: const Text('VIEW PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.of(ctx).pop('profile'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F9D58),
                      side: const BorderSide(color: Color(0xFF0F9D58)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('ADD ANOTHER STUDENT', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.of(ctx).pop('another'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop('home'),
                    child: const Text('GO HOME', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );

        if (!mounted) return;

        if (action == 'profile') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudentFormScreen(
                schoolClass: targetClass,
                existingStudent: targetStudent,
              ),
            ),
          );
        } else if (action == 'another') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudentFormScreen(schoolClass: targetClass),
            ),
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not save student. ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = widget.schoolClass?.schoolId ?? ref.watch(currentSchoolProvider).valueOrNull?.id ?? '';
    final classesAsync = ref.watch(classesStreamProvider(schoolId));
    final Map<PhotoType, StudentPhoto> photosByType = widget.isEditing
        ? (ref.watch(studentPhotosProvider(widget.existingStudent!.id)).valueOrNull ?? {})
        : const {};

    // Auto-select first class if none selected yet
    if (_selectedClassId.isEmpty && (classesAsync.valueOrNull?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedClassId.isEmpty) {
          setState(() => _selectedClassId = classesAsync.value!.first.id);
        }
      });
    }

    final asOfForAge = DateTime.now();
    final age = _dateOfBirth != null
        ? AgeCalculator.calculate(dateOfBirth: _dateOfBirth!, asOf: asOfForAge)
        : null;

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
              GrBookTopBar(
                trailing: widget.isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.assignment_ind_outlined, color: GrBookTheme.primary, size: 20),
                              tooltip: 'Student Profile (A4 Sheet)',
                              onPressed: () {
                                final currentClass = widget.schoolClass ??
                                    (classesAsync.valueOrNull?.where((c) => c.id == widget.existingStudent!.classId).firstOrNull);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudentA4ProfileScreen(
                                      student: widget.existingStudent!,
                                      schoolClass: currentClass,
                                      pickedStudentPhoto: _pickedFiles[PhotoType.student],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.workspace_premium_outlined, color: GrBookTheme.primary, size: 20),
                              tooltip: 'Certificates',
                              onPressed: () {
                                final currentClass = widget.schoolClass ??
                                    (classesAsync.valueOrNull?.where((c) => c.id == widget.existingStudent!.classId).firstOrNull);
                                if (currentClass != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CertificateScreen(
                                        student: widget.existingStudent!,
                                        schoolClass: currentClass,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.rate_review_outlined, color: GrBookTheme.primary, size: 20),
                              tooltip: 'Complaint History',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ComplaintHistoryScreen(student: widget.existingStudent!),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20),
                              tooltip: 'Delete Student',
                              onPressed: () async {
                                final s = widget.existingStudent!;
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
                                    'Are you sure you want to delete ${s.studentName} (G.R: ${s.grNumber}) permanently?\n\nAll records, photos, complaints, and history will be permanently deleted from this device and Supabase cloud. This action cannot be undone.',
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
                                    studentId: s.id,
                                    schoolId: s.schoolId,
                                  );
                                  triggerSync(ref);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${s.studentName} permanently deleted.')),
                                    );
                                    Navigator.of(context).pop();
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
                        ),
                      ],
                    )
                    : null,
              ),

              // Subtitle matching reference image 8
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.isEditing ? 'Student Profile' : 'Add Student',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GrBookTheme.primaryDark,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: GrBookTheme.getCardBackground(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.35 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 1. Profile photo (matching reference image 8 circular avatar with camera badge)
                          Center(
                            child: ProfilePhotoAvatar(
                              photo: photosByType[PhotoType.student],
                              pickedFile: _pickedFiles[PhotoType.student],
                              fallbackInitial: _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                              onPicked: (file) => setState(() => _pickedFiles[PhotoType.student] = file),
                              resolveSignedUrl: (p) => ref.read(studentPhotoRepositoryProvider).signedUrlFor(p),
                              radius: 46,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Student Name Pill Field (Centered in rounded box, larger and spacious)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF14221A) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.3),
                            ),
                            child: TextFormField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: GrBookTheme.getTextPrimary(context)),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: InputBorder.none,
                                hintText: 'Enter Student Full Name',
                                hintStyle: TextStyle(fontSize: 14.5, color: Color(0xFF94A3B8)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Student name is required' : null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3. Row 1: G.R No. | Class (Short fields stay in 2 columns)
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.assignment_outlined,
                                  label: 'G.R No.',
                                  child: TextFormField(
                                    controller: _grController,
                                    keyboardType: TextInputType.text,
                                    style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: '001',
                                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.school_outlined,
                                  label: 'Class',
                                  trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: GrBookTheme.textSecondary),
                                  child: classesAsync.when(
                                    loading: () => const Text('Loading...', style: TextStyle(fontSize: 13)),
                                    error: (_, __) => const Text('Error', style: TextStyle(fontSize: 13)),
                                    data: (classes) => DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: classes.any((c) => c.id == _selectedClassId) ? _selectedClassId : null,
                                        isDense: true,
                                        icon: const SizedBox.shrink(),
                                        style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.bold),
                                        items: classes
                                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName)))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) setState(() => _selectedClassId = v);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 4. Father Name (Full width for clear, uncut name visibility)
                          _ProfileFieldCard(
                            icon: Icons.person,
                            label: 'Father Name',
                            child: TextFormField(
                              controller: _fatherNameController,
                              style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Enter father full name',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 5. Mother Name (Full width for clear visibility)
                          _ProfileFieldCard(
                            icon: Icons.person_outline,
                            label: 'Mother Name',
                            child: TextFormField(
                              controller: _motherNameController,
                              style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Enter mother name',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 6. Mobile No. (Full width for easy typing)
                          _ProfileFieldCard(
                            icon: Icons.phone,
                            label: 'Mobile No.',
                            child: TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'e.g. 0300-1234567',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 7. Last School Attended (Horizontally wide & prominent as requested)
                          _ProfileFieldCard(
                            icon: Icons.apartment_rounded,
                            label: 'Last School Attended',
                            child: TextFormField(
                              controller: _lastSchoolController,
                              style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Enter previous school attended',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 8. Date of Birth (Full width, easy to tap)
                          _ProfileFieldCard(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date of Birth',
                            onTap: () => _pickDate(isDob: true),
                            trailing: const Icon(Icons.calendar_month_outlined, size: 20, color: Color(0xFF94A3B8)),
                            child: Text(
                              _dateOfBirth != null ? _dateFormat.format(_dateOfBirth!) : 'Select Date of Birth',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: _dateOfBirth != null ? GrBookTheme.textPrimary : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 9. Age Here (Full width, comfortable spacing, no squeezed text)
                          _ProfileFieldCard(
                            icon: Icons.access_time_rounded,
                            label: 'Age (Calculated from Date of Birth)',
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F8F4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFB7DFC6)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      age != null ? '${age.years} Yr' : '-- Yr',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F8F4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFB7DFC6)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      age != null ? '${age.months} Mo' : '-- Mo',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F8F4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFB7DFC6)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      age != null ? '${age.days} Days' : '-- Days',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 10. Gender Section (Matching reference image: Female / Male radio buttons)
                          _ProfileFieldCard(
                            icon: Icons.wc_rounded,
                            label: 'Gender',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  // Female
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => setState(() => _selectedGender = 'FEMALE'),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: (_selectedGender == 'FEMALE' || _selectedGender == 'GIRL')
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFF9E9E9E),
                                                width: 2,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(3.5),
                                            child: (_selectedGender == 'FEMALE' || _selectedGender == 'GIRL')
                                                ? Container(
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFF4CAF50),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Female',
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: (_selectedGender == 'FEMALE' || _selectedGender == 'GIRL')
                                                  ? Colors.black87
                                                  : const Color(0xFF616161),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  // Male
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => setState(() => _selectedGender = 'MALE'),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: (_selectedGender == 'MALE' || _selectedGender == 'BOY')
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFF9E9E9E),
                                                width: 2,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(3.5),
                                            child: (_selectedGender == 'MALE' || _selectedGender == 'BOY')
                                                ? Container(
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFF4CAF50),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Male',
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: (_selectedGender == 'MALE' || _selectedGender == 'BOY')
                                                  ? Colors.black87
                                                  : const Color(0xFF616161),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 9. Date of Admission (Full width)
                          _ProfileFieldCard(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date of Admission',
                            onTap: () => _pickDate(isDob: false),
                            trailing: const Icon(Icons.calendar_month_outlined, size: 20, color: Color(0xFF94A3B8)),
                            child: Text(
                              _dateOfAdmission != null ? _dateFormat.format(_dateOfAdmission!) : 'Select date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _dateOfAdmission != null ? GrBookTheme.textPrimary : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 10. Address (Full width)
                          _ProfileFieldCard(
                            icon: Icons.location_on,
                            label: 'Address',
                            child: TextFormField(
                              controller: _addressController,
                              style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Enter complete residential address',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Optional details toggle
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _showAdditionalFields = !_showAdditionalFields),
                              icon: Icon(_showAdditionalFields ? Icons.expand_less : Icons.expand_more, size: 20, color: GrBookTheme.primary),
                              label: Text(
                                _showAdditionalFields ? 'Hide Additional Details' : 'More Details (CNIC, B-Form, Remarks)',
                                style: const TextStyle(fontSize: 13, color: GrBookTheme.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          if (_showAdditionalFields) ...[
                            _ProfileFieldCard(
                              icon: Icons.credit_card_rounded,
                              label: 'Father CNIC No.',
                              child: TextFormField(
                                controller: _cnicController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'e.g. 45302-XXXXXXX-X',
                                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ProfileFieldCard(
                              icon: Icons.badge_outlined,
                              label: 'B-Form Number',
                              child: TextFormField(
                                controller: _bFormController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'e.g. 45302-XXXXXXX-X',
                                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ProfileFieldCard(
                              icon: Icons.notes_rounded,
                              label: 'Remarks',
                              child: TextFormField(
                                controller: _remarksController,
                                style: const TextStyle(fontSize: 14.5, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Optional notes or remarks',
                                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 12),

                          // 9. Document Photos Section (Matching reference image 8)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8F4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD6E8DC), width: 1),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: DocumentPhotoTile(
                                        label: 'B-Form Picture',
                                        photo: photosByType[PhotoType.bForm],
                                        pickedFile: _pickedFiles[PhotoType.bForm],
                                        onPicked: (file) => setState(() => _pickedFiles[PhotoType.bForm] = file),
                                        resolveSignedUrl: (p) => ref.read(studentPhotoRepositoryProvider).signedUrlFor(p),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: DocumentPhotoTile(
                                        label: 'Father CNIC Picture',
                                        photo: photosByType[PhotoType.fatherCnic],
                                        pickedFile: _pickedFiles[PhotoType.fatherCnic],
                                        onPicked: (file) => setState(() => _pickedFiles[PhotoType.fatherCnic] = file),
                                        resolveSignedUrl: (p) => ref.read(studentPhotoRepositoryProvider).signedUrlFor(p),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: 170,
                                  child: DocumentPhotoTile(
                                    label: 'Student Token Pic',
                                    photo: photosByType[PhotoType.token],
                                    pickedFile: _pickedFiles[PhotoType.token],
                                    onPicked: (file) => setState(() => _pickedFiles[PhotoType.token] = file),
                                    resolveSignedUrl: (p) => ref.read(studentPhotoRepositoryProvider).signedUrlFor(p),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (widget.isEditing) ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E3A8A),
                                side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: const Color(0xFFEFF6FF),
                              ),
                              icon: const Icon(Icons.assignment_ind_rounded, color: Color(0xFF1E3A8A), size: 20),
                              label: const Text(
                                'View Student Profile (A4 Sheet & PDF / JPG)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              onPressed: () {
                                final currentClass = widget.schoolClass ??
                                    (classesAsync.valueOrNull?.where((c) => c.id == widget.existingStudent!.classId).firstOrNull);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudentA4ProfileScreen(
                                      student: widget.existingStudent!,
                                      schoolClass: currentClass,
                                      pickedStudentPhoto: _pickedFiles[PhotoType.student],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // 10. Bottom Button ("Save Changes" or "Save Student")
                          GrBookGradientButton(
                            text: widget.isEditing ? 'Save Changes' : 'Save Student',
                            isLoading: _isSubmitting,
                            icon: widget.isEditing ? Icons.save_rounded : Icons.check_circle_outline_rounded,
                            trailingIcon: null,
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
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
    _nameController.dispose();
    _grController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _mobileController.dispose();
    _lastSchoolController.dispose();
    _addressController.dispose();
    _cnicController.dispose();
    _bFormController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}

class _ProfileFieldCard extends StatelessWidget {
  const _ProfileFieldCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14221A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1.3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: isDark ? const Color(0xFF68D391) : GrBookTheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: GrBookTheme.getTextSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  child,
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
