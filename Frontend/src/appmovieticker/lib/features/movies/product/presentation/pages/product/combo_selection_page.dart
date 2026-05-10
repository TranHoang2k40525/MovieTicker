import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/core/network/dio_client.dart';
import 'package:appmovieticker/core/constants/api_constants.dart';
import 'package:appmovieticker/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:appmovieticker/features/movies/movie/data/datasources/movie/movies_remote_datasource.dart';
import 'package:appmovieticker/features/movies/product/data/models/product/product_item.dart';
import 'package:appmovieticker/features/movies/payment/presentation/pages/payment/checkout_payment_page.dart';
import 'package:appmovieticker/features/movies/show/presentation/pages/showtime/cinema_showtime_page.dart';
import 'package:appmovieticker/features/movies/show/presentation/pages/showtime/movie_showtime_page.dart';

class ComboSelectionPage extends StatefulWidget {
  const ComboSelectionPage({
    super.key,
    required this.movieTitle,
    this.moviePosterUrl,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.holdId,
    required this.expiresAt,
    required this.selectedSeats,
    required this.selectedSeatTotalPrice,
    required this.showId,
  });

  final String movieTitle;
  final String? moviePosterUrl;
  final String cinemaName;
  final String cinemaAddress;
  final int holdId;
  final DateTime expiresAt;
  final List<String> selectedSeats;
  final double selectedSeatTotalPrice;
  final int showId;

  @override
  State<ComboSelectionPage> createState() => _ComboSelectionPageState();
}

class _ComboSelectionPageState extends State<ComboSelectionPage> {
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();
  final AuthLocalDataSource _localDataSource = di.sl<AuthLocalDataSource>();
  final DioClient _dioClient = di.sl<DioClient>();

  List<ProductItem> _products = [];
  Map<int, int> _selectedQuantities = {};
  bool _loading = true;
  String? _error;
  late DateTime _expirationTime;
  bool _isSubmitting = false;
  bool _holdExpiredHandled = false;
  bool _holdReleased = false;
  bool _isNavigatingAway = false;

