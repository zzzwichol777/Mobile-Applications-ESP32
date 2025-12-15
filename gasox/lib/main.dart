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
import 'screens/splash_screen.dart';
import 'models/sensor_reading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'utils/location_integration.dart';
import 'screens/location_readings_screen.dart';

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

  // Solicitar permisos esenciales
  await _requestEssentialPermissions();

  // Solo inicializar notificaciones en Android
  try {
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
  } catch (e) {
    print('Error initializing platform-specific features: $e');
    // Continuar sin estas características en plataformas no compatibles
  }

  runApp(const GasoxApp());
}

/// Solicita los 4 permisos esenciales de la app
Future<void> _requestEssentialPermissions() async {
  try {
    print('=== SOLICITANDO PERMISOS ===');

    // Solicitar permisos uno por uno para mejor control
    final Map<Permission, PermissionStatus> statuses = {};

    // 1. Ubicación
    final locationStatus = await Permission.location.request();
    statuses[Permission.location] = locationStatus;

    // 2. Notificaciones
    final notificationStatus = await Permission.notification.request();
    statuses[Permission.notification] = notificationStatus;

    // 3. Almacenamiento (probar diferentes permisos según la versión de Android)
    PermissionStatus storageStatus;
    try {
      // Primero intentar con manageExternalStorage (Android 11+)
      storageStatus = await Permission.manageExternalStorage.request();
      if (!storageStatus.isGranted) {
        // Si no funciona, intentar con storage tradicional
        storageStatus = await Permission.storage.request();
      }
    } catch (e) {
      // Si falla, usar storage tradicional
      storageStatus = await Permission.storage.request();
    }
    statuses[Permission.storage] = storageStatus;

    // 4. Archivos de audio (para sonidos personalizados)
    PermissionStatus audioStatus;
    try {
      audioStatus = await Permission.audio.request();
    } catch (e) {
      // Si no existe el permiso de audio, usar storage
      audioStatus = storageStatus;
    }
    statuses[Permission.audio] = audioStatus;
  } catch (e) {
    print('Error al solicitar permisos: $e');
  }
}

class GasoxApp extends StatelessWidget {
  const GasoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GASOX',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.orange,
        colorScheme: ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.orangeAccent,
          surface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.orange,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.orange,
          thumbColor: Colors.orangeAccent,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ESP32Service _esp32Service = ESP32Service();
  Timer? _timer;

  int mq4Value = 0;
  int mq7Value = 0;
  double mq4Threshold = 3000;
  double mq7Threshold = 3000;
  bool isAlarmActive = false;
  bool isConnected = false;

  bool _wasAlarmActive = false;
  AudioPlayer? _alarmPlayer;
  bool _isPlayingAlarm = false;

  late AnimationController _alarmAnimationController;
  late Animation<double> _alarmAnimation;

  late TextEditingController _mq4Controller;
  late TextEditingController _mq7Controller;

  DateTime? _lastAutoSave;

