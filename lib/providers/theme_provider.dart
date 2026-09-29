import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  static const _storageKey = 'gr_book_theme_mode';
  final _storage = const FlutterSecureStorage();

  Future<void> _loadTheme() async {
    try {
      final val = await _storage.read(key: _storageKey);
      if (val == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.light;
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await _storage.write(key: _storageKey, value: 'light');
    } else {
      state = ThemeMode.dark;
      await _storage.write(key: _storageKey, value: 'dark');
    }
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
