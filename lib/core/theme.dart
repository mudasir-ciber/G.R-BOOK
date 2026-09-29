import 'package:flutter/material.dart';

/// Exact theme matching the 10 UI reference images:
/// Emerald/mint green palette, pill buttons, soft bordered cards, and mint background gradient.
/// Also includes a dedicated Dark Theme with dark slate/emerald surfaces and crisp white fonts.
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

  // Dark palette
  static const Color darkBackground = Color(0xFF0F1713);
  static const Color darkCardBackground = Color(0xFF18261E);
  static const Color darkBorderColor = Color(0xFF24382B);
  static const Color darkTextSecondary = Color(0xFF9FB5A6);

  static const LinearGradient mintBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFDCF4E6),
      Color(0xFFEEF9F2),
      Color(0xFFFAFCFA),
    ],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D1711),
      Color(0xFF111D16),
      Color(0xFF14221A),
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

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static LinearGradient getBackgroundGradient(BuildContext context) =>
      isDark(context) ? darkBackgroundGradient : mintBackgroundGradient;

  static Color getCardBackground(BuildContext context) =>
      isDark(context) ? darkCardBackground : cardBackground;

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : textPrimary;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color getBorderColor(BuildContext context) =>
      isDark(context) ? darkBorderColor : borderColor;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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

  static ThemeData get darkThemeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF10B981),
        surface: darkCardBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF14221A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF6B7E73), fontSize: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorderColor, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
