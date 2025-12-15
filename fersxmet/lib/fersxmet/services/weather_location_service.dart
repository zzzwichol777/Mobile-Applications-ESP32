import 'package:geolocator/geolocator.dart';

class WeatherLocationService {
  static final WeatherLocationService _instance = WeatherLocationService._internal();
  factory WeatherLocationService() => _instance;
  WeatherLocationService._internal();

  Position? _lastKnownPosition;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servicios de ubicación deshabilitados');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permisos de ubicación denegados');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permisos de ubicación denegados permanentemente');
        return false;
      }

      await _getCurrentLocation();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error inicializando servicio de ubicación: $e');
      return false;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  Future<Position?> updateLocation() async {
    return await _getCurrentLocation();
  }

  String getLocationString() {
    if (_lastKnownPosition == null) return 'Ubicación no disponible';

    return 'Lat: ${_lastKnownPosition!.latitude.toStringAsFixed(6)}, '
        'Lng: ${_lastKnownPosition!.longitude.toStringAsFixed(6)}';
  }

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

  bool get isLocationEnabled => _isInitialized && _lastKnownPosition != null;
}
