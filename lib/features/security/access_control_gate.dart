import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/master_admin_config.dart';
import '../../core/theme.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/gr_book_ui_components.dart';
import '../auth/auth_providers.dart';
import '../auth/login_screen.dart';

/// Wraps the main application and enforces:
/// 1. Master Admin (Mudasir Ahmed) instant access.
/// 2. 3-Day offline security grace period (locks if app has been offline > 72 hours).
/// 3. Master Admin approval system (pending users cannot access school records until approved).
/// 4. Suspension check (suspended users are blocked from access).
class AccessControlGate extends ConsumerStatefulWidget {
  const AccessControlGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AccessControlGate> createState() => _AccessControlGateState();
}

class _AccessControlGateState extends ConsumerState<AccessControlGate> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isSuperAdmin = false;
  bool _isOfflineExpired = false;
  String _userStatus = 'pending';
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription? _profileRealtimeSub;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluateAccess();
    _connectivitySub = ref.read(connectivityServiceProvider).onStatusChange.listen((online) {
      if (online && mounted) {
        _silentlySyncStatus();
        _setupProfileRealtime();
      }
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _profileRealtimeSub?.cancel();
    _connectivitySub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluateAccess();
    }
  }

  void _setupLiveListeners() {
    _heartbeatTimer?.cancel();
    // Heartbeat every 15 seconds: if phone is online, silently syncs status with server!
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      final online = await ref.read(connectivityServiceProvider).isOnline();
      if (online) {
        _silentlySyncStatus();
      }
    });

    _setupProfileRealtime();
  }

  Future<void> _setupProfileRealtime() async {
    _profileRealtimeSub?.cancel();
    final auth = ref.read(authServiceProvider);
    if (await auth.isCurrentUserSuperAdmin()) return; // Founder does not need live blocking

    final targetId = await auth.getEffectiveUserId();
    if (targetId.isEmpty || targetId == 'local_admin') return;

    try {
      final client = ref.read(supabaseClientProvider);
      _profileRealtimeSub = client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', targetId)
          .listen((records) async {
            if (records.isNotEmpty && mounted) {
              final profile = records.first;
              final status = profile['status']?.toString() ?? 'pending';
              final role = profile['role']?.toString() ?? 'principal';

              // Persist locally immediately so even going offline keeps it locked
              final storage = ref.read(secureStorageProvider);
              await storage.write(key: 'grbook_user_status', value: status);
              await storage.write(key: 'grbook_user_role', value: role);
              await storage.write(key: 'grbook_last_online_verified', value: DateTime.now().toIso8601String());

              if (mounted) {
                setState(() {
                  _userStatus = status;
                });
              }
            }
          });
    } catch (_) {}
  }

  Future<void> _silentlySyncStatus() async {
    try {
      final auth = ref.read(authServiceProvider);
      final updatedStatus = await auth.refreshOnlineStatus();
      if (mounted) {
        final recheckExpired = await auth.isOfflineGracePeriodExpired();
        final isSuper = await auth.isCurrentUserSuperAdmin();
        if (_userStatus != updatedStatus || _isOfflineExpired != recheckExpired || _isSuperAdmin != isSuper) {
          setState(() {
            _userStatus = updatedStatus;
            _isOfflineExpired = recheckExpired;
            _isSuperAdmin = isSuper;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _evaluateAccess() async {
    final auth = ref.read(authServiceProvider);

    // 1. Master Admin is always granted full access
    if (await auth.isCurrentUserSuperAdmin()) {
      if (mounted) {
        setState(() {
          _isSuperAdmin = true;
          _userStatus = 'active';
          _isOfflineExpired = false;
          _isLoading = false;
        });
      }
      return;
    }

    // 2. Read local status first (cached in secure storage)
    final cachedStatus = await auth.getUserStatus();
    final offlineExpired = await auth.isOfflineGracePeriodExpired();
    final isOnline = await ref.read(connectivityServiceProvider).isOnline();

    // SMART 72-HOUR LOGIC:
    // If 72 hours passed BUT phone is online right now, don't show the warning screen!
    // Instead, silently refresh right now and reset the 3-day timer!
    if (offlineExpired && isOnline) {
      try {
        final updatedStatus = await auth.refreshOnlineStatus();
        final recheckExpired = await auth.isOfflineGracePeriodExpired();
        final isSuper = await auth.isCurrentUserSuperAdmin();
        if (mounted) {
          setState(() {
            _isSuperAdmin = isSuper;
            _userStatus = updatedStatus;
            _isOfflineExpired = recheckExpired;
            _isLoading = false;
          });
        }
        _setupLiveListeners();
        return;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isSuperAdmin = false;
        _userStatus = cachedStatus;
        _isOfflineExpired = offlineExpired;
        _isLoading = false;
      });
    }

    // 3. If online, sync live status from Supabase
    if (isOnline) {
      try {
        final updatedStatus = await auth.refreshOnlineStatus();
        if (mounted) {
          final recheckExpired = await auth.isOfflineGracePeriodExpired();
          final isSuper = await auth.isCurrentUserSuperAdmin();
          setState(() {
            _userStatus = updatedStatus;
            _isOfflineExpired = recheckExpired;
            _isSuperAdmin = isSuper;
          });
        }
      } catch (_) {}
    }

    _setupLiveListeners();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: GrBookTheme.primary),
        ),
      );
    }

    if (_isSuperAdmin) {
      return widget.child;
    }

    if (_isOfflineExpired) {
      return OfflineSecurityVerificationScreen(
        onVerified: _evaluateAccess,
      );
    }

    if (_userStatus == 'deleted') {
      return AccountDeletedScreen(
        onRefresh: _evaluateAccess,
      );
    }

    if (_userStatus == 'suspended') {
      return AccountSuspendedScreen(
        onRefresh: _evaluateAccess,
      );
    }

    if (_userStatus == 'rejected') {
      return AccountRejectedScreen(
        onRefresh: _evaluateAccess,
      );
    }

    if (_userStatus != 'active') {
      return AccountPendingApprovalScreen(
        onRefresh: _evaluateAccess,
      );
    }

    return widget.child;
  }
}

