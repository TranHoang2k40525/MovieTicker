import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import '../../core/constants/api_constants.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';

class DioClient {
  final AuthLocalDataSource localDataSource;
  late final Dio dio;
  bool _refreshingToken = false;

  DioClient({required this.localDataSource}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (dio.httpClientAdapter is IOHttpClientAdapter) {
      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      adapter.createHttpClient = () {
        final client = HttpClient();
        // Support local development certificate on localhost.
        client.badCertificateCallback = (cert, host, port) {
          return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2' || host == '192.168.0.149';
        };
        return client;
      };
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await localDataSource.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final requestPath = error.requestOptions.path;
          if (requestPath.contains(ApiConstants.login) ||
              requestPath.contains(ApiConstants.refreshToken)) {
            return handler.next(error);
          }

          if (_refreshingToken) {
            return handler.next(error);
          }

          _refreshingToken = true;
          try {
            final refreshed = await _tryRefreshToken();
            if (!refreshed) {
              await localDataSource.clearToken();
              return handler.next(error);
            }

            final newToken = await localDataSource.getToken();
            if (newToken == null || newToken.isEmpty) {
              return handler.next(error);
            }

            final requestOptions = error.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await dio.fetch(requestOptions);
            return handler.resolve(retryResponse);
          } catch (_) {
            await localDataSource.clearToken();
            return handler.next(error);
          } finally {
            _refreshingToken = false;
          }
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await localDataSource.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (refreshDio.httpClientAdapter is IOHttpClientAdapter) {
      final adapter = refreshDio.httpClientAdapter as IOHttpClientAdapter;
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2' || host == '192.168.0.149';
        };
        return client;
      };
    }

    final response = await refreshDio.post(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    final dynamic raw = response.data;
    if (raw is! Map<String, dynamic>) {
      return false;
    }

    final success = raw['success'] == true;
    if (!success) {
      return false;
    }

    final dynamic data = raw['data'];
    if (data is! Map<String, dynamic>) {
      return false;
    }

    final access = data['accessToken'] ?? data['AccessToken'];
    if (access is! String || access.isEmpty) {
      return false;
    }
    await localDataSource.cacheToken(access);

    final maybeRefresh = data['refreshToken'] ?? data['RefreshToken'];
    if (maybeRefresh is String && maybeRefresh.isNotEmpty) {
      await localDataSource.cacheRefreshToken(maybeRefresh);
    }

    return true;
  }
}
