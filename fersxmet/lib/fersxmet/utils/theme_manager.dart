import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static final List<Function> _listeners = [];
  static Color _primaryColor = const Color(0xFF7B68EE); // Morado pastel por defecto
  static ThemeData? _currentTheme;

  // Paleta de colores predefinidos
  static final Map<String, Color> themeColors = {
    'Morado Pastel': const Color(0xFF7B68EE),
    'Azul Pastel': const Color(0xFF87CEEB),
    'Rosa Pastel': const Color(0xFFFFB6C1),
    'Verde Pastel': const Color(0xFF98D8C8),
    'Coral Pastel': const Color(0xFFFF9999),
    'Lavanda': const Color(0xFFE6E6FA),
    'Menta': const Color(0xFF98FF98),
    'Durazno': const Color(0xFFFFDAB9),
    'Turquesa': const Color(0xFF40E0D0),
    'Lila': const Color(0xFFC8A2C8),
  };

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('theme_color');
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    _buildTheme();
  }

  static void _buildTheme() {
    _currentTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _primaryColor.withOpacity(0.7),
        surface: const Color(0xFF16213E),
        background: const Color(0xFF1A1A2E),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: _primaryColor,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF16213E).withOpacity(0.8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white60,
        ),
      ),
      iconTheme: IconThemeData(
        color: _primaryColor,
        size: 24,
      ),
    );
  }

  static ThemeData get currentTheme {
    if (_currentTheme == null) {
      _buildTheme();
    }
    return _currentTheme!;
  }

  static Color get primaryColor => _primaryColor;

  static Future<void> setThemeColor(Color color) async {
    _primaryColor = color;
    _buildTheme();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', color.value);
    
    _notifyListeners();
  }

  static void addListener(Function listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}
