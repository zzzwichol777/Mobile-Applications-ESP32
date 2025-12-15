class WeatherReadingFields {
  static const String tableName = 'weather_readings';
  static const String id = 'id';
  static const String timestamp = 'timestamp';
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String luminosity = 'luminosity';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String locationAccuracy = 'location_accuracy';
  static const String hasLocation = 'has_location';
}

class WeatherReading {
  final int? id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double luminosity;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final bool hasLocation;

  WeatherReading({
    this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.luminosity,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.hasLocation = false,
  });

  WeatherReading copy({
    int? id,
    DateTime? timestamp,
    double? temperature,
    double? humidity,
    double? luminosity,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    bool? hasLocation,
  }) =>
      WeatherReading(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        temperature: temperature ?? this.temperature,
        humidity: humidity ?? this.humidity,
        luminosity: luminosity ?? this.luminosity,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        locationAccuracy: locationAccuracy ?? this.locationAccuracy,
        hasLocation: hasLocation ?? this.hasLocation,
      );

  static WeatherReading fromJson(Map<String, Object?> json) => WeatherReading(
        id: json[WeatherReadingFields.id] as int?,
        timestamp: DateTime.parse(json[WeatherReadingFields.timestamp] as String),
        temperature: json[WeatherReadingFields.temperature] as double,
        humidity: json[WeatherReadingFields.humidity] as double,
        luminosity: json[WeatherReadingFields.luminosity] as double,
        latitude: json[WeatherReadingFields.latitude] as double?,
        longitude: json[WeatherReadingFields.longitude] as double?,
        locationAccuracy: json[WeatherReadingFields.locationAccuracy] as double?,
        hasLocation: json[WeatherReadingFields.hasLocation] == 1,
      );

  Map<String, Object?> toJson() => {
        WeatherReadingFields.id: id,
        WeatherReadingFields.timestamp: timestamp.toIso8601String(),
        WeatherReadingFields.temperature: temperature,
        WeatherReadingFields.humidity: humidity,
        WeatherReadingFields.luminosity: luminosity,
        WeatherReadingFields.latitude: latitude,
        WeatherReadingFields.longitude: longitude,
        WeatherReadingFields.locationAccuracy: locationAccuracy,
        WeatherReadingFields.hasLocation: hasLocation ? 1 : 0,
      };

  String getLocationString() {
    if (!hasLocation || latitude == null || longitude == null) {
      return 'Sin ubicación';
    }
    return 'Lat: ${latitude!.toStringAsFixed(6)}, Lng: ${longitude!.toStringAsFixed(6)}';
  }
}
