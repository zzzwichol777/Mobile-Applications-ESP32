import 'package:flutter/material.dart';
import 'dart:async';
import 'weather_home_screen_new.dart';
import '../utils/theme_manager.dart';

class WeatherSplashScreen extends StatefulWidget {
  const WeatherSplashScreen({super.key});

  @override
  State<WeatherSplashScreen> createState() => _WeatherSplashScreenState();
}

class _WeatherSplashScreenState extends State<WeatherSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const WeatherHomeScreenNew(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getDarkThemeColor(Color primaryColor) {
    final hslColor = HSLColor.fromColor(primaryColor);
    final darkColor = hslColor.withLightness(0.15).withSaturation(0.4);
    return darkColor.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ThemeManager.primaryColor;
    final darkBgColor = _getDarkThemeColor(primaryColor);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkBgColor.withOpacity(0.3),
              darkBgColor.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'FERSXMET',
                  style: const TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SISTEMA METEOROLÓGICO',
                  style: const TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
