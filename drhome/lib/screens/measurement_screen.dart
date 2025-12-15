import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/esp32_provider.dart';
import '../providers/patient_provider.dart';
import '../models/measurement.dart';
import 'esp32_config_screen.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  bool _isMeasuring = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _startMeasurement() async {
    final esp32 = Provider.of<ESP32Provider>(context, listen: false);
    await esp32.startMeasurement();
    setState(() => _isMeasuring = true);
  }

  Future<void> _stopMeasurement() async {
    final esp32 = Provider.of<ESP32Provider>(context, listen: false);
    await esp32.stopMeasurement();
    setState(() => _isMeasuring = false);
  }

  Future<void> _saveMeasurement() async {
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final esp32 = Provider.of<ESP32Provider>(context, listen: false);

    if (patientProvider.selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un paciente primero')),
      );
      return;
    }

    if (esp32.heartRate == 0 || esp32.spo2 == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando lecturas válidas...')),
      );
      return;
    }

    final measurement = Measurement(
      patientId: patientProvider.selectedPatient!.id!,
      heartRate: esp32.heartRate,
      spo2: esp32.spo2,
      bodyTemp: esp32.bodyTemp,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    await patientProvider.addMeasurement(measurement);
    _notesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Medición guardada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medición de Signos Vitales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_input_antenna),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<ESP32Provider, PatientProvider>(
        builder: (context, esp32, patientProvider, child) {
          if (esp32.ipAddress.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('ESP32 no configurado'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurar'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Estado de conexión
              Container(
                decoration: BoxDecoration(
                  color: esp32.isConnected 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: esp32.isConnected 
                        ? Colors.green.withOpacity(0.3) 
                        : Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: esp32.isConnected ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (esp32.isConnected ? Colors.green : Colors.red)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          esp32.isConnected ? Icons.wifi : Icons.wifi_off,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              esp32.isConnected ? 'ESP32 Conectado' : 'ESP32 Desconectado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: esp32.isConnected ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              esp32.ipAddress.isEmpty ? 'Sin configurar' : esp32.ipAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (esp32.isConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACTIVO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Paciente seleccionado
              if (patientProvider.selectedPatient != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            patientProvider.selectedPatient!.gender == 'Masculino'
                                ? Icons.man
                                : Icons.woman,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paciente',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                patientProvider.selectedPatient!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${patientProvider.selectedPatient!.age} años',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: Colors.white.withOpacity(0.9),
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Signos vitales
              _VitalCard(
                icon: Icons.favorite,
                title: 'Frecuencia Cardíaca',
                value: '${esp32.heartRate}',
                unit: 'BPM',
                color: Colors.red,
                status: _getHeartRateStatus(esp32.heartRate),
              ),
              const SizedBox(height: 12),
              _VitalCard(
                icon: Icons.air,
                title: 'Saturación de Oxígeno',
                value: '${esp32.spo2}',
                unit: '%',
                color: Colors.blue,
                status: _getSpO2Status(esp32.spo2),
              ),
              const SizedBox(height: 12),
              _VitalCard(
                icon: Icons.thermostat,
                title: 'Temperatura Corporal',
                value: esp32.bodyTemp.toStringAsFixed(1),
                unit: '°C',
                color: Colors.orange,
                status: _getTempStatus(esp32.bodyTemp),
              ),
              const SizedBox(height: 16),

              // Estado del sensor
              if (!esp32.fingerDetected && _isMeasuring)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[100]!, Colors.amber[50]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.touch_app,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Esperando dedo...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.amber,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Coloca el dedo en el sensor MAX30102',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Notas
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas de la medición',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Botones de control
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isMeasuring 
                              ? [Colors.red, Colors.red[700]!]
                              : [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_isMeasuring ? Colors.red : Theme.of(context).colorScheme.primary)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isMeasuring ? _stopMeasurement : _startMeasurement,
                        icon: Icon(_isMeasuring ? Icons.stop_circle : Icons.play_circle_filled),
                        label: Text(
                          _isMeasuring ? 'Detener' : 'Iniciar Medición',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green[700]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _saveMeasurement,
                      icon: const Icon(Icons.save_rounded, size: 24),
                      label: const Text(
                        'Guardar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _getHeartRateStatus(int hr) {
    if (hr == 0) return '';
    if (hr < 60) return 'Bradicardia';
    if (hr <= 100) return 'Normal';
    return 'Taquicardia';
  }

  String _getSpO2Status(int spo2) {
    if (spo2 == 0) return '';
    if (spo2 < 90) return 'Crítico';
    if (spo2 < 95) return 'Bajo';
    return 'Normal';
  }

  String _getTempStatus(double temp) {
    if (temp == 0) return '';
    if (temp < 36.5) return 'Baja';
    if (temp < 37.5) return 'Normal';
    if (temp < 38.0) return 'Febrícula';
    return 'Fiebre';
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color color;
  final String status;

  const _VitalCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isNormal = status == 'Normal';
    final statusColor = isNormal ? Colors.green : Colors.orange;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (status.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
