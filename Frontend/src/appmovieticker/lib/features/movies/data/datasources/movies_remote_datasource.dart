import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/movie_list_item.dart';
import '../models/movie_showtime_item.dart';
import '../models/cinema_showtime_item.dart';
import '../models/nearby_cinema_item.dart';

abstract class MoviesRemoteDataSource {
  Future<List<MovieListItem>> getNowShowingMovies();
  Future<List<MovieListItem>> getUpcomingMovies();
  Future<List<MovieListItem>> getSpecialMovies();
  Future<List<MovieListItem>> getShowingAndUpcomingMovies({int page, int sizePage});
  Future<List<NearbyCinemaItem>> getNearbyCinemas({required double latitude, required double longitude});
  Future<List<CinemaShowtimeMovieItem>> getCinemaShowtimes({required int cinemaId, DateTime? filterDate});
  Future<List<MovieShowtimeCinemaItem>> getMovieShowtimes({
    required int movieId,
    required double latitude,
    required double longitude,
    DateTime? filterDate,
  });
  Future<MovieListItem> getMovieDetail({required int movieId});
}

class MoviesRemoteDataSourceImpl implements MoviesRemoteDataSource {
  MoviesRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<List<MovieListItem>> getNowShowingMovies() {
    return _fetchMovieList(ApiConstants.movieNowShowing);
  }

  @override
  Future<List<MovieListItem>> getUpcomingMovies() {
    return _fetchMovieList(ApiConstants.movieUpcoming);
  }

  @override
  Future<List<MovieListItem>> getSpecialMovies() {
    return _fetchMovieList(ApiConstants.movieSpecial);
  }

  @override
  Future<List<MovieListItem>> getShowingAndUpcomingMovies({int page = 1, int sizePage = 12}) {
    return _fetchMovieList(
      '${ApiConstants.movieShowingAndUpcoming}?page=$page&sizePage=$sizePage',
    );
  }

  @override
  Future<List<NearbyCinemaItem>> getNearbyCinemas({required double latitude, required double longitude}) async {
    final response = await dioClient.dio.post(
      ApiConstants.cinemaNearby,
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return _parseList(response.data, NearbyCinemaItem.fromJson);
  }

  @override
  Future<List<CinemaShowtimeMovieItem>> getCinemaShowtimes({required int cinemaId, DateTime? filterDate}) async {
    final response = await dioClient.dio.get(
      '/CinemaPub/$cinemaId/showtimes',
      queryParameters: {
        if (filterDate != null) 'filterDate': _formatDateOnly(filterDate),
      },
    );

    return _parseList(response.data, CinemaShowtimeMovieItem.fromJson);
  }

  @override
  Future<List<MovieShowtimeCinemaItem>> getMovieShowtimes({
    required int movieId,
    required double latitude,
    required double longitude,
    DateTime? filterDate,
  }) async {
    final response = await dioClient.dio.post(
      ApiConstants.cinemaMovieShowtimes,
      queryParameters: {
        if (filterDate != null) 'filterDate': _formatDateOnly(filterDate),
      },
      data: {
        'movieId': movieId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return _parseList(response.data, MovieShowtimeCinemaItem.fromJson);
  }

  @override
  Future<MovieListItem> getMovieDetail({required int movieId}) async {
    final response = await dioClient.dio.get('${ApiConstants.movieDetail}/$movieId');

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MovieListItem.fromJson(data);
    }

    final list = _parseList(data, MovieListItem.fromJson);
    if (list.isNotEmpty) {
      return list.first;
    }

    throw Exception('Khong tim thay chi tiet phim #$movieId');
  }

  Future<List<MovieListItem>> _fetchMovieList(String path) async {
    final response = await dioClient.dio.get(path);
    return _parseList(response.data, MovieListItem.fromJson);
  }

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    final rawList = _extractList(data);
    return rawList
        .whereType<Map>()
        .map((item) => fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'result', r'$values', 'value']) {
        final nested = data[key];
        final nestedList = _extractList(nested);
        if (nestedList.isNotEmpty) {
          return nestedList;
        }
      }
    }

    return const [];
  }

  String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}