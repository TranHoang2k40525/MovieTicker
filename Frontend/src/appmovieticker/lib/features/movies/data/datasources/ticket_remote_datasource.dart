import '../../../../core/network/dio_client.dart';
import '../models/my_ticket_detail.dart';
import '../models/my_ticket_history_item.dart';
import '../models/my_ticket_item.dart';

abstract class TicketRemoteDataSource {
  Future<List<MyTicketItem>> getMyTickets();
  Future<MyTicketDetail> getTicketDetail(int bookingId);
  Future<List<MyTicketHistoryItem>> getMyTicketHistory();
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  TicketRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<List<MyTicketItem>> getMyTickets() async {
    final response = await dioClient.dio.get('/tickets/my');
    final payload = _unwrapPayload(response.data);
    final list = _extractList(payload);

    return list
        .whereType<Map>()
        .map((e) => MyTicketItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<MyTicketDetail> getTicketDetail(int bookingId) async {
    final response = await dioClient.dio.get('/tickets/my/$bookingId');
    final payload = _unwrapPayload(response.data);
    return MyTicketDetail.fromJson(payload);
  }

  @override
  Future<List<MyTicketHistoryItem>> getMyTicketHistory() async {
    final response = await dioClient.dio.get('/tickets/my/history');
    final payload = _unwrapPayload(response.data);
    final list = _extractList(payload);

    return list
        .whereType<Map>()
        .map((e) => MyTicketHistoryItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Map<String, dynamic> _unwrapPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['Data'] ?? data['result'] ?? data['Result'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    return <String, dynamic>{};
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
