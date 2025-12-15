import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_reading_with_location.dart';
import '../services/enhanced_sensor_service.dart';

class LocationReadingsScreen extends StatefulWidget {
  const LocationReadingsScreen({super.key});

  @override
  State<LocationReadingsScreen> createState() => _LocationReadingsScreenState();
}

class _LocationReadingsScreenState extends State<LocationReadingsScreen> {
  final EnhancedSensorService _enhancedService = EnhancedSensorService();
  List<SensorReadingWithLocation> _readings = [];
  bool _isLoading = true;
  bool _showOnlyWithLocation = false;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() => _isLoading = true);

    try {
      final readings = _showOnlyWithLocation
          ? await _enhancedService.getReadingsWithValidLocation()
          : await _enhancedService.getAllReadingsWithLocation();

      setState(() {
        _readings = readings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar lecturas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReading(SensorReadingWithLocation reading) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Confirmar eliminación',
          style: TextStyle(color: Colors.white, fontFamily: 'Manrope'),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar esta ${reading.isHighReading ? 'alarma' : 'lectura'}?\n\nFecha: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(reading.timestamp)}',
          style: const TextStyle(color: Colors.white70, fontFamily: 'Manrope'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey, fontFamily: 'Manrope'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontFamily: 'Manrope'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && reading.id != null) {
      try {
        final success =
            await _enhancedService.deleteReadingWithLocation(reading.id!);

        if (success) {
          await _loadReadings(); // Recargar la lista
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${reading.isHighReading ? 'Alarma' : 'Lectura'} eliminada correctamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar la lectura'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAllReadings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Confirmar eliminación masiva',
          style: TextStyle(color: Colors.white, fontFamily: 'Manrope'),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar TODAS las lecturas con ubicación? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Manrope'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey, fontFamily: 'Manrope'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Eliminar Todo',
              style: TextStyle(fontFamily: 'Manrope'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _enhancedService.deleteAllReadingsWithLocation();

        if (success) {
          await _loadReadings(); // Recargar la lista
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Todas las lecturas han sido eliminadas'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar las lecturas'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
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
      appBar: AppBar(
        title: const Text(
          'Lecturas con Ubicación',
          style: TextStyle(fontFamily: 'Manrope'),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(
                _showOnlyWithLocation ? Icons.location_on : Icons.location_off),
            onPressed: () {
              setState(() {
                _showOnlyWithLocation = !_showOnlyWithLocation;
              });
              _loadReadings();
            },
            tooltip: _showOnlyWithLocation
                ? 'Mostrar todas las lecturas'
                : 'Solo lecturas con ubicación',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReadings,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete_all') {
                _deleteAllReadings();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Eliminar todo',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : _readings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showOnlyWithLocation
                              ? 'No hay lecturas con ubicación'
                              : 'No hay lecturas guardadas',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _readings.length,
                    itemBuilder: (context, index) {
                      final reading = _readings[index];
                      return _buildReadingCard(reading);
                    },
                  ),
      ),
    );
  }

  Widget _buildReadingCard(SensorReadingWithLocation reading) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final isHighReading = reading.isHighReading;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isHighReading ? Colors.red : Colors.orange.withValues(alpha: 0.3),
          width: isHighReading ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        dateFormat.format(reading.timestamp),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isHighReading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Text(
                            'ALARMA',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: isHighReading ? Colors.red : Colors.orange,
                    size: 20,
                  ),
                  onPressed: () => _deleteReading(reading),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Eliminar ${isHighReading ? 'alarma' : 'lectura'}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSensorValue(
                    'MQ4 (Metano)',
                    reading.mq4Value,
                    'ppm',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSensorValue(
                    'MQ7 (CO)',
                    reading.mq7Value,
                    'ppm',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.orange),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  reading.hasLocation ? Icons.location_on : Icons.location_off,
                  color: reading.hasLocation ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reading.getLocationString(),
                    style: TextStyle(
                      color: reading.hasLocation
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ],
            ),
            if (reading.hasLocation && reading.locationAccuracy != null) ...[
              const SizedBox(height: 4),
              Text(
                'Precisión: ${reading.locationAccuracy!.toStringAsFixed(1)}m',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorValue(String label, int value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
