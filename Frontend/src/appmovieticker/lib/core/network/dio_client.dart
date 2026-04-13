import 'package:dio/dio.dart';
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

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await localDataSource.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer \$token';
          }
          return handler.next(options);
        },
      ),
    );
  }
}