  @override
  void initState() {
    super.initState();
    _expirationTime = widget.expiresAt;
    _loadProducts();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (DateTime.now().isBefore(_expirationTime)) {
          setState(() {});
          _startCountdownTimer();
        } else {
          _showExpiredDialog();
        }
      }
    });
  }

  Future<void> _showExpiredDialog() async {
    if (_holdExpiredHandled) {
      return;
    }
    _holdExpiredHandled = true;

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
        content: const Text('Thời gian giữ ghế của bạn đã hết. Vui lòng quay lại và chọn ghế lại.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE62C2C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

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
    if (!mounted || _isNavigatingAway) {
      return;
    }
    _isNavigatingAway = true;
    Navigator.of(context).popUntil((route) {
      return route.settings.name == MovieShowtimePage.routeName || route.settings.name == CinemaShowtimePage.routeName;
    });
  }

  Future<void> _confirmCancelBooking() async {
    if (!mounted || _isSubmitting || _isNavigatingAway) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy đặt vé?'),
        titleTextStyle: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 20),
        contentTextStyle: const TextStyle(color: Color(0xFF374151), height: 1.35),
        content: const Text('Nếu thoát lúc này, ghế đang giữ sẽ được trả lại ngay. Bạn có chắc chắn muốn hủy không?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục đặt vé'),
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

    await _releaseHoldSilently();
    _navigateToHome();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await _remoteDataSource.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        for (var product in products) {
          _selectedQuantities[product.productId] = 0;
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _parseErrorMessage(e) ?? 'Không tải được danh sách combo. Vui lòng thử lại.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách combo. Vui lòng thử lại.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
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

  void _incrementQuantity(int productId) {
    setState(() {
      _selectedQuantities[productId] = (_selectedQuantities[productId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(int productId) {
    setState(() {
      final current = _selectedQuantities[productId] ?? 0;
      if (current > 0) {
        _selectedQuantities[productId] = current - 1;
      }
    });
  }

  Future<void> _confirmBooking() async {
    final selectedProducts = _selectedQuantities.entries
        .where((e) => e.value > 0)
        .map((e) => {'productId': e.key, 'quantity': e.value})
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tiếp tục thanh toán'),
        titleTextStyle: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 20),
        contentTextStyle: const TextStyle(color: Color(0xFF374151), height: 1.35),
        content: const Text('Xác nhận combo để sang màn thanh toán?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE62C2C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _proceedToCheckout(selectedProducts);
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToCheckout(List<Map<String, int>> products) async {
    setState(() {
      _isSubmitting = true;
    });

    var loadingDialogShown = false;

    try {
      final token = await _localDataSource.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập lại')),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x59000000),
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Color(0xFFE62C2C), strokeWidth: 2.5),
              ),
              SizedBox(width: 12 * _uiScale(context)),
              const Expanded(
                child: Text(
                  'Đang xác nhận đặt vé...',
                  style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
      loadingDialogShown = true;

      // Call backend API to confirm booking
      final response = await _dioClient.dio.post(
        '/bookings/holds/confirm',
        data: {
          'holdId': widget.holdId,
          'products': products.map((p) => {
            'productId': p['productId'],
            'quantity': p['quantity'],
          }).toList(),
        },
      );

      if (!mounted) return;
      if (loadingDialogShown) {
        Navigator.of(context).pop();
        loadingDialogShown = false;
      }

      final responseData = response.data;
      final success = responseData['success'] ?? false;

      if (!success) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Không thể xác nhận đặt vé')),
        );
        return;
      }

      if (!mounted) return;

      final result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => CheckoutPaymentPage(
            holdId: widget.holdId,
            expiresAt: _expirationTime,
            movieTitle: widget.movieTitle,
            moviePosterUrl: widget.moviePosterUrl,
            cinemaName: widget.cinemaName,
            cinemaAddress: widget.cinemaAddress,
            selectedSeats: widget.selectedSeats,
            selectedSeatTotalPrice: widget.selectedSeatTotalPrice,
            products: _products,
            initialQuantities: _selectedQuantities,
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        _holdReleased = true;
        Navigator.of(context).pop(true);
        return;
      }

      if (result == 'hold_expired') {
        await _showExpiredDialog();
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (loadingDialogShown) {
        Navigator.of(context).pop();
        loadingDialogShown = false;
      }
      setState(() {
        _isSubmitting = false;
      });

      if (_isHoldExpiredError(e)) {
        await _showExpiredDialog();
        return;
      }
      
      final errorMsg = _parseErrorMessageFromDio(e) ?? 'Không thể xác nhận đặt vé. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (loadingDialogShown) {
        Navigator.of(context).pop();
        loadingDialogShown = false;
      }
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          content: Text('Lỗi: $e', style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  bool _isHoldExpiredError(DioException exception) {
    final status = exception.response?.statusCode ?? 0;
    if (status == 408 || status == 409 || status == 410) {
      return true;
    }

    final msg = (_parseErrorMessageFromDio(exception) ?? '').toLowerCase();
    return msg.contains('hết hạn') || msg.contains('het han') || msg.contains('expired') || msg.contains('hold');
  }

  String? _parseErrorMessageFromDio(DioException exception) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['Message'];
      if (message != null) {
        return message.toString();
      }
    }
    return null;
  }

  double _uiScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < 700) {
      return (size.width / 390).clamp(0.75, 0.95);
    }
    return (size.width / 390).clamp(1.0, 1.5);
  }

  String _resolveImageUrl(ProductItem product) {
    final raw = product.imageUrl ?? product.imageProduct;
    if (raw == null || raw.isEmpty) {
      return '';
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final fileName = raw.split('\\').last.split('/').last;
    return '${ApiConstants.mediaBaseUrl}/assets/Images/PRODUCT/$fileName';
  }

  String _formatPrice(num? price) {
    final value = price ?? 0;
    return '${value.toStringAsFixed(0)} đ';
  }

  double _selectedTotalPrice() {
    var total = 0.0;
    for (final product in _products) {
      final quantity = _selectedQuantities[product.productId] ?? 0;
      total += (product.price ?? 0).toDouble() * quantity;
    }
    return total;
  }

  double _grandTotalPrice() {
    return widget.selectedSeatTotalPrice + _selectedTotalPrice();
  }

  void _showProductDetail(ProductItem product) {
    final scale = _uiScale(context);
    final imageUrl = _resolveImageUrl(product);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.52,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7E7A6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16 * scale, 14 * scale, 16 * scale, 24 * scale),
                children: [
                  Center(
                    child: Container(
                      width: 42 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB78E2D),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18 * scale),
                        child: Container(
                          width: 120 * scale,
                          height: 120 * scale,
                          color: const Color(0xFFF1D670),
                          child: imageUrl.isEmpty
                              ? Icon(Icons.local_movies_rounded, size: 54 * scale, color: const Color(0xFFB78E2D))
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.local_movies_rounded,
                                    size: 54 * scale,
                                    color: const Color(0xFFB78E2D),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 14 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nameProduct ?? 'Sản phẩm',
                              style: TextStyle(
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF211A08),
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              _formatPrice(product.price),
                              style: TextStyle(
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD11F1B),
                              ),
                            ),
                            SizedBox(height: 10 * scale),
                            Text(
                              product.description ?? 'Không có mô tả chi tiết.',
                              style: TextStyle(
                                fontSize: 11.5 * scale,
                                height: 1.35,
                                color: const Color(0xFF4F4520),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18 * scale),
                  Container(
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16 * scale),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin chi tiết',
                          style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2A220A),
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          product.description ?? 'Không có mô tả chi tiết.',
                          style: TextStyle(
                            fontSize: 11.5 * scale,
                            height: 1.45,
                            color: const Color(0xFF4F4520),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18 * scale),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD11F1B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14 * scale),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Đóng',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
    final now = DateTime.now();
    final remaining = _expirationTime.difference(now);
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final isExpired = remaining.isNegative;

    return WillPopScope(
      onWillPop: () async {
        await _confirmCancelBooking();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(8 * scale),
              child: Column(
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    padding: EdgeInsets.all(12 * scale),
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movieTitle,
                            style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            '${widget.cinemaName}, ${widget.cinemaAddress}',
                            style: TextStyle(fontSize: 10 * scale, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
                      decoration: BoxDecoration(
                        color: isExpired ? const Color(0xFFFF6B6B) : const Color(0xFFE63C39),
                        borderRadius: BorderRadius.circular(6 * scale),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Còn lại',
                            style: TextStyle(fontSize: 8 * scale, color: Colors.white),
                          ),
                          Text(
                            isExpired ? 'Hết hạn' : '$minutes:${seconds.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    GestureDetector(
                      onTap: _confirmCancelBooking,
                      child: Icon(Icons.close, size: 24 * scale),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12 * scale),

              // Red banner - promotional message
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFE63C39),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Text(
                  'Áp dụng các ưu đãi khi mua combo ngay hôm nay!',
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 12 * scale),

              // Products list
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!),
                                SizedBox(height: 12 * scale),
                                ElevatedButton(
                                  onPressed: _loadProducts,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : _products.isEmpty
                            ? Center(
                                child: Text(
                                  'Không có combo nào',
                                  style: TextStyle(fontSize: 12 * scale),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _products.length,
                                separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
                                itemBuilder: (context, index) {
                                  final product = _products[index];
                                  final quantity = _selectedQuantities[product.productId] ?? 0;
                                  return _ProductCard(
                                    product: product,
                                    quantity: quantity,
                                    onIncrement: () => _incrementQuantity(product.productId),
                                    onDecrement: () => _decrementQuantity(product.productId),
                                    onTap: () => _showProductDetail(product),
                                    resolveImageUrl: _resolveImageUrl,
                                    formatPrice: _formatPrice,
                                    scale: scale,
                                  );
                                },
                              ),
              ),

              SizedBox(height: 12 * scale),

              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 12 * scale),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16 * scale),
                  border: Border.all(color: const Color(0xFFE6D49B)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movieTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5 * scale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF161616),
                            ),
                          ),
                          SizedBox(height: 2 * scale),
                          Text(
                            '${widget.selectedSeats.join(', ')} · ${_selectedQuantities.values.fold<int>(0, (sum, value) => sum + value)} combo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5 * scale,
                              color: const Color(0xFF6A5A22),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          Text(
                            'Tiền ghế: ${_formatPrice(widget.selectedSeatTotalPrice)}',
                            style: TextStyle(
                              fontSize: 10.5 * scale,
                              color: const Color(0xFF6A5A22),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(_grandTotalPrice()),
                          style: TextStyle(
                            fontSize: 12.5 * scale,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFD11F1B),
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          '+ combo: ${_formatPrice(_selectedTotalPrice())}',
                          style: TextStyle(
                            fontSize: 9.8 * scale,
                            color: const Color(0xFF6A5A22),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD11F1B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: (isExpired || _isSubmitting) ? null : _confirmBooking,
                          child: Text(
                            _isSubmitting ? 'Đang xử lý...' : 'Thanh toán',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE63C39)),
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      ),
                      onPressed: _confirmCancelBooking,
                      child: Text(
                        'Quay lại',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: const Color(0xFFE63C39),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE63C39),
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      ),
                      onPressed: (isExpired || _isSubmitting) ? null : _confirmBooking,
                      child: Text(
                        _isSubmitting ? 'Đang xử lý...' : 'Tiếp tục',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTap,
    required this.resolveImageUrl,
    required this.formatPrice,
    required this.scale,
  });

  final ProductItem product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onTap;
  final String Function(ProductItem product) resolveImageUrl;
  final String Function(num? price) formatPrice;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(product);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10 * scale),
        child: Container(
          margin: EdgeInsets.only(bottom: 2 * scale),
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF6E7A2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90 * scale,
                height: 124 * scale,
                color: const Color(0xFFF0D86A),
                padding: EdgeInsets.all(8 * scale),
                child: imageUrl.isEmpty
                    ? Icon(Icons.local_movies_rounded, size: 34 * scale, color: const Color(0xFFB78E2D))
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.local_movies_rounded,
                          size: 34 * scale,
                          color: const Color(0xFFB78E2D),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10 * scale, 10 * scale, 12 * scale, 10 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.nameProduct ?? 'Sản phẩm',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2A220A),
                              ),
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Text(
                            formatPrice(product.price),
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6A5500),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6 * scale),
                      Text(
                        product.description ?? 'Bấm vào để xem chi tiết sản phẩm.',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5 * scale,
                          height: 1.28,
                          color: const Color(0xFF3D330F),
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Row(
                        children: [
                          _QtyRoundButton(icon: Icons.remove, onTap: onDecrement, scale: scale),
                          SizedBox(width: 10 * scale),
                          Container(
                            width: 30 * scale,
                            alignment: Alignment.center,
                            child: Text(
                              quantity.toString(),
                              style: TextStyle(
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF211A08),
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * scale),
                          _QtyRoundButton(icon: Icons.add, onTap: onIncrement, scale: scale),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyRoundButton extends StatelessWidget {
  const _QtyRoundButton({required this.icon, required this.onTap, required this.scale});

  final IconData icon;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26 * scale,
        height: 26 * scale,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16 * scale, color: const Color(0xFF211A08)),
      ),
    );
  }
}
