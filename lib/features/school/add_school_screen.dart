import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/school_repository.dart';
import '../classes/classes_screen.dart';

/// Requirement #5 / UI reference screen 3 ("Add School").
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Add School')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'School Name', prefixIcon: Icon(Icons.school_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'School name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _semisController,
                  decoration: const InputDecoration(labelText: 'SEMIS Code', prefixIcon: Icon(Icons.numbers_outlined)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ucController,
                  decoration: const InputDecoration(labelText: 'U.C.', prefixIcon: Icon(Icons.map_outlined)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _talukaController,
                  decoration: const InputDecoration(labelText: 'Taluka', prefixIcon: Icon(Icons.location_city_outlined)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(labelText: 'District', prefixIcon: Icon(Icons.pin_drop_outlined)),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: GrBookTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save & Continue', style: TextStyle(fontSize: 16)),
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
