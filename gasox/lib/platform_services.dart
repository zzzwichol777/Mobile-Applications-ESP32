import 'package:flutter/foundation.dart';

// Servicios de plataforma condicionales
class PlatformServices {
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static bool get isWeb => kIsWeb;
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  // Funciones stub para plataformas no compatibles
  static Future<void> initializeNotifications() async {
    if (isMobile) {
      // Solo inicializar notificaciones en móvil
      // La implementación real iría aquí
    }
  }

  static Future<void> initializeWorkManager() async {
    if (isMobile) {
      // Solo inicializar WorkManager en móvil
      // La implementación real iría aquí
    }
  }

  static Future<void> requestPermissions() async {
    if (isMobile) {
      // Solo solicitar permisos en móvil
      // La implementación real iría aquí
    }
  }

  static Future<void> showNotification(String title, String body) async {
    if (isMobile) {
      // Solo mostrar notificaciones en móvil
      // La implementación real iría aquí
    } else {
      // En web/desktop, mostrar en consola o usar alternativa
      print('Notification: $title - $body');
    }
  }

  static Future<void> playAlarmSound() async {
    if (isMobile) {
      // Solo reproducir sonido en móvil
      // La implementación real iría aquí
    } else {
      // En web/desktop, usar alternativa o no hacer nada
      print('Alarm sound would play here');
    }
  }

  static Future<void> vibrate() async {
    if (isMobile) {
      // Solo vibrar en móvil
      // La implementación real iría aquí
    } else {
      // En web/desktop, no hacer nada
      print('Vibration would happen here');
    }
  }
}
