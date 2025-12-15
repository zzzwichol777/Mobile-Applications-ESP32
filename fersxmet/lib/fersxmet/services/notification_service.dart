import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> checkAnomalies({
    required double temperature,
    required double humidity,
    required double luminosity,
    required double objectTemp,
    required double ambientTemp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (!notificationsEnabled) return;

    // Temperatura ambiente muy alta
    if (temperature > 35) {
      await _showNotification(
        id: 1,
        title: '🔥 Temperatura Alta',
        body: 'Temperatura ambiente: ${temperature.toStringAsFixed(1)}°C - Nivel crítico',
        priority: Priority.high,
      );
    }

    // Temperatura ambiente muy baja
    if (temperature < 10) {
      await _showNotification(
        id: 2,
        title: '❄️ Temperatura Baja',
        body: 'Temperatura ambiente: ${temperature.toStringAsFixed(1)}°C - Nivel bajo',
        priority: Priority.high,
      );
    }

    // Humedad muy alta
    if (humidity > 80) {
      await _showNotification(
        id: 3,
        title: '💧 Humedad Alta',
        body: 'Humedad: ${humidity.toStringAsFixed(1)}% - Riesgo de condensación',
        priority: Priority.high,
      );
    }

    // Humedad muy baja
    if (humidity < 30) {
      await _showNotification(
        id: 4,
        title: '🏜️ Humedad Baja',
        body: 'Humedad: ${humidity.toStringAsFixed(1)}% - Ambiente muy seco',
        priority: Priority.defaultPriority,
      );
    }

    // Luminosidad muy alta
    if (luminosity > 10000) {
      await _showNotification(
        id: 5,
        title: '☀️ Luz Solar Directa',
        body: 'Luminosidad: ${luminosity.toStringAsFixed(0)} lux - Luz muy intensa',
        priority: Priority.defaultPriority,
      );
    }

    // Objeto muy caliente detectado
    final tempDiff = objectTemp - ambientTemp;
    if (tempDiff > 15) {
      await _showNotification(
        id: 6,
        title: '🔥 Objeto Caliente Detectado',
        body: 'Temperatura del objeto: ${objectTemp.toStringAsFixed(1)}°C (+${tempDiff.toStringAsFixed(1)}°C)',
        priority: Priority.max,
      );
    }

    // Objeto muy frío detectado
    if (tempDiff < -10) {
      await _showNotification(
        id: 7,
        title: '🧊 Objeto Frío Detectado',
        body: 'Temperatura del objeto: ${objectTemp.toStringAsFixed(1)}°C (${tempDiff.toStringAsFixed(1)}°C)',
        priority: Priority.high,
      );
    }

    // Condiciones ideales
    if (temperature >= 20 && temperature <= 25 && humidity >= 40 && humidity <= 60) {
      // No notificar condiciones ideales para no saturar
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    Priority priority = Priority.defaultPriority,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('notifications_sound') ?? true;
    final vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;

    // Vibrar si está habilitado
    if (vibrationEnabled && priority == Priority.max) {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 500, 200, 500]);
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'fersxmet_alerts',
      'Alertas FERSXMET',
      channelDescription: 'Notificaciones de anomalías detectadas',
      importance: _getImportance(priority),
      priority: priority,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  Importance _getImportance(Priority priority) {
    switch (priority) {
      case Priority.max:
        return Importance.max;
      case Priority.high:
        return Importance.high;
      case Priority.low:
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
