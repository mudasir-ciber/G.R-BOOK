import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/master_admin_config.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_service.dart';

/// Screen: Master Admin Control Portal
/// Accessible exclusively to Founder Mudasir Ahmed to manage approvals,
/// suspend/activate school accounts, and contact users directly.
class MasterAdminPortalScreen extends ConsumerStatefulWidget {
  const MasterAdminPortalScreen({super.key});

  @override
  ConsumerState<MasterAdminPortalScreen> createState() => _MasterAdminPortalScreenState();
}

class _MasterAdminPortalScreenState extends ConsumerState<MasterAdminPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _activeUsers = [];
  List<Map<String, dynamic>> _rejectedUsers = [];
  List<Map<String, dynamic>> _allUsers = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isUserSuperAdmin(Map<String, dynamic> u) {
    final role = u['role']?.toString() ?? '';
    final mobile = u['mobile_number']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    final name = u['full_name']?.toString() ?? '';
    return role == 'super_admin' ||
        MasterAdminConfig.isFounderIdentifier(mobile) ||
        MasterAdminConfig.isFounderIdentifier(email) ||
        name == MasterAdminConfig.founderName;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = ref.read(authServiceProvider);

    try {
      final pending = await auth.fetchPendingUsers();
      final active = await auth.fetchActiveUsers();
      final rejected = await auth.fetchRejectedUsers();
      final all = await auth.fetchAllUsers();

      active.sort((a, b) {
        final aIsSuper = _isUserSuperAdmin(a);
        final bIsSuper = _isUserSuperAdmin(b);
        if (aIsSuper && !bIsSuper) return -1;
        if (!aIsSuper && bIsSuper) return 1;
        return 0;
      });

      all.sort((a, b) {
        final aIsSuper = _isUserSuperAdmin(a);
        final bIsSuper = _isUserSuperAdmin(b);
        if (aIsSuper && !bIsSuper) return -1;
        if (!aIsSuper && bIsSuper) return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          _pendingUsers = pending;
          _activeUsers = active;
          _rejectedUsers = rejected;
          _allUsers = all;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showStatusResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
    Map<String, dynamic>? user,
    String? actionType,
  }) async {
    final mobile = user?['mobile_number']?.toString() ?? '';
    final email = user?['email']?.toString() ?? '';

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final bgColor = GrBookTheme.getCardBackground(ctx);
        final textPrimary = GrBookTheme.getTextPrimary(ctx);
        final textSecondary = GrBookTheme.getTextSecondary(ctx);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
          backgroundColor: bgColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Reference Symbol (Green Checkmark / Red Cross)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: const Size(90, 90),
                    painter: _StatusSymbolPainter(isSuccess: isSuccess),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),
                if (user != null &&
                    (mobile.isNotEmpty || email.isNotEmpty) &&
                    (actionType == 'approval' || actionType == 'reactivate' || actionType == 'reject')) ...[
                  const SizedBox(height: 20),
                  Divider(height: 1, color: GrBookTheme.getBorderColor(ctx)),
                  const SizedBox(height: 16),
                  if (mobile.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 20),
                        label: const Text(
                          'WhatsApp Notify',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          _notifyUserOnWhatsApp(user, messageType: actionType ?? 'general');
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (email.isNotEmpty && (actionType == 'approval' || actionType == 'reactivate')) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F9D58),
                          side: const BorderSide(color: Color(0xFF0F9D58), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.email_outlined, size: 20),
                        label: Text(
                          actionType == 'approval' ? 'Send Approval Email' : 'Send Reactivation Email',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          if (actionType == 'approval') {
                            _sendApprovalEmail(user);
                          } else {
                            _sendReactivationEmail(user);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isSuccess ? const Color(0xFF0F9D58) : const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAdminResetPasswordDialog(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    final mobile = user['mobile_number']?.toString() ?? '';
    final newPassController = TextEditingController(text: '123456');
    bool shareOnWhatsApp = mobile.isNotEmpty;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.key_rounded, color: GrBookTheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Reset Password for $name', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter new password for this user (minimum 6 characters):',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newPassController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (mobile.isNotEmpty) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: shareOnWhatsApp,
                  title: const Text('Share new password on WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onChanged: (v) => setDialogState(() => shareOnWhatsApp = v ?? true),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final newPassword = newPassController.text.trim();
    if (newPassword.length < 6) {
      _showStatusResultDialog(
        isSuccess: false,
        title: 'Invalid Password',
        message: 'Password must be at least 6 characters long.',
      );
      return;
    }

    try {
      await ref.read(authServiceProvider).adminResetUserPassword(
            userId: userId,
            newPassword: newPassword,
          );

      if (mounted) {
        if (shareOnWhatsApp && mobile.isNotEmpty) {
          _shareNewPasswordOnWhatsApp(user, newPassword);
        }
        _showStatusResultDialog(
          isSuccess: true,
          title: 'Password Reset!',
          message: 'Password for "$name" has been reset to: $newPassword',
          user: user,
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusResultDialog(
          isSuccess: false,
          title: 'Reset Failed',
          message: e is AuthServiceException ? e.message : '$e',
        );
      }
    }
  }

  Future<void> _shareNewPasswordOnWhatsApp(Map<String, dynamic> user, String newPassword) async {
    final mobile = user['mobile_number']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    if (mobile.isEmpty) return;

    final digits = AuthService.normalizePhone(mobile);
    final formattedNumber = digits.startsWith('0') ? '92${digits.substring(1)}' : digits;
    final message = 'Assalam-o-Alaikum $name, your G.R. BOOK password has been reset by Admin Mudasir Ahmed.\n\nYour new password is: $newPassword\n\nYou can now log in to the app.';

    final uri = Uri.parse('https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';

    if (_isUserSuperAdmin(user)) {
      _showStatusResultDialog(
        isSuccess: false,
        title: 'Action Not Allowed',
        message: 'Cannot delete Super Admin account.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to completely delete the account for "$name"?\n\n'
          '• The account status will be set to DELETED on the server.\n'
          '• When they try to log in, they will see the "Account Deleted" screen.\n'
          '• They will be completely blocked from accessing school records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).deleteUserAccount(userId);
      if (mounted) {
        _loadData();
        _showStatusResultDialog(
          isSuccess: false,
          title: 'Account Deleted',
          message: '$name\'s account has been completely deleted from the server.',
          user: user,
          actionType: 'delete',
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusResultDialog(
          isSuccess: false,
          title: 'Delete Failed',
          message: 'Error deleting account: $e',
        );
      }
    }
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    final auth = ref.read(authServiceProvider);

    try {
      await auth.approveUser(userId);
      if (mounted) {
        _loadData();
        _showStatusResultDialog(
          isSuccess: true,
          title: 'Account Approved!',
          message: '$name has been approved successfully.\nTheir account is now active and ready to log in.',
          user: user,
          actionType: 'approval',
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusResultDialog(
          isSuccess: false,
          title: 'Approval Failed',
          message: 'Error approving $name: $e',
        );
      }
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Reject Request'),
          ],
        ),
        content: Text(
          'Are you sure you want to reject the registration request for "$name"?\n\nThe user will see the Rejection screen when they open the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).rejectUser(userId);
      if (mounted) {
        _loadData();
        _showStatusResultDialog(
          isSuccess: false,
          title: 'Request Rejected',
          message: '$name\'s registration request has been rejected.',
          user: user,
          actionType: 'reject',
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusResultDialog(
          isSuccess: false,
          title: 'Operation Failed',
          message: 'Error: $e',
        );
      }
    }
  }

  Future<void> _reactivateUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.replay_rounded, color: Color(0xFF0F9D58), size: 24),
            SizedBox(width: 8),
            Text('Reactivate Account'),
          ],
        ),
        content: Text(
          'Do you want to reactivate the account for "$name"?\n\nThey will regain full access to school records immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).reactivateUser(userId);
      if (mounted) {
        _loadData();
        _showStatusResultDialog(
          isSuccess: true,
          title: 'Account Reactivated!',
          message: '$name has been reactivated successfully.\nThey can now log in and access all records.',
          user: user,
          actionType: 'reactivate',
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusResultDialog(
          isSuccess: false,
          title: 'Operation Failed',
          message: 'Error: $e',
        );
      }
    }
  }


  Future<void> _promptReactivationEmail(Map<String, dynamic> user) async {
    final name = user['full_name']?.toString() ?? 'User';
    final email = user['email']?.toString() ?? '';

    final sendNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF0F9D58), size: 28),
            SizedBox(width: 10),
            Text('Account Reactivated!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name is now active.'),
            const SizedBox(height: 10),
            Text(
              'Send a reactivation email to $email:',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
            icon: const Icon(Icons.email_rounded, size: 18),
            label: const Text('Send Email'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (sendNow == true) {
      await _sendReactivationEmail(user);
    }
  }

  Future<void> _sendApprovalEmail(Map<String, dynamic> user) async {
    final name = user['full_name']?.toString() ?? 'User';
    final email = user['email']?.toString() ?? '';
    final mobile = user['mobile_number']?.toString() ?? '';

    if (email.isEmpty) return;

    final subject = 'Your G.R. BOOK Account is Approved!';
    final body = '''Hello $name,

Good news! Your G.R. BOOK account has been approved by Admin Mudasir Ahmed.

You can now open the app and log in using your Google account or your password.

Account Details:
• Name: $name
• Email: $email${mobile.isNotEmpty ? '\n• Phone: $mobile' : ''}
• Status: Active

If you need any help, please contact Mudasir Ahmed at 0336-8456907.

Thank you,
G.R. BOOK Team''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final fallback = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }
  }

  Future<void> _sendReactivationEmail(Map<String, dynamic> user) async {
    final name = user['full_name']?.toString() ?? 'User';
    final email = user['email']?.toString() ?? '';
    final mobile = user['mobile_number']?.toString() ?? '';

    if (email.isEmpty) return;

    final subject = 'Your G.R. BOOK Account is Reactivated!';
    final body = '''Hello $name,

Good news! Your G.R. BOOK account has been reactivated by Admin Mudasir Ahmed.

You can now open the app and log in to manage your school records.

Account Details:
• Name: $name
• Email: $email${mobile.isNotEmpty ? '\n• Phone: $mobile' : ''}
• Status: Active

If you have any questions, please contact Mudasir Ahmed at 0336-8456907.

Thank you,
G.R. BOOK Team''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final fallback = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    final currentStatus = user['status']?.toString() ?? 'pending';
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    final actionText = newStatus == 'active' ? 'activate' : 'block';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == 'active' ? 'Activate User' : 'Block User'),
        content: Text(
          'Are you sure you want to $actionText "$name"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: newStatus == 'active' ? const Color(0xFF0F9D58) : Colors.red.shade600,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(newStatus == 'active' ? 'Activate' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).setUserStatus(userId, newStatus);
      if (mounted) {
        _loadData();
        _showStatusResultDialog(
          isSuccess: newStatus == 'active',
          title: newStatus == 'active' ? 'Account Activated' : 'Account Blocked',
          message: newStatus == 'active'
              ? '$name is now active and has access to school records.'
              : '$name has been blocked from accessing school records.',
          user: user,
          actionType: 'toggle',
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusResultDialog(
          isSuccess: false,
          title: 'Operation Failed',
          message: 'Error: $e',
        );
      }
    }
  }

  Future<void> _notifyUserOnWhatsApp(Map<String, dynamic> user, {String messageType = 'general'}) async {
    final mobile = user['mobile_number']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This user has no phone number.')),
      );
      return;
    }

    final digits = AuthService.normalizePhone(mobile);
    final formattedNumber = digits.startsWith('0') ? '92${digits.substring(1)}' : digits;

    String message;
    if (messageType == 'approval') {
      message = 'Hello $name, your G.R. BOOK account has been approved by Admin Mudasir Ahmed. You can now log in and manage your school records.';
    } else if (messageType == 'reject') {
      message = 'Hello $name, your registration request for G.R. BOOK was not approved. If you have paid the fee or need help, please contact Mudasir Ahmed.';
    } else if (messageType == 'reactivate') {
      message = 'Hello $name, your G.R. BOOK account has been reactivated by Admin Mudasir Ahmed! You can now log in and use the app.';
    } else {
      message = 'Hello $name, this is Admin Mudasir Ahmed contacting you regarding your G.R. BOOK account.';
    }

    final uri = Uri.parse('https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _callUser(String phone) async {
    final digits = AuthService.normalizePhone(phone);
    final uri = Uri.parse('tel:+$digits');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);
    final cardBg = GrBookTheme.getCardBackground(context);
    final borderColor = GrBookTheme.getBorderColor(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);

    final filteredAll = _allUsers.where((u) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = (u['full_name']?.toString() ?? '').toLowerCase();
      final email = (u['email']?.toString() ?? '').toLowerCase();
      final phone = (u['mobile_number']?.toString() ?? '').toLowerCase();
      final school = (u['school_name']?.toString() ?? '').toLowerCase();
      return name.contains(query) || email.contains(query) || phone.contains(query) || school.contains(query);
    }).toList()
      ..sort((a, b) {
        final aIsSuper = _isUserSuperAdmin(a);
        final bIsSuper = _isUserSuperAdmin(b);
        if (aIsSuper && !bIsSuper) return -1;
        if (!aIsSuper && bIsSuper) return 1;
        return 0;
      });

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      appBar: AppBar(
        title: const Text('Master Admin Portal'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GrBookTheme.primary,
          labelColor: GrBookTheme.primary,
          unselectedLabelColor: textSecondary,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingUsers.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Active'),
                  if (_activeUsers.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F9D58),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Rejected'),
                  if (_rejectedUsers.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_rejectedUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('All Accounts'),
                  const SizedBox(width: 4),
                  Text(
                    '(${_allUsers.length})',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: GrBookTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: PENDING APPROVALS
                RefreshIndicator(
                  color: GrBookTheme.primary,
                  onRefresh: _loadData,
                  child: _pendingUsers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_rounded, size: 64, color: GrBookTheme.primary.withValues(alpha: 0.4)),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No Pending Approvals',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'All accounts are approved. No new requests pending.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pendingUsers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final user = _pendingUsers[i];
                            return _buildPendingCard(user, cardBg, borderColor, textPrimary, textSecondary);
                          },
                        ),
                ),

                // TAB 2: ACTIVE ACCOUNTS
                RefreshIndicator(
                  color: GrBookTheme.primary,
                  onRefresh: _loadData,
                  child: _activeUsers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 64, color: GrBookTheme.primary.withValues(alpha: 0.4)),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No Active Accounts',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Approved accounts will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activeUsers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final user = _activeUsers[i];
                            return _buildActiveCard(user, cardBg, borderColor, textPrimary, textSecondary);
                          },
                        ),
                ),

                // TAB 3: REJECTED REQUESTS
                RefreshIndicator(
                  color: GrBookTheme.primary,
                  onRefresh: _loadData,
                  child: _rejectedUsers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.thumb_up_alt_outlined, size: 64, color: GrBookTheme.primary.withValues(alpha: 0.4)),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No Rejected Requests',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No registration requests are currently rejected.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rejectedUsers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final user = _rejectedUsers[i];
                            return _buildRejectedCard(user, cardBg, borderColor, textPrimary, textSecondary);
                          },
                        ),
                ),

                // TAB 3: ALL ACCOUNTS WITH SUSPEND / ACTIVATE SWITCH
                Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search by name, phone, email, school...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      ),
                    ),

                    // User List
                    Expanded(
                      child: RefreshIndicator(
                        color: GrBookTheme.primary,
                        onRefresh: _loadData,
                        child: filteredAll.isEmpty
                            ? Center(
                                child: Text('No accounts found.', style: TextStyle(color: textSecondary)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredAll.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (ctx, i) {
                                  final user = filteredAll[i];
                                  return _buildAllUserCard(user, cardBg, borderColor, textPrimary, textSecondary);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPendingCard(
    Map<String, dynamic> user,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final name = user['full_name']?.toString() ?? 'Unnamed';
    final mobile = user['mobile_number']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final school = user['school_name']?.toString() ?? '';
    final createdAtRaw = user['created_at']?.toString() ?? '';
    String formattedDate = '';
    if (createdAtRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAtRaw);
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: GrBookTheme.primary.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: GrBookTheme.primary, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                    ),
                    if (school.isNotEmpty)
                      Text(
                        school,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pending',
                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),

          // Contact Rows
          if (mobile.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: GrBookTheme.primary),
                const SizedBox(width: 8),
                Text(mobile, style: TextStyle(color: textPrimary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (email.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: GrBookTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (formattedDate.isNotEmpty)
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Registered: $formattedDate',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          // Quick Contact Bar (WhatsApp, Call, Email)
          if (mobile.isNotEmpty || email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GrBookTheme.isDark(context)
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Text(
                    'Contact:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (mobile.isNotEmpty) ...[
                    _buildActionButton(
                      icon: const WhatsAppLogo(size: 18),
                      backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                      tooltip: 'WhatsApp',
                      onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'general'),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: const Icon(Icons.phone_rounded, size: 16, color: GrBookTheme.primary),
                      backgroundColor: GrBookTheme.primary.withValues(alpha: 0.12),
                      tooltip: 'Call Phone',
                      onPressed: () => _callUser(mobile),
                    ),
                  ],
                  if (email.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icon(Icons.email_outlined, size: 16, color: Colors.blue.shade700),
                      backgroundColor: Colors.blue.withValues(alpha: 0.12),
                      tooltip: 'Send Email',
                      onPressed: () => _sendApprovalEmail(user),
                    ),
                  ],
                  const Spacer(),
                  if (!_isUserSuperAdmin(user)) ...[
                    _buildActionButton(
                      icon: Icon(Icons.key_rounded, size: 16, color: Colors.amber.shade900),
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      tooltip: 'Reset Password',
                      onPressed: () => _showAdminResetPasswordDialog(user),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade700),
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      tooltip: 'Delete Account',
                      onPressed: () => _deleteUser(user),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Primary Decision Buttons: Approve & Reject
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D58),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text(
                    'Approve',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () => _approveUser(user),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade400, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red.shade700),
                  ),
                  onPressed: () => _rejectUser(user),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(
    Map<String, dynamic> user,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final name = user['full_name']?.toString() ?? 'Unnamed';
    final mobile = user['mobile_number']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final school = user['school_name']?.toString() ?? '';
    final isSuper = _isUserSuperAdmin(user);
    final approvedAtRaw = user['approved_at']?.toString() ?? user['created_at']?.toString() ?? '';
    String formattedDate = '';
    if (approvedAtRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(approvedAtRaw);
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuper ? Colors.amber.shade400 : const Color(0xFF0F9D58).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isSuper
                    ? Colors.amber.shade600
                    : const Color(0xFF0F9D58).withValues(alpha: 0.15),
                foregroundColor: isSuper ? Colors.white : const Color(0xFF0F9D58),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSuper) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (school.isNotEmpty)
                      Text(
                        school,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F9D58).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),

          // Contact details
          if (mobile.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: GrBookTheme.primary),
                const SizedBox(width: 8),
                Text(mobile, style: TextStyle(color: textPrimary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (email.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: GrBookTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (formattedDate.isNotEmpty)
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Active since: $formattedDate',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),

          // Quick Contact Bar (WhatsApp, Call, Email, Delete)
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GrBookTheme.isDark(context)
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Text(
                  'Contact:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                if (mobile.isNotEmpty) ...[
                  _buildActionButton(
                    icon: const WhatsAppLogo(size: 18),
                    backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                    tooltip: 'WhatsApp',
                    onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'general'),
                  ),
                  const SizedBox(width: 6),
                  _buildActionButton(
                    icon: const Icon(Icons.phone_rounded, size: 16, color: GrBookTheme.primary),
                    backgroundColor: GrBookTheme.primary.withValues(alpha: 0.12),
                    tooltip: 'Call Phone',
                    onPressed: () => _callUser(mobile),
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildActionButton(
                    icon: Icon(Icons.email_outlined, size: 16, color: Colors.blue.shade700),
                    backgroundColor: Colors.blue.withValues(alpha: 0.12),
                    tooltip: 'Send Email',
                    onPressed: () => _sendApprovalEmail(user),
                  ),
                ],
                const Spacer(),
                if (!isSuper) ...[
                  _buildActionButton(
                    icon: Icon(Icons.key_rounded, size: 16, color: Colors.amber.shade900),
                    backgroundColor: Colors.amber.withValues(alpha: 0.15),
                    tooltip: 'Reset Password',
                    onPressed: () => _showAdminResetPasswordDialog(user),
                  ),
                  const SizedBox(width: 6),
                  _buildActionButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade700),
                    backgroundColor: Colors.red.withValues(alpha: 0.12),
                    tooltip: 'Delete Account',
                    onPressed: () => _deleteUser(user),
                  ),
                ],
              ],
            ),
          ),

          if (!isSuper) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.block_rounded, size: 20),
                label: const Text(
                  'Suspend Access',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () => _toggleUserStatus(user),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectedCard(
    Map<String, dynamic> user,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final name = user['full_name']?.toString() ?? 'Unnamed';
    final mobile = user['mobile_number']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final school = user['school_name']?.toString() ?? '';
    final createdAtRaw = user['created_at']?.toString() ?? '';
    String formattedDate = '';
    if (createdAtRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAtRaw);
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.red.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                    ),
                    if (school.isNotEmpty)
                      Text(
                        school,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rejected',
                  style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),

          // Contact Rows
          if (mobile.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: GrBookTheme.primary),
                const SizedBox(width: 8),
                Text(mobile, style: TextStyle(color: textPrimary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (email.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: GrBookTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (formattedDate.isNotEmpty)
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Registered: $formattedDate',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          // Quick Contact Bar (WhatsApp, Call, Email)
          if (mobile.isNotEmpty || email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GrBookTheme.isDark(context)
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Text(
                    'Contact:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (mobile.isNotEmpty) ...[
                    _buildActionButton(
                      icon: const WhatsAppLogo(size: 18),
                      backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                      tooltip: 'WhatsApp',
                      onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'reactivate'),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: const Icon(Icons.phone_rounded, size: 16, color: GrBookTheme.primary),
                      backgroundColor: GrBookTheme.primary.withValues(alpha: 0.12),
                      tooltip: 'Call Phone',
                      onPressed: () => _callUser(mobile),
                    ),
                  ],
                  if (email.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icon(Icons.email_outlined, size: 16, color: Colors.blue.shade700),
                      backgroundColor: Colors.blue.withValues(alpha: 0.12),
                      tooltip: 'Send Email',
                      onPressed: () => _promptReactivationEmail(user),
                    ),
                  ],
                  const Spacer(),
                  if (!_isUserSuperAdmin(user)) ...[
                    _buildActionButton(
                      icon: Icon(Icons.key_rounded, size: 16, color: Colors.amber.shade900),
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      tooltip: 'Reset Password',
                      onPressed: () => _showAdminResetPasswordDialog(user),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade700),
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      tooltip: 'Delete Account',
                      onPressed: () => _deleteUser(user),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Primary Decision Button: Reactivate Account
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.replay_rounded, size: 20),
              label: const Text(
                'Reactivate Account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () => _reactivateUser(user),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllUserCard(
    Map<String, dynamic> user,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final name = user['full_name']?.toString() ?? 'Unnamed';
    final mobile = user['mobile_number']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final school = user['school_name']?.toString() ?? '';
    final status = user['status']?.toString() ?? 'pending';
    final isSuper = _isUserSuperAdmin(user);
    final isActive = status == 'active';
    final isSuspended = status == 'suspended';
    final isRejected = status == 'rejected';
    final isDeleted = status == 'deleted';
    final isPending = status == 'pending';

    Color badgeColor;
    String badgeText;
    if (isActive) {
      badgeColor = const Color(0xFF0F9D58);
      badgeText = 'Active';
    } else if (isDeleted) {
      badgeColor = Colors.grey.shade700;
      badgeText = 'Deleted';
    } else if (isSuspended) {
      badgeColor = Colors.red;
      badgeText = 'Suspended';
    } else if (isRejected) {
      badgeColor = Colors.deepOrange;
      badgeText = 'Rejected';
    } else {
      badgeColor = Colors.amber.shade800;
      badgeText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isSuper
                    ? Colors.amber.shade600
                    : (isActive ? GrBookTheme.primary : (isRejected ? Colors.deepOrange : Colors.grey.shade600)),
                foregroundColor: Colors.white,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSuper) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      school.isNotEmpty ? school : (email.isNotEmpty ? email : mobile),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 8),

          // Control Switch and Actions
          if (!isSuper && isPending) ...[
            Row(
              children: [
                if (mobile.isNotEmpty) ...[
                  _buildActionButton(
                    icon: const WhatsAppLogo(size: 18),
                    backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                    tooltip: 'WhatsApp',
                    onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'general'),
                  ),
                  const SizedBox(width: 6),
                ],
                if (email.isNotEmpty) ...[
                  _buildActionButton(
                    icon: Icon(Icons.email_outlined, size: 16, color: Colors.blue.shade700),
                    backgroundColor: Colors.blue.withValues(alpha: 0.12),
                    tooltip: 'Email User',
                    onPressed: () => _sendApprovalEmail(user),
                  ),
                  const SizedBox(width: 6),
                ],
                const Spacer(),
                _buildActionButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade700),
                  backgroundColor: Colors.red.withValues(alpha: 0.12),
                  tooltip: 'Delete Account',
                  onPressed: () => _deleteUser(user),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D58),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Approve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () => _approveUser(user),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Reject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () => _rejectUser(user),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                if (!isSuper) ...[
                  if (mobile.isNotEmpty) ...[
                    _buildActionButton(
                      icon: const WhatsAppLogo(size: 18),
                      backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                      tooltip: 'WhatsApp',
                      onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'general'),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (email.isNotEmpty) ...[
                    _buildActionButton(
                      icon: Icon(Icons.email_outlined, size: 16, color: Colors.blue.shade700),
                      backgroundColor: Colors.blue.withValues(alpha: 0.12),
                      tooltip: 'Email User',
                      onPressed: () => _sendApprovalEmail(user),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (!isDeleted) ...[
                    _buildActionButton(
                      icon: Icon(Icons.key_rounded, size: 16, color: Colors.amber.shade900),
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      tooltip: 'Reset Password',
                      onPressed: () => _showAdminResetPasswordDialog(user),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade700),
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      tooltip: 'Delete Account',
                      onPressed: () => _deleteUser(user),
                    ),
                  ],
                ],

                const Spacer(),

                if (!isSuper) ...[
                  if (isDeleted) ...[
                    Text(
                      'Deleted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _reactivateUser(user),
                    ),
                  ] else if (isSuspended || isRejected) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: const Text('Reactivate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _reactivateUser(user),
                    ),
                  ] else ...[
                    Text(
                      isActive ? 'Allowed' : 'Blocked',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF0F9D58) : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: isActive,
                        activeThumbColor: const Color(0xFF0F9D58),
                        activeTrackColor: const Color(0xFF0F9D58).withValues(alpha: 0.4),
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.withValues(alpha: 0.3),
                        onChanged: (_) => _toggleUserStatus(user),
                      ),
                    ),
                  ],
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      'Full Super Admin Access',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ],
    ),
  );
}

  Widget _buildActionButton({
    required Widget icon,
    required Color backgroundColor,
    required String tooltip,
    required VoidCallback onPressed,
    double size = 32,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
        ),
      ),
    );
  }
}

