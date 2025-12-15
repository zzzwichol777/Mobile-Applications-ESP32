class Patient {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final double? height;
  final double? weight;
  final String? bloodType;
  final String? allergies;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.height,
    this.weight,
    this.bloodType,
    this.allergies,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'blood_type': bloodType,
      'allergies': allergies,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      height: map['height'],
      weight: map['weight'],
      bloodType: map['blood_type'],
      allergies: map['allergies'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? bloodType,
    String? allergies,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'N/A';
    if (bmiValue < 18.5) return 'Bajo peso';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Sobrepeso';
    return 'Obesidad';
  }
}
