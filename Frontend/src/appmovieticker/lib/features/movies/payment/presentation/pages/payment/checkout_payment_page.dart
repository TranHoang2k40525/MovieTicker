import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/core/constants/api_constants.dart';
import 'package:appmovieticker/core/network/dio_client.dart';
import 'package:appmovieticker/features/movies/payment/data/datasources/payment/payment_remote_datasource.dart';
import 'package:appmovieticker/features/movies/product/data/models/product/product_item.dart';
import 'package:appmovieticker/features/movies/show/presentation/pages/showtime/cinema_showtime_page.dart';
import 'package:appmovieticker/features/movies/show/presentation/pages/showtime/movie_showtime_page.dart';
import 'payment_simulation_page.dart';

class CheckoutPaymentPage extends StatefulWidget {
  const CheckoutPaymentPage({
    super.key,
    required this.holdId,
    required this.expiresAt,
    required this.movieTitle,
    this.moviePosterUrl,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.selectedSeats,
    required this.selectedSeatTotalPrice,
    required this.products,
    required this.initialQuantities,
  });

  final int holdId;
  final DateTime expiresAt;
  final String movieTitle;
  final String? moviePosterUrl;
  final String cinemaName;
  final String cinemaAddress;
  final List<String> selectedSeats;
  final double selectedSeatTotalPrice;
  final List<ProductItem> products;
  final Map<int, int> initialQuantities;

