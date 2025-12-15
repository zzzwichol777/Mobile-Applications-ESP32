import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/esp32_weather_service.dart';
import '../services/weather_database_service.dart';
import '../services/weather_location_service.dart';
import '../models/weather_reading.dart';
import 'weather_database_screen.dart';
import 'weather_network_settings_screen.dart';
import 'theme_selector_screen.dart';
import '../widgets/heat_map_widget.dart';

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  final ESP32WeatherService _esp32Service = ESP32WeatherService();
  final WeatherLocationService _locationService = WeatherLocationService();
  Timer? _timer;

  double temperature = 0.0;
  double humidity = 0.0;
  double luminosity = 0.0;
  bool isConnected = false;
  List<List<double>>? heatMapData;

  @override
  void initState() {
    super.initState();
    _locationService.initialize();
    _loadSavedConnection().then((_) {
      _startPeriodicCheck();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateWeatherData();
    });
  }

  Future<void> _updateWeatherData() async {
    if (!isConnected) return;

    try {
      final data = await _esp32Service.getWeatherData();
      final heatMap = await _esp32Service.getHeatMap();

      setState(() {
        temperature = data['temperature']!;
        humidity = data['humidity']!;
        luminosity = data['luminosity']!;
        heatMapData = heatMap;
        isConnected = true;
      });
    } catch (e) {
      print('Error actualizando datos: $e');
      setState(() => isConnected = false);
    }
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
            content: const Text('Lectura guardada correctamente'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildLocationWidget(),
                      const SizedBox(height: 20),
                      _buildSensorCards(),
                      const SizedBox(height: 20),
                      _buildHeatMapCard(),
                      const SizedBox(height: 20),
                      _buildSaveButton(),
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FERSXMET',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              Text(
                'Sistema Meteorológico',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(
                icon: Icons.storage,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeatherDatabaseScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _buildIconButton(
                icon: Icons.wifi,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeatherNetworkSettingsScreen(),
                    ),
                  );
                },
                color: isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              _buildIconButton(
                icon: Icons.palette,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeSelectorScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color ?? Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildLocationWidget() {
    final locationData = _locationService.getLocationData();
    final hasLocation = locationData['available'] as bool;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasLocation ? Icons.location_on : Icons.location_off,
            color: hasLocation ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasLocation
                  ? _locationService.getLocationString()
                  : 'Ubicación no disponible',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSensorCard(
            icon: Icons.thermostat,
            label: 'Temperatura Ambiental',
            value: temperature.toStringAsFixed(1),
            unit: '°C',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSensorCard(
            icon: Icons.water_drop,
            label: 'Humedad',
            value: humidity.toStringAsFixed(1),
            unit: '%',
            color: Colors.blue,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                unit,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatMapCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.yellow.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.light_mode, color: Colors.yellow, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    'Luminosidad',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    luminosity.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    ' lux',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.yellow,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.heat_pump,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mapa de Calor',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              heatMapData != null
                  ? HeatMapWidget(data: heatMapData!)
                  : Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Text(
                        'Esperando datos...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isConnected ? _saveReading : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          disabledBackgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save, size: 24),
            const SizedBox(width: 10),
            Text(
              'Guardar Lecturas',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
