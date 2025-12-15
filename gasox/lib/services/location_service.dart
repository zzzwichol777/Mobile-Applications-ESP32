import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  bool _isLocationEnabled = false;

  Position? get lastKnownPosition => _lastKnownPosition;
  bool get isLocationEnabled => _isLocationEnabled;

  /// Inicializa el servicio de ubicación y solicita permisos
  Future<bool> initialize() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return false;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return false;
      }

      _isLocationEnabled = true;
      await _getCurrentLocation();
      return true;
    } catch (e) {
      print('Error initializing location service: $e');
      return false;
    }
  }

  /// Obtiene la ubicación actual
  Future<Position?> _getCurrentLocation() async {
    try {
      if (!_isLocationEnabled) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Actualiza la ubicación actual
  Future<Position?> updateLocation() async {
    return await _getCurrentLocation();
  }

  /// Obtiene la dirección aproximada basada en coordenadas
  String getLocationString() {
    if (_lastKnownPosition == null) return 'Ubicación no disponible';

    return 'Lat: ${_lastKnownPosition!.latitude.toStringAsFixed(6)}, '
        'Lng: ${_lastKnownPosition!.longitude.toStringAsFixed(6)}';
  }

  /// Obtiene información detallada de la ubicación
  Map<String, dynamic> getLocationData() {
    if (_lastKnownPosition == null) {
      return {
        'available': false,
        'latitude': null,
        'longitude': null,
        'accuracy': null,
        'timestamp': null,
      };
    }

    return {
      'available': true,
      'latitude': _lastKnownPosition!.latitude,
      'longitude': _lastKnownPosition!.longitude,
      'accuracy': _lastKnownPosition!.accuracy,
      'timestamp': _lastKnownPosition!.timestamp,
    };
  }

  /// Calcula la distancia entre dos puntos
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
