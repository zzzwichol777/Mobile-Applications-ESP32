import 'package:flutter/material.dart';

enum AppThemeMode {
  medical,
  ocean,
  lavender,
  mint,
}

class AppTheme {
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.medical:
        return _medicalTheme();
      case AppThemeMode.ocean:
        return _oceanTheme();
      case AppThemeMode.lavender:
        return _lavenderTheme();
      case AppThemeMode.mint:
        return _mintTheme();
    }
  }

  static ThemeData _medicalTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3b82f6),
        primary: const Color(0xFF3b82f6),
        secondary: const Color(0xFF60a5fa),
        surface: const Color(0xFFf0f4f8),
        background: const Color(0xFFffffff),
      ),
      scaffoldBackgroundColor: const Color(0xFFf0f4f8),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF3b82f6),
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData _oceanTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0891b2),
        primary: const Color(0xFF0891b2),
        secondary: const Color(0xFF06b6d4),
        surface: const Color(0xFFecfeff),
        background: const Color(0xFFffffff),
      ),
      scaffoldBackgroundColor: const Color(0xFFecfeff),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF0891b2),
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData _lavenderTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8b5cf6),
        primary: const Color(0xFF8b5cf6),
        secondary: const Color(0xFFa78bfa),
        surface: const Color(0xFFf5f3ff),
        background: const Color(0xFFffffff),
      ),
      scaffoldBackgroundColor: const Color(0xFFf5f3ff),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF8b5cf6),
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData _mintTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF10b981),
        primary: const Color(0xFF10b981),
        secondary: const Color(0xFF34d399),
        surface: const Color(0xFFecfdf5),
        background: const Color(0xFFffffff),
      ),
      scaffoldBackgroundColor: const Color(0xFFecfdf5),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF10b981),
        foregroundColor: Colors.white,
      ),
    );
  }

  static String getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.medical:
        return 'Médico Azul';
      case AppThemeMode.ocean:
        return 'Océano';
      case AppThemeMode.lavender:
        return 'Lavanda';
      case AppThemeMode.mint:
        return 'Menta';
    }
  }

  static IconData getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.medical:
        return Icons.medical_services;
      case AppThemeMode.ocean:
        return Icons.water;
      case AppThemeMode.lavender:
        return Icons.spa;
      case AppThemeMode.mint:
        return Icons.eco;
    }
  }
}
