import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/esp32_service.dart';
import 'services/database_service.dart';
import 'screens/network_settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/info_screen.dart';
import 'screens/database_screen.dart';
import 'screens/splash_screen.dart';
import 'models/sensor_reading.dart';
import 'platform_services.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo inicializar servicios específicos de móvil si no estamos en web
  if (PlatformServices.isMobile) {
    await PlatformServices.initializeNotifications();
    await PlatformServices.initializeWorkManager();
    await PlatformServices.requestPermissions();
  }

  runApp(const GasoxApp());
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

  late AnimationController _alarmAnimationController;
  late Animation<double> _alarmAnimation;

  late TextEditingController _mq4Controller;
  late TextEditingController _mq7Controller;

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
        await PlatformServices.playAlarmSound();
        await PlatformServices.vibrate();
        _alarmAnimationController.repeat(reverse: true);

        await _saveCurrentReading(auto: true);
        print('Lectura guardada automáticamente por activación de alarma');
      } else if (!isAlarmActive && _wasAlarmActive) {
        _alarmAnimationController.stop();
      }

      _wasAlarmActive = isAlarmActive;
    } catch (e) {
      print('Error checking sensors: $e');
      setState(() => isConnected = false);
    }
  }

  Future<void> _showAlarmNotification() async {
    await PlatformServices.showNotification(
      '¡PELIGRO! Niveles altos de gas',
      'MQ4: $mq4Value ppm\nMQ7: $mq7Value ppm',
    );
  }

  Future<void> _saveCurrentReading({bool auto = false}) async {
    try {
      final reading = SensorReading(
        timestamp: DateTime.now(),
        mq4Value: mq4Value,
        mq7Value: mq7Value,
        isHighReading: isAlarmActive,
      );

      await DatabaseService.instance.insertReading(reading);

      if (!auto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lectura guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!auto && mounted) {
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
        await _esp32Service.setMQ4Threshold(mq4Threshold.toInt());
        await Future.delayed(const Duration(milliseconds: 500));
        await _esp32Service.setMQ7Threshold(mq7Threshold.toInt());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Umbrales actualizados en ESP32'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al actualizar umbrales: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset('assets/images/menu.png', width: 24, height: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Center(
          child: Image.asset('assets/images/logo.png', height: 32),
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
              width: 24,
              height: 24,
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
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child:
                            Image.asset('assets/images/logo.png', height: 50)),
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
                title: const Text('Notificaciones',
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Manrope')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsScreen()));
                },
              ),
              ListTile(
                leading: Image.asset('assets/images/wifi_orange.png',
                    width: 24, height: 24),
                title: const Text('Configuración de Red',
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Manrope')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NetworkSettingsScreen()));
                },
              ),
              ListTile(
                leading: Image.asset('assets/images/database_icon.png',
                    width: 24, height: 24),
                title: const Text('Base de Datos',
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Manrope')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DatabaseScreen()));
                },
              ),
              ListTile(
                leading: Image.asset('assets/images/info_icon.png',
                    width: 24, height: 24),
                title: const Text('Acerca de',
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Manrope')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InfoScreen()));
                },
              ),
              const Divider(color: Colors.orange),
              ListTile(
                leading: Image.asset('assets/images/update.png',
                    width: 24, height: 24),
                title: const Text('Actualizar Datos',
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Manrope')),
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red
                            .withOpacity(0.15 + _alarmAnimation.value * 0.25),
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red
                                .withOpacity(0.5 + 0.5 * _alarmAnimation.value),
                            size: 48 + 16 * _alarmAnimation.value,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '¡ALARMA ACTIVADA!',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const Text(
                            'Se han detectado niveles peligrosos de gas',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontFamily: 'Manrope',
                            ),
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
              Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Configuración de Umbrales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mq4Controller,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white, fontFamily: 'Manrope'),
                              decoration: InputDecoration(
                                labelText: 'Umbral MQ4',
                                labelStyle: const TextStyle(
                                    color: Colors.orange,
                                    fontFamily: 'Manrope'),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.orange, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null) {
                                  mq4Threshold = parsed;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _mq7Controller,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white, fontFamily: 'Manrope'),
                              decoration: InputDecoration(
                                labelText: 'Umbral MQ7',
                                labelStyle: const TextStyle(
                                    color: Colors.orange,
                                    fontFamily: 'Manrope'),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.orange, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null) {
                                  mq7Threshold = parsed;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateThresholds,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Actualizar Umbrales',
                            style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
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
                          const Text('Estado de conexión:',
                              style: TextStyle(
                                  color: Colors.white, fontFamily: 'Manrope')),
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
                          const Text('Estado de alarma:',
                              style: TextStyle(
                                  color: Colors.white, fontFamily: 'Manrope')),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        width: double.infinity,
        height: 210,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, width: 48, height: 48),
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
                color: isOverThreshold ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'ppm',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Manrope',
                color: isOverThreshold ? Colors.red : Colors.green,
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
    );
  }
}
