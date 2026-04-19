import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/my_ticket_detail.dart';

class MyTicketDetailPage extends StatefulWidget {
  const MyTicketDetailPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<MyTicketDetailPage> createState() => _MyTicketDetailPageState();
}

class _MyTicketDetailPageState extends State<MyTicketDetailPage> {
  final TicketRemoteDataSource _ticketRemoteDataSource = di.sl<TicketRemoteDataSource>();

  bool _loading = true;
  String? _error;
  MyTicketDetail? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _ticketRemoteDataSource.getTicketDetail(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được chi tiết vé';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E6C8),
      appBar: AppBar(title: const Text('Vé điện tử')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _detail == null
                  ? const Center(child: Text('Không tìm thấy dữ liệu vé'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(14 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TicketPaper(detail: _detail!, scale: scale),
                        ],
                      ),
                    ),
    );
  }

  double _uiScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < 700) {
      return (size.width / 390).clamp(0.75, 0.95);
    }
    return (size.width / 1200).clamp(0.9, 1.25);
  }
}

class _TicketPaper extends StatelessWidget {
  const _TicketPaper({required this.detail, required this.scale});

  final MyTicketDetail detail;
  final double scale;

  String _fmtDate(DateTime? value) {
    if (value == null) return 'N/A';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _money(double value) => '${value.toStringAsFixed(0)} đ';

  String? _resolvePosterUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return null;
    }
    final normalized = rawUrl.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    final host = ApiConstants.mediaBaseUrl.replaceAll(RegExp(r'/$'), '');
    final path = normalized.startsWith('/') ? normalized : '/$normalized';
    return '$host$path';
  }

  @override
  Widget build(BuildContext context) {
    final seatText = detail.seats.map((x) => x.seatNumber).where((x) => x.isNotEmpty).join(', ');
    final seatClassText = detail.seats.map((x) => x.seatClass).toSet().join(', ');
    final barcodeData = detail.barcodeValue.isNotEmpty ? detail.barcodeValue : detail.serialNumber;
    final posterUrl = _resolvePosterUrl(detail.movieImageUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0x66000000),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14 * scale, 14 * scale, 14 * scale, 12 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14 * scale),
                  child: SizedBox(
                    width: 96 * scale,
                    height: 138 * scale,
                    child: posterUrl == null
                        ? Container(
                            color: const Color(0xFFE0E0E0),
                            child: Icon(Icons.movie_creation_outlined, size: 34 * scale),
                          )
                        : Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE0E0E0),
                              child: Icon(Icons.movie_creation_outlined, size: 34 * scale),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.movieTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 6 * scale),
                      Text('Mã vé: ${detail.ticketCode}', style: TextStyle(fontSize: 11 * scale)),
                      SizedBox(height: 4 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                        decoration: BoxDecoration(
                          color: detail.isExpired ? const Color(0xFFFFE7E6) : const Color(0xFFE8F7EE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          detail.statusLabel,
                          style: TextStyle(
                            fontSize: 11 * scale,
                            color: detail.isExpired ? const Color(0xFFD93025) : const Color(0xFF137333),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Perforation(scale: scale),
          Padding(
            padding: EdgeInsets.fromLTRB(14 * scale, 12 * scale, 14 * scale, 10 * scale),
            child: Column(
              children: [
                _RowInfo(label: 'Rạp', value: detail.cinemaName),
                _RowInfo(label: 'Địa chỉ', value: detail.cinemaAddress),
                _RowInfo(label: 'Phòng', value: detail.hallName),
                _RowInfo(label: 'Ngày chiếu', value: _fmtDate(detail.showDate)),
                _RowInfo(label: 'Suất chiếu', value: detail.showTime),
                _RowInfo(label: 'Ghế', value: seatText),
                _RowInfo(label: 'Hạng ghế', value: seatClassText),
              ],
            ),
          ),
          _Perforation(scale: scale),
          Padding(
            padding: EdgeInsets.fromLTRB(14 * scale, 12 * scale, 14 * scale, 10 * scale),
            child: Column(
              children: [
                _RowInfo(label: 'Tiền ghế', value: _money(detail.seatTotal)),
                _RowInfo(label: 'Combo', value: _money(detail.comboTotal)),
                _RowInfo(label: 'Giảm voucher', value: _money(detail.voucherDiscount)),
                _RowInfo(label: 'VAT (${(detail.vatRate * 100).toStringAsFixed(0)}%)', value: _money(detail.vatAmount)),
                const Divider(height: 16),
                _RowInfo(
                  label: 'Grand Total',
                  value: _money(detail.grandTotal),
                  emphasize: true,
                ),
              ],
            ),
          ),
          _Perforation(scale: scale),
          Padding(
            padding: EdgeInsets.fromLTRB(14 * scale, 14 * scale, 14 * scale, 16 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số seri: ${detail.serialNumber}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * scale)),
                SizedBox(height: 8 * scale),
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 8 * scale),
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: barcodeData,
                    drawText: false,
                    width: double.infinity,
                    height: 80 * scale,
                    errorBuilder: (context, error) => Text(
                      'Không tạo được barcode',
                      style: TextStyle(fontSize: 11 * scale, color: Colors.red),
                    ),
                  ),
                ),
                SizedBox(height: 6 * scale),
                Center(
                  child: Text(
                    barcodeData,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Center(
                  child: Text(
                    'Mã vạch Code128 quét ra đúng số seri',
                    style: TextStyle(fontSize: 10 * scale, color: const Color(0xFF666666)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20 * scale,
      child: Row(
        children: [
          Transform.translate(
            offset: Offset(-10 * scale, 0),
            child: Container(
              width: 20 * scale,
              height: 20 * scale,
              decoration: const BoxDecoration(color: Color(0xFFF3E6C8), shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashCount = (constraints.maxWidth / (8 * scale)).floor().clamp(8, 120);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (_) => Container(width: 4 * scale, height: 1.5 * scale, color: const Color(0xFFDFDFDF)),
                  ),
                );
              },
            ),
          ),
          Transform.translate(
            offset: Offset(10 * scale, 0),
            child: Container(
              width: 20 * scale,
              height: 20 * scale,
              decoration: const BoxDecoration(color: Color(0xFFF3E6C8), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  const _RowInfo({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 106,
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF5A5A5A),
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF1B1B1B),
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
