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
  List<Map<String, dynamic>> _rejectedUsers = [];
  List<Map<String, dynamic>> _allUsers = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final rejected = await auth.fetchRejectedUsers();
      final all = await auth.fetchAllUsers();
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
          _rejectedUsers = rejected;
          _allUsers = all;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    final mobile = user['mobile_number']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final auth = ref.read(authServiceProvider);

    try {
      await auth.approveUser(userId);
      if (mounted) {
        _loadData();
        if (email.isNotEmpty) {
          _promptApprovalEmail(user);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0F9D58),
              content: Text('$name has been approved!'),
              action: mobile.isNotEmpty
                  ? SnackBarAction(
                      label: 'WhatsApp Notify',
                      textColor: Colors.white,
                      onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'approval'),
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    final mobile = user['mobile_number']?.toString() ?? '';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('$name\'s request has been rejected.'),
            action: mobile.isNotEmpty
                ? SnackBarAction(
                    label: 'WhatsApp',
                    textColor: Colors.white,
                    onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'reject'),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reactivateUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    final mobile = user['mobile_number']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

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
        if (email.isNotEmpty) {
          _promptReactivationEmail(user);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0F9D58),
              content: Text('$name has been reactivated!'),
              action: mobile.isNotEmpty
                  ? SnackBarAction(
                      label: 'WhatsApp Notify',
                      textColor: Colors.white,
                      onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'reactivate'),
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _promptApprovalEmail(Map<String, dynamic> user) async {
    final name = user['full_name']?.toString() ?? 'User';
    final email = user['email']?.toString() ?? '';

    final sendNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF0F9D58), size: 28),
            SizedBox(width: 10),
            Text('Account Approved!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name is now active.'),
            const SizedBox(height: 10),
            Text(
              'Send a welcome email to $email:',
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
      await _sendApprovalEmail(user);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newStatus == 'active' ? const Color(0xFF0F9D58) : Colors.orange.shade800,
            content: Text('$name is now ${newStatus == "active" ? "active" : "blocked"}.'),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
          tabs: [
            Tab(
              child: Row(
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

                // TAB 2: REJECTED REQUESTS
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    'Quick Contact:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (mobile.isNotEmpty) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF1E7E34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      tooltip: 'WhatsApp',
                      onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'general'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: GrBookTheme.primary.withValues(alpha: 0.12),
                        foregroundColor: GrBookTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      tooltip: 'Call Phone',
                      onPressed: () => _callUser(mobile),
                    ),
                  ],
                  if (email.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.12),
                        foregroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.email_outlined, size: 18),
                      tooltip: 'Send Email',
                      onPressed: () => _sendApprovalEmail(user),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    'Quick Contact:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (mobile.isNotEmpty) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF1E7E34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      tooltip: 'WhatsApp',
                      onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'reactivate'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: GrBookTheme.primary.withValues(alpha: 0.12),
                        foregroundColor: GrBookTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      tooltip: 'Call Phone',
                      onPressed: () => _callUser(mobile),
                    ),
                  ],
                  if (email.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.12),
                        foregroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.email_outlined, size: 18),
                      tooltip: 'Send Email',
                      onPressed: () => _promptReactivationEmail(user),
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
    final isPending = status == 'pending';

    Color badgeColor;
    String badgeText;
    if (isActive) {
      badgeColor = const Color(0xFF0F9D58);
      badgeText = 'Active';
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
                if (mobile.isNotEmpty)
                  Text(mobile, style: TextStyle(fontSize: 12, color: textSecondary)),
                const Spacer(),
                if (mobile.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                    tooltip: 'WhatsApp',
                    onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'general'),
                  ),
                if (email.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.email_outlined, color: Colors.blue.shade600, size: 18),
                    tooltip: 'Email User',
                    onPressed: () => _sendApprovalEmail(user),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (mobile.isNotEmpty)
                  Text(
                    mobile,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  )
                else if (email.isNotEmpty)
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),

                if (!isSuper) ...[
                  Row(
                    children: [
                      if (mobile.isNotEmpty) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                          tooltip: 'WhatsApp',
                          onPressed: () => _notifyUserOnWhatsApp(user, messageType: 'general'),
                        ),
                      ],
                      if (email.isNotEmpty) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.email_outlined, color: Colors.blue.shade600, size: 18),
                          tooltip: 'Email User',
                          onPressed: () => _sendApprovalEmail(user),
                        ),
                      ],
                      if (isSuspended || isRejected) ...[
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
                      Switch(
                        value: isActive,
                        activeThumbColor: const Color(0xFF0F9D58),
                        activeTrackColor: const Color(0xFF0F9D58).withValues(alpha: 0.4),
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.withValues(alpha: 0.3),
                        onChanged: (_) => _toggleUserStatus(user),
                      ),
                    ],
                  ],
                ),
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
}
