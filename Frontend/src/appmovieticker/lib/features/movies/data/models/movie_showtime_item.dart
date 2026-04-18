class MovieShowtimeCinemaItem {
  const MovieShowtimeCinemaItem({
    required this.cinemaId,
    required this.cinemaName,
    required this.cityAddress,
    required this.distanceInKm,
    required this.showtimes,
  });

  final int cinemaId;
  final String cinemaName;
  final String cityAddress;
  final double distanceInKm;
  final List<MovieShowtimeItem> showtimes;

  factory MovieShowtimeCinemaItem.fromJson(Map<String, dynamic> json) {
    final showtimeData = json['showtimes'] ?? json['Showtimes'];
    return MovieShowtimeCinemaItem(
      cinemaId: _readInt(json['cinemaId'] ?? json['CinemaId']),
      cinemaName: _readString(json['cinemaName'] ?? json['CinemaName']),
      cityAddress: _readString(json['cityAddress'] ?? json['CityAddress']),
      distanceInKm: _readDouble(json['distanceInKm'] ?? json['DistanceInKm']),
      showtimes: _readShowtimes(showtimeData),
    );
  }

  static List<MovieShowtimeItem> _readShowtimes(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => MovieShowtimeItem.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return const [];
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

class MovieShowtimeItem {
  const MovieShowtimeItem({
    required this.showId,
    required this.showDate,
    required this.startTime,
    required this.endTime,
    required this.cinemaHallId,
    required this.hallName,
    required this.experienceType,
  });

  final int showId;
  final DateTime? showDate;
  final String startTime;
  final String endTime;
  final int cinemaHallId;
  final String hallName;
  final String experienceType;

  factory MovieShowtimeItem.fromJson(Map<String, dynamic> json) {
    return MovieShowtimeItem(
      showId: _readInt(json['showId'] ?? json['ShowId']),
      showDate: _readDate(json['showDate'] ?? json['ShowDate']),
      startTime: _readString(json['startTime'] ?? json['StartTime']),
      endTime: _readString(json['endTime'] ?? json['EndTime']),
      cinemaHallId: _readInt(json['cinemaHallId'] ?? json['CinemaHallId']),
      hallName: _readString(json['hallName'] ?? json['HallName']),
      experienceType: _readString(json['experienceType'] ?? json['ExperienceType']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}