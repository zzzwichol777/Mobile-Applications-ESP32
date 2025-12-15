import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/patient_provider.dart';
import '../models/measurement.dart';
import 'add_patient_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientProvider>(
      builder: (context, provider, child) {
        final patient = provider.selectedPatient!;
        final measurements = provider.measurements;

        return Scaffold(
          appBar: AppBar(
            title: Text(patient.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPatientScreen(patient: patient),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar paciente'),
                      content: const Text('¿Estás seguro? Se eliminarán todos los registros.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await provider.deletePatient(patient.id!);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Información del paciente
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          patient.gender == 'Masculino' ? Icons.man : Icons.woman,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        patient.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('${patient.age} años • ${patient.gender}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (patient.height != null)
                            _InfoChip(
                              icon: Icons.height,
                              label: '${patient.height!.toStringAsFixed(0)} cm',
                            ),
                          if (patient.weight != null)
                            _InfoChip(
                              icon: Icons.monitor_weight,
                              label: '${patient.weight!.toStringAsFixed(1)} kg',
                            ),
                          if (patient.bloodType != null)
                            _InfoChip(
                              icon: Icons.bloodtype,
                              label: patient.bloodType!,
                            ),
                        ],
                      ),
                      if (patient.bmi != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'IMC: ${patient.bmi!.toStringAsFixed(1)} - ${patient.bmiCategory}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (patient.allergies != null) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Alergias: ${patient.allergies}',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (patient.notes != null) ...[
                        const Divider(height: 32),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Notas: ${patient.notes}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Historial de mediciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historial de Mediciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${measurements.length} registros',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (measurements.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.monitor_heart_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Sin mediciones registradas',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...measurements.map((m) => _MeasurementCard(
                      measurement: m,
                      patient: patient,
                      onDelete: () async {
                        await provider.deleteMeasurement(m.id!);
                      },
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final patient;
  final VoidCallback onDelete;

  const _MeasurementCard({
    required this.measurement,
    required this.patient,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatientProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          measurement.isAbnormal ? Icons.warning_amber : Icons.check_circle,
          color: measurement.isAbnormal ? Colors.orange : Colors.green,
        ),
        title: Text(DateFormat('dd/MM/yyyy HH:mm').format(measurement.timestamp)),
        subtitle: Text(
          '${measurement.heartRate} BPM • ${measurement.spo2}% • ${measurement.bodyTemp.toStringAsFixed(1)}°C',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _VitalInfo(
                      icon: Icons.favorite,
                      label: 'FC',
                      value: '${measurement.heartRate}',
                      unit: 'BPM',
                      status: measurement.heartRateStatus,
                    ),
                    _VitalInfo(
                      icon: Icons.air,
                      label: 'SpO2',
                      value: '${measurement.spo2}',
                      unit: '%',
                      status: measurement.spo2Status,
                    ),
                    _VitalInfo(
                      icon: Icons.thermostat,
                      label: 'Temp',
                      value: measurement.bodyTemp.toStringAsFixed(1),
                      unit: '°C',
                      status: measurement.tempStatus,
                    ),
                  ],
                ),
                if (measurement.notes != null) ...[
                  const Divider(height: 24),
                  Text(
                    'Notas: ${measurement.notes}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const Divider(height: 24),
                const Text(
                  'Diagnóstico Automático:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    provider.getDiagnosis(measurement, patient),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar medición'),
                          content: const Text('¿Estás seguro?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) onDelete();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String status;

  const _VitalInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          '$value $unit',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 10,
            color: status == 'Normal' ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}
