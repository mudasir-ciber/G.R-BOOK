import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/master_admin_config.dart';
import '../../core/theme.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluateAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluateAccess();
    }
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

    // 2. Read local status first
    final cachedStatus = await auth.getUserStatus();
    final offlineExpired = await auth.isOfflineGracePeriodExpired();

    if (mounted) {
      setState(() {
        _isSuperAdmin = false;
        _userStatus = cachedStatus;
        _isOfflineExpired = offlineExpired;
        _isLoading = false;
      });
    }

    // 3. Try to refresh live status from Supabase
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

    if (_userStatus == 'suspended') {
      return AccountSuspendedScreen(
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
            content: Text('Aapka account abhi bhi review mein hai. Baraye mehrbani Admin se raabta karein.'),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    ref.read(appUnlockedProvider.notifier).state = false;
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
                  'Aapka account kamyabi se ban chuka hai! School record ki security aur verification ke liye Master Admin se approval darkaar hai.',
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
                            'WhatsApp Par Rabta Karein',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            final msg = Uri.encodeComponent(
                              'Assalam-o-Alaikum Mudasir Bhai, mene G.R. Book app par account banaya hai. Baraye mehrbani mera account approve farmayein.',
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
                  'Aapka account Master Admin ki janib se temporarily suspend (block) kar diya gaya hai. Access bahal karwane ke liye baraye mehrbani Master Admin Mudasir Ahmed se raabta karein.',
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
                        'Assalam-o-Alaikum Mudasir Bhai, mera account suspend show ho raha hai. Baraye mehrbani review farmayein.',
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
              content: Text('Online security verification kamyab! App unlock ho chuki hai.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status: $updatedStatus. Baraye mehrbani internet connect karein ya Admin se raabta karein.'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internet se connect karein aur dubara koshish karein.'),
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
                  'School record ki hifazat aur access verification ke liye har 3 din mein kam az kam 1 baar internet se connect hona lazmi hai.\n\nBaraye mehrbani apna Mobile Data ya Wi-Fi on karein aur niche button tap karein.',
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
                      'Assalam-o-Alaikum Mudasir Bhai, mera 3-day offline verification required hai.',
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
