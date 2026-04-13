class NearbyCinemaItem {
  const NearbyCinemaItem({
    required this.cinemaId,
    required this.cinemaName,
    required this.cityAddress,
    required this.latitude,
    required this.longitude,
    required this.distanceInKm,
  });

  final int cinemaId;
  final String cinemaName;
  final String cityAddress;
  final double latitude;
  final double longitude;
  final double distanceInKm;

  factory NearbyCinemaItem.fromJson(Map<String, dynamic> json) {
    return NearbyCinemaItem(
      cinemaId: _readInt(json['cinemaId'] ?? json['CinemaId']),
      cinemaName: _readString(json['cinemaName'] ?? json['CinemaName']),
      cityAddress: _readString(json['cityAddress'] ?? json['CityAddress']),
      latitude: _readDouble(json['latitude'] ?? json['Latitude']),
      longitude: _readDouble(json['longitude'] ?? json['Longitude']),
      distanceInKm: _readDouble(json['distanceInKm'] ?? json['DistanceInKm']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }
}