class _StatusSymbolPainter extends CustomPainter {
  final bool isSuccess;

  const _StatusSymbolPainter({required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circular solid colored background
    final circlePaint = Paint()
      ..color = isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw white checkmark or cross inside
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isSuccess) {
      final path = Path();
      path.moveTo(size.width * 0.28, size.height * 0.52);
      path.lineTo(size.width * 0.44, size.height * 0.68);
      path.lineTo(size.width * 0.72, size.height * 0.36);
      canvas.drawPath(path, strokePaint);
    } else {
      final d = size.width * 0.20;
      canvas.drawLine(
        Offset(center.dx - d, center.dy - d),
        Offset(center.dx + d, center.dy + d),
        strokePaint,
      );
      canvas.drawLine(
        Offset(center.dx + d, center.dy - d),
        Offset(center.dx - d, center.dy + d),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StatusSymbolPainter oldDelegate) =>
      oldDelegate.isSuccess != isSuccess;
}

/// Authentic, resolution-independent WhatsApp brand logo
class WhatsAppLogo extends StatelessWidget {
  final double size;

  const WhatsAppLogo({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: const _WhatsAppBubblePainter(),
          ),
          Transform.rotate(
            angle: -0.35,
            child: Icon(
              Icons.phone,
              color: Colors.white,
              size: size * 0.52,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppBubblePainter extends CustomPainter {
  const _WhatsAppBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.46;

    // Green speech bubble
    final greenPaint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bubblePath = Path();
    bubblePath.addOval(Rect.fromCircle(center: center, radius: radius));

    // Tail at bottom-left
    final tailPath = Path()
      ..moveTo(w * 0.22, h * 0.70)
      ..lineTo(w * 0.05, h * 0.95)
      ..lineTo(w * 0.42, h * 0.86)
      ..close();

    bubblePath.addPath(tailPath, Offset.zero);
    canvas.drawPath(bubblePath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