  @override
  State<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends State<CheckoutPaymentPage> {
  final DioClient _dioClient = di.sl<DioClient>();
  final PaymentRemoteDataSource _paymentRemoteDataSource = di.sl<PaymentRemoteDataSource>();

  late Map<int, int> _selectedQuantities;
  _CheckoutPreviewData? _preview;
  List<_VoucherItem> _vouchers = const [];
  String? _appliedVoucherCode;

  bool _loading = true;
  bool _submitting = false;
  bool _syncingCombo = false;
  bool _holdReleased = false;
  bool _navigatingAway = false;
  late DateTime _expirationTime;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _expirationTime = widget.expiresAt;
    _selectedQuantities = Map<int, int>.from(widget.initialQuantities);
    _initializePage();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      final expired = DateTime.now().isAfter(_expirationTime);
      if (expired) {
        _countdownTimer?.cancel();
        _handleHoldExpired();
        return;
      }

      setState(() {});
    });
  }

  Future<void> _initializePage() async {
    setState(() {
      _loading = true;
    });

    try {
      await _loadPreview(voucherCode: _appliedVoucherCode);
    } on DioException catch (e) {
      final handled = await _handleDioError(
        e,
        fallbackMessage: 'Không thể đồng bộ thông tin thanh toán.',
        navigateOnHoldExpired: true,
      );
      if (handled == false) {
        _showSnack('Không thể đồng bộ thông tin thanh toán.');
      }
    } catch (_) {
      _showSnack('Không thể đồng bộ thông tin thanh toán.');
    }

    try {
      await _loadVouchers();
    } on DioException catch (e) {
      await _handleDioError(
        e,
        fallbackMessage: 'Không tải được danh sách voucher.',
        navigateOnHoldExpired: true,
      );
    } catch (_) {
      _showSnack('Không tải được danh sách voucher.');
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _syncComboAndPreview() async {
    await _confirmSelectedCombos();
    await _loadPreview(voucherCode: _appliedVoucherCode);
  }

  Future<void> _confirmSelectedCombos() async {
    final selectedProducts = _selectedQuantities.entries
        .where((e) => e.value > 0)
        .map((e) => {
              'productId': e.key,
              'quantity': e.value,
            })
        .toList();

    await _dioClient.dio.post(
      '/bookings/holds/confirm',
      data: {
        'holdId': widget.holdId,
        'products': selectedProducts,
      },
    );
  }

  Future<void> _loadPreview({String? voucherCode}) async {
    final payload = await _paymentRemoteDataSource.preview(
      holdId: widget.holdId,
      voucherCode: voucherCode,
    );

    setState(() {
      _preview = _CheckoutPreviewData.fromJson(payload);
    });
  }

  Future<void> _loadVouchers() async {
    final list = await _paymentRemoteDataSource.getVouchers();
    final vouchers = list
        .whereType<Map>()
        .map((item) => _VoucherItem.fromJson(item.cast<String, dynamic>()))
        .toList();

    if (!mounted) return;
    setState(() {
      _vouchers = vouchers;
    });
  }

  Future<void> _changeComboQuantity(int productId, int delta) async {
    final current = _selectedQuantities[productId] ?? 0;
    final next = (current + delta).clamp(0, 99);
    if (current == next) {
      return;
    }

    setState(() {
      _selectedQuantities[productId] = next;
      _syncingCombo = true;
    });

    try {
      await _syncComboAndPreview();
    } on DioException catch (e) {
      await _handleDioError(
        e,
        fallbackMessage: 'Không thể cập nhật combo.',
        navigateOnHoldExpired: true,
      );
    } catch (_) {
      _showSnack('Không thể cập nhật combo.');
    }

    if (!mounted) return;
    setState(() {
      _syncingCombo = false;
    });
  }

  Future<void> _openVoucherPicker() async {
    if (_vouchers.isEmpty) {
      _showSnack('Hiện chưa có voucher khả dụng.');
      return;
    }

    final pickedCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final scale = _uiScale(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(14 * scale, 14 * scale, 14 * scale, 22 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn voucher',
                  style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 10 * scale),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.52),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _vouchers.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
                    itemBuilder: (context, index) {
                      final voucher = _vouchers[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(10 * scale),
                          border: Border.all(color: const Color(0xFFE3E3E3)),
                        ),
                        child: ListTile(
                          title: Text(voucher.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13 * scale)),
                          subtitle: Text(voucher.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: TextButton(
                            onPressed: () => Navigator.of(context).pop(voucher.code),
                            child: const Text('Áp dụng'),
                          ),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await _showVoucherDetail(voucher.code);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (pickedCode == null || pickedCode.isEmpty) {
      return;
    }

    setState(() {
      _appliedVoucherCode = pickedCode;
      _loading = true;
    });

    try {
      await _loadPreview(voucherCode: pickedCode);
    } on DioException catch (e) {
      await _handleDioError(
        e,
        fallbackMessage: 'Không thể áp voucher.',
        navigateOnHoldExpired: true,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showVoucherDetail(String code) async {
    try {
      final dto = _VoucherItem.fromJson(await _paymentRemoteDataSource.getVoucherDetail(code));
      if (!mounted) return;

      final scale = _uiScale(context);
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(dto.title),
          titleTextStyle: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dto.description, style: TextStyle(fontSize: 12 * scale)),
              SizedBox(height: 8 * scale),
              Text('Mã: ${dto.code}', style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.w700)),
              Text('Giảm: ${_formatCurrency(dto.discountValue)}', style: TextStyle(fontSize: 11 * scale)),
            ],
          ),
          contentTextStyle: TextStyle(color: const Color(0xFF374151), fontSize: 12 * scale, height: 1.35),
          actionsPadding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 16 * scale),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE62C2C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _appliedVoucherCode = dto.code;
                  _loading = true;
                });
                _loadPreview(voucherCode: dto.code).whenComplete(() {
                  if (!mounted) return;
                  setState(() {
                    _loading = false;
                  });
                });
              },
              child: const Text('Dùng voucher này'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      await _handleDioError(
        e,
        fallbackMessage: 'Không lấy được chi tiết voucher.',
        navigateOnHoldExpired: true,
      );
    }
  }

  Future<void> _goToSimulationPayment(double grandTotal) async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final paid = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => PaymentSimulationPage(
            holdId: widget.holdId,
            expiresAt: _expirationTime,
            voucherCode: _appliedVoucherCode,
            payableAmount: grandTotal,
          ),
        ),
      );

      if (!mounted) return;
      if (paid == true) {
        _holdReleased = true;
        Navigator.of(context).pop(true);
        return;
      }

      if (paid == 'hold_expired') {
        await _handleHoldExpired();
      }
    } on DioException catch (e) {
      await _handleDioError(
        e,
        fallbackMessage: 'Thanh toán thất bại.',
        navigateOnHoldExpired: true,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
    final preview = _preview;

    final seatTotal = preview?.seatTotal ?? widget.selectedSeatTotalPrice;
    final comboTotal = preview?.comboTotal ?? _localComboTotal();
    final subTotal = preview?.subTotalBeforeDiscount ?? (seatTotal + comboTotal);
    final voucherDiscount = preview?.voucherDiscount ?? 0;
    final grandTotal = preview?.grandTotal ?? subTotal;
    final remaining = _expirationTime.difference(DateTime.now());
    final isExpired = remaining.isNegative;
    final mm = remaining.inMinutes.clamp(0, 999);
    final ss = (remaining.inSeconds % 60).clamp(0, 59);

    return WillPopScope(
      onWillPop: () async {
        await _confirmCancelBooking();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE9E9E9),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 18 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4 * scale, bottom: 8 * scale),
                child: Text(
                  'thong tin thanh toán',
                  style: TextStyle(fontSize: 30 * scale / 2.4, color: const Color(0xFF4A90E2), fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 8 * scale),
                padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
                decoration: BoxDecoration(
                  color: isExpired ? const Color(0xFFB42318) : const Color(0xFFE63C39),
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Text(
                  isExpired
                      ? 'Phiên giữ ghế đã hết hạn'
                      : 'Thời gian giữ ghế còn: ${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16 * scale),
                  border: Border.all(color: const Color(0xFF555555), width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 42 * scale,
                      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _submitting ? null : _confirmCancelBooking,
                            icon: Icon(Icons.arrow_back, size: 22 * scale),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 8 * scale),
                          Text('Thanh toán', style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10 * scale, 4 * scale, 10 * scale, 10 * scale),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Poster(posterUrl: widget.moviePosterUrl, scale: scale),
                          SizedBox(width: 10 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((preview?.movieTitle.isNotEmpty == true ? preview!.movieTitle : widget.movieTitle).toUpperCase(),
                                    style: TextStyle(fontSize: 10.6 * scale, fontWeight: FontWeight.w800)),
                                SizedBox(height: 2 * scale),
                                Text(preview?.movieAge ?? 'T13', style: TextStyle(fontSize: 9 * scale, color: const Color(0xFFE62C2C))),
                                SizedBox(height: 8 * scale),
                                Text(preview?.showDateLabel ?? '-', style: TextStyle(fontSize: 10 * scale)),
                                Text(preview?.showTimeRangeLabel ?? '-', style: TextStyle(fontSize: 10 * scale)),
                                Text('Cinema: ${preview?.cinemaName.isNotEmpty == true ? preview!.cinemaName : widget.cinemaName}', style: TextStyle(fontSize: 10 * scale)),
                                Text('Seat: ${preview?.seatNumbers.join(', ') ?? widget.selectedSeats.join(', ')}', style: TextStyle(fontSize: 10 * scale)),
                                SizedBox(height: 4 * scale),
                                Text('Tổng Thanh Toán ${_formatCurrency(grandTotal)}',
                                    style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.w800, color: const Color(0xFFE62C2C), fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SectionTitle(title: 'THÔNG TIN VÉ', scale: scale),
                    _InfoRow(label: 'Số lượng', value: '${preview?.seatCount ?? widget.selectedSeats.length}', scale: scale),
                    _InfoRow(label: 'Tổng', value: _formatCurrency(seatTotal), scale: scale, bold: true),
                    _SectionTitle(title: 'Thêm Combo/ Bắp nước', scale: scale),
                    _buildComboList(scale),
                    _SectionTitle(title: 'GIẢM GIÁ', scale: scale),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 8 * scale),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _appliedVoucherCode == null ? 'Chưa áp voucher' : 'Voucher: $_appliedVoucherCode',
                              style: TextStyle(fontSize: 10.5 * scale),
                            ),
                          ),
                          TextButton(onPressed: _loading ? null : _openVoucherPicker, child: const Text('Chọn voucher')),
                        ],
                      ),
                    ),
                    _SectionTitle(title: 'TỔNG KẾT', scale: scale),
                    _InfoRow(label: 'Tổng Cộng', value: _formatCurrency(subTotal), scale: scale),
                    _InfoRow(label: 'Giảm Giá', value: _formatCurrency(voucherDiscount), scale: scale),
                    _InfoRow(label: 'Thuế quà tặng/ eGift', value: _formatCurrency(preview?.vatAmount ?? 0), scale: scale),
                    _InfoRow(label: 'Còn lại', value: _formatCurrency(grandTotal), scale: scale, bold: true),
                    _SectionTitle(title: 'THANH TOÁN', scale: scale),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10 * scale, 8 * scale, 10 * scale, 12 * scale),
                      child: Row(
                        children: [
                          Container(
                            width: 18 * scale,
                            height: 18 * scale,
                            decoration: BoxDecoration(color: const Color(0xFFDB2B77), borderRadius: BorderRadius.circular(3 * scale)),
                            alignment: Alignment.center,
                            child: Text('momo', style: TextStyle(color: Colors.white, fontSize: 7 * scale, fontWeight: FontWeight.w700)),
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(child: Text('momo', style: TextStyle(fontSize: 10.5 * scale, fontStyle: FontStyle.italic))),
                          Icon(Icons.check, color: Colors.green, size: 22 * scale),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14 * scale),
              Center(
                child: SizedBox(
                  width: 156 * scale,
                  height: 28 * scale,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE62C2C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: (_loading || _syncingCombo || _submitting)
                        ? null
                        : () => _goToSimulationPayment(grandTotal),
                    child: Text(
                      _submitting ? 'Đang chuyển...' : 'Tiếp tục',
                      style: TextStyle(fontSize: 11.5 * scale, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              if (_loading || _syncingCombo)
                Padding(
                  padding: EdgeInsets.only(top: 10 * scale),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildComboList(double scale) {
    if (widget.products.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 10 * scale),
        child: Text('Chưa chọn combo', style: TextStyle(fontSize: 10.5 * scale, color: const Color(0xFF666666))),
      );
    }

    return Column(
      children: widget.products.map((product) {
        final qty = _selectedQuantities[product.productId] ?? 0;
        return Padding(
          padding: EdgeInsets.fromLTRB(8 * scale, 8 * scale, 8 * scale, 8 * scale),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${(product.nameProduct ?? '').toUpperCase()} -${_formatCurrency((product.price ?? 0).toDouble())}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.2 * scale, fontWeight: FontWeight.w600),
                ),
              ),
              _QtyButton(icon: Icons.remove, onTap: () => _changeComboQuantity(product.productId, -1), scale: scale),
              SizedBox(width: 10 * scale),
              Text('$qty', style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.w800)),
              SizedBox(width: 10 * scale),
              _QtyButton(icon: Icons.add, onTap: () => _changeComboQuantity(product.productId, 1), scale: scale),
            ],
          ),
        );
      }).toList(),
    );
  }

  double _localComboTotal() {
    var total = 0.0;
    for (final product in widget.products) {
      final qty = _selectedQuantities[product.productId] ?? 0;
      total += (product.price ?? 0).toDouble() * qty;
    }
    return total;
  }

  String _formatCurrency(num value) {
    return '${value.toStringAsFixed(0)} đ';
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

  bool _isHoldExpiredError(DioException exception) {
    final status = exception.response?.statusCode ?? 0;
    if (status == 408 || status == 409 || status == 410) {
      return true;
    }

    final msg = (_parseErrorMessage(exception) ?? '').toLowerCase();
    return msg.contains('hết hạn') || msg.contains('het han') || msg.contains('expired') || msg.contains('hold');
  }

  Future<bool> _handleDioError(
    DioException exception, {
    required String fallbackMessage,
    required bool navigateOnHoldExpired,
  }) async {
    if (navigateOnHoldExpired && _isHoldExpiredError(exception)) {
      await _handleHoldExpired();
      return true;
    }

    _showSnack(_parseErrorMessage(exception) ?? fallbackMessage);
    return true;
  }

  Future<void> _handleHoldExpired() async {
    if (!mounted || _navigatingAway) return;
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
        content: const Text('Phiên giữ ghế đã hết hạn. Bạn sẽ quay lại trang chọn suất chiếu.'),
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
    _navigateToHome();
  }

  Future<void> _confirmCancelBooking() async {
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
        content: const Text('Nếu quay lại lúc này, ghế đang giữ sẽ được trả lại ngay. Bạn có chắc chắn muốn hủy không?'),
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
    _navigateToHome();
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

  void _navigateToHome() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) {
      return route.settings.name == MovieShowtimePage.routeName || route.settings.name == CinemaShowtimePage.routeName;
    });
  }

  double _uiScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < 700) {
      return (size.width / 390).clamp(0.74, 0.95);
    }
    return (size.width / 390).clamp(1.0, 1.4);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.scale});

  final String title;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFD6D6D6),
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 5 * scale),
      child: Text(
        title,
        style: TextStyle(fontSize: 10 * scale, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.scale,
    this.bold = false,
  });

  final String label;
  final String value;
  final double scale;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8 * scale, 6 * scale, 8 * scale, 3 * scale),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 10.5 * scale, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 10.5 * scale, fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.posterUrl, required this.scale});

  final String? posterUrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final resolvedPosterUrl = _resolvePosterUrl(posterUrl);
    final hasPoster = resolvedPosterUrl.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2 * scale),
      child: Container(
        width: 82 * scale,
        height: 122 * scale,
        color: const Color(0xFFE0E0E0),
        child: hasPoster
            ? Image.network(
                resolvedPosterUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PosterFallback(),
              )
            : const _PosterFallback(),
      ),
    );
  }

  String _resolvePosterUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return '';
    }

    final normalized = rawUrl.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    final fileName = normalized.split('\\').last.split('/').last;
    return '${ApiConstants.mediaBaseUrl}/assets/Images/MOVIE/$fileName';
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4D62FF), Color(0xFFB93B9D), Color(0xFFFF6A4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.local_movies_rounded, color: Colors.white, size: 38),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, required this.scale});

  final IconData icon;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 22 * scale,
        height: 22 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        child: Icon(icon, size: 14 * scale),
      ),
    );
  }
}

