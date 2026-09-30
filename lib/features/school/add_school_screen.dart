import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/school_repository.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../classes/classes_screen.dart';

/// Screen 3: Add School Page matching reference UI image 3 exactly.
class AddSchoolScreen extends ConsumerStatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  ConsumerState<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends ConsumerState<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _semisController = TextEditingController();
  final _ucController = TextEditingController();
  final _talukaController = TextEditingController();
  final _districtController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(schoolRepositoryProvider).createSchool(
            schoolName: _nameController.text.trim(),
            semisCode: _semisController.text.trim().isEmpty ? null : _semisController.text.trim(),
            uc: _ucController.text.trim().isEmpty ? null : _ucController.text.trim(),
            taluka: _talukaController.text.trim().isEmpty ? null : _talukaController.text.trim(),
            district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ClassesScreen()),
      );
    } on SchoolRepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: GrBookTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: TextStyle(color: GrBookTheme.getTextPrimary(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: GrBookTheme.getTextSecondary(context)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GrBookTheme.isDark(context) ? const Color(0xFF1E2E24) : GrBookTheme.primaryLight,
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GrBookTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar with Back Button
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: GrBookTheme.getCardBackground(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: GrBookTheme.getBorderColor(context), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GrBookTheme.primary, size: 18),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                ),

                // Illustration Header
                Center(
                  child: Image.asset(
                    'assets/images/auth_header.png',
                    width: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Column(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 48, color: GrBookTheme.primary),
                        SizedBox(height: 6),
                        Text(
                          'G.R. Book',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Rounded Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  decoration: BoxDecoration(
                    color: GrBookTheme.getCardBackground(context),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F7A42),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Add Your School',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: GrBookTheme.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your school information to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: GrBookTheme.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        _buildField(
                          controller: _nameController,
                          label: 'School Name',
                          hint: 'Enter School Name',
                          icon: Icons.apartment_rounded,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _semisController,
                          label: 'SEMIS Code',
                          hint: 'Enter SEMIS Code',
                          icon: Icons.qr_code_2_rounded,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _ucController,
                          label: 'U.C',
                          hint: 'Enter U.C',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _talukaController,
                          label: 'Taluka',
                          hint: 'Enter Taluka',
                          icon: Icons.location_city_outlined,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _districtController,
                          label: 'District',
                          hint: 'Enter District',
                          icon: Icons.map_outlined,
                        ),
                        const SizedBox(height: 24),

                        // Save & Continue Button
                        GrBookGradientButton(
                          text: 'Save & Continue',
                          isLoading: _isSubmitting,
                          onPressed: _submit,
                          trailingIcon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
