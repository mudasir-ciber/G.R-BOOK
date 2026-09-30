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
  List<Map<String, dynamic>> _allUsers = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = ref.read(authServiceProvider);

    try {
      final pending = await auth.fetchPendingUsers();
      final all = await auth.fetchAllUsers();

      if (mounted) {
        setState(() {
          _pendingUsers = pending;
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
    final auth = ref.read(authServiceProvider);

    try {
      await auth.approveUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F9D58),
            content: Text('$name ka account kamyabi se approve ho chuka hai!'),
            action: mobile.isNotEmpty
                ? SnackBarAction(
                    label: 'WhatsApp Notify',
                    textColor: Colors.white,
                    onPressed: () => _notifyUserOnWhatsApp(user, isApproval: true),
                  )
                : null,
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

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    final currentStatus = user['status']?.toString() ?? 'pending';
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    final actionText = newStatus == 'active' ? 'bahal (Activate)' : 'band (Suspend)';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == 'active' ? 'Activate Account' : 'Suspend Account'),
        content: Text(
          'Kya aap waqai "$name" ka account $actionText karna chahte hain?',
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
            child: Text(newStatus == 'active' ? 'Activate' : 'Suspend'),
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
            content: Text('$name ka account $newStatus ho chuka hai.'),
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

  Future<void> _notifyUserOnWhatsApp(Map<String, dynamic> user, {required bool isApproval}) async {
    final mobile = user['mobile_number']?.toString() ?? '';
    final name = user['full_name']?.toString() ?? 'User';
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Is user ka koi phone number mojood nahi hai.')),
      );
      return;
    }

    final digits = AuthService.normalizePhone(mobile);
    final formattedNumber = digits.startsWith('0') ? '92${digits.substring(1)}' : digits;

    final message = isApproval
        ? 'Assalam-o-Alaikum $name, Aapka G.R. Book application account Master Admin Mudasir Ahmed ki janib se approve kar diya gaya hai. Ab aap app mein mukammal login karke classes aur school record manage kar sakte hain.'
        : 'Assalam-o-Alaikum $name, G.R. Book application ke hawale se Master Admin Mudasir Ahmed ki janib se raabta kiya gaya hai.';

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
    }).toList();

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
                  const Text('Pending Approvals'),
                  if (_pendingUsers.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                  const Text('All Accounts'),
                  const SizedBox(width: 6),
                  Text(
                    '(${_allUsers.length})',
                    style: TextStyle(fontSize: 12, color: textSecondary),
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
                                    'Tamam accounts approved hain ya koi naya signup pending nahi hai.',
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

                // TAB 2: ALL ACCOUNTS WITH SUSPEND / ACTIVATE SWITCH
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
          const SizedBox(height: 14),

          // Action Buttons: Approve & WhatsApp
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D58),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Approve (Manzoor)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _approveUser(user),
                ),
              ),
              if (mobile.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  tooltip: 'WhatsApp User',
                  onPressed: () => _notifyUserOnWhatsApp(user, isApproval: false),
                ),
                const SizedBox(width: 4),
                IconButton.outlined(
                  style: IconButton.styleFrom(
                    foregroundColor: textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  tooltip: 'Call User',
                  onPressed: () => _callUser(mobile),
                ),
              ],
            ],
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
    final role = user['role']?.toString() ?? 'principal';
    final isSuper = role == 'super_admin' || MasterAdminConfig.isFounderIdentifier(mobile) || MasterAdminConfig.isFounderIdentifier(email);
    final isActive = status == 'active';

    Color badgeColor;
    String badgeText;
    if (isActive) {
      badgeColor = const Color(0xFF0F9D58);
      badgeText = 'Active';
    } else if (status == 'suspended') {
      badgeColor = Colors.red;
      badgeText = 'Suspended';
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
                    : (isActive ? GrBookTheme.primary : Colors.grey.shade600),
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
                        icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                        tooltip: 'WhatsApp',
                        onPressed: () => _notifyUserOnWhatsApp(user, isApproval: false),
                      ),
                    ],
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
      ),
    );
  }
}
