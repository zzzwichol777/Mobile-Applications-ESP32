import 'sensor_reading.dart';

class SensorReadingWithLocationFields extends SensorReadingFields {
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String locationAccuracy = 'location_accuracy';
  static const String hasLocation = 'has_location';

  static const List<String> allValues = [
    ...SensorReadingFields.values,
    latitude,
    longitude,
    locationAccuracy,
    hasLocation
  ];
}

class SensorReadingWithLocation extends SensorReading {
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final bool hasLocation;

  const SensorReadingWithLocation({
    super.id,
    required super.timestamp,
    required super.mq4Value,
    required super.mq7Value,
    required super.isHighReading,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.hasLocation = false,
  });

  @override
  SensorReadingWithLocation copy({
    int? id,
    DateTime? timestamp,
    int? mq4Value,
    int? mq7Value,
    bool? isHighReading,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    bool? hasLocation,
  }) =>
      SensorReadingWithLocation(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        mq4Value: mq4Value ?? this.mq4Value,
        mq7Value: mq7Value ?? this.mq7Value,
        isHighReading: isHighReading ?? this.isHighReading,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        locationAccuracy: locationAccuracy ?? this.locationAccuracy,
        hasLocation: hasLocation ?? this.hasLocation,
      );

  static SensorReadingWithLocation fromJson(Map<String, Object?> json) =>
      SensorReadingWithLocation(
        id: json[SensorReadingFields.id] as int?,
        timestamp:
            DateTime.parse(json[SensorReadingFields.timestamp] as String),
        mq4Value: json[SensorReadingFields.mq4Value] as int,
        mq7Value: json[SensorReadingFields.mq7Value] as int,
        isHighReading: json[SensorReadingFields.isHighReading] == 1,
        latitude: json[SensorReadingWithLocationFields.latitude] as double?,
        longitude: json[SensorReadingWithLocationFields.longitude] as double?,
        locationAccuracy:
            json[SensorReadingWithLocationFields.locationAccuracy] as double?,
        hasLocation: json[SensorReadingWithLocationFields.hasLocation] == 1,
      );

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
        SensorReadingWithLocationFields.latitude: latitude,
        SensorReadingWithLocationFields.longitude: longitude,
        SensorReadingWithLocationFields.locationAccuracy: locationAccuracy,
        SensorReadingWithLocationFields.hasLocation: hasLocation ? 1 : 0,
      };

  String getLocationString() {
    if (!hasLocation || latitude == null || longitude == null) {
      return 'Sin ubicación';
    }
    return 'Lat: ${latitude!.toStringAsFixed(6)}, Lng: ${longitude!.toStringAsFixed(6)}';
  }
}
