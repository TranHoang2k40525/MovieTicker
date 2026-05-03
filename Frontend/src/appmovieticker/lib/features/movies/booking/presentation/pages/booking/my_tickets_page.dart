import 'package:flutter/material.dart';

import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/features/movies/booking/data/datasources/booking/ticket_remote_datasource.dart';
import 'package:appmovieticker/features/movies/booking/data/models/booking/my_ticket_item.dart';
import 'my_ticket_detail_page.dart';
import 'ticket_online_history_page.dart';
import 'package:appmovieticker/features/movies/movie/presentation/widgets/movie/movie_menu_dialog.dart';

enum _TicketTab { upcoming, viewed }

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  final TicketRemoteDataSource _ticketRemoteDataSource = di.sl<TicketRemoteDataSource>();

  bool _loading = true;
  String? _error;
  List<MyTicketItem> _tickets = const [];
  _TicketTab _tab = _TicketTab.upcoming;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _ticketRemoteDataSource.getMyTickets();
      if (!mounted) return;
      setState(() {
        _tickets = data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách vé';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  List<MyTicketItem> get _filteredTickets {
    if (_tab == _TicketTab.upcoming) {
      return _tickets.where((x) => !x.isExpired).toList();
    }
    return _tickets.where((x) => x.isExpired).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
    final items = _filteredTickets;

    return Scaffold(
      backgroundColor: const Color(0xFFD9CC7A),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 * scale, 10 * scale, 8 * scale, 8 * scale),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD9CC7A),
              borderRadius: BorderRadius.circular(22 * scale),
              border: Border.all(color: const Color(0xFFFF3B30), width: 1),
            ),
            child: Column(
              children: [
                _Header(scale: scale, onMenuTap: () => showMovieMenuDialog(context, scale: scale)),
                _TopTabs(
                  scale: scale,
                  tab: _tab,
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : items.isEmpty
                              ? _EmptyTicket(scale: scale)
                              : RefreshIndicator(
                                  onRefresh: _loadTickets,
                                  child: ListView.separated(
                                    padding: EdgeInsets.fromLTRB(10 * scale, 10 * scale, 10 * scale, 10 * scale),
                                    itemBuilder: (context, index) {
                                      final ticket = items[index];
                                      return InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => MyTicketDetailPage(bookingId: ticket.bookingId),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(10 * scale),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(10 * scale),
                                            border: Border.all(color: const Color(0xFFE23C39)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(ticket.movieTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12 * scale)),
                                              SizedBox(height: 4 * scale),
                                              Text('Mã vé: ${ticket.ticketCode}', style: TextStyle(fontSize: 10 * scale)),
                                              Text('${ticket.cinemaName} • ${ticket.showTime}', style: TextStyle(fontSize: 10 * scale)),
                                              SizedBox(height: 6 * scale),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      ticket.statusLabel,
                                                      style: TextStyle(
                                                        fontSize: 10 * scale,
                                                        color: ticket.isExpired ? const Color(0xFF8F4D4B) : const Color(0xFFE63C39),
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Text('${ticket.totalPrice.toStringAsFixed(0)} đ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11 * scale)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
                                    itemCount: items.length,
                                  ),
                                ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale, 16 * scale),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1F1F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TicketOnlineHistoryPage()),
                        );
                      },
                      child: const Text('LỊCH SỬ QUẦY ONLINE', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _Header extends StatelessWidget {
  const _Header({required this.scale, required this.onMenuTap});

  final double scale;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54 * scale,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, size: 24 * scale, color: const Color(0xFFE14A4A)),
          ),
          Text(
            'Vé của tôi',
            style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
          ),
          const Spacer(),
          IconButton(
            onPressed: onMenuTap,
            icon: Icon(Icons.menu_rounded, size: 34 * scale, color: const Color(0xFFE14A4A)),
          ),
        ],
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({required this.scale, required this.tab, required this.onChanged});

  final double scale;
  final _TicketTab tab;
  final ValueChanged<_TicketTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onChanged(_TicketTab.upcoming),
              child: Container(
                padding: EdgeInsets.only(bottom: 8 * scale, top: 8 * scale),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: tab == _TicketTab.upcoming ? const Color(0xFFFF2B2B) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Phim sắp xem',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: tab == _TicketTab.upcoming ? const Color(0xFFFF2B2B) : const Color(0xFFB99A2F),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(_TicketTab.viewed),
              child: Container(
                padding: EdgeInsets.only(bottom: 8 * scale, top: 8 * scale),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: tab == _TicketTab.viewed ? const Color(0xFFFF2B2B) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Phim đã xem',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: tab == _TicketTab.viewed ? const Color(0xFFFF2B2B) : const Color(0xFFB99A2F),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTicket extends StatelessWidget {
  const _EmptyTicket({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36 * scale,
            backgroundImage: const AssetImage('assets/images/avatramacdinh.png'),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Không có dữ liệu',
            style: TextStyle(fontSize: 16 * scale, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
