import '../services/enhanced_sensor_service.dart';
import '../services/location_service.dart';
import '../widgets/location_widget.dart';
import '../screens/location_readings_screen.dart';

/// Clase de utilidades para integrar fácilmente la geolocalización en la app
class LocationIntegration {
  static final EnhancedSensorService _enhancedService = EnhancedSensorService();
  static final LocationService _locationService = LocationService();

  /// Inicializa los servicios de ubicación
  /// Llama esto en el initState de tu pantalla principal
  static Future<bool> initialize() async {
    return await _locationService.initialize();
  }

  /// Guarda una lectura de sensor con ubicación automáticamente
  /// Úsalo en lugar de DatabaseService.instance.insertReading()
  static Future<void> saveReadingWithLocation({
    required int mq4Value,
    required int mq7Value,
    required bool isHighReading,
    bool auto = false,
  }) async {
    await _enhancedService.saveReadingWithLocation(
      mq4Value: mq4Value,
      mq7Value: mq7Value,
      isHighReading: isHighReading,
      auto: auto,
    );
  }

  /// Obtiene el widget de ubicación compacto para mostrar en la UI
  /// Puedes agregarlo donde quieras mostrar la ubicación actual
  static LocationWidget getCompactLocationWidget() {
    return const LocationWidget(
      showTitle: false,
      compact: true,
    );
  }

  /// Obtiene el widget de ubicación completo
  /// Úsalo en cards o secciones dedicadas
  static LocationWidget getFullLocationWidget() {
    return const LocationWidget(
      showTitle: true,
      compact: false,
    );
  }

  /// Obtiene la pantalla de lecturas con ubicación
  /// Agrégala como una nueva opción en tu drawer
  static LocationReadingsScreen getLocationReadingsScreen() {
    return const LocationReadingsScreen();
  }

  /// Verifica si la ubicación está habilitada
  static bool get isLocationEnabled => _locationService.isLocationEnabled;

  /// Obtiene la ubicación actual como string
  static String getCurrentLocationString() {
    return _locationService.getLocationString();
  }

  /// Actualiza la ubicación actual
  static Future<bool> updateLocation() async {
    return await _enhancedService.updateCurrentLocation();
  }

  /// Obtiene los datos completos de ubicación
  static Map<String, dynamic> getCurrentLocationData() {
    return _locationService.getLocationData();
  }
}

/// Ejemplo de uso:
/// 
/// En initState():
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   LocationIntegration.initialize();
///   // ... resto de tu código
/// }
/// ```
/// 
/// Para guardar lecturas con ubicación:
/// ```dart
/// await LocationIntegration.saveReadingWithLocation(
///   mq4Value: mq4Value,
///   mq7Value: mq7Value,
///   isHighReading: isAlarmActive,
///   auto: true,
/// );
/// ```
/// 
/// Para mostrar ubicación en la UI:
/// ```dart
/// LocationIntegration.getCompactLocationWidget()
/// ```
/// 
/// Para agregar al drawer:
/// ```dart
/// ListTile(
///   leading: Icon(Icons.location_on),
///   title: Text('Lecturas con Ubicación'),
///   onTap: () {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (context) => LocationIntegration.getLocationReadingsScreen(),
///       ),
///     );
///   },
/// ),
/// ```