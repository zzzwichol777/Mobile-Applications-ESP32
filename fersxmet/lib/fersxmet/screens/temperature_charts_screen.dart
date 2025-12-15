import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/esp32_weather_service.dart';
import '../widgets/temperature_chart_widget.dart';
import '../utils/theme_manager.dart';

class TemperatureChartsScreen extends StatefulWidget {
  const TemperatureChartsScreen({super.key});

  @override
  State<TemperatureChartsScreen> createState() => _TemperatureChartsScreenState();
}

class _TemperatureChartsScreenState extends State<TemperatureChartsScreen> {
  final ESP32WeatherService _esp32Service = ESP32WeatherService();
  Timer? _timer;
  
  final List<TemperatureDataPoint> _ambientData = [];
  final List<TemperatureDataPoint> _objectData = [];
  final List<TemperatureDataPoint> _dht22Data = [];
  
  static const int maxDataPoints = 30;
  bool _isRecording = false;
  bool _isConnected = false;
  
  double _currentAmbient = 0.0;
  double _currentObject = 0.0;
  double _currentDHT22 = 0.0;

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
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isConnected = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isConnected = false);
      }
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _ambientData.clear();
      _objectData.clear();
      _dht22Data.clear();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchData());
    _fetchData();
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() => _isRecording = false);
  }


  Future<void> _fetchData() async {
    if (!_esp32Service.isConnected) {
      setState(() => _isConnected = false);
      return;
    }

    try {
      final weatherData = await _esp32Service.getWeatherData();
      final thermalData = await _esp32Service.getThermalData();
      
      final now = DateTime.now();
      
      setState(() {
        _isConnected = true;
        _currentDHT22 = weatherData['temperature']!;
        _currentAmbient = thermalData['ambient_temp']!;
        _currentObject = thermalData['object_temp']!;
        
        _dht22Data.add(TemperatureDataPoint(
          timestamp: now,
          temperature: _currentDHT22,
          source: 'DHT22',
        ));
        
        _ambientData.add(TemperatureDataPoint(
          timestamp: now,
          temperature: _currentAmbient,
          source: 'MLX90614_Ambient',
        ));
        
        _objectData.add(TemperatureDataPoint(
          timestamp: now,
          temperature: _currentObject,
          source: 'MLX90614_Object',
        ));
        
        if (_dht22Data.length > maxDataPoints) _dht22Data.removeAt(0);
        if (_ambientData.length > maxDataPoints) _ambientData.removeAt(0);
        if (_objectData.length > maxDataPoints) _objectData.removeAt(0);
      });
    } catch (e) {
      print('Error obteniendo datos: $e');
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildCurrentReadings(primaryColor),
                      const SizedBox(height: 20),
                      _buildControlButtons(primaryColor),
                      const SizedBox(height: 20),
                      _buildDHT22Chart(primaryColor),
                      const SizedBox(height: 20),
                      _buildMLXChart(primaryColor),
                      const SizedBox(height: 20),
                      _buildComparisonChart(primaryColor),
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
            child: Icon(Icons.show_chart, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gráficos de Temperatura',
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

  Widget _buildCurrentReadings(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getDarkThemeColor(primaryColor).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Lecturas Actuales',
            style: TextStyle(
              fontFamily: 'ExpletusSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildReadingItem('DHT22', _currentDHT22, Colors.cyan),
              _buildReadingItem('MLX Amb.', _currentAmbient, Colors.teal),
              _buildReadingItem('MLX Obj.', _currentObject, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingItem(String label, double value, Color color) {
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
          '${value.toStringAsFixed(1)}°C',
          style: TextStyle(
            fontFamily: 'ExpletusSans',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }


  Widget _buildControlButtons(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: _isRecording ? Icons.stop : Icons.play_arrow,
            label: _isRecording ? 'Detener' : 'Iniciar',
            color: _isRecording ? Colors.red : Colors.green,
            onTap: _isConnected ? (_isRecording ? _stopRecording : _startRecording) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Limpiar',
            color: primaryColor,
            onTap: _clearData,
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

  void _clearData() {
    setState(() {
      _ambientData.clear();
      _objectData.clear();
      _dht22Data.clear();
    });
  }

  Widget _buildDHT22Chart(Color primaryColor) {
    return _buildChartCard(
      title: 'DHT22 - Temperatura Ambiente',
      icon: Icons.thermostat,
      primaryColor: primaryColor,
      child: TemperatureChartWidget(
        ambientData: _dht22Data,
        objectData: const [],
        title: '',
        showLegend: false,
      ),
    );
  }

  Widget _buildMLXChart(Color primaryColor) {
    return _buildChartCard(
      title: 'MLX90614 - Dual',
      icon: Icons.heat_pump,
      primaryColor: primaryColor,
      child: TemperatureChartWidget(
        ambientData: _ambientData,
        objectData: _objectData,
        title: '',
        showLegend: true,
      ),
    );
  }

  Widget _buildComparisonChart(Color primaryColor) {
    return _buildChartCard(
      title: 'Comparación DHT22 vs MLX90614',
      icon: Icons.compare_arrows,
      primaryColor: primaryColor,
      child: TemperatureChartWidget(
        ambientData: _dht22Data,
        objectData: _ambientData,
        title: '',
        showLegend: true,
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(icon, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'ExpletusSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }

  Color _getDarkThemeColor(Color primaryColor) {
    final hslColor = HSLColor.fromColor(primaryColor);
    final darkColor = hslColor.withLightness(0.15).withSaturation(0.4);
    return darkColor.toColor();
  }
}
