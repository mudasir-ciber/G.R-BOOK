import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_service.dart';
import '../students/widgets/photo_picker_sheet.dart';

/// Principal Account: Name, Mobile, Profile Picture, Official Signature, and Password.
class MyAccountScreen extends ConsumerStatefulWidget {
  const MyAccountScreen({super.key});

  @override
  ConsumerState<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends ConsumerState<MyAccountScreen> {
  late final TextEditingController _nameController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _savingName = false;
  bool _changingPassword = false;
  String? _nameError;
  String? _passwordError;

  File? _profilePhotoFile;
  File? _signatureFile;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.userMetadata?['full_name'] as String? ?? '');
    _loadLocalImages();
  }

  Future<void> _loadLocalImages() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final pFile = File('${docDir.path}/principal_profile.png');
      final sFile = File('${docDir.path}/principal_signature.png');
      setState(() {
        if (pFile.existsSync()) _profilePhotoFile = pFile;
        if (sFile.existsSync()) _signatureFile = sFile;
      });
    } catch (_) {}
  }

  Future<void> _pickProfilePhoto() async {
    final file = await showPhotoPickerSheet(context, preferredAspectRatio: 1.0);
    if (file != null) {
      final docDir = await getApplicationDocumentsDirectory();
      final target = File('${docDir.path}/principal_profile.png');
      await file.copy(target.path);
      setState(() => _profilePhotoFile = target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F9D58),
            content: Text('Principal profile photo updated.'),
          ),
        );
      }
    }
  }

  Future<void> _pickSignature() async {
    final file = await showPhotoPickerSheet(context, preferredAspectRatio: 2.5);
    if (file != null) {
      final docDir = await getApplicationDocumentsDirectory();
      final target = File('${docDir.path}/principal_signature.png');
      await file.copy(target.path);
      setState(() => _signatureFile = target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F9D58),
            content: Text('Principal signature saved. It will now appear on all certificates!'),
          ),
        );
      }
    }
  }

  Future<void> _removeSignature() async {
    if (_signatureFile != null && await _signatureFile!.exists()) {
      await _signatureFile!.delete();
    }
    setState(() => _signatureFile = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Principal signature removed.')),
      );
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty.');
      return;
    }
    setState(() {
      _savingName = true;
      _nameError = null;
    });
    try {
      await ref.read(authServiceProvider).updateFullName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F9D58),
            content: Text('Principal name updated.'),
          ),
        );
      }
    } on AuthServiceException catch (e) {
      setState(() => _nameError = e.message);
    } catch (e) {
      setState(() => _nameError = 'Could not save. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    if (newPassword.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters.');
      return;
    }
    if (newPassword != _confirmPasswordController.text) {
      setState(() => _passwordError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _changingPassword = true;
      _passwordError = null;
    });
    try {
      await ref.read(authServiceProvider).changePassword(newPassword);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F9D58),
            content: Text('Password changed successfully.'),
          ),
        );
      }
    } on AuthServiceException catch (e) {
      setState(() => _passwordError = e.message);
    } catch (e) {
      setState(() => _passwordError = 'Could not change password. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final mobileNumber = user?.userMetadata?['mobile_number'] as String? ?? '-';

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(
        title: const Text('Principal Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          children: [
            // 1. Profile Information Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(44),
                          onTap: () async {
                            if (_profilePhotoFile != null && await _profilePhotoFile!.exists()) {
                              if (!context.mounted) return;
                              await FullScreenImageViewer.open(
                                context,
                                file: _profilePhotoFile,
                                title: 'Principal Profile Picture',
                                onImageChanged: (newFile) async {
                                  final docDir = await getApplicationDocumentsDirectory();
                                  final target = File('${docDir.path}/principal_profile.png');
                                  await newFile.copy(target.path);
                                  setState(() => _profilePhotoFile = target);
                                },
                                aspectRatio: 1.0,
                              );
                            } else {
                              _pickProfilePhoto();
                            }
                          },
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE2E8F0),
                              border: Border.all(color: GrBookTheme.primary, width: 2.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _profilePhotoFile != null && _profilePhotoFile!.existsSync()
                                ? Image.file(_profilePhotoFile!, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'P',
                                      style: const TextStyle(fontSize: 32, color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _pickProfilePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: GrBookTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : 'Principal',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GrBookTheme.primaryDark),
                    ),
                    const Text('School Head / Administrator', style: TextStyle(color: GrBookTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    if (_nameError != null) ...[
                      Text(_nameError!, style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: GrBookTheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          Text('Mobile Number: $mobileNumber', style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: GrBookTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _savingName ? null : _saveName,
                        child: _savingName
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Name', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Principal Official Signature Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.draw_rounded, color: GrBookTheme.primary, size: 22),
                        SizedBox(width: 8),
                        Text('Principal Official Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Upload your signature image. It will be automatically printed on all certificates, leaving certificates, and official school notes.',
                      style: TextStyle(fontSize: 12.5, color: GrBookTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    if (_signatureFile != null && _signatureFile!.existsSync()) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          if (!context.mounted) return;
                          await FullScreenImageViewer.open(
                            context,
                            file: _signatureFile,
                            title: 'Principal Signature',
                            onImageChanged: (newFile) async {
                              final docDir = await getApplicationDocumentsDirectory();
                              final target = File('${docDir.path}/principal_signature.png');
                              await newFile.copy(target.path);
                              setState(() => _signatureFile = target);
                            },
                            aspectRatio: 2.5,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: GrBookTheme.primary, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          child: Image.file(_signatureFile!, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: GrBookTheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _pickSignature,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Change Signature'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            tooltip: 'Remove Signature',
                            onPressed: _removeSignature,
                          ),
                        ],
                      ),
                    ] else ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickSignature,
                        child: Container(
                          width: double.infinity,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: GrBookTheme.primary, size: 30),
                              SizedBox(height: 6),
                              Text('Tap to Upload Signature (PNG/JPG)', style: TextStyle(color: GrBookTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Change Password Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: GrBookTheme.primary, size: 22),
                        SizedBox(width: 8),
                        Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_passwordError != null) ...[
                      Text(_passwordError!, style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: GrBookTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _changingPassword ? null : _changePassword,
                        child: _changingPassword
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