  @override
  void initState() {
    super.initState();
    _alarmAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _alarmAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _alarmAnimationController,
      curve: Curves.easeInOut,
    ));

    _mq4Controller =
        TextEditingController(text: mq4Threshold.toInt().toString());
    _mq7Controller =
        TextEditingController(text: mq7Threshold.toInt().toString());

    // Inicializar geolocalización
    LocationIntegration.initialize();

    _loadSavedConnection().then((_) {
      _startPeriodicCheck();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _alarmAnimationController.dispose();
    _mq4Controller.dispose();
    _mq7Controller.dispose();
    _alarmPlayer?.dispose();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkSensors();
    });
  }

  Future<void> _checkSensors() async {
    try {
      if (!isConnected) return;

      final values = await _esp32Service.getSensorValues();
      final alarmState = await _esp32Service.getAlarmState();

      final bool shouldAlarm =
          values['mq4']! > mq4Threshold || values['mq7']! > mq7Threshold;

      setState(() {
        mq4Value = values['mq4'] ?? 0;
        mq7Value = values['mq7'] ?? 0;
        isAlarmActive = shouldAlarm || alarmState;
        isConnected = true;
      });

      if (isAlarmActive && !_wasAlarmActive) {
        await _showAlarmNotification();
        await _playAlarmSound();
        await _startVibration();
        _alarmAnimationController.repeat(reverse: true);

        await _saveCurrentReading(auto: true);
        print('Lectura guardada automáticamente por activación de alarma');
      } else if (!isAlarmActive && _wasAlarmActive) {
        await _stopAlarmSound();
        Vibration.cancel();
        _alarmAnimationController.stop();
      }

      _wasAlarmActive = isAlarmActive;
    } catch (e) {
      print('Error checking sensors: $e');
      setState(() => isConnected = false);
    }
  }

  Future<void> _updateThresholds() async {
    try {
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: No hay conexión con el ESP32'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actualizando umbrales en ESP32...'),
          duration: Duration(seconds: 1),
        ),
      );

      if (mq4Threshold < 0 ||
          mq7Threshold < 0 ||
          mq4Threshold > 80000 ||
          mq7Threshold > 80000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: Los umbrales deben estar entre 0 y 80000'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        print('Enviando umbral MQ4: ${mq4Threshold.toInt()}');
        await _esp32Service.setMQ4Threshold(mq4Threshold.toInt());
        await Future.delayed(const Duration(milliseconds: 500));
        print('Enviando umbral MQ7: ${mq7Threshold.toInt()}');
        await _esp32Service.setMQ7Threshold(mq7Threshold.toInt());
        await Future.delayed(const Duration(milliseconds: 500));

        final response = await _esp32Service.sendCommand('GET_THRESHOLDS');
        print('Respuesta de umbrales: $response');

        try {
          final Map<String, dynamic> thresholds = jsonDecode(response);
          if (thresholds.containsKey('mq4_threshold') &&
              thresholds.containsKey('mq7_threshold')) {
            final int mq4ThresholdFromESP = thresholds['mq4_threshold'];
            final int mq7ThresholdFromESP = thresholds['mq7_threshold'];

            print(
                'Umbrales recibidos - MQ4: $mq4ThresholdFromESP, MQ7: $mq7ThresholdFromESP');

            setState(() {
              _mq4Controller.text = mq4ThresholdFromESP.toString();
              _mq7Controller.text = mq7ThresholdFromESP.toString();
              mq4Threshold = mq4ThresholdFromESP.toDouble();
              mq7Threshold = mq7ThresholdFromESP.toDouble();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Umbrales actualizados en ESP32'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Respuesta incompleta del ESP32');
          }
        } catch (parseError) {
          print('Error al procesar respuesta: $parseError');
          setState(() {
            _mq4Controller.text = mq4Threshold.toInt().toString();
            _mq7Controller.text = mq7Threshold.toInt().toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Umbrales enviados pero no se pudo verificar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (cmdError) {
        print('Error al enviar comandos: $cmdError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $cmdError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error al actualizar umbrales: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCurrentReading({bool auto = false}) async {
    try {
      // Guardar en base de datos original
      final reading = SensorReading(
        timestamp: DateTime.now(),
        mq4Value: mq4Value,
        mq7Value: mq7Value,
        isHighReading: isAlarmActive,
      );

      await DatabaseService.instance.insertReading(reading);

      // También guardar con geolocalización
      await LocationIntegration.saveReadingWithLocation(
        mq4Value: mq4Value,
        mq7Value: mq7Value,
        isHighReading: isAlarmActive,
        auto: auto,
      );

      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lectura guardada correctamente (con ubicación)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar lectura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('esp32_ip');
    final port = prefs.getInt('esp32_port') ?? 8080;
    if (ip != null && ip.isNotEmpty) {
      try {
        await _esp32Service.connect(ip, port);
        setState(() {
          isConnected = true;
        });
        print('Connected to ESP32 at $ip:$port');
      } catch (e) {
        print('Failed to connect to ESP32: $e');
        setState(() {
          isConnected = false;
        });
      }
    }
  }

  Future<void> _playAlarmSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('notifications_sound') ?? true;
      if (!soundEnabled) {
        print('Sonido desactivado en preferencias');
        return;
      }

      final alarmVolume = prefs.getDouble('alarm_volume') ?? 0.8;
      final customAlarmPath = prefs.getString('custom_alarm_path');
      final selectedAlarmSound =
          prefs.getString('selected_alarm_sound') ?? 'assets/sounds/alarm1.mp3';

      print('Configuración de sonido:');
      print('- Volumen: $alarmVolume');
      print('- Sonido seleccionado: $selectedAlarmSound');
      print('- Sonido personalizado: $customAlarmPath');

      await _stopAlarmSound();
      _alarmPlayer = AudioPlayer();
      await _alarmPlayer!.setVolume(alarmVolume);

      Future<void> playSound() async {
        try {
          if (selectedAlarmSound == 'custom' &&
              customAlarmPath != null &&
              customAlarmPath.isNotEmpty) {
            print('Reproduciendo sonido personalizado: $customAlarmPath');
            await _alarmPlayer!.play(DeviceFileSource(customAlarmPath));
          } else if (selectedAlarmSound.startsWith('assets/')) {
            final assetPath = selectedAlarmSound.replaceFirst('assets/', '');
            print('Reproduciendo sonido de assets: $assetPath');
            await _alarmPlayer!.play(AssetSource(assetPath));
          } else {
            print('Usando sonido por defecto: sounds/alarm1.mp3');
            await _alarmPlayer!.play(AssetSource('sounds/alarm1.mp3'));
          }
        } catch (e) {
          print('Error al reproducir sonido: $e');
          try {
            await _alarmPlayer!.play(AssetSource('sounds/alarm1.mp3'));
          } catch (fallbackError) {
            print('Error al reproducir sonido de respaldo: $fallbackError');
          }
        }
      }

      await playSound();
      _isPlayingAlarm = true;
      print('Alarma sonora iniciada (primera reproducción)');

      Timer(const Duration(seconds: 15), () async {
        if (_isPlayingAlarm) {
          print('Reproduciendo alarma por segunda vez');
          await playSound();
          Timer(const Duration(seconds: 15), () {
            _stopAlarmSound();
            print(
                'Alarma sonora detenida automáticamente después de 30 segundos totales');
          });
        }
      });
    } catch (e) {
      print('Error general en reproducción de alarma: $e');
    }
  }

  Future<void> _stopAlarmSound() async {
    try {
      if (_alarmPlayer != null && _isPlayingAlarm) {
        await _alarmPlayer!.stop();
        await _alarmPlayer!.dispose();
        _alarmPlayer = null;
        _isPlayingAlarm = false;
        print('Alarm sound stopped');
      }
    } catch (e) {
      print('Error stopping alarm sound: $e');
    }
  }

  Future<void> _startVibration() async {
    final prefs = await SharedPreferences.getInstance();
    final vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
    if (vibrationEnabled && (await Vibration.hasVibrator() ?? false)) {
      List<int> pattern = [0];
      for (int i = 0; i < 15; i++) {
        pattern.add(500);
        pattern.add(200);
      }
      Vibration.vibrate(pattern: pattern);
      print('Vibración activada por 15 segundos');
    }
  }

  Future<void> _showAlarmNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      if (!notificationsEnabled) {
        print('Notificaciones desactivadas en preferencias');
        return;
      }

      print('Mostrando notificación de alarma');

      List<int> vibrationPattern = [0];
      for (int i = 0; i < 10; i++) {
        vibrationPattern.add(500);
        vibrationPattern.add(200);
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'gas_alarm_channel',
        'Gas Alarms',
        channelDescription: 'Notificaciones de alarma de gas',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(vibrationPattern),
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        ongoing: true,
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        '¡PELIGRO! Niveles altos de gas',
        'MQ4: $mq4Value ppm\nMQ7: $mq7Value ppm',
        NotificationDetails(android: androidPlatformChannelSpecifics),
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Factores de escala responsivos
    final textScaleFactor = isLandscape ? 0.85 : 1.0;
    final paddingFactor = isLandscape ? 0.7 : 1.0;
    final cardHeightFactor = isLandscape ? 0.8 : 1.0;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              'assets/images/menu.png',
              width: isLandscape ? 20 : 24,
              height: isLandscape ? 20 : 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Center(
          child: Image.asset(
            'assets/images/logo.png',
            height: isLandscape ? 28 : 32,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.orange),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              isConnected
                  ? 'assets/images/wifi.png'
                  : 'assets/images/wifiN.png',
              width: isLandscape ? 20 : 24,
              height: isLandscape ? 20 : 24,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondo.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sistema de detección de gas',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Image.asset('assets/images/noti_icon.png',
                    width: 24, height: 24),
                title: const Text(
                  'Notificaciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Image.asset('assets/images/wifi_orange.png',
                    width: 24, height: 24),
                title: const Text(
                  'Configuración de Red',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NetworkSettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Image.asset('assets/images/database_icon.png',
                    width: 24, height: 24),
                title: const Text(
                  'Base de Datos',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DatabaseScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on,
                    color: Colors.orange, size: 24),
                title: const Text(
                  'Lecturas con Ubicación',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LocationReadingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Image.asset('assets/images/info_icon.png',
                    width: 24, height: 24),
                title: const Text(
                  'Acerca de',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InfoScreen()),
                  );
                },
              ),
              const Divider(color: Colors.orange),
              ListTile(
                leading: Image.asset('assets/images/update.png',
                    width: 24, height: 24),
                title: const Text(
                  'Actualizar Datos',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _checkSensors();
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            children: [
              if (isAlarmActive)
                AnimatedBuilder(
                  animation: _alarmAnimation,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20 * paddingFactor),
                      decoration: BoxDecoration(
                        color: Colors.red
                            .withOpacity(0.15 + _alarmAnimation.value * 0.25),
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red
                                .withOpacity(0.5 + 0.5 * _alarmAnimation.value),
                            size: (48 + 16 * _alarmAnimation.value) *
                                textScaleFactor,
                          ),
                          SizedBox(height: 8 * paddingFactor),
                          Text(
                            '¡ALARMA ACTIVADA!',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 24 * textScaleFactor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          Text(
                            'Se han detectado niveles peligrosos de gas',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16 * textScaleFactor,
                              fontFamily: 'Manrope',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (isAlarmActive) const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSensorCard(
                      icon: 'assets/images/metano.png',
                      title: 'MQ4 (Metano)',
                      value: mq4Value,
                      threshold: mq4Threshold,
                      isOverThreshold: mq4Value > mq4Threshold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSensorCard(
                      icon: 'assets/images/co.png',
                      title: 'MQ7 (CO)',
                      value: mq7Value,
                      threshold: mq7Threshold,
                      isOverThreshold: mq7Value > mq7Threshold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Widget de ubicación
              LocationIntegration.getFullLocationWidget(),
              const SizedBox(height: 20),
              Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración De Umbrales',
                        style: TextStyle(
                          fontSize: 20 * textScaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MQ4 (Metano):',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.orange,
                                inactiveTrackColor: Colors.grey.shade700,
                                thumbColor: Colors.orange,
                                overlayColor: Colors.orange.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: mq4Threshold,
                                min: 0,
                                max: 80000,
                                divisions: 800,
                                label: '${mq4Threshold.toInt()} ppm',
                                onChanged: (value) {
                                  setState(() {
                                    mq4Threshold = value;
                                    _mq4Controller.text =
                                        value.toInt().toString();
                                  });
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _mq4Controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12),
                                suffixText: 'ppm',
                                suffixStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isEmpty) return;
                                final parsed = double.tryParse(value);
                                if (parsed != null &&
                                    parsed >= 0 &&
                                    parsed <= 80000) {
                                  setState(() {
                                    mq4Threshold = parsed;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MQ7 (CO):',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.orange,
                                inactiveTrackColor: Colors.grey.shade700,
                                thumbColor: Colors.orange,
                                overlayColor: Colors.orange.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: mq7Threshold,
                                min: 0,
                                max: 80000,
                                divisions: 800,
                                label: '${mq7Threshold.toInt()} ppm',
                                onChanged: (value) {
                                  setState(() {
                                    mq7Threshold = value;
                                    _mq7Controller.text =
                                        value.toInt().toString();
                                  });
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _mq7Controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12),
                                suffixText: 'ppm',
                                suffixStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isEmpty) return;
                                final parsed = double.tryParse(value);
                                if (parsed != null &&
                                    parsed >= 0 &&
                                    parsed <= 80000) {
                                  setState(() {
                                    mq7Threshold = parsed;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: isConnected ? _updateThresholds : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.zero,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.orange,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isConnected
                                    ? [
                                        Colors.orange.shade700,
                                        Colors.orange.shade300
                                      ]
                                    : [Colors.black, Colors.grey.shade900],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              constraints: const BoxConstraints(minWidth: 200),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/update.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Actualizar Umbrales',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          isConnected ? () => _saveCurrentReading() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.zero,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.orange,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isConnected
                                ? [
                                    Colors.orange.shade700,
                                    Colors.orange.shade300
                                  ]
                                : [Colors.black, Colors.grey.shade900],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save),
                              const SizedBox(width: 8),
                              const Text(
                                'Guardar Lectura',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DatabaseScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade700,
                              Colors.orange.shade300
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history),
                              const SizedBox(width: 8),
                              const Text(
                                'Ver Historial',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Información del Sistema',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estado de conexión:',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          Text(
                            isConnected ? 'Conectado' : 'Desconectado',
                            style: TextStyle(
                              color: isConnected
                                  ? const Color(0xFF74FF77)
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estado de alarma:',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          Text(
                            isAlarmActive ? 'ACTIVA' : 'Normal',
                            style: TextStyle(
                              color: isAlarmActive
                                  ? Colors.red
                                  : const Color(0xFF74FF77),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Última lectura:',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          Text(
                            DateTime.now().toString().substring(11, 19),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String icon,
    required String title,
    required int value,
    required double threshold,
    required bool isOverThreshold,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Container(
              color: Colors.black.withOpacity(0.8),
              width: double.infinity,
              height: 210,
            ),
            Container(
              width: double.infinity,
              height: 210,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    icon,
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Manrope',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Manrope',
                      foreground: _getSensorPaint(value, threshold),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'ppm',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Manrope',
                      foreground: _getSensorPaint(value, threshold),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Umbral: ${threshold.toInt()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'Manrope',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Paint _getSensorPaint(int value, double threshold) {
    if (value > threshold) {
      return Paint()..color = Colors.red;
    } else {
      return Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFF74FF77),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));
    }
  }
}
