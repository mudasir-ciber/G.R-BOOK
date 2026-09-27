import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/school.dart';
import '../../providers/repository_providers.dart';

/// Requirement #5: the school profile must be editable later.
class SchoolProfileScreen extends ConsumerStatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  ConsumerState<SchoolProfileScreen> createState() => _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends ConsumerState<SchoolProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _semisController;
  late final TextEditingController _ucController;
  late final TextEditingController _talukaController;
  late final TextEditingController _districtController;
  School? _loadedSchool;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _semisController = TextEditingController();
    _ucController = TextEditingController();
    _talukaController = TextEditingController();
    _districtController = TextEditingController();
  }

  void _populateIfNeeded(School school) {
    if (_loadedSchool?.id == school.id) return;
    _loadedSchool = school;
    _nameController.text = school.schoolName;
    _semisController.text = school.semisCode ?? '';
    _ucController.text = school.uc ?? '';
    _talukaController.text = school.taluka ?? '';
    _districtController.text = school.district ?? '';
  }

  Future<void> _save() async {
    if (_loadedSchool == null || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = _loadedSchool!.copyWith(
        schoolName: _nameController.text.trim(),
        semisCode: _semisController.text.trim().isEmpty ? null : _semisController.text.trim(),
        uc: _ucController.text.trim().isEmpty ? null : _ucController.text.trim(),
        taluka: _talukaController.text.trim().isEmpty ? null : _talukaController.text.trim(),
        district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      );
      await ref.read(schoolRepositoryProvider).updateSchoolProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('School profile updated.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('School Profile')),
      body: schoolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load school: $e')),
        data: (school) {
          if (school == null) {
            return const Center(child: Text('No school found on this device yet.'));
          }
          _populateIfNeeded(school);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'School Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _semisController, decoration: const InputDecoration(labelText: 'SEMIS Code')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _ucController, decoration: const InputDecoration(labelText: 'U.C.')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _talukaController, decoration: const InputDecoration(labelText: 'Taluka')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _districtController, decoration: const InputDecoration(labelText: 'District')),
                    const SizedBox(height: 28),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: GrBookTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _semisController.dispose();
    _ucController.dispose();
    _talukaController.dispose();
    _districtController.dispose();
    super.dispose();
  }
}
