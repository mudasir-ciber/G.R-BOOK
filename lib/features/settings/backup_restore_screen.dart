import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/backup_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/google_drive_backup_service.dart';
import '../auth/auth_providers.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isSignedIn = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _autoBackupEnabled = false;
  DateTime? _lastBackupAt;
  List<DriveBackupSummary> _backups = [];
  String? _error;

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
      setState(() => _error = 'Google sign-in failed: $e');
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup completed.')));
      }
    } catch (e) {
      setState(() => _error = 'Backup failed: $e');
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
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
              const SizedBox(height: 16),
            ],
            if (!_isSignedIn) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_outlined, size: 40, color: GrBookTheme.primary),
                      const SizedBox(height: 12),
                      const Text('Sign in with Google to back up your school data to Drive.', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
                        onPressed: _signIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastBackupAt != null ? 'Last backup: ${dateFormat.format(_lastBackupAt!)}' : 'No backup yet.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _isBackingUp ? null : _backupNow,
                          icon: _isBackingUp
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.backup_outlined),
                          label: const Text('Backup Now'),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _autoBackupEnabled,
                        activeColor: GrBookTheme.primary,
                        title: const Text('Automatic Backup'),
                        subtitle: const Text('Backs up when you open the app if it has been more than 24 hours since the last backup.'),
                        onChanged: (v) async {
                          await ref.read(backupPreferencesProvider).setAutoBackupEnabled(v);
                          setState(() => _autoBackupEnabled = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Previous Backups', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_backups.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('No backups found on Drive yet.'))
              else
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
          ],
        ),
      ),
    );
  }
}
