import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/core/network/dio_client.dart';
import 'package:appmovieticker/features/movies/payment/data/datasources/payment/payment_remote_datasource.dart';
import 'package:appmovieticker/features/movies/movie/presentation/pages/movie/movies_page.dart';
import 'package:appmovieticker/features/movies/show/presentation/pages/showtime/cinema_showtime_page.dart';
import 'package:appmovieticker/features/movies/show/presentation/pages/showtime/movie_showtime_page.dart';

class PaymentSimulationPage extends StatefulWidget {
  const PaymentSimulationPage({
    super.key,
    required this.holdId,
    required this.expiresAt,
    this.voucherCode,
    required this.payableAmount,
  });

  final int holdId;
  final DateTime expiresAt;
  final String? voucherCode;
  final double payableAmount;

  @override
  State<PaymentSimulationPage> createState() => _PaymentSimulationPageState();
}

class _PaymentSimulationPageState extends State<PaymentSimulationPage> {
  final DioClient _dioClient = di.sl<DioClient>();
  final PaymentRemoteDataSource _paymentRemoteDataSource = di.sl<PaymentRemoteDataSource>();

  bool _submitting = false;
  late DateTime _expirationTime;
  Timer? _countdownTimer;
  bool _expiredHandled = false;
  bool _holdReleased = false;
  bool _navigatingAway = false;

  @override
  void initState() {
    super.initState();
    _expirationTime = widget.expiresAt;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      if (DateTime.now().isAfter(_expirationTime)) {
        _countdownTimer?.cancel();
        _handleExpired();
        return;
      }

      setState(() {});
    });
  }

  Future<void> _handleExpired() async {
    if (!mounted || _expiredHandled || _navigatingAway) {
      return;
    }
    _expiredHandled = true;
    _navigatingAway = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hết thời gian giữ ghế'),
        titleTextStyle: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 20),
        contentTextStyle: const TextStyle(color: Color(0xFF374151), height: 1.35),
        content: const Text('Phiên giữ ghế đã hết hạn. Vui lòng chọn lại suất chiếu.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE62C2C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    await _releaseHoldSilently();
    _navigateBackToShowtime();
  }

  Future<void> _releaseHoldSilently() async {
    if (_holdReleased) {
      return;
    }

    _holdReleased = true;
    try {
      await _dioClient.dio.delete('/bookings/holds/${widget.holdId}');
    } catch (_) {
      // best effort release
    }
  }

  void _navigateBackToShowtime() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) {
      return route.settings.name == MovieShowtimePage.routeName || route.settings.name == CinemaShowtimePage.routeName;
    });
  }

  void _navigateToHome() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MoviesPage()),
      (route) => false,
    );
  }

  Future<void> _confirmCancelPayment() async {
    if (!mounted || _submitting || _navigatingAway) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy thanh toán?'),
        titleTextStyle: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 20),
        contentTextStyle: const TextStyle(color: Color(0xFF374151), height: 1.35),
        content: const Text('Nếu thoát lúc này, ghế đang giữ sẽ được trả lại ngay. Bạn có chắc chắn muốn hủy không?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục thanh toán'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE62C2C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hủy đặt vé'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) {
      return;
    }

    _navigatingAway = true;
    await _releaseHoldSilently();
    _navigateBackToShowtime();
  }

  Future<void> _simulatePayment() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    if (DateTime.now().isAfter(_expirationTime)) {
      await _handleExpired();
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      return;
    }

    try {
      final data = await _paymentRemoteDataSource.mockMomoSuccess(
        holdId: widget.holdId,
        voucherCode: widget.voucherCode,
      );

      final paidAmount = _readNum(data['paidAmount']).toDouble();
      final ticketCode = (data['ticketCode'] ?? '').toString();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thanh toán thành công'),
          titleTextStyle: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 20),
          contentTextStyle: const TextStyle(color: Color(0xFF374151), height: 1.35),
          content: Text('Mã vé: $ticketCode\nSố tiền: ${paidAmount.toStringAsFixed(0)} đ'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE62C2C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      _countdownTimer?.cancel();
      _holdReleased = true;
      _navigateToHome();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseErrorMessage(e) ?? 'Giả lập thanh toán thất bại.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giả lập thanh toán thất bại.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
    }
  }

  String? _parseErrorMessage(DioException exception) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['Message'];
      if (message != null) {
        return message.toString();
      }
    }
    return null;
  }

  num _readNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _expirationTime.difference(DateTime.now());
    final isExpired = remaining.isNegative;
    final mm = remaining.inMinutes.clamp(0, 999);
    final ss = (remaining.inSeconds % 60).clamp(0, 59);

    return WillPopScope(
      onWillPop: () async {
        await _confirmCancelPayment();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F7),
        appBar: AppBar(
          leading: IconButton(
            onPressed: _submitting ? null : _confirmCancelPayment,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Giả lập thanh toán'),
        ),
        body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isExpired ? const Color(0xFFB42318) : const Color(0xFFE63C39),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired
                        ? 'Phiên giữ ghế đã hết hạn'
                        : 'Thời gian giữ ghế còn: ${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Bạn đang ở cổng thanh toán mô phỏng (sandbox).', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text('Mã giữ ghế: ${widget.holdId}'),
                Text('Voucher: ${widget.voucherCode?.isNotEmpty == true ? widget.voucherCode : 'Không áp dụng'}'),
                const SizedBox(height: 8),
                Text('Số tiền cần thanh toán: ${widget.payableAmount.toStringAsFixed(0)} đ', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_submitting || isExpired) ? null : _simulatePayment,
                    child: Text(_submitting ? 'Đang xử lý...' : 'Giả lập thanh toán'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
