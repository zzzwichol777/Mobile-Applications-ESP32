import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  AppThemeMode _currentTheme = AppThemeMode.medical;

  ThemeProvider(this.prefs) {
    _loadTheme();
  }

  AppThemeMode get currentTheme => _currentTheme;

  void _loadTheme() {
    final themeIndex = prefs.getInt('theme') ?? 0;
    _currentTheme = AppThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode theme) async {
    _currentTheme = theme;
    await prefs.setInt('theme', theme.index);
    notifyListeners();
  }
}
