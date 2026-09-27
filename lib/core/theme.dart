import 'package:flutter/material.dart';

/// Placeholder green/mint theme (requirement #36). Once the 10 UI
/// reference images are provided, exact colors/spacing/typography
/// should be sampled from them and substituted here — the rest of the
/// app reads colors only through GrBookTheme, so this is the single
/// place a pixel-accurate pass needs to touch.
class GrBookTheme {
  GrBookTheme._();

  static const Color primary = Color(0xFF2E9E6C); // mint-green
  static const Color primaryDark = Color(0xFF1F7A52);
  static const Color background = Color(0xFFF6FAF8);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A2E22);
  static const Color textSecondary = Color(0xFF6B7C74);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
