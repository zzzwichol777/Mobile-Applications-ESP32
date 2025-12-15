import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/weather_reading.dart';

class WeatherDatabaseService {
  static final WeatherDatabaseService instance = WeatherDatabaseService._init();
  static Database? _database;

  WeatherDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('weather_readings.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${WeatherReadingFields.tableName} (
        ${WeatherReadingFields.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${WeatherReadingFields.timestamp} TEXT NOT NULL,
        ${WeatherReadingFields.temperature} REAL NOT NULL,
        ${WeatherReadingFields.humidity} REAL NOT NULL,
        ${WeatherReadingFields.luminosity} REAL NOT NULL,
        ${WeatherReadingFields.latitude} REAL,
        ${WeatherReadingFields.longitude} REAL,
        ${WeatherReadingFields.locationAccuracy} REAL,
        ${WeatherReadingFields.hasLocation} INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<WeatherReading> insertReading(WeatherReading reading) async {
    final db = await instance.database;
    final id = await db.insert(WeatherReadingFields.tableName, reading.toJson());
    return reading.copy(id: id);
  }

  Future<List<WeatherReading>> getAllReadings() async {
    final db = await instance.database;
    final result = await db.query(
      WeatherReadingFields.tableName,
      orderBy: '${WeatherReadingFields.timestamp} DESC',
    );
    return result.map((json) => WeatherReading.fromJson(json)).toList();
  }

  Future<List<WeatherReading>> getReadingsWithLocation() async {
    final db = await instance.database;
    final result = await db.query(
      WeatherReadingFields.tableName,
      where: '${WeatherReadingFields.hasLocation} = ?',
      whereArgs: [1],
      orderBy: '${WeatherReadingFields.timestamp} DESC',
    );
    return result.map((json) => WeatherReading.fromJson(json)).toList();
  }

  Future<int> deleteReading(int id) async {
    final db = await instance.database;
    return await db.delete(
      WeatherReadingFields.tableName,
      where: '${WeatherReadingFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllReadings() async {
    final db = await instance.database;
    return await db.delete(WeatherReadingFields.tableName);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
