import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../classes/classes_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

/// Main navigation container holding exactly 3 tabs:
/// 1. HOME
/// 2. CLASSES
/// 3. MY ACCOUNT
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = ref.watch(appUnlockedProvider);

    return PopScope(
      canPop: _currentIndex == 0 || !isUnlocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0 && isUnlocked) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              onNavigateToClasses: () => setState(() => _currentIndex = 1),
              onNavigateToAccount: () => setState(() => _currentIndex = 2),
            ),
            const ClassesScreen(),
            const SettingsScreen(showBack: false),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isDark = GrBookTheme.isDark(context);
    final navBg = isDark ? const Color(0xFF142019) : Colors.white;
    final borderTop = isDark ? const BorderSide(color: Color(0xFF24382B), width: 1) : BorderSide.none;

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: borderTop),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'HOME',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.school_rounded,
                label: 'CLASSES',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_rounded,
                label: 'MY ACCOUNT',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isDark = GrBookTheme.isDark(context);
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF0F9D58);
    final inactiveColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final selectedBg = isDark ? const Color(0xFF22382B) : const Color(0xFFE8F5E9);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onTabSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                    letterSpacing: 0.3,
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
