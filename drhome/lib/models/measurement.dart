class Measurement {
  final int? id;
  final int patientId;
  final int heartRate;
  final int spo2;
  final double bodyTemp;
  final String? notes;
  final DateTime timestamp;

  Measurement({
    this.id,
    required this.patientId,
    required this.heartRate,
    required this.spo2,
    required this.bodyTemp,
    this.notes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'heart_rate': heartRate,
      'spo2': spo2,
      'body_temp': bodyTemp,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'],
      patientId: map['patient_id'],
      heartRate: map['heart_rate'],
      spo2: map['spo2'],
      bodyTemp: map['body_temp'],
      notes: map['notes'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String get heartRateStatus {
    if (heartRate < 60) return 'Bradicardia';
    if (heartRate <= 100) return 'Normal';
    return 'Taquicardia';
  }

  String get spo2Status {
    if (spo2 < 90) return 'Crítico';
    if (spo2 < 95) return 'Bajo';
    return 'Normal';
  }

  String get tempStatus {
    if (bodyTemp < 35.0) return 'Hipotermia';
    if (bodyTemp < 36.5) return 'Baja';
    if (bodyTemp < 37.5) return 'Normal';
    if (bodyTemp < 38.0) return 'Febrícula';
    return 'Fiebre';
  }

  bool get isAbnormal {
    return heartRate < 60 || heartRate > 100 || 
           spo2 < 95 || 
           bodyTemp < 36.5 || bodyTemp >= 37.5;
  }
}
