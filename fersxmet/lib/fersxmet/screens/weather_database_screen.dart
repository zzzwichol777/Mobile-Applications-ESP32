import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_database_service.dart';
import '../models/weather_reading.dart';

class WeatherDatabaseScreen extends StatefulWidget {
  const WeatherDatabaseScreen({super.key});

  @override
  State<WeatherDatabaseScreen> createState() => _WeatherDatabaseScreenState();
}

class _WeatherDatabaseScreenState extends State<WeatherDatabaseScreen> {
  List<WeatherReading> _readings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() => _isLoading = true);
    try {
      final readings = await WeatherDatabaseService.instance.getAllReadings();
      setState(() {
        _readings = readings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReading(int id) async {
    try {
      await WeatherDatabaseService.instance.deleteReading(id);
      _loadReadings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lectura eliminada'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllReadings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Eliminar todas las lecturas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await WeatherDatabaseService.instance.deleteAllReadings();
        _loadReadings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Todas las lecturas eliminadas'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : _readings.isEmpty
                        ? _buildEmptyState()
                        : _buildReadingsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base de Datos',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  '${_readings.length} lecturas',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (_readings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _deleteAllReadings,
              color: Colors.red,
              tooltip: 'Eliminar todas',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay lecturas guardadas',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _readings.length,
      itemBuilder: (context, index) {
        final reading = _readings[index];
        return _buildReadingCard(reading);
      },
    );
  }

  Widget _buildReadingCard(WeatherReading reading) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(15),
            title: Text(
              dateFormat.format(reading.timestamp),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildDataRow(
                  Icons.thermostat,
                  'Temperatura',
                  '${reading.temperature.toStringAsFixed(1)}°C',
                  Colors.orange,
                ),
                const SizedBox(height: 5),
                _buildDataRow(
                  Icons.water_drop,
                  'Humedad',
                  '${reading.humidity.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
                const SizedBox(height: 5),
                _buildDataRow(
                  Icons.light_mode,
                  'Luminosidad',
                  '${reading.luminosity.toStringAsFixed(0)} lux',
                  Colors.yellow,
                ),
                if (reading.hasLocation) ...[
                  const SizedBox(height: 5),
                  _buildDataRow(
                    Icons.location_on,
                    'Ubicación',
                    reading.getLocationString(),
                    Colors.green,
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => _deleteReading(reading.id!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
