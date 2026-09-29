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
import '../../widgets/sync_status_banner.dart';
import '../audit/audit_log_screen.dart';
import 'certificate_screen.dart';
import 'widgets/document_photo_tile.dart';
import 'widgets/profile_photo_avatar.dart';

/// Screen 8: Student Profile / Add Student matching reference UI image 8 exactly.
/// Serves both as "Add Student" and "Student Profile" with full photo picker support
/// for Student Photo, B-Form, Father CNIC, and Token Picture.
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
      final Student targetStudent;
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
        targetStudent = updated;
      } else {
        targetStudent = await repo.createStudent(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Student updated successfully.' : 'Student registered successfully.')),
      );
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

              if (widget.isEditing) const SyncStatusBanner(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: GrBookTheme.borderColor, width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
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

                          // 2. Student Name Pill Field (Centered in rounded box)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD6E8DC), width: 1.2),
                            ),
                            child: TextFormField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GrBookTheme.textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                border: InputBorder.none,
                                hintText: 'Student Name',
                                hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Student name is required' : null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3. Row 1: G.R No. | Class
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.assignment_outlined,
                                  label: 'G.R No.',
                                  child: TextFormField(
                                    controller: _grController,
                                    keyboardType: TextInputType.text,
                                    style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: '001',
                                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
                                  trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: GrBookTheme.textSecondary),
                                  child: classesAsync.when(
                                    loading: () => const Text('Loading...', style: TextStyle(fontSize: 12)),
                                    error: (_, __) => const Text('Error', style: TextStyle(fontSize: 12)),
                                    data: (classes) => DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: classes.any((c) => c.id == _selectedClassId) ? _selectedClassId : null,
                                        isDense: true,
                                        icon: const SizedBox.shrink(),
                                        style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary, fontWeight: FontWeight.bold),
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

                          // 4. Row 2: Father Name | Mobile No.
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.person,
                                  label: 'Father Name',
                                  child: TextFormField(
                                    controller: _fatherNameController,
                                    style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w500),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: 'Enter father name',
                                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.phone,
                                  label: 'Mobile No.',
                                  child: TextFormField(
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w500),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: 'Enter mobile number',
                                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 5. Row 3: Mother Name | Last School
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.person,
                                  label: 'Mother Name',
                                  child: TextFormField(
                                    controller: _motherNameController,
                                    style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w500),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: 'Enter mother name',
                                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.apartment_rounded,
                                  label: 'Last School',
                                  child: TextFormField(
                                    controller: _lastSchoolController,
                                    style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w500),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: 'Enter last school',
                                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 6. Row 4: Date of Birth | Age Here
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Date of Birth',
                                  onTap: () => _pickDate(isDob: true),
                                  trailing: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF94A3B8)),
                                  child: Text(
                                    _dateOfBirth != null ? _dateFormat.format(_dateOfBirth!) : 'Select date',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _dateOfBirth != null ? GrBookTheme.textPrimary : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ProfileFieldCard(
                                  icon: Icons.person_outline,
                                  label: 'Age Here',
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            age != null ? '${age.years} Yr' : 'Year',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GrBookTheme.textPrimary),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            age != null ? '${age.months} Mo' : 'Month',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GrBookTheme.textPrimary),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            age != null ? '${age.days} D' : 'Days',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GrBookTheme.textPrimary),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 7. Row 5: Date of Admission
                          _ProfileFieldCard(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date of Admission',
                            onTap: () => _pickDate(isDob: false),
                            trailing: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF94A3B8)),
                            child: Text(
                              _dateOfAdmission != null ? _dateFormat.format(_dateOfAdmission!) : 'Select date',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _dateOfAdmission != null ? GrBookTheme.textPrimary : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 8. Row 6: Address
                          _ProfileFieldCard(
                            icon: Icons.location_on,
                            label: 'Address',
                            child: TextFormField(
                              controller: _addressController,
                              style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary, fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: 'Enter address',
                                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Optional details toggle
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _showAdditionalFields = !_showAdditionalFields),
                              icon: Icon(_showAdditionalFields ? Icons.expand_less : Icons.expand_more, size: 18, color: GrBookTheme.primary),
                              label: Text(
                                _showAdditionalFields ? 'Hide Additional Details' : 'More Details (CNIC, B-Form, Remarks)',
                                style: const TextStyle(fontSize: 12, color: GrBookTheme.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          if (_showAdditionalFields) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _ProfileFieldCard(
                                    icon: Icons.credit_card_rounded,
                                    label: 'Father CNIC No.',
                                    child: TextFormField(
                                      controller: _cnicController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        hintText: 'e.g. 45302-XXXXXXX-X',
                                        hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ProfileFieldCard(
                                    icon: Icons.badge_outlined,
                                    label: 'B-Form Number',
                                    child: TextFormField(
                                      controller: _bFormController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        hintText: 'e.g. 45302-XXXXXXX-X',
                                        hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _ProfileFieldCard(
                              icon: Icons.notes_rounded,
                              label: 'Remarks',
                              child: TextFormField(
                                controller: _remarksController,
                                style: const TextStyle(fontSize: 13, color: GrBookTheme.textPrimary),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Optional notes or remarks',
                                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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

                          // 10. Bottom Button ("Edit Data" or "Save Student")
                          GrBookGradientButton(
                            text: widget.isEditing ? 'Edit Data' : 'Save Student',
                            isLoading: _isSubmitting,
                            icon: widget.isEditing ? Icons.edit_rounded : Icons.check_circle_outline_rounded,
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E8DC), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: GrBookTheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: GrBookTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  child,
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
