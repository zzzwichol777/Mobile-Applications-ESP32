import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/esp32_provider.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => ESP32Provider()),
      ],
      child: const DrHomeApp(),
    ),
  );
}

class DrHomeApp extends StatelessWidget {
  const DrHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'DrHome',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(themeProvider.currentTheme),
          home: const SplashScreen(),
        );
      },
    );
  }
}
