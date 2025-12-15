import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/esp32_weather_service.dart';
import '../services/notification_service.dart';
import '../utils/theme_manager.dart';

class EnvironmentalAnalysisScreen extends StatefulWidget {
  const EnvironmentalAnalysisScreen({super.key});

  @override
  State<EnvironmentalAnalysisScreen> createState() =>
      _EnvironmentalAnalysisScreenState();
}

class _EnvironmentalAnalysisScreenState
    extends State<EnvironmentalAnalysisScreen> {
  final ESP32WeatherService _esp32Service = ESP32WeatherService();
  final NotificationService _notificationService = NotificationService();
  Timer? _timer;

  bool _isConnected = false;
  bool _isMonitoring = false;

  // Datos DHT22
  double _temperature = 0.0;
  double _humidity = 0.0;

  // Datos MLX90614
  double _ambientTemp = 0.0;
  double _objectTemp = 0.0;

  // Historial para tendencias
  final List<double> _humidityHistory = [];
  final List<double> _tempHistory = [];
  static const int _historySize = 10;

  @override
  void initState() {
    super.initState();
    _loadSavedConnection();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('esp32_ip');
    final port = prefs.getInt('esp32_port') ?? 8080;

    if (ip != null && ip.isNotEmpty) {
      try {
        await _esp32Service.connect(ip, port);
        if (mounted) {
          setState(() => _isConnected = true);
          _fetchData();
        }
      } catch (e) {
        if (mounted) setState(() => _isConnected = false);
      }
    }
  }

  void _startMonitoring() {
    setState(() => _isMonitoring = true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData());
    _fetchData();
  }

  void _stopMonitoring() {
    _timer?.cancel();
    setState(() => _isMonitoring = false);
  }

  Future<void> _fetchData() async {
    if (!_esp32Service.isConnected) {
      setState(() => _isConnected = false);
      return;
    }

    try {
      final weatherData = await _esp32Service.getWeatherData();
      final thermalData = await _esp32Service.getThermalData();

      setState(() {
        _isConnected = true;
        _temperature = weatherData['temperature']!;
        _humidity = weatherData['humidity']!;
        _ambientTemp = thermalData['ambient_temp']!;
        _objectTemp = thermalData['object_temp']!;

        // Guardar historial para tendencias
        _humidityHistory.add(_humidity);
        _tempHistory.add(_temperature);
        if (_humidityHistory.length > _historySize) _humidityHistory.removeAt(0);
        if (_tempHistory.length > _historySize) _tempHistory.removeAt(0);
      });

      // Verificar alertas
      _checkAlerts();
    } catch (e) {
      print('Error obteniendo datos: $e');
    }
  }

  void _checkAlerts() {
    _notificationService.checkAnomalies(
      temperature: _temperature,
      humidity: _humidity,
      luminosity: 0,
      objectTemp: _objectTemp,
      ambientTemp: _ambientTemp,
    );
  }

  // Cálculos de análisis ambiental
  double get _heatIndex {
    // Índice de calor (sensación térmica)
    if (_temperature < 27) return _temperature;
    final t = _temperature;
    final h = _humidity;
    return -8.78469475556 +
        1.61139411 * t +
        2.33854883889 * h -
        0.14611605 * t * h -
        0.012308094 * t * t -
        0.0164248277778 * h * h +
        0.002211732 * t * t * h +
        0.00072546 * t * h * h -
        0.000003582 * t * t * h * h;
  }

  double get _dewPoint {
    // Punto de rocío
    final a = 17.27;
    final b = 237.7;
    final alpha = (a * _temperature) / (b + _temperature) + math.log(_humidity / 100);
    return (b * alpha) / (a - alpha);
  }

  int get _rainProbability {
    // Probabilidad de lluvia basada en humedad y tendencia
    double prob = 0;

    // Base por humedad actual
    if (_humidity >= 90) prob = 85;
    else if (_humidity >= 80) prob = 65;
    else if (_humidity >= 70) prob = 45;
    else if (_humidity >= 60) prob = 25;
    else prob = 10;

    // Ajuste por tendencia de humedad
    if (_humidityHistory.length >= 3) {
      final trend = _humidityHistory.last - _humidityHistory.first;
      if (trend > 10) prob += 15; // Humedad subiendo rápido
      else if (trend > 5) prob += 8;
      else if (trend < -5) prob -= 10; // Humedad bajando
    }

    // Ajuste por punto de rocío cercano a temperatura
    final dewDiff = _temperature - _dewPoint;
    if (dewDiff < 2) prob += 20;
    else if (dewDiff < 5) prob += 10;

    return prob.clamp(0, 100).round();
  }

  String get _plantStatus {
    if (_humidity >= 60 && _humidity <= 80) return 'Óptima';
    if (_humidity >= 40 && _humidity < 60) return 'Aceptable';
    if (_humidity > 80) return 'Muy húmedo';
    if (_humidity < 40) return 'Muy seco';
    return 'Desconocido';
  }

  Color get _plantStatusColor {
    if (_humidity >= 60 && _humidity <= 80) return Colors.green;
    if (_humidity >= 40 && _humidity < 60) return Colors.orange;
    return Colors.red;
  }

  String get _comfortLevel {
    final hi = _heatIndex;
    if (hi < 20) return 'Frío';
    if (hi >= 20 && hi < 26) return 'Confortable';
    if (hi >= 26 && hi < 32) return 'Cálido';
    if (hi >= 32 && hi < 40) return 'Caluroso';
    return 'Peligroso';
  }

  Color get _comfortColor {
    final hi = _heatIndex;
    if (hi < 20) return Colors.blue;
    if (hi >= 20 && hi < 26) return Colors.green;
    if (hi >= 26 && hi < 32) return Colors.orange;
    return Colors.red;
  }

  // Análisis térmico objeto vs ambiente
  String get _thermalAlert {
    final diff = _objectTemp - _ambientTemp;
    if (diff > 20) return '⚠️ ¡PELIGRO! Objeto muy caliente';
    if (diff > 10) return '🔥 Objeto caliente - Precaución';
    if (diff > 5) return '🌡️ Objeto tibio';
    if (diff < -10) return '🧊 Objeto muy frío';
    if (diff < -5) return '❄️ Objeto frío';
    return '✅ Temperatura normal';
  }

  Color get _thermalAlertColor {
    final diff = _objectTemp - _ambientTemp;
    if (diff > 20) return Colors.red;
    if (diff > 10) return Colors.orange;
    if (diff > 5) return Colors.amber;
    if (diff < -10) return Colors.blue;
    if (diff < -5) return Colors.lightBlue;
    return Colors.green;
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
            colors: [darkBgColor.withOpacity(0.3), darkBgColor.withOpacity(0.6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(primaryColor),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildControlButtons(primaryColor),
                      const SizedBox(height: 16),
                      _buildRainProbabilityCard(primaryColor),
                      const SizedBox(height: 16),
                      _buildThermalAlertCard(primaryColor),
                      const SizedBox(height: 16),
                      _buildComfortCard(primaryColor),
                      const SizedBox(height: 16),
                      _buildPlantStatusCard(primaryColor),
                      const SizedBox(height: 16),
                      _buildDetailedReadings(primaryColor),
                      const SizedBox(height: 20),
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

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.3),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.eco, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Análisis Ambiental',
                  style: TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'DHT22 + MLX90614',
                  style: TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          _buildConnectionIndicator(primaryColor),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (_isConnected ? Colors.green : Colors.red).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _isConnected ? 'Online' : 'Offline',
            style: TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 12,
              color: _isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: _isMonitoring ? Icons.stop : Icons.play_arrow,
            label: _isMonitoring ? 'Detener' : 'Monitorear',
            color: _isMonitoring ? Colors.red : Colors.green,
            onTap: _isConnected
                ? (_isMonitoring ? _stopMonitoring : _startMonitoring)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.refresh,
            label: 'Actualizar',
            color: primaryColor,
            onTap: _isConnected ? _fetchData : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnabled
              ? [color, color.withOpacity(0.7)]
              : [Colors.grey.shade700, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRainProbabilityCard(Color primaryColor) {
    final prob = _rainProbability;
    final probColor = prob > 70
        ? Colors.blue
        : prob > 40
            ? Colors.cyan
            : Colors.grey;

    return _buildCard(
      primaryColor: primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, color: probColor, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Probabilidad de Lluvia',
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: prob / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(probColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$prob%',
                    style: TextStyle(
                      fontFamily: 'ExpletusSans',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: probColor,
                    ),
                  ),
                  Text(
                    prob > 70
                        ? 'Alta'
                        : prob > 40
                            ? 'Media'
                            : 'Baja',
                    style: TextStyle(
                      fontFamily: 'ExpletusSans',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Punto de rocío: ${_dewPoint.toStringAsFixed(1)}°C',
            style: TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalAlertCard(Color primaryColor) {
    final diff = _objectTemp - _ambientTemp;

    return _buildCard(
      primaryColor: primaryColor,
      borderColor: _thermalAlertColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, color: _thermalAlertColor, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Alerta Térmica',
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _thermalAlertColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _thermalAlertColor.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  _thermalAlert,
                  style: TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _thermalAlertColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTempColumn('Objeto', _objectTemp, Colors.orange),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _thermalAlertColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontFamily: 'ExpletusSans',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _thermalAlertColor,
                        ),
                      ),
                    ),
                    _buildTempColumn('Ambiente', _ambientTemp, Colors.teal),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempColumn(String label, double temp, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ExpletusSans',
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${temp.toStringAsFixed(1)}°C',
          style: TextStyle(
            fontFamily: 'ExpletusSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildComfortCard(Color primaryColor) {
    return _buildCard(
      primaryColor: primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_satisfied_alt, color: _comfortColor, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Índice de Confort',
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    'Sensación',
                    style: TextStyle(
                      fontFamily: 'ExpletusSans',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_heatIndex.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontFamily: 'ExpletusSans',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _comfortColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _comfortColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _comfortColor),
                ),
                child: Text(
                  _comfortLevel,
                  style: TextStyle(
                    fontFamily: 'ExpletusSans',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _comfortColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Basado en temperatura (${_temperature.toStringAsFixed(1)}°C) y humedad (${_humidity.toStringAsFixed(0)}%)',
            style: TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlantStatusCard(Color primaryColor) {
    return _buildCard(
      primaryColor: primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_florist, color: _plantStatusColor, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Estado para Plantas',
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _plantStatusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _plantStatusColor.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      '${_humidity.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'ExpletusSans',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Humedad',
                      style: TextStyle(
                        fontFamily: 'ExpletusSans',
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _plantStatusColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _plantStatus,
                        style: TextStyle(
                          fontFamily: 'ExpletusSans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _plantStatusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPlantRecommendation(),
                        style: TextStyle(
                          fontFamily: 'ExpletusSans',
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPlantRecommendation() {
    if (_humidity >= 60 && _humidity <= 80) return 'Condiciones ideales';
    if (_humidity >= 40 && _humidity < 60) return 'Considera regar pronto';
    if (_humidity > 80) return 'Reduce el riego';
    if (_humidity < 40) return '¡Necesita agua!';
    return '';
  }

  Widget _buildDetailedReadings(Color primaryColor) {
    return _buildCard(
      primaryColor: primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Lecturas Detalladas',
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReadingRow('DHT22 Temperatura', '${_temperature.toStringAsFixed(1)}°C', Colors.cyan),
          _buildReadingRow('DHT22 Humedad', '${_humidity.toStringAsFixed(0)}%', Colors.blue),
          _buildReadingRow('MLX90614 Ambiente', '${_ambientTemp.toStringAsFixed(1)}°C', Colors.teal),
          _buildReadingRow('MLX90614 Objeto', '${_objectTemp.toStringAsFixed(1)}°C', Colors.orange),
          _buildReadingRow('Punto de Rocío', '${_dewPoint.toStringAsFixed(1)}°C', Colors.purple),
          _buildReadingRow('Sensación Térmica', '${_heatIndex.toStringAsFixed(1)}°C', Colors.amber),
        ],
      ),
    );
  }

  Widget _buildReadingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Color primaryColor,
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: child,
    );
  }

  Color _getDarkThemeColor(Color primaryColor) {
    final hslColor = HSLColor.fromColor(primaryColor);
    final darkColor = hslColor.withLightness(0.15).withSaturation(0.4);
    return darkColor.toColor();
  }
}
