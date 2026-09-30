import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/gr_book_ui_components.dart';

class AddDataStorageScreen extends ConsumerStatefulWidget {
  const AddDataStorageScreen({super.key});

  @override
  ConsumerState<AddDataStorageScreen> createState() => _AddDataStorageScreenState();
}

class _AddDataStorageScreenState extends ConsumerState<AddDataStorageScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _detectedFolderPath;
  bool _backupExists = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkStorage();
  }

  Future<void> _checkStorage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storageService = ref.read(offlineStorageServiceProvider);
      final dir = await storageService.getOrCreateGrBookDir();
      final backupFile = File(p.join(dir.path, 'gr_book_complete_backup.json'));
      final exists = await backupFile.exists();

      if (mounted) {
        setState(() {
          _detectedFolderPath = dir.path;
          _backupExists = exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not access storage folder: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreFromDetected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sync_rounded, color: GrBookTheme.primary, size: 28),
            SizedBox(width: 10),
            Text('Sync & Restore Data?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will import all school records, classes, students, and photo linkages from your phone\'s GR BOOK folder into the app.\n\nDo you want to proceed?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Sync Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final storageService = ref.read(offlineStorageServiceProvider);
      final result = await storageService.restoreFromStorageFolder();

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _statusMessage = '✓ ${result.message}';
        });
        _showSuccessDialog(result.schoolName, result.studentsCount, result.classesCount, result.photosCount);
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Restore failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickAndRestoreFile() async {
    try {
      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select GR BOOK Backup File',
      );

      if (pickResult == null || pickResult.files.single.path == null) return;

      final filePath = pickResult.files.single.path!;

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
        _statusMessage = null;
      });

      final storageService = ref.read(offlineStorageServiceProvider);
      final result = await storageService.restoreFromStorageFolder(customPath: filePath);

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _statusMessage = '✓ ${result.message}';
        });
        _showSuccessDialog(result.schoolName, result.studentsCount, result.classesCount, result.photosCount);
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'File selection failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportBackupNow() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final storageService = ref.read(offlineStorageServiceProvider);
      final path = await storageService.exportCurrentStateToStorage();

      if (!mounted) return;

      setState(() {
        _backupExists = true;
        _statusMessage = '✓ All data and student photos successfully exported to: $path';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline backup successfully saved to phone storage!'),
          backgroundColor: GrBookTheme.primaryDark,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Export failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(String schoolName, int students, int classes, int photos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('Data Restored!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('School: $schoolName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text('• Classes: $classes', style: const TextStyle(fontSize: 14)),
            Text('• Students: $students', style: const TextStyle(fontSize: 14)),
            Text('• Photos: $photos', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Text(
              'All records have been synced and restored exactly as they were before.',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Back to Settings/Home
            },
            child: const Text('Go to Home / Classes'),
          ),
        ],
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GrBookTopBar(showBack: true),
              const GrBookPageHeader(
                title: 'Add Data',
                subtitle: 'Restore & Sync records from phone\'s GR BOOK folder',
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          if (_statusMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: GrBookTheme.isDark(context) ? const Color(0xFF132A1C) : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: GrBookTheme.isDark(context) ? const Color(0xFF1E482C) : Colors.green.shade300),
                              ),
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(color: GrBookTheme.isDark(context) ? const Color(0xFF4ADE80) : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: GrBookTheme.isDark(context) ? const Color(0xFF321414) : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: GrBookTheme.isDark(context) ? const Color(0xFF5A2020) : Colors.red.shade300),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: GrBookTheme.isDark(context) ? const Color(0xFFF87171) : Colors.red.shade900, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Detected Phone Storage Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: GrBookTheme.getCardBackground(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: GrBookTheme.getBorderColor(context)),
                              boxShadow: const [
                                BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: GrBookTheme.isDark(context) ? const Color(0xFF1E2E24) : GrBookTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.folder_special_rounded, color: GrBookTheme.primary, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Phone File Manager Folder',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GrBookTheme.getTextPrimary(context)),
                                          ),
                                          Text(
                                            'GR BOOK Directory',
                                            style: TextStyle(fontSize: 12, color: GrBookTheme.getTextSecondary(context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_backupExists)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: GrBookTheme.isDark(context) ? const Color(0xFF13381F) : Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Found Backup',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GrBookTheme.isDark(context) ? const Color(0xFF4ADE80) : Colors.green.shade800),
                                        ),
                                      ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text(
                                  'Folder Path:\n${_detectedFolderPath ?? "Not resolved"}',
                                  style: TextStyle(fontSize: 12, color: GrBookTheme.getTextPrimary(context), fontFamily: 'monospace'),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _backupExists
                                      ? 'A complete backup file (gr_book_complete_backup.json) was detected in this folder. Tap below to sync and import all records.'
                                      : 'No backup found in this folder yet. If you have backup files or reinstalling, you can select the file below, or create a backup now.',
                                  style: TextStyle(fontSize: 13, color: GrBookTheme.getTextSecondary(context), height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                if (_backupExists)
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: GrBookTheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      icon: _isProcessing
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Icon(Icons.sync_rounded),
                                      label: Text(
                                        _isProcessing ? 'Syncing...' : 'Sync & Restore Data Now',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      onPressed: _isProcessing ? null : _restoreFromDetected,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Browse & Pick Custom File Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: GrBookTheme.getCardBackground(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: GrBookTheme.getBorderColor(context)),
                              boxShadow: const [
                                BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: GrBookTheme.isDark(context) ? const Color(0xFF1E2E24) : const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.file_open_rounded, color: Color(0xFF2E7D32), size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Select Custom Backup File',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GrBookTheme.getTextPrimary(context)),
                                          ),
                                          Text(
                                            'Browse storage, SD card, or downloads',
                                            style: TextStyle(fontSize: 12, color: GrBookTheme.getTextSecondary(context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'If your backup file is stored elsewhere or you received it via WhatsApp or Bluetooth, choose it from your phone storage.',
                                  style: TextStyle(fontSize: 13, color: GrBookTheme.getTextSecondary(context), height: 1.4),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: GrBookTheme.getBorderColor(context), width: 1.4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                    ),
                                    icon: const Icon(Icons.drive_folder_upload_rounded, color: GrBookTheme.primary),
                                    label: Text(
                                      'Browse File Manager (.json)',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: GrBookTheme.isDark(context) ? const Color(0xFF4ADE80) : GrBookTheme.primary),
                                    ),
                                    onPressed: _isProcessing ? null : _pickAndRestoreFile,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Manual Export Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: GrBookTheme.getCardBackground(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: GrBookTheme.getBorderColor(context)),
                              boxShadow: const [
                                BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: GrBookTheme.isDark(context) ? const Color(0xFF2E2214) : const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.save_as_rounded, color: Color(0xFFE65100), size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Save Backup to Phone Now',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GrBookTheme.getTextPrimary(context)),
                                          ),
                                          Text(
                                            'Export all classes and photos to GR BOOK',
                                            style: TextStyle(fontSize: 12, color: GrBookTheme.getTextSecondary(context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Creates an instant offline copy in your phone\'s GR BOOK folder. Even if you uninstall the app, this folder will stay safe on your phone.',
                                  style: TextStyle(fontSize: 13, color: GrBookTheme.getTextSecondary(context), height: 1.4),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE65100),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                    ),
                                    icon: const Icon(Icons.download_rounded),
                                    label: const Text(
                                      'Save Backup to Storage Now',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: _isProcessing ? null : _exportBackupNow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
