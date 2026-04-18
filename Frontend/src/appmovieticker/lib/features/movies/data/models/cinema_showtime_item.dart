class CinemaShowtimeMovieItem {
  const CinemaShowtimeMovieItem({
    required this.movieId,
    required this.movieTitle,
    required this.imageUrl,
    required this.movieAge,
    required this.movieGenre,
    required this.movieRuntime,
    required this.showtimes,
  });

  final int movieId;
  final String movieTitle;
  final String imageUrl;
  final String movieAge;
  final String movieGenre;
  final int? movieRuntime;
  final List<CinemaShowtimeDetailItem> showtimes;

  factory CinemaShowtimeMovieItem.fromJson(Map<String, dynamic> json) {
    final showtimesData = json['showtimes'] ?? json['Showtimes'];
    return CinemaShowtimeMovieItem(
      movieId: _readInt(json['movieId'] ?? json['MovieId']),
      movieTitle: _readString(json['movieTitle'] ?? json['MovieTitle']),
      imageUrl: _readString(json['imageUrl'] ?? json['ImageUrl']),
      movieAge: _readString(json['movieAge'] ?? json['MovieAge']),
      movieGenre: _readString(json['movieGenre'] ?? json['MovieGenre']),
      movieRuntime: _readNullableInt(json['movieRuntime'] ?? json['MovieRuntime']),
      showtimes: _readShowtimes(showtimesData),
    );
  }

  static List<CinemaShowtimeDetailItem> _readShowtimes(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => CinemaShowtimeDetailItem.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }
}

class CinemaShowtimeDetailItem {
  const CinemaShowtimeDetailItem({
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

  factory CinemaShowtimeDetailItem.fromJson(Map<String, dynamic> json) {
    return CinemaShowtimeDetailItem(
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