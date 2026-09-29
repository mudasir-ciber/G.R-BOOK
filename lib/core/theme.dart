import 'package:flutter/material.dart';

/// Exact theme matching the 10 UI reference images:
/// Emerald/mint green palette, pill buttons, soft bordered cards, and mint background gradient.
class GrBookTheme {
  GrBookTheme._();

  static const Color primary = Color(0xFF0F7A42); // Vibrant deep emerald green from images
  static const Color primaryDark = Color(0xFF095A2F);
  static const Color primaryLight = Color(0xFFE7F7ED); // Light green background tint for icons
  static const Color background = Color(0xFFF3FAF5); // Mint white background
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF162E20);
  static const Color textSecondary = Color(0xFF6B7E73);
  static const Color borderColor = Color(0xFFD6EFE0);

  static const LinearGradient mintBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFDCF4E6),
      Color(0xFFEEF9F2),
      Color(0xFFFAFCFA),
    ],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0F8A4B),
      Color(0xFF065C32),
    ],
  );

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: cardBackground,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
