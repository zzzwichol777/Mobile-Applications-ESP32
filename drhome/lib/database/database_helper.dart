import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/measurement.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('drhome.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL,
        weight REAL,
        blood_type TEXT,
        allergies TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        heart_rate INTEGER NOT NULL,
        spo2 INTEGER NOT NULL,
        body_temp REAL NOT NULL,
        notes TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');
  }

  // CRUD Pacientes
  Future<int> createPatient(Patient patient) async {
    final db = await database;
    return await db.insert('patients', patient.toMap());
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final result = await db.query('patients', orderBy: 'name ASC');
    return result.map((map) => Patient.fromMap(map)).toList();
  }

  Future<Patient?> getPatient(int id) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await database;
    return await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Mediciones
  Future<int> createMeasurement(Measurement measurement) async {
    final db = await database;
    return await db.insert('measurements', measurement.toMap());
  }

  Future<List<Measurement>> getPatientMeasurements(int patientId) async {
    final db = await database;
    final result = await db.query(
      'measurements',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => Measurement.fromMap(map)).toList();
  }

  Future<List<Measurement>> getRecentMeasurements(int patientId, int limit) async {
    final db = await database;
    final result = await db.query(
      'measurements',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((map) => Measurement.fromMap(map)).toList();
  }

  Future<int> deleteMeasurement(int id) async {
    final db = await database;
    return await db.delete(
      'measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getMeasurementCount(int patientId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM measurements WHERE patient_id = ?',
      [patientId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
