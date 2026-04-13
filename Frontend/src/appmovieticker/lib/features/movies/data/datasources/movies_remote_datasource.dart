import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/movie_list_item.dart';
import '../models/nearby_cinema_item.dart';

abstract class MoviesRemoteDataSource {
  Future<List<MovieListItem>> getNowShowingMovies();
  Future<List<MovieListItem>> getUpcomingMovies();
  Future<List<MovieListItem>> getSpecialMovies();
  Future<List<MovieListItem>> getShowingAndUpcomingMovies({int page, int sizePage});
  Future<List<NearbyCinemaItem>> getNearbyCinemas({required double latitude, required double longitude});
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
}