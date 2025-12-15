import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/esp32_weather_service.dart';
import '../services/weather_database_service.dart';
import '../services/weather_location_service.dart';
import '../services/notification_service.dart';
import '../models/weather_reading.dart';
import '../utils/theme_manager.dart';
import 'weather_database_screen.dart';
import 'weather_network_settings_screen.dart';
import 'theme_selector_screen.dart';
import 'notifications_settings_screen.dart';
import 'temperature_charts_screen.dart';
import 'environmental_analysis_screen.dart';

class WeatherHomeScreenNew extends StatefulWidget {
  const WeatherHomeScreenNew({super.key});

  @override
  State<WeatherHomeScreenNew> createState() => _WeatherHomeScreenNewState();
}

class _WeatherHomeScreenNewState extends State<WeatherHomeScreenNew> with SingleTickerProviderStateMixin {
  final ESP32WeatherService _esp32Service = ESP32WeatherService();
  final WeatherLocationService _locationService = WeatherLocationService();
  final NotificationService _notificationService = NotificationService.instance;
  
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Datos de sensores
  double temperature = 0.0;
  double humidity = 0.0;
  double luminosity = 0.0;
  double objectTemp = 0.0;
  double ambientTemp = 0.0;
  double heatIndex = 0.0;
  bool isConnected = false;
  bool sensorsAvailable = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _notificationService.initialize();
    _locationService.initialize();
    _loadSavedConnection().then((_) {
      _startPeriodicCheck();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateWeatherData();
    });
  }

  Future<void> _updateWeatherData() async {
    if (!isConnected) return;

    try {
      final weatherData = await _esp32Service.getWeatherData();
      final thermalData = await _esp32Service.getThermalData();

      setState(() {
        temperature = weatherData['temperature']!;
        humidity = weatherData['humidity']!;
        luminosity = weatherData['luminosity']!;
        objectTemp = thermalData['object_temp']!;
        ambientTemp = thermalData['ambient_temp']!;
        heatIndex = _calculateHeatIndex(temperature, humidity);
        isConnected = true;
        sensorsAvailable = true;
      });

      // Verificar anomalías
      await _notificationService.checkAnomalies(
        temperature: temperature,
        humidity: humidity,
        luminosity: luminosity,
        objectTemp: objectTemp,
        ambientTemp: ambientTemp,
      );
    } catch (e) {
      print('Error actualizando datos: $e');
      setState(() => isConnected = false);
    }
  }

  double _calculateHeatIndex(double temp, double hum) {
    if (temp < 27) return temp;
    
    final t = temp;
    final h = hum;
    
    final hi = -8.78469475556 +
        1.61139411 * t +
        2.33854883889 * h +
        -0.14611605 * t * h +
        -0.012308094 * t * t +
        -0.0164248277778 * h * h +
        0.002211732 * t * t * h +
        0.00072546 * t * h * h +
        -0.000003582 * t * t * h * h;
    
    return hi;
  }

  Future<void> _saveReading() async {
    try {
      final locationData = _locationService.getLocationData();

      final reading = WeatherReading(
        timestamp: DateTime.now(),
        temperature: temperature,
        humidity: humidity,
        luminosity: luminosity,
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
        locationAccuracy: locationData['accuracy'],
        hasLocation: locationData['available'],
      );

      await WeatherDatabaseService.instance.insertReading(reading);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Lectura guardada correctamente'),
              ],
            ),
            backgroundColor: ThemeManager.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error al guardar: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
        setState(() => isConnected = true);
      } catch (e) {
        setState(() => isConnected = false);
      }
    }
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(primaryColor),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildTopIcons(primaryColor),
                        const SizedBox(height: 20),
                        _buildMainSensorCards(primaryColor),
                        const SizedBox(height: 20),
                        _buildLuminosityCard(primaryColor),
                        const SizedBox(height: 20),
                        _buildThermalCard(primaryColor),
                        const SizedBox(height: 20),
                        _buildHeatIndexCard(primaryColor),
                        const SizedBox(height: 24),
                        _buildSaveButton(primaryColor),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.cloud, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FERSXMET',
                style: const TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Sistema Meteorológico',
                style: const TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDarkThemeColor(Color primaryColor) {
    // Convertir el color primario a HSL
    final hslColor = HSLColor.fromColor(primaryColor);
    
    // Crear una versión oscura reduciendo la luminosidad
    final darkColor = hslColor.withLightness(0.15).withSaturation(0.4);
    
    return darkColor.toColor();
  }

  Widget _buildTopIcons(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIconButton(
            icon: Icons.storage,
            color: primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WeatherDatabaseScreen()),
              );
            },
          ),
          _buildIconButton(
            icon: Icons.show_chart,
            color: primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TemperatureChartsScreen()),
              );
            },
          ),
          _buildIconButton(
            icon: Icons.eco,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EnvironmentalAnalysisScreen()),
              );
            },
          ),
          _buildIconButton(
            icon: Icons.wifi,
            color: isConnected ? Colors.green : Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WeatherNetworkSettingsScreen()),
              );
            },
          ),
          _buildIconButton(
            icon: Icons.notifications,
            color: primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsSettingsScreen()),
              );
            },
          ),
          _buildIconButton(
            icon: Icons.palette,
            color: primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeSelectorScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }



  Widget _buildMainSensorCards(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildSensorCard(
            icon: Icons.thermostat_outlined,
            label: 'Temperatura Ambiental',
            value: temperature.toStringAsFixed(1),
            unit: '°C',
            color: primaryColor,
            subtitle: _getTemperatureStatus(temperature),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSensorCard(
            icon: Icons.water_drop_outlined,
            label: 'Humedad',
            value: humidity.toStringAsFixed(1),
            unit: '%',
            color: primaryColor,
            subtitle: _getHumidityStatus(humidity),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(ThemeManager.primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 16,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'ExpletusSans',
                fontSize: 10,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLuminosityCard(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.light_mode, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                'Luminosidad',
                style: const TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                luminosity.toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'lux',
                  style: TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 18,
                    color: primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getLuminosityStatus(luminosity),
            style: const TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalCard(Color primaryColor) {
    final tempDiff = objectTemp - ambientTemp;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.heat_pump, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                'Sensor Térmico IR',
                style: const TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildThermalValue(
                'Ambiente',
                ambientTemp.toStringAsFixed(1),
                primaryColor.withOpacity(0.7),
              ),
              Container(
                width: 2,
                height: 50,
                color: primaryColor.withOpacity(0.3),
              ),
              _buildThermalValue(
                'Objeto',
                objectTemp.toStringAsFixed(1),
                tempDiff > 5 ? Colors.red : (tempDiff < -5 ? Colors.blue : primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tempDiff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: tempDiff > 0 ? Colors.red : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Diferencia: ${tempDiff.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getThermalStatus(tempDiff),
            style: const TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 11,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThermalValue(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'ExpletusSans',
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'ExpletusSans',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '°C',
              style: TextStyle(
                fontFamily: 'ExpletusSans',
                fontSize: 14,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeatIndexCard(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wb_sunny, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                'Sensación Térmica',
                style: const TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heatIndex.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '°C',
                  style: TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 18,
                    color: primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getHeatIndexStatus(heatIndex),
            style: const TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 12,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color primaryColor) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected
              ? [primaryColor, primaryColor.withOpacity(0.7)]
              : [Colors.grey.shade700, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnected ? _saveReading : null,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Guardar Lecturas',
                  style: const TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTemperatureStatus(double temp) {
    if (temp < 10) return 'Muy frío';
    if (temp < 18) return 'Frío';
    if (temp < 24) return 'Agradable';
    if (temp < 30) return 'Cálido';
    if (temp < 35) return 'Caluroso';
    return 'Muy caluroso';
  }

  String _getHumidityStatus(double hum) {
    if (hum < 30) return 'Muy seco';
    if (hum < 40) return 'Seco';
    if (hum < 60) return 'Confortable';
    if (hum < 70) return 'Húmedo';
    return 'Muy húmedo';
  }

  String _getLuminosityStatus(double lux) {
    if (lux < 10) return 'Oscuridad';
    if (lux < 50) return 'Muy tenue';
    if (lux < 200) return 'Tenue';
    if (lux < 500) return 'Iluminación interior';
    if (lux < 1000) return 'Bien iluminado';
    if (lux < 10000) return 'Luz brillante';
    return 'Luz solar directa';
  }

  String _getThermalStatus(double diff) {
    if (diff.abs() < 2) return 'Objeto a temperatura ambiente';
    if (diff > 15) return '¡Objeto muy caliente detectado!';
    if (diff > 5) return 'Objeto más caliente que el ambiente';
    if (diff < -10) return '¡Objeto muy frío detectado!';
    if (diff < -5) return 'Objeto más frío que el ambiente';
    return 'Diferencia térmica normal';
  }

  String _getHeatIndexStatus(double hi) {
    if (hi < 27) return 'Sin riesgo';
    if (hi < 32) return 'Precaución';
    if (hi < 41) return 'Precaución extrema';
    if (hi < 54) return 'Peligro';
    return 'Peligro extremo';
  }
}
