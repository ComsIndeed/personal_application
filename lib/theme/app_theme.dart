import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color accent = Color(0xFF10B981); // Emerald

  // Midnight Palette (Solid, no opacity)
  static const Color nightfallBg = Color(0xFF000000);
  static const Color nightfallSurface = Color(0xFF000000);
  static const Color nightfallCard = Color(0xFF09090B);
  static const Color nightfallBorder = Color(0xFF18181B);
  static const Color nightfallTextPrimary = Color(0xFFFAFAFA);
  static const Color nightfallTextSecondary = Color(0xFFA1A1AA);

  // Light Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        surface: nightfallSurface,
        onSurface: nightfallTextPrimary,
        surfaceContainerHighest: nightfallCard,
      ),
      scaffoldBackgroundColor: nightfallBg,
      cardColor: nightfallCard,
      dividerColor: nightfallBorder,
      iconTheme: const IconThemeData(color: nightfallTextSecondary),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: nightfallTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: nightfallTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: nightfallTextPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: nightfallTextSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: nightfallTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: nightfallSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: nightfallBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: nightfallBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: lightSurface,
        onSurface: Color(0xFF334155),
      ),
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      dividerColor: Colors.black12,
      iconTheme: const IconThemeData(color: Color(0xFF64748B)),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
    );
  }
}

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