class _CheckoutPreviewData {
  const _CheckoutPreviewData({
    required this.movieTitle,
    required this.movieAge,
    required this.showDateLabel,
    required this.showTimeRangeLabel,
    required this.cinemaName,
    required this.hallName,
    required this.seatNumbers,
    required this.seatCount,
    required this.seatTotal,
    required this.comboTotal,
    required this.subTotalBeforeDiscount,
    required this.voucherDiscount,
    required this.vatAmount,
    required this.grandTotal,
  });

  final String movieTitle;
  final String movieAge;
  final String showDateLabel;
  final String showTimeRangeLabel;
  final String cinemaName;
  final String hallName;
  final List<String> seatNumbers;
  final int seatCount;
  final double seatTotal;
  final double comboTotal;
  final double subTotalBeforeDiscount;
  final double voucherDiscount;
  final double vatAmount;
  final double grandTotal;

  factory _CheckoutPreviewData.fromJson(Map<String, dynamic> json) {
    dynamic readAny(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key];
        }
      }
      return null;
    }

    List<String> readSeats(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return const [];
    }

    double readDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return _CheckoutPreviewData(
      movieTitle: (readAny(const ['movieTitle', 'MovieTitle']) ?? '').toString(),
      movieAge: (readAny(const ['movieAge', 'MovieAge']) ?? '').toString(),
      showDateLabel: (readAny(const ['showDateLabel', 'ShowDateLabel', 'showDate', 'ShowDate']) ?? '').toString(),
      showTimeRangeLabel: (readAny(const ['showTimeRangeLabel', 'ShowTimeRangeLabel', 'timeRange', 'TimeRange']) ?? '').toString(),
      cinemaName: (readAny(const ['cinemaName', 'CinemaName']) ?? '').toString(),
      hallName: (readAny(const ['hallName', 'HallName']) ?? '').toString(),
      seatNumbers: readSeats(readAny(const ['seatNumbers', 'SeatNumbers'])),
      seatCount: readInt(readAny(const ['seatCount', 'SeatCount'])),
      seatTotal: readDouble(readAny(const ['seatTotal', 'SeatTotal'])),
      comboTotal: readDouble(readAny(const ['comboTotal', 'ComboTotal'])),
      subTotalBeforeDiscount: readDouble(readAny(const ['subTotalBeforeDiscount', 'SubTotalBeforeDiscount'])),
      voucherDiscount: readDouble(readAny(const ['voucherDiscount', 'VoucherDiscount'])),
      vatAmount: readDouble(readAny(const ['vatAmount', 'VatAmount'])),
      grandTotal: readDouble(readAny(const ['grandTotal', 'GrandTotal'])),
    );
  }
}

class _VoucherItem {
  const _VoucherItem({
    required this.code,
    required this.title,
    required this.description,
    required this.discountValue,
  });

  final String code;
  final String title;
  final String description;
  final double discountValue;

  factory _VoucherItem.fromJson(Map<String, dynamic> json) {
    double readDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return _VoucherItem(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      discountValue: readDouble(json['discountValue']),
    );
  }
}
