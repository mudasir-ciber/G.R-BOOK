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
import '../../repositories/student_photo_repository.dart';
import '../audit/audit_log_screen.dart';
import 'certificate_screen.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../../widgets/sync_status_banner.dart';
import 'widgets/document_photo_tile.dart';
import 'widgets/profile_photo_avatar.dart';

/// Single screen used both to add a new student (existingStudent ==
/// null) and to view/edit one (existingStudent provided) — matching the
/// provided UI reference ("Student Profile" screen), where one form
/// serves both purposes and the bottom button reads "Edit Data" once a
/// student already exists.
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, required this.schoolClass, this.existingStudent});

  final SchoolClass schoolClass;
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

  DateTime? _dateOfBirth;
  DateTime? _dateOfAdmission;
  late String _selectedClassId;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _showAdditionalFields = false;

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
    _remarksController = TextEditingController(text: s?.remarks ?? '');
    _dateOfBirth = s?.dateOfBirth;
    _dateOfAdmission = s?.dateOfAdmission ?? DateTime.now();
    _selectedClassId = s?.classId ?? widget.schoolClass.id;
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
      return 'Student is only ${age.format()} old on the admission date. '
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
          'You can still save this student if this is intentional.',
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

    final classRepo = ref.read(classRepositoryProvider);
    final targetClass = await classRepo.getClassById(_selectedClassId) ?? widget.schoolClass;

    final ageError = _validateEceAdmissionAge(targetClass);
    if (ageError != null) {
      setState(() => _errorMessage = ageError);
      return;
    }

    final grNumber = _grController.text.trim();
    final isDuplicate = await ref.read(studentRepositoryProvider).checkDuplicateGrNumber(
          schoolId: widget.schoolClass.schoolId,
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
          remarks: _emptyToNull(_remarksController.text),
        );
        await repo.updateStudent(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated.')));
      } else {
        await repo.createStudent(
          schoolId: widget.schoolClass.schoolId,
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
          remarks: _emptyToNull(_remarksController.text),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = 'Could not save student. ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesStreamProvider(widget.schoolClass.schoolId));
    final Map<PhotoType, StudentPhoto> photosByType = widget.isEditing
        ? (ref.watch(studentPhotosProvider(widget.existingStudent!.id)).valueOrNull ?? {})
        : const {};

    final asOfForAge = DateTime.now();
    final age = _dateOfBirth != null
        ? AgeCalculator.calculate(dateOfBirth: _dateOfBirth!, asOf: asOfForAge)
        : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GrBookTheme.mintBackgroundGradient,
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
                          IconButton(
                            icon: const Icon(Icons.workspace_premium_outlined, color: GrBookTheme.primary, size: 22),
                            tooltip: 'Certificates',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CertificateScreen(
                                    student: widget.existingStudent!,
                                    schoolClass: widget.schoolClass,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.history, color: GrBookTheme.primary, size: 22),
                            tooltip: 'History',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AuditLogScreen(
                                    schoolId: widget.existingStudent!.schoolId,
                                    studentId: widget.existingStudent!.id,
                                    title: '${widget.existingStudent!.studentName} — History',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : null,
              ),
              GrBookPageHeader(
                title: widget.isEditing ? 'Student Profile' : 'Add Student',
                subtitle: widget.isEditing ? 'View and edit student information' : 'Register a new student',
              ),
              if (widget.isEditing) const SyncStatusBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ---- Profile photo (camera-badged circle) ----
                      Center(
                        child: widget.isEditing
                            ? ProfilePhotoAvatar(
                                photo: photosByType[PhotoType.student],
                                fallbackInitial: _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                                onPicked: (file) => _onPhotoPicked(PhotoType.student, file),
                                resolveSignedUrl: (p) => ref.read(studentPhotoRepositoryProvider).signedUrlFor(p),
                              )
                            : CircleAvatar(
                                radius: 52,
                                backgroundColor: GrBookTheme.primary.withOpacity(0.10),
                                child: const Icon(Icons.person_outline, size: 44, color: GrBookTheme.primary),
                              ),
                      ),
                      const SizedBox(height: 8),
                      if (!widget.isEditing)
                        Text(
                          'You can add the student photo after saving',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      const SizedBox(height: 16),

                      // ---- Student Name ----
                      TextFormField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(hintText: 'Student Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Student name is required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),

                      // ---- G.R No | Class ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _grController,
                              decoration: const InputDecoration(labelText: 'G.R No', prefixIcon: Icon(Icons.badge_outlined)),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: classesAsync.when(
                              loading: () => const SizedBox(height: 56),
                              error: (_, __) => const SizedBox(height: 56),
                              data: (classes) => DropdownButtonFormField<String>(
                                initialValue: classes.any((c) => c.id == _selectedClassId) ? _selectedClassId : null,
                                decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.school_outlined)),
                                items: classes
                                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedClassId = v ?? _selectedClassId),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ---- Father Name | Mobile No. ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fatherNameController,
                              decoration: const InputDecoration(labelText: 'Father Name', prefixIcon: Icon(Icons.person_outline)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Mobile No.', prefixIcon: Icon(Icons.phone_outlined)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ---- Mother Name | Last School ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _motherNameController,
                              decoration: const InputDecoration(labelText: 'Mother Name', prefixIcon: Icon(Icons.person_outline)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastSchoolController,
                              decoration: const InputDecoration(labelText: 'Last School', prefixIcon: Icon(Icons.school_outlined)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ---- Date of Birth | Age Here ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Date of Birth',
                              value: _dateOfBirth,
                              format: _dateFormat,
                              onTap: () => _pickDate(isDob: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _AgeHereDisplay(age: age)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ---- Date of Admission ----
                      _DateField(
                        label: 'Date of Admission',
                        value: _dateOfAdmission,
                        format: _dateFormat,
                        onTap: () => _pickDate(isDob: false),
                      ),
                      const SizedBox(height: 14),

                      // ---- Address ----
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                      ),
                      const SizedBox(height: 10),

                      // Additional fields required by the data model
                      // (CNIC/B-Form numbers, remarks) but not shown in
                      // the reference screens — tucked behind a toggle
                      // so the primary layout stays visually identical.
                      TextButton.icon(
                        onPressed: () => setState(() => _showAdditionalFields = !_showAdditionalFields),
                        icon: Icon(_showAdditionalFields ? Icons.expand_less : Icons.expand_more),
                        label: const Text('Additional Details'),
                      ),
                      if (_showAdditionalFields) ...[
                        TextFormField(
                          controller: _cnicController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Father CNIC Number'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bFormController,
                          decoration: const InputDecoration(labelText: 'B-Form Number'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _remarksController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Remarks'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),

                      // ---- Document photo tiles ----
                      if (widget.isEditing) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DocumentPhotoTile(
                                label: 'B-Form Picture',
                                photo: photosByType[PhotoType.bForm],
                                onPicked: (file) => _onPhotoPicked(PhotoType.bForm, file),
                                resolveSignedUrl: (p) => ref.read(studentPhotoRepositoryProvider).signedUrlFor(p),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: DocumentPhotoTile(
                                label: 'Father CNIC Picture',
                                photo: photosByType[PhotoType.fatherCnic],
                                onPicked: (file) => _onPhotoPicked(PhotoType.fatherCnic, file),
                                resolveSignedUrl: (p) => ref.read(studentPhotoRepositoryProvider).signedUrlFor(p),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 160,
                          child: DocumentPhotoTile(
                            label: 'Student Token Pic',
                            photo: photosByType[PhotoType.token],
                            onPicked: (file) => _onPhotoPicked(PhotoType.token, file),
                            resolveSignedUrl: (p) => ref.read(studentPhotoRepositoryProvider).signedUrlFor(p),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Save the student first, then add B-Form, CNIC and Token photos from their profile.',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ---- Save / Edit Data button ----
                      GrBookGradientButton(
                        text: widget.isEditing ? 'Edit Data' : 'Add Student',
                        isLoading: _isSubmitting,
                        icon: widget.isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
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

  Future<void> _onPhotoPicked(PhotoType type, File file) async {
    if (!widget.isEditing) return; // photos are added after the student exists
    final student = widget.existingStudent!;
    await ref.read(studentPhotoRepositoryProvider).captureAndSave(
          schoolId: student.schoolId,
          studentId: student.id,
          photoType: type,
          rawFile: file,
          userId: null,
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

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.format, required this.onTap});

  final String label;
  final DateTime? value;
  final DateFormat format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value != null ? format.format(value!) : 'Select date', overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// "Age Here" — three read-only boxes (Year / Month / Days), matching
/// the reference exactly. Always computed live from Date of Birth as of
/// today; never manually editable, since it's a derived value.
class _AgeHereDisplay extends StatelessWidget {
  const _AgeHereDisplay({required this.age});

  final AgeResult? age;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Age Here', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _AgeBox(value: age?.years, label: 'Yr')),
            const SizedBox(width: 6),
            Expanded(child: _AgeBox(value: age?.months, label: 'Mo')),
            const SizedBox(width: 6),
            Expanded(child: _AgeBox(value: age?.days, label: 'Days')),
          ],
        ),
      ],
    );
  }
}

class _AgeBox extends StatelessWidget {
  const _AgeBox({required this.value, required this.label});

  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(value?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
