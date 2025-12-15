import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/measurement.dart';
import '../database/database_helper.dart';

class PatientProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  List<Measurement> _measurements = [];

  List<Patient> get patients => _patients;
  Patient? get selectedPatient => _selectedPatient;
  List<Measurement> get measurements => _measurements;

  Future<void> loadPatients() async {
    _patients = await _db.getAllPatients();
    notifyListeners();
  }

  Future<void> addPatient(Patient patient) async {
    final id = await _db.createPatient(patient);
    await loadPatients();
    notifyListeners();
  }

  Future<void> updatePatient(Patient patient) async {
    await _db.updatePatient(patient);
    if (_selectedPatient?.id == patient.id) {
      _selectedPatient = patient;
    }
    await loadPatients();
    notifyListeners();
  }

  Future<void> deletePatient(int id) async {
    await _db.deletePatient(id);
    if (_selectedPatient?.id == id) {
      _selectedPatient = null;
      _measurements = [];
    }
    await loadPatients();
    notifyListeners();
  }

  Future<void> selectPatient(int id) async {
    _selectedPatient = await _db.getPatient(id);
    if (_selectedPatient != null) {
      await loadMeasurements(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPatient = null;
    _measurements = [];
    notifyListeners();
  }

  Future<void> loadMeasurements(int patientId) async {
    _measurements = await _db.getPatientMeasurements(patientId);
    notifyListeners();
  }

  Future<void> addMeasurement(Measurement measurement) async {
    await _db.createMeasurement(measurement);
    await loadMeasurements(measurement.patientId);
    notifyListeners();
  }

  Future<void> deleteMeasurement(int id) async {
    await _db.deleteMeasurement(id);
    if (_selectedPatient != null) {
      await loadMeasurements(_selectedPatient!.id!);
    }
    notifyListeners();
  }

  String getDiagnosis(Measurement measurement, Patient patient) {
    List<String> findings = [];
    List<String> recommendations = [];

    // Análisis de frecuencia cardíaca
    if (measurement.heartRate < 60) {
      findings.add('Bradicardia (frecuencia cardíaca baja)');
      recommendations.add('Consultar con cardiólogo si presenta mareos o fatiga');
    } else if (measurement.heartRate > 100) {
      findings.add('Taquicardia (frecuencia cardíaca elevada)');
      recommendations.add('Evitar cafeína y estrés. Consultar si persiste');
    }

    // Análisis de SpO2
    if (measurement.spo2 < 90) {
      findings.add('Hipoxemia severa (oxigenación crítica)');
      recommendations.add('⚠️ ATENCIÓN MÉDICA URGENTE REQUERIDA');
    } else if (measurement.spo2 < 95) {
      findings.add('Saturación de oxígeno baja');
      recommendations.add('Consultar con médico. Considerar oxigenoterapia');
    }

    // Análisis de temperatura
    if (measurement.bodyTemp < 35.0) {
      findings.add('Hipotermia');
      recommendations.add('Abrigarse y buscar atención médica');
    } else if (measurement.bodyTemp >= 38.0) {
      findings.add('Fiebre');
      recommendations.add('Hidratarse, descansar y tomar antipiréticos si es necesario');
    } else if (measurement.bodyTemp >= 37.5) {
      findings.add('Febrícula (temperatura ligeramente elevada)');
      recommendations.add('Monitorear evolución y mantenerse hidratado');
    }

    // Análisis de IMC si está disponible
    if (patient.bmi != null) {
      final bmi = patient.bmi!;
      if (bmi < 18.5) {
        findings.add('Bajo peso (IMC: ${bmi.toStringAsFixed(1)})');
        recommendations.add('Consultar nutricionista para plan de alimentación');
      } else if (bmi >= 30) {
        findings.add('Obesidad (IMC: ${bmi.toStringAsFixed(1)})');
        recommendations.add('Programa de ejercicio y dieta supervisada');
      } else if (bmi >= 25) {
        findings.add('Sobrepeso (IMC: ${bmi.toStringAsFixed(1)})');
        recommendations.add('Actividad física regular y alimentación balanceada');
      }
    }

    // Diagnóstico general
    String diagnosis = '';
    
    if (findings.isEmpty) {
      diagnosis = '✅ SIGNOS VITALES NORMALES\n\n';
      diagnosis += 'Todos los parámetros se encuentran dentro de rangos saludables.\n\n';
      diagnosis += 'Recomendaciones:\n';
      diagnosis += '• Mantener hábitos saludables\n';
      diagnosis += '• Ejercicio regular\n';
      diagnosis += '• Alimentación balanceada\n';
      diagnosis += '• Chequeos médicos periódicos';
    } else {
      diagnosis = '⚠️ HALLAZGOS CLÍNICOS\n\n';
      diagnosis += 'Observaciones:\n';
      for (var finding in findings) {
        diagnosis += '• $finding\n';
      }
      diagnosis += '\nRecomendaciones:\n';
      for (var rec in recommendations) {
        diagnosis += '• $rec\n';
      }
      diagnosis += '\n⚕️ Este diagnóstico es orientativo. Consulte con un profesional de la salud.';
    }

    return diagnosis;
  }
}
