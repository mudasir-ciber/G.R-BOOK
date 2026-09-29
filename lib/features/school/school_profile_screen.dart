import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/school.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/gr_book_ui_components.dart';

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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: GrBookTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GrBookTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: GrBookTheme.primary, size: 20),
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
        ),
      ],
    );
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
              const GrBookTopBar(),
              const GrBookPageHeader(
                title: 'School Profile',
                subtitle: 'View and edit your school information',
              ),
              Expanded(
                child: schoolAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Could not load school: $e')),
                  data: (school) {
                    if (school == null) {
                      return const Center(child: Text('No school found on this device yet.'));
                    }
                    _populateIfNeeded(school);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildField(
                                controller: _nameController,
                                label: 'School Name',
                                hint: 'Enter School Name',
                                icon: Icons.apartment_rounded,
                                isRequired: true,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _semisController,
                                label: 'SEMIS Code',
                                hint: 'Enter SEMIS Code',
                                icon: Icons.qr_code_2_rounded,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _ucController,
                                label: 'U.C',
                                hint: 'Enter U.C',
                                icon: Icons.location_on_outlined,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _talukaController,
                                label: 'Taluka',
                                hint: 'Enter Taluka',
                                icon: Icons.location_city_outlined,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _districtController,
                                label: 'District',
                                hint: 'Enter District',
                                icon: Icons.map_outlined,
                              ),
                              const SizedBox(height: 24),
                              GrBookGradientButton(
                                text: 'Save Changes',
                                icon: Icons.save_rounded,
                                trailingIcon: null,
                                isLoading: _isSaving,
                                onPressed: _save,
                              ),
                            ],
                          ),
                        ),
                      ),
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
    _nameController.dispose();
    _semisController.dispose();
    _ucController.dispose();
    _talukaController.dispose();
    _districtController.dispose();
    super.dispose();
  }
}
