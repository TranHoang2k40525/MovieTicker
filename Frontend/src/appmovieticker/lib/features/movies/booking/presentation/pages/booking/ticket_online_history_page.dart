import 'package:flutter/material.dart';

import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/features/movies/booking/data/datasources/booking/ticket_remote_datasource.dart';
import 'package:appmovieticker/features/movies/booking/data/models/booking/my_ticket_history_item.dart';

class TicketOnlineHistoryPage extends StatefulWidget {
  const TicketOnlineHistoryPage({super.key});

  @override
  State<TicketOnlineHistoryPage> createState() => _TicketOnlineHistoryPageState();
}

class _TicketOnlineHistoryPageState extends State<TicketOnlineHistoryPage> {
  final TicketRemoteDataSource _ticketRemoteDataSource = di.sl<TicketRemoteDataSource>();

  bool _loading = true;
  String? _error;
  List<MyTicketHistoryItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _ticketRemoteDataSource.getMyTicketHistory();
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được lịch sử quầy online';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String _money(double value) => '${value.toStringAsFixed(0)} đ';

  String _fmtDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _fmtDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${_fmtDate(date)} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Lịch sử quầy online'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(child: Text('Chưa có giao dịch online'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE6E6E6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.movieTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 6),
                                Text('Mã vé: ${item.ticketCode}'),
                                Text('Số seri: ${item.serialNumber}'),
                                Text('Rạp: ${item.cinemaName}'),
                                Text('Suất chiếu: ${_fmtDate(item.showDate)} • ${item.showTime}'),
                                Text('Thanh toán: ${_fmtDateTime(item.paymentDate)} • ${item.paymentMethod.isEmpty ? 'Online' : item.paymentMethod}'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.isExpired ? const Color(0xFFFFE7E6) : const Color(0xFFE8F7EE),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        item.statusLabel,
                                        style: TextStyle(
                                          color: item.isExpired ? const Color(0xFFD93025) : const Color(0xFF137333),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(_money(item.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: _items.length,
                      ),
                    ),
    );
  }
}
