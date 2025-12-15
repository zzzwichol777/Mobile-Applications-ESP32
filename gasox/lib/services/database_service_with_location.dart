import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_reading.dart';
import '../models/sensor_reading_with_location.dart';

class DatabaseServiceWithLocation {
  static final DatabaseServiceWithLocation instance =
      DatabaseServiceWithLocation._init();
  static Database? _database;

  DatabaseServiceWithLocation._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gasox_readings_with_location.db');
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
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const realType = 'REAL';

    await db.execute('''
      CREATE TABLE ${SensorReadingFields.tableName}_with_location (
        ${SensorReadingFields.id} $idType,
        ${SensorReadingFields.timestamp} $textType,
        ${SensorReadingFields.mq4Value} $integerType,
        ${SensorReadingFields.mq7Value} $integerType,
        ${SensorReadingFields.isHighReading} $boolType,
        ${SensorReadingWithLocationFields.latitude} $realType,
        ${SensorReadingWithLocationFields.longitude} $realType,
        ${SensorReadingWithLocationFields.locationAccuracy} $realType,
        ${SensorReadingWithLocationFields.hasLocation} $boolType
      )
    ''');
  }

  Future<int> insertReadingWithLocation(
      SensorReadingWithLocation reading) async {
    final db = await instance.database;
    return await db.insert(
        '${SensorReadingFields.tableName}_with_location', reading.toJson());
  }

  Future<List<SensorReadingWithLocation>> getAllReadingsWithLocation() async {
    final db = await instance.database;
    const orderBy = '${SensorReadingFields.timestamp} DESC';

    final result = await db.query(
      '${SensorReadingFields.tableName}_with_location',
      orderBy: orderBy,
    );

    return result
        .map((json) => SensorReadingWithLocation.fromJson(json))
        .toList();
  }

  Future<List<SensorReadingWithLocation>> getHighReadingsWithLocation() async {
    final db = await instance.database;
    const orderBy = '${SensorReadingFields.timestamp} DESC';

    final result = await db.query(
      '${SensorReadingFields.tableName}_with_location',
      where: '${SensorReadingFields.isHighReading} = ?',
      whereArgs: [1],
      orderBy: orderBy,
    );

    return result
        .map((json) => SensorReadingWithLocation.fromJson(json))
        .toList();
  }

  Future<List<SensorReadingWithLocation>> getReadingsWithLocation() async {
    final db = await instance.database;
    const orderBy = '${SensorReadingFields.timestamp} DESC';

    final result = await db.query(
      '${SensorReadingFields.tableName}_with_location',
      where: '${SensorReadingWithLocationFields.hasLocation} = ?',
      whereArgs: [1],
      orderBy: orderBy,
    );

    return result
        .map((json) => SensorReadingWithLocation.fromJson(json))
        .toList();
  }

  Future<int> deleteReadingWithLocation(int id) async {
    final db = await instance.database;
    return await db.delete(
      '${SensorReadingFields.tableName}_with_location',
      where: '${SensorReadingFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllReadingsWithLocation() async {
    final db = await instance.database;
    await db.delete('${SensorReadingFields.tableName}_with_location');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
