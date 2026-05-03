import 'package:appmovieticker/core/network/dio_client.dart';

abstract class PaymentRemoteDataSource {
  Future<Map<String, dynamic>> preview({required int holdId, String? voucherCode});
  Future<List<dynamic>> getVouchers();
  Future<Map<String, dynamic>> getVoucherDetail(String code);
  Future<Map<String, dynamic>> mockMomoSuccess({required int holdId, String? voucherCode});
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<Map<String, dynamic>> preview({required int holdId, String? voucherCode}) async {
    final response = await _postWithFallback(
      primaryPath: '/payments/preview',
      fallbackPath: '/checkout/preview',
      data: {
        'holdId': holdId,
        if (voucherCode != null && voucherCode.isNotEmpty) 'voucherCode': voucherCode,
      },
    );

    return _unwrapPayload(response.data);
  }

  @override
  Future<List<dynamic>> getVouchers() async {
    final response = await _getWithFallback(
      primaryPath: '/payments/vouchers',
      fallbackPath: '/checkout/vouchers',
    );

    return _extractList(_unwrapPayload(response.data));
  }

  @override
  Future<Map<String, dynamic>> getVoucherDetail(String code) async {
    final response = await _getWithFallback(
      primaryPath: '/payments/vouchers/$code',
      fallbackPath: '/checkout/vouchers/$code',
    );

    return _unwrapPayload(response.data);
  }

  @override
  Future<Map<String, dynamic>> mockMomoSuccess({required int holdId, String? voucherCode}) async {
    final response = await _postWithFallback(
      primaryPath: '/payments/momo/mock-success',
      fallbackPath: '/checkout/payments/momo/mock-success',
      data: {
        'holdId': holdId,
        if (voucherCode != null && voucherCode.isNotEmpty) 'voucherCode': voucherCode,
        'paymentMethod': 'momo_mock',
      },
    );

    return _unwrapPayload(response.data);
  }

  Future<dynamic> _postWithFallback({
    required String primaryPath,
    required String fallbackPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await dioClient.dio.post(primaryPath, data: data);
    } catch (_) {
      return dioClient.dio.post(fallbackPath, data: data);
    }
  }

  Future<dynamic> _getWithFallback({
    required String primaryPath,
    required String fallbackPath,
  }) async {
    try {
      return await dioClient.dio.get(primaryPath);
    } catch (_) {
      return dioClient.dio.get(fallbackPath);
    }
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
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['items'] ?? data['result'] ?? data['value'] ?? data[r'$values'];
      if (nested is List) {
        return nested;
      }
    }

    return const [];
  }
}
