import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../providers/repository_providers.dart';
import '../../services/offline_storage_service.dart';
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

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.folder_shared_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Storage Access Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Android requires "All files access" permission to read and restore records from your phone\'s GR_BOOK folder.\n\nPlease tap "Allow in Settings" and enable access for G.R BOOK.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              OfflineStorageService.openAppSettings();
            },
            child: const Text('Allow in Settings'),
          ),
        ],
      ),
    );
  }

  /// Runs an async task while showing an animated 0% to 100% progress dialog.
  Future<void> _runWithProgressDialog({
    required String title,
    required Future<void> Function(void Function(double progress, String status) onProgress) action,
  }) async {
    double progress = 0.0;
    String status = 'Initializing...';
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          dialogSetState = setModalState;
          final pct = (progress * 100).clamp(0, 100).toInt();

          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GrBookTheme.isDark(context) ? const Color(0xFF1E3A24) : GrBookTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sync_rounded, color: GrBookTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(fontSize: 13, color: GrBookTheme.getTextSecondary(context), fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GrBookTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(GrBookTheme.primary),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    status,
                    style: TextStyle(fontSize: 13, color: GrBookTheme.getTextPrimary(context), height: 1.3),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
      ),
    );

    try {
      await action((p, s) {
        if (mounted && dialogSetState != null) {
          dialogSetState!(() {
            progress = p;
            status = s;
          });
        }
      });
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Exports entire database and photos to a single ZIP archive, then opens share sheet for Google Drive.
  Future<void> _saveToGoogleDriveZip() async {
    setState(() {
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      File? zipFile;
      final storageService = ref.read(offlineStorageServiceProvider);

      await _runWithProgressDialog(
        title: 'Saving to Google Drive',
        action: (onProgress) async {
          zipFile = await storageService.createCompleteZipBackup(onProgress: onProgress);
        },
      );

      if (zipFile == null || !await zipFile!.exists()) return;

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(zipFile!.path, mimeType: 'application/zip')],
        text: 'G.R BOOK Complete Backup Archive (School Data & Photos)',
        subject: 'G.R BOOK Backup Archive',
      );

      if (mounted) {
        setState(() {
          _statusMessage = '✓ Backup ZIP created! Choose Google Drive in the share options to save.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup ZIP ready! Tap "Save to Drive" in the share options.'),
            backgroundColor: GrBookTheme.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to create Google Drive backup: $e');
      }
    }
  }

  /// Restores from a chosen ZIP archive (or JSON) with 0% to 100% progress indicator.
  Future<void> _restoreFromZipPicker() async {
    try {
      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
        dialogTitle: 'Select Backup File (.zip or .json)',
      );

      if (pickResult == null || pickResult.files.single.path == null) return;
      final pickedPath = pickResult.files.single.path!;
      final pickedFile = File(pickedPath);

      if (pickedPath.toLowerCase().endsWith('.zip')) {
        RestoreSummary? result;
        final storageService = ref.read(offlineStorageServiceProvider);

        await _runWithProgressDialog(
          title: 'Restoring from ZIP Backup',
          action: (onProgress) async {
            result = await storageService.restoreFromZipFile(pickedFile, onProgress: onProgress);
          },
        );

        if (!mounted || result == null) return;

        if (result!.success) {
          setState(() {
            _statusMessage = '✓ ${result!.message}';
          });
          _showSuccessDialog(result!.schoolName, result!.studentsCount, result!.classesCount, result!.photosCount);
        } else {
          setState(() {
            _errorMessage = result!.message;
          });
        }
      } else {
        // Direct JSON file
        setState(() {
          _isProcessing = true;
          _errorMessage = null;
          _statusMessage = null;
        });

        final storageService = ref.read(offlineStorageServiceProvider);
        final result = await storageService.restoreFromStorageFolder(customPath: pickedPath);

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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Restore failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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

    // Check permission first
    if (!await OfflineStorageService.hasStoragePermission()) {
      final granted = await OfflineStorageService.requestStoragePermission();
      if (!granted && mounted) {
        _showPermissionDialog();
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final storageService = ref.read(offlineStorageServiceProvider);
      final result = await storageService.restoreFromStorageFolder();

      if (!mounted) return;

      if (result.needsPermission) {
        _showPermissionDialog();
        setState(() {
          _errorMessage = result.message;
        });
        return;
      }

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
        final msg = e.toString().toLowerCase();
        if (msg.contains('permission denied') || msg.contains('errno = 13')) {
          _showPermissionDialog();
        }
        setState(() => _errorMessage = 'Restore failed: $e');
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
                subtitle: 'Restore & Sync records from Google Drive or phone storage',
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
                                color: GrBookTheme.isDark(context) ? const Color(0xFF331616) : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: GrBookTheme.isDark(context) ? const Color(0xFF5C2424) : Colors.red.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(color: GrBookTheme.isDark(context) ? const Color(0xFFFCA5A5) : Colors.red.shade900, fontSize: 12.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_errorMessage!.contains('permission') || _errorMessage!.contains('Permission')) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade700,
                                          side: BorderSide(color: Colors.red.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.settings_outlined, size: 18),
                                        label: const Text('Open Settings to Grant Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        onPressed: OfflineStorageService.openAppSettings,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 1. Save Data to Google Drive (ZIP Archive)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: GrBookTheme.isDark(context)
                                    ? [const Color(0xFF1A3828), const Color(0xFF142C1F)]
                                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: GrBookTheme.primary.withValues(alpha: 0.3), width: 1.5),
                              boxShadow: const [
                                BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 3)),
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
                                        color: GrBookTheme.primary,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Save to Google Drive',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.5,
                                              color: GrBookTheme.getTextPrimary(context),
                                            ),
                                          ),
                                          Text(
                                            'Create ZIP Archive (0% - 100%)',
                                            style: TextStyle(fontSize: 12, color: GrBookTheme.getTextSecondary(context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Bundles all school records, classes, register, and student photos into a secure ZIP archive and lets you upload directly to Google Drive or share via WhatsApp.',
                                  style: TextStyle(fontSize: 13, color: GrBookTheme.getTextSecondary(context), height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: GrBookTheme.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.add_to_drive_rounded, size: 20),
                                    label: const Text(
                                      'Save Data to Google Drive (ZIP)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                    onPressed: _isProcessing ? null : _saveToGoogleDriveZip,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 2. Restore from ZIP Archive (Google Drive / WhatsApp)
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
                                        color: GrBookTheme.isDark(context) ? const Color(0xFF263345) : const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.folder_zip_rounded, color: Color(0xFF1976D2), size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Restore from ZIP File',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GrBookTheme.getTextPrimary(context)),
                                          ),
                                          Text(
                                            'Google Drive / WhatsApp Backup',
                                            style: TextStyle(fontSize: 12, color: GrBookTheme.getTextSecondary(context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Download your backup ZIP from Google Drive, and tap below to restore all student data and photos with automatic progress.',
                                  style: TextStyle(fontSize: 13, color: GrBookTheme.getTextSecondary(context), height: 1.4),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                    ),
                                    icon: const Icon(Icons.file_download_rounded, color: Color(0xFF1976D2)),
                                    label: const Text(
                                      'Select & Restore Backup ZIP',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                                    ),
                                    onPressed: _isProcessing ? null : _restoreFromZipPicker,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 3. Phone File Manager Folder (GR_BOOK Directory)
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
                                            'Phone Storage Folder',
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
                                      ? 'A complete backup was detected in this folder. Tap below to sync and import all records.'
                                      : 'No backup found in this folder yet. You can save a backup or restore from ZIP above.',
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

                          // 4. Save Backup to Phone Now (Manual Local Export)
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
                                            'Save to Phone Storage',
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
