import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/sensor_reading.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<SensorReading> _readings = [];
  bool _isLoading = true;
  bool _showOnlyHighReadings = false;

  // Estadísticas
  int _totalReadings = 0;
  int _alarmReadings = 0;
  int _normalReadings = 0;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<SensorReading> readings;
      if (_showOnlyHighReadings) {
        readings = await DatabaseService.instance.getHighReadings();
      } else {
        readings = await DatabaseService.instance.getAllReadings();
      }

      // Calcular estadísticas
      final allReadings = await DatabaseService.instance.getAllReadings();
      final highReadings = await DatabaseService.instance.getHighReadings();

      setState(() {
        _readings = readings;
        _totalReadings = allReadings.length;
        _alarmReadings = highReadings.length;
        _normalReadings = _totalReadings - _alarmReadings;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReading(int id) async {
    try {
      await DatabaseService.instance.deleteReading(id);
      await _loadReadings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lectura eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllReadings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar todas las lecturas? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseService.instance.deleteAllReadings();
        await _loadReadings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las lecturas han sido eliminadas'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFormattedDate(DateTime timestamp) {
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }

  String _getFormattedTime(DateTime timestamp) {
    return DateFormat('HH:mm:ss').format(timestamp);
  }

  Color _getReadingColor(SensorReading reading) {
    if (reading.isHighReading) {
      return Colors.red;
    }
    final maxValue = reading.mq4Value > reading.mq7Value
        ? reading.mq4Value
        : reading.mq7Value;

    if (maxValue > 2000) return Colors.orange;
    if (maxValue > 1000) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getReadingStatus(SensorReading reading) {
    if (reading.isHighReading) {
      return 'MEDICIÓN ALTA';
    }
    final maxValue = reading.mq4Value > reading.mq7Value
        ? reading.mq4Value
        : reading.mq7Value;

    if (maxValue > 2000) return 'PRECAUCIÓN';
    if (maxValue > 1000) return 'NORMAL';
    return 'NORMAL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          MediaQuery.of(context).orientation == Orientation.portrait,
      appBar: MediaQuery.of(context).orientation == Orientation.landscape
          ? AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Base de Datos',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadReadings,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'filter':
                        setState(() {
                          _showOnlyHighReadings = !_showOnlyHighReadings;
                        });
                        _loadReadings();
                        break;
                      case 'delete_all':
                        _deleteAllReadings();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'filter',
                      child: Row(
                        children: [
                          Icon(
                            _showOnlyHighReadings
                                ? Icons.filter_alt_off
                                : Icons.filter_alt,
                            size: 20,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showOnlyHighReadings
                                ? 'Mostrar todas'
                                : 'Solo alarmas',
                            style: const TextStyle(fontFamily: 'Manrope'),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever,
                              color: Colors.black, size: 20),
                          SizedBox(width: 8),
                          Text('Eliminar todo',
                              style: TextStyle(
                                  color: Colors.black, fontFamily: 'Manrope')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image:
                        AssetImage('assets/banners/banner_database_screen.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadReadings,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        switch (value) {
                          case 'filter':
                            setState(() {
                              _showOnlyHighReadings = !_showOnlyHighReadings;
                            });
                            _loadReadings();
                            break;
                          case 'delete_all':
                            _deleteAllReadings();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'filter',
                          child: Row(
                            children: [
                              Icon(
                                _showOnlyHighReadings
                                    ? Icons.filter_alt_off
                                    : Icons.filter_alt,
                                size: 20,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showOnlyHighReadings
                                    ? 'Mostrar todas'
                                    : 'Solo alarmas',
                                style: const TextStyle(fontFamily: 'Manrope'),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever,
                                  color: Color.fromARGB(255, 255, 0, 0),
                                  size: 20),
                              SizedBox(width: 8),
                              Text('Eliminar todo',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      fontFamily: 'Manrope')),
                            ],
                          ),
                        ),
                      ],
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
        child: RefreshIndicator(
          onRefresh: _loadReadings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).orientation == Orientation.portrait
                  ? 100.0
                  : 16.0,
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Column(
              children: [
                // Card azul de estadísticas - MISMA SEPARACIÓN
                Container(
                  margin: const EdgeInsets.only(
                      bottom: 12.0), // MISMO MARGEN QUE LAS OTRAS CARDS
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade800,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storage, color: Colors.white, size: 28),
                            SizedBox(height: 10),
                            Text(
                              "Estadísticas De Lecturas",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard("Total", _totalReadings.toString(),
                                Colors.blue.shade900),
                            _buildStatCard("Alarmas", _alarmReadings.toString(),
                                Colors.blue.shade900),
                            _buildStatCard(
                                "Normales",
                                _normalReadings.toString(),
                                Colors.blue.shade900),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de lecturas
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  )
                else if (_readings.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No hay lecturas guardadas',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Manrope'),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _readings.length,
                    itemBuilder: (context, index) {
                      final reading = _readings[index];
                      final isAlarm = reading.isHighReading;

                      // Colores y gradientes
                      Gradient cardGradient;
                      Color textColor;
                      if (isAlarm) {
                        cardGradient = const LinearGradient(
                          colors: [Colors.red, Color(0xFF800000)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        );
                        textColor = const Color.fromARGB(255, 255, 255, 255);
                      } else {
                        cardGradient = const LinearGradient(
                          colors: [
                            Colors.amber,
                            Color.fromARGB(255, 251, 255, 0)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        );
                        textColor = Colors.black;
                      }

                      return Container(
                        margin: const EdgeInsets.only(
                            bottom: 12.0), // MISMO MARGEN PARA TODAS
                        decoration: BoxDecoration(
                          gradient: cardGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16, color: textColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getFormattedDate(reading.timestamp),
                                        style: TextStyle(
                                          color: textColor,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 16, color: textColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getFormattedTime(reading.timestamp),
                                        style: TextStyle(
                                          color: textColor,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        color: isAlarm
                                            ? const Color.fromARGB(
                                                255, 255, 255, 255)
                                            : const Color.fromARGB(
                                                255, 0, 0, 0),
                                        size: 20),
                                    onPressed: () =>
                                        _deleteReading(reading.id!),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSensorValueCardCustom(
                                    'MQ4: ${reading.mq4Value} ppm',
                                    'assets/images/metano.png',
                                    textColor,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildSensorValueCardCustom(
                                    'MQ7: ${reading.mq7Value} ppm',
                                    'assets/images/co.png',
                                    textColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: textColor),
                                ),
                                child: Text(
                                  _getReadingStatus(reading),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Manrope',
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'Manrope',
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorValueCardCustom(
      String text, String iconPath, Color textColor) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.35,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Manrope',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
