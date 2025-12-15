import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/esp32_service.dart';
import 'services/database_service.dart';
import 'screens/network_settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/info_screen.dart';
import 'screens/database_screen.dart';
import 'screens/splash_screen.dart';
import 'models/sensor_reading.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo inicializar funciones específicas de móvil si no estamos en web
  if (!kIsWeb) {
    // Aquí irían las inicializaciones específicas de móvil
    // pero las omitimos para web
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

// Versión simplificada de HomeScreen para web
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

      final bool shouldAlarm =
          values['mq4']! > mq4Threshold || values['mq7']! > mq7Threshold;

      setState(() {
        mq4Value = values['mq4'] ?? 0;
        mq7Value = values['mq7'] ?? 0;
        isAlarmActive = shouldAlarm;
        isConnected = true;
      });

      if (isAlarmActive) {
        _alarmAnimationController.repeat(reverse: true);
        await _saveCurrentReading(auto: true);
      } else {
        _alarmAnimationController.stop();
      }
    } catch (e) {
      print('Error checking sensors: $e');
      setState(() => isConnected = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              'assets/images/menu.png',
              width: 24,
              height: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Center(
          child: Image.asset(
            'assets/images/logo.png',
            height: 32,
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
                      child: Image.asset('assets/images/logo.png', height: 50),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sistema de detección de gas',
                      style: TextStyle(
                        color: Colors.white70,
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
          padding: const EdgeInsets.all(16),
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSensorCard(
                      icon: 'assets/images/co.png',
                      title: 'MQ7 (CO)',
                      value: mq7Value,
                      threshold: mq7Threshold,
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
                      const Text(
                        'Estado del Sistema',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estado de conexión:',
                              style: TextStyle(
                                  color: Colors.white, fontFamily: 'Manrope')),
                          Text(
                            isConnected ? 'Conectado' : 'Desconectado',
                            style: TextStyle(
                              color: isConnected ? Colors.green : Colors.red,
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
                              color: isAlarmActive ? Colors.red : Colors.green,
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
  }) {
    final isOverThreshold = value > threshold;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        width: double.infinity,
        height: 180,
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
