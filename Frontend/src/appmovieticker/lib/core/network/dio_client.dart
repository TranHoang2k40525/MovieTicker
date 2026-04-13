import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import '../../core/constants/api_constants.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';

class DioClient {
  final AuthLocalDataSource localDataSource;
  late final Dio dio;

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
          return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
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
      ),
    );
  }
}
