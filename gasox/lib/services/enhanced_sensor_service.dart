import '../models/sensor_reading.dart';
import '../models/sensor_reading_with_location.dart';
import 'database_service.dart';
import 'database_service_with_location.dart';
import 'location_service.dart';

class EnhancedSensorService {
  static final EnhancedSensorService _instance =
      EnhancedSensorService._internal();
  factory EnhancedSensorService() => _instance;
  EnhancedSensorService._internal();

  final LocationService _locationService = LocationService();
  bool _locationInitialized = false;

  /// Inicializa el servicio de ubicación si no está inicializado
  Future<void> _ensureLocationInitialized() async {
    if (!_locationInitialized) {
      _locationInitialized = await _locationService.initialize();
    }
  }

  /// Guarda una lectura de sensor con información de ubicación si está disponible
  Future<void> saveReadingWithLocation({
    required int mq4Value,
    required int mq7Value,
    required bool isHighReading,
    bool auto = false,
  }) async {
    await _ensureLocationInitialized();

    // Obtener ubicación actual
    final locationData = _locationService.getLocationData();

    // Crear lectura con ubicación
    final readingWithLocation = SensorReadingWithLocation(
      timestamp: DateTime.now(),
      mq4Value: mq4Value,
      mq7Value: mq7Value,
      isHighReading: isHighReading,
      latitude: locationData['latitude'],
      longitude: locationData['longitude'],
      locationAccuracy: locationData['accuracy'],
      hasLocation: locationData['available'],
    );

    // Guardar en base de datos con ubicación
    await DatabaseServiceWithLocation.instance
        .insertReadingWithLocation(readingWithLocation);

    // NOTA: No guardamos en la base de datos original para evitar duplicación
    // La base de datos con ubicación ya contiene toda la información necesaria
  }

  /// Obtiene todas las lecturas con información de ubicación
  Future<List<SensorReadingWithLocation>> getAllReadingsWithLocation() async {
    return await DatabaseServiceWithLocation.instance
        .getAllReadingsWithLocation();
  }

  /// Obtiene solo las lecturas de alarma con ubicación
  Future<List<SensorReadingWithLocation>> getHighReadingsWithLocation() async {
    return await DatabaseServiceWithLocation.instance
        .getHighReadingsWithLocation();
  }

  /// Obtiene solo las lecturas que tienen información de ubicación
  Future<List<SensorReadingWithLocation>> getReadingsWithValidLocation() async {
    return await DatabaseServiceWithLocation.instance.getReadingsWithLocation();
  }

  /// Actualiza la ubicación actual
  Future<bool> updateCurrentLocation() async {
    await _ensureLocationInitialized();
    final position = await _locationService.updateLocation();
    return position != null;
  }

  /// Obtiene el estado actual de la ubicación
  bool get isLocationEnabled => _locationService.isLocationEnabled;

  /// Obtiene la cadena de ubicación actual
  String getCurrentLocationString() => _locationService.getLocationString();

  /// Obtiene los datos completos de ubicación
  Map<String, dynamic> getCurrentLocationData() =>
      _locationService.getLocationData();

  /// Elimina una lectura específica por ID
  Future<bool> deleteReadingWithLocation(int id) async {
    try {
      final result = await DatabaseServiceWithLocation.instance
          .deleteReadingWithLocation(id);
      return result > 0;
    } catch (e) {
      print('Error eliminando lectura con ubicación: $e');
      return false;
    }
  }

  /// Elimina todas las lecturas con ubicación
  Future<bool> deleteAllReadingsWithLocation() async {
    try {
      await DatabaseServiceWithLocation.instance
          .deleteAllReadingsWithLocation();
      return true;
    } catch (e) {
      print('Error eliminando todas las lecturas con ubicación: $e');
      return false;
    }
  }
}
