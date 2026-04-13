class MovieListItem {
  const MovieListItem({
    required this.movieId,
    required this.movieTitle,
    required this.imageUrl,
    required this.movieAge,
    required this.movieGenre,
    required this.movieLanguage,
    this.movieReleaseDate,
    this.movieRuntime,
    required this.movieActor,
  });

  final int movieId;
  final String movieTitle;
  final String imageUrl;
  final DateTime? movieReleaseDate;
  final int? movieRuntime;
  final String movieAge;
  final String movieGenre;
  final String movieActor;
  final String movieLanguage;

  factory MovieListItem.fromJson(Map<String, dynamic> json) {
    return MovieListItem(
      movieId: _readInt(json['movieId'] ?? json['MovieId']),
      movieTitle: _readString(json['movieTitle'] ?? json['MovieTitle']),
      imageUrl: _readString(json['imageUrl'] ?? json['ImageUrl']),
      movieReleaseDate: _readDate(json['movieReleaseDate'] ?? json['MovieReleaseDate']),
      movieRuntime: _readNullableInt(json['movieRuntime'] ?? json['MovieRuntime']),
      movieAge: _readString(json['movieAge'] ?? json['MovieAge']),
      movieGenre: _readString(json['movieGenre'] ?? json['MovieGenre']),
      movieActor: _readString(json['movieActor'] ?? json['MovieActor']),
      movieLanguage: _readString(json['movieLanguage'] ?? json['MovieLanguage']),
    );
  }

  bool get isUpcoming {
    final releaseDate = movieReleaseDate;
    if (releaseDate == null) {
      return false;
    }
    final today = DateTime.now();
    return releaseDate.isAfter(DateTime(today.year, today.month, today.day));
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

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}