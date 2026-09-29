import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../providers/backup_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/google_drive_backup_service.dart';
import '../auth/auth_providers.dart';
import 'add_data_storage_screen.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isSignedIn = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isExportingLocal = false;
  bool _autoBackupEnabled = false;
  DateTime? _lastBackupAt;
  List<DriveBackupSummary> _backups = [];
  String? _error;
  String? _localBackupMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = ref.read(googleDriveBackupServiceProvider);
    final prefs = ref.read(backupPreferencesProvider);
    final account = await service.signInSilently();
    _autoBackupEnabled = await prefs.isAutoBackupEnabled();
    _lastBackupAt = await prefs.getLastBackupAt();
    if (mounted) {
      setState(() => _isSignedIn = account != null);
    }
    if (account != null) await _refreshBackups();
  }

  Future<void> _refreshBackups() async {
    final school = await ref.read(schoolRepositoryProvider).getLocalSchool();
    if (school == null) return;
    try {
      final backups = await ref.read(googleDriveBackupServiceProvider).listBackups(schoolId: school.id);
      if (mounted) setState(() => _backups = backups);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _signIn() async {
    setState(() => _error = null);
    try {
      final account = await ref.read(googleDriveBackupServiceProvider).signIn();
      setState(() => _isSignedIn = account != null);
      if (account != null) await _refreshBackups();
    } catch (e) {
      setState(() => _error = 'Google sign-in error: $e\n\nIf you see "Error 403: access_denied", your Google account must be added to the Google Cloud Console Test Users list, or use Local Phone Storage Backup.');
    }
  }

  Future<void> _backupToLocalStorageNow() async {
    setState(() {
      _isExportingLocal = true;
      _localBackupMessage = null;
      _error = null;
    });
    try {
      final storageService = ref.read(offlineStorageServiceProvider);
      final path = await storageService.exportCurrentStateToStorage();
      if (mounted) {
        setState(() {
          _localBackupMessage = '✓ Backup successfully created in:\n$path';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline backup successfully saved to phone!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Local export failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isExportingLocal = false);
    }
  }

  Future<void> _shareBackupFile() async {
    setState(() {
      _isExportingLocal = true;
      _error = null;
    });
    try {
      final storageService = ref.read(offlineStorageServiceProvider);
      final dirPath = await storageService.exportCurrentStateToStorage();
      final backupFile = File('$dirPath/gr_book_complete_backup.json');
      if (await backupFile.exists()) {
        await Share.shareXFiles(
          [XFile(backupFile.path, mimeType: 'application/json')],
          text: 'G.R BOOK Complete School Records Backup',
          subject: 'G.R BOOK School Backup File',
        );
      } else {
        throw Exception('Backup file could not be generated.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Share/Save failed: $e');
    } finally {
      if (mounted) setState(() => _isExportingLocal = false);
    }
  }

  Future<void> _backupNow() async {
    final school = await ref.read(schoolRepositoryProvider).getLocalSchool();
    if (school == null) return;
    setState(() {
      _isBackingUp = true;
      _error = null;
    });
    try {
      final userId = ref.read(currentUserProvider)?.id;
      await ref.read(googleDriveBackupServiceProvider).backupNow(schoolId: school.id, userId: userId);
      final now = DateTime.now();
      await ref.read(backupPreferencesProvider).setLastBackupAt(now);
      setState(() => _lastBackupAt = now);
      await _refreshBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Drive Backup completed.')));
      }
    } catch (e) {
      setState(() => _error = 'Google Drive Backup failed: $e');
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restore(DriveBackupSummary backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Text(
          'This will overwrite your local data with the backup from '
          '${backup.createdTime != null ? DateFormat('dd-MM-yyyy hh:mm a').format(backup.createdTime!.toLocal()) : backup.name}. '
          'Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
      _error = null;
    });
    try {
      final userId = ref.read(currentUserProvider)?.id;
      await ref.read(googleDriveBackupServiceProvider).restoreBackup(backupFileId: backup.id, userId: userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore completed.')));
      }
    } catch (e) {
      setState(() => _error = 'Restore failed: $e');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');

    return Scaffold(
      backgroundColor: GrBookTheme.background,
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            if (_localBackupMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                child: Text(_localBackupMessage!, style: TextStyle(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],

            // 1. LOCAL PHONE STORAGE BACKUP (RECOMMENDED)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GrBookTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder_special_rounded, color: GrBookTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Storage Backup (Offline)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GrBookTheme.textPrimary),
                              ),
                              Text(
                                'Recommended • 100% Offline & Reliable',
                                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Saves all classes, student records, and student photos into your phone\'s public GR BOOK folder. This folder survives app uninstallation and does not require Google verification.',
                      style: TextStyle(fontSize: 13, color: GrBookTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: GrBookTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: _isExportingLocal ? null : _backupToLocalStorageNow,
                            icon: _isExportingLocal
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_alt_rounded, size: 20),
                            label: const Text(
                              'Save Backup to Phone Now',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GrBookTheme.primary,
                              side: const BorderSide(color: GrBookTheme.primary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: GrBookTheme.primaryLight.withValues(alpha: 0.35),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddDataStorageScreen()),
                            ),
                            icon: const Icon(Icons.drive_folder_upload_rounded, color: GrBookTheme.primary, size: 20),
                            label: const Text(
                              'Add Data / Restore from Storage',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. GOOGLE DRIVE BACKUP SECTION
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_outlined, color: Color(0xFF1967D2), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Google Drive Cloud Backup',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GrBookTheme.textPrimary),
                              ),
                              Text(
                                'Cloud sync & one-tap Drive sharing',
                                style: TextStyle(fontSize: 12, color: GrBookTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Universal One-Tap Share to Drive / Apps
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1967D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: _isExportingLocal ? null : _shareBackupFile,
                        icon: const Icon(Icons.drive_file_move_rounded, size: 20),
                        label: const Text(
                          'Save to Google Drive & Share',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚡ Instantly upload backup to Google Drive or send via WhatsApp/Gmail using your phone\'s native sharing (No Error 403 access restrictions).',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.35),
                    ),

                    const Divider(height: 28),

                    if (!_isSignedIn) ...[
                      const Text(
                        'Direct Cloud API Sign-in:\nNote: If Google displays "Error 403: access_denied", Google Cloud Console requires registering your Gmail as a developer Test User. You can use "Save to Google Drive & Share" above without any restrictions.',
                        style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1967D2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: _signIn,
                          icon: const Icon(Icons.login_rounded, color: Color(0xFF1967D2)),
                          label: const Text('Direct Sign in with Google Drive', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1967D2))),
                        ),
                      ),
                    ] else ...[
                      Text(
                        _lastBackupAt != null ? 'Last Google Drive backup: ${dateFormat.format(_lastBackupAt!)}' : 'No cloud backup yet.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1967D2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isBackingUp ? null : _backupNow,
                          icon: _isBackingUp
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Backup to Google Drive', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _autoBackupEnabled,
                        activeThumbColor: const Color(0xFF1967D2),
                        title: const Text('Automatic Cloud Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Auto-uploads daily snapshot when app is opened.'),
                        onChanged: (v) async {
                          await ref.read(backupPreferencesProvider).setAutoBackupEnabled(v);
                          setState(() => _autoBackupEnabled = v);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_isSignedIn && _backups.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Cloud Backups on Drive', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._backups.map(
                (b) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined, color: GrBookTheme.primaryDark),
                    title: Text(b.createdTime != null ? dateFormat.format(b.createdTime!.toLocal()) : b.name),
                    subtitle: Text(b.sizeBytes != null ? '${(b.sizeBytes! / 1024).toStringAsFixed(1)} KB' : ''),
                    trailing: _isRestoring
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : OutlinedButton(
                            onPressed: () => _restore(b),
                            child: const Text('Restore'),
                          ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
