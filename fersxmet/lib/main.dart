import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fersxmet/services/esp32_weather_service.dart';
import 'fersxmet/services/weather_database_service.dart';
import 'fersxmet/services/notification_service.dart';
import 'fersxmet/screens/weather_home_screen_new.dart';
import 'fersxmet/screens/weather_splash_screen.dart';
import 'fersxmet/utils/theme_manager.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await ThemeManager.initialize();
  await NotificationService.instance.initialize();
  
  runApp(const FersxmetApp());
}

class FersxmetApp extends StatefulWidget {
  const FersxmetApp({super.key});

  @override
  State<FersxmetApp> createState() => _FersxmetAppState();
}

class _FersxmetAppState extends State<FersxmetApp> {
  @override
  void initState() {
    super.initState();
    // Escuchar cambios de tema
    ThemeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FERSXMET',
      theme: ThemeManager.currentTheme,
      home: const WeatherSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
