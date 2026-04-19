import '../../../../core/network/dio_client.dart';
import '../models/notification_item.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationItem>> getMyNotifications();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<List<NotificationItem>> getMyNotifications() async {
    final response = await dioClient.dio.get('/notifications/my');
    final list = _extractList(response.data);

    return list
        .whereType<Map>()
        .map((e) => NotificationItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['items'] ?? data['result'] ?? data['value'] ?? data[r'$values'];
      if (nested is List) return nested;
    }
    return const [];
  }
}