/// Screen shown when account is pending Master Admin approval
class AccountPendingApprovalScreen extends ConsumerStatefulWidget {
  const AccountPendingApprovalScreen({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  ConsumerState<AccountPendingApprovalScreen> createState() => _AccountPendingApprovalScreenState();
}

class _AccountPendingApprovalScreenState extends ConsumerState<AccountPendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _launchContact(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    setState(() => _isChecking = true);
    await widget.onRefresh();
    if (mounted) {
      setState(() => _isChecking = false);
      final status = await ref.read(authServiceProvider).getUserStatus();
      if (status != 'active') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is still under review. Please contact Admin.'),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    ref.read(appUnlockedProvider.notifier).state = false;
    ref.invalidate(isSuperAdminProvider);
    ref.invalidate(currentUserProvider);
    await ref.read(authServiceProvider).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);
    final cardBg = GrBookTheme.getCardBackground(context);
    final borderColor = GrBookTheme.getBorderColor(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Status Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 20),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text(
                    'APPROVAL PENDING',
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Account Under Review',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your account has been created! To protect school records, Admin Mudasir Ahmed will review and approve your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Master Admin Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F9D58).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'MA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MasterAdminConfig.founderName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Master Administrator & Founder',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  MasterAdminConfig.founderFormattedPhone,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: GrBookTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 14),

                      // Direct WhatsApp Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 20),
                          label: const Text(
                            'Contact on WhatsApp',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            final msg = Uri.encodeComponent(
                              'Hello Mudasir Bhai, I created my G.R. BOOK account. Please review and approve my account.',
                            );
                            _launchContact('https://wa.me/${MasterAdminConfig.founderPhone}?text=$msg');
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Phone Call Button
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text('Call Founder'),
                          onPressed: () => _launchContact('tel:+${MasterAdminConfig.founderPhone}'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Check Status Button
                GrBookGradientButton(
                  text: 'Check Approval Status',
                  isLoading: _isChecking,
                  onPressed: _handleRefresh,
                  icon: Icons.refresh_rounded,
                ),
                const SizedBox(height: 12),

                // Logout / Change Account
                TextButton(
                  onPressed: _logout,
                  child: Text(
                    'Logout / Log in with another account',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen shown when account has been suspended by Master Admin
class AccountSuspendedScreen extends ConsumerWidget {
  const AccountSuspendedScreen({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  Future<void> _launchContact(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = GrBookTheme.isDark(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ACCESS SUSPENDED',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Account Access Blocked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your account has been suspended by Admin Mudasir Ahmed. To restore your access, please contact Admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // WhatsApp Contact
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Contact Mudasir Ahmed on WhatsApp'),
                    onPressed: () {
                      final msg = Uri.encodeComponent(
                        'Hello Mudasir Bhai, my G.R. BOOK account is suspended. Please check my account.',
                      );
                      _launchContact('https://wa.me/${MasterAdminConfig.founderPhone}?text=$msg');
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Refresh Status
                GrBookOutlinedButton(
                  text: 'Check Status Again',
                  icon: Icons.refresh_rounded,
                  onPressed: onRefresh,
                ),
                const SizedBox(height: 12),

                // Logout
                TextButton(
                  onPressed: () async {
                    ref.read(appUnlockedProvider.notifier).state = false;
                    ref.invalidate(isSuperAdminProvider);
                    ref.invalidate(currentUserProvider);
                    await ref.read(authServiceProvider).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: Text('Logout', style: TextStyle(color: textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen shown when account registration request has been rejected by Master Admin
class AccountRejectedScreen extends ConsumerStatefulWidget {
  const AccountRejectedScreen({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  ConsumerState<AccountRejectedScreen> createState() => _AccountRejectedScreenState();
}

class _AccountRejectedScreenState extends ConsumerState<AccountRejectedScreen> {
  bool _isChecking = false;

  Future<void> _launchContact(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    setState(() => _isChecking = true);
    await widget.onRefresh();
    if (mounted) {
      setState(() => _isChecking = false);
      final status = await ref.read(authServiceProvider).getUserStatus();
      if (status != 'active') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is still not approved. Please contact Admin.'),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    ref.read(appUnlockedProvider.notifier).state = false;
    ref.invalidate(isSuperAdminProvider);
    ref.invalidate(currentUserProvider);
    await ref.read(authServiceProvider).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);
    final cardBg = GrBookTheme.getCardBackground(context);
    final borderColor = GrBookTheme.getBorderColor(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Text(
                    'REQUEST REJECTED',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Account Request Not Approved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your account request was not approved by Admin Mudasir Ahmed.\n\nIf you have already paid or want to activate your school account, please contact Admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Master Admin Contact Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F9D58).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'MA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MasterAdminConfig.founderName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Master Administrator & Founder',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  MasterAdminConfig.founderFormattedPhone,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: GrBookTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 14),

                      // Direct WhatsApp Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 20),
                          label: const Text(
                            'Contact on WhatsApp',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            final msg = Uri.encodeComponent(
                              'Hello Mudasir Bhai, my G.R. BOOK account request was rejected. I want to pay and activate my account. Please guide me.',
                            );
                            _launchContact('https://wa.me/${MasterAdminConfig.founderPhone}?text=$msg');
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Phone Call Button
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text('Call Founder'),
                          onPressed: () => _launchContact('tel:+${MasterAdminConfig.founderPhone}'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Check Again Button
                GrBookGradientButton(
                  text: 'Check Status Again',
                  isLoading: _isChecking,
                  onPressed: _handleRefresh,
                  icon: Icons.refresh_rounded,
                ),
                const SizedBox(height: 12),

                // Logout
                TextButton(
                  onPressed: _logout,
                  child: Text(
                    'Logout / Log in with another account',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen shown when user has been offline for more than 3 days (72 hours)
class OfflineSecurityVerificationScreen extends ConsumerStatefulWidget {
  const OfflineSecurityVerificationScreen({super.key, required this.onVerified});

  final Future<void> Function() onVerified;

  @override
  ConsumerState<OfflineSecurityVerificationScreen> createState() =>
      _OfflineSecurityVerificationScreenState();
}

class _OfflineSecurityVerificationScreenState
    extends ConsumerState<OfflineSecurityVerificationScreen> {
  bool _isVerifying = false;

  Future<void> _handleVerify() async {
    setState(() => _isVerifying = true);
    try {
      final updatedStatus = await ref.read(authServiceProvider).refreshOnlineStatus();
      final stillExpired = await ref.read(authServiceProvider).isOfflineGracePeriodExpired();

      await widget.onVerified();
      if (mounted) {
        if (!stillExpired && updatedStatus == 'active') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF0F9D58),
              content: Text('Online security check passed! App is unlocked.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status: $updatedStatus. Please connect to internet or contact Admin.'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please connect to the internet and try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: GrBookTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: GrBookTheme.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.wifi_protected_setup_rounded,
                    size: 48,
                    color: GrBookTheme.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: GrBookTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: GrBookTheme.primary),
                  ),
                  child: const Text(
                    '3-DAY OFFLINE LIMIT REACHED',
                    style: TextStyle(
                      color: GrBookTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Security Check Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'To protect student records, please connect to the internet for 1 minute once every 3 days.\n\nPlease turn on Wi-Fi or Mobile Data and tap the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Verify Button
                GrBookGradientButton(
                  text: 'Connect & Verify Now',
                  isLoading: _isVerifying,
                  onPressed: _handleVerify,
                  icon: Icons.wifi_rounded,
                ),
                const SizedBox(height: 12),

                // WhatsApp Help
                GrBookOutlinedButton(
                  text: 'Contact Founder Mudasir Ahmed',
                  icon: Icons.chat_rounded,
                  onPressed: () async {
                    final msg = Uri.encodeComponent(
                      'Hello Mudasir Bhai, my G.R. BOOK app needs 3-day verification.',
                    );
                    final uri = Uri.parse('https://wa.me/${MasterAdminConfig.founderPhone}?text=$msg');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Logout
                TextButton(
                  onPressed: () async {
                    ref.read(appUnlockedProvider.notifier).state = false;
                    ref.invalidate(isSuperAdminProvider);
                    ref.invalidate(currentUserProvider);
                    await ref.read(authServiceProvider).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: Text('Logout', style: TextStyle(color: textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen shown when account has been deleted by Master Admin
class AccountDeletedScreen extends ConsumerStatefulWidget {
  const AccountDeletedScreen({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  ConsumerState<AccountDeletedScreen> createState() => _AccountDeletedScreenState();
}

class _AccountDeletedScreenState extends ConsumerState<AccountDeletedScreen> {
  bool _isChecking = false;

  Future<void> _launchContact(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    setState(() => _isChecking = true);
    await widget.onRefresh();
    if (mounted) {
      setState(() => _isChecking = false);
      final status = await ref.read(authServiceProvider).getUserStatus();
      if (status == 'deleted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is deleted. Please contact Admin if you need help.'),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    ref.read(appUnlockedProvider.notifier).state = false;
    ref.invalidate(isSuperAdminProvider);
    ref.invalidate(currentUserProvider);
    await ref.read(authServiceProvider).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = GrBookTheme.isDark(context);
    final cardBg = GrBookTheme.getCardBackground(context);
    final borderColor = GrBookTheme.getBorderColor(context);
    final textPrimary = GrBookTheme.getTextPrimary(context);
    final textSecondary = GrBookTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: isDark ? GrBookTheme.darkBackground : GrBookTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade700, width: 2),
                  ),
                  child: Icon(
                    Icons.person_off_rounded,
                    size: 48,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade700),
                  ),
                  child: const Text(
                    'ACCOUNT DELETED',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Account Is No More Active',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This account has been deleted by Administrator Mudasir Ahmed.\n\nYou cannot access school records with this account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Master Admin Contact Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F9D58).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'MA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MasterAdminConfig.founderName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Master Administrator & Founder',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  MasterAdminConfig.founderFormattedPhone,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: GrBookTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 14),

                      // Direct WhatsApp Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 20),
                          label: const Text(
                            'Contact Admin on WhatsApp',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            final msg = Uri.encodeComponent(
                              'Hello Mudasir Bhai, my G.R. BOOK account shows deleted. Please check my account.',
                            );
                            _launchContact('https://wa.me/${MasterAdminConfig.founderPhone}?text=$msg');
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Phone Call Button
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text('Call Admin'),
                          onPressed: () => _launchContact('tel:+${MasterAdminConfig.founderPhone}'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Check Status Again
                GrBookGradientButton(
                  text: 'Check Status Again',
                  icon: Icons.refresh_rounded,
                  isLoading: _isChecking,
                  onPressed: _handleRefresh,
                ),
                const SizedBox(height: 12),

                // Logout
                TextButton(
                  onPressed: _logout,
                  child: Text(
                    'Logout / Switch Account',
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
