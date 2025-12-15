/*
ARCHIVO DE RESPALDO DEL MAIN.DART ORIGINAL
==========================================

Este archivo contiene el código original de main.dart antes de las modificaciones
para compatibilidad multiplataforma. Se mantiene como referencia histórica.

NOTA: Todo el contenido está comentado para evitar errores de compilación
debido a dependencias que no están disponibles en todas las plataformas.

Para usar este código, descomenta las secciones necesarias y asegúrate de que
las dependencias estén disponibles en pubspec.yaml:

- workmanager: ^0.6.0
- flutter_local_notifications: ^19.2.1
- permission_handler: ^12.0.0+1
- audioplayers: ^5.2.1
- vibration: ^3.1.3

CONTENIDO ORIGINAL COMENTADO:
=============================

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/esp32_service.dart';
import 'services/database_service.dart';
import 'screens/network_settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/info_screen.dart';
import 'screens/database_screen.dart';
import 'models/sensor_reading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Ejecutando tarea en segundo plano: $task");
    final esp32 = ESP32Service();
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('esp32_ip');
    final port = prefs.getInt('esp32_port') ?? 8080;
    if (ip != null && ip.isNotEmpty) {
      try {
        await esp32.connect(ip, port);
        final alarm = await esp32.getAlarmState();
        print("Estado de alarma: $alarm");
        if (alarm) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'alarm_channel',
            'Alarmas',
            channelDescription: 'Notificaciones de alarma de gas',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            playSound: true,
            enableVibration: true,
          );
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);
          await flutterLocalNotificationsPlugin.show(
            0,
            '¡PELIGRO!',
            'Se detectaron niveles peligrosos de gas',
            platformChannelSpecifics,
            payload: 'alarm',
          );
        }
      } catch (e) {
        print("Error en tarea en segundo plano: $e");
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: initializationSettingsAndroid),
  );

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await Workmanager().registerPeriodicTask(
    "gasAlarmCheck",
    "checkGasAlarm",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  await Permission.notification.request();

  runApp(const GasoxApp());
}

// ... resto del código original con todas las funcionalidades específicas de móvil
// incluyendo notificaciones, sonidos, vibración, WorkManager, etc.

*/

// ARCHIVO DE RESPALDO - TODO EL CONTENIDO ESTÁ COMENTADO
// Para evitar errores de compilación en plataformas web/desktop

void main() {
  // Este es solo un placeholder para evitar errores
  // El código real está en main.dart
  print(
      'Este es el archivo de respaldo. Use main.dart para la aplicación actual.');
}
