import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_item.dart';
import '../widgets/movie_menu_dialog.dart';

enum _NotificationTab { notification, inbox }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationRemoteDataSource _remoteDataSource = di.sl<NotificationRemoteDataSource>();

  bool _loading = true;
  String? _error;
  List<NotificationItem> _items = const [];
  _NotificationTab _tab = _NotificationTab.notification;

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
      final items = await _remoteDataSource.getMyNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được thông báo';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  List<NotificationItem> get _filtered {
    if (_tab == _NotificationTab.notification) {
      return _items.where((x) => x.channel.toLowerCase() == 'notification').toList();
    }
    return _items.where((x) => x.channel.toLowerCase() == 'inbox').toList();
  }

  String _timeText(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
    final items = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 * scale, 10 * scale, 8 * scale, 8 * scale),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(22 * scale),
              border: Border.all(color: const Color(0xFFFF3B30), width: 1),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 54 * scale,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back, size: 24 * scale, color: const Color(0xFFE14A4A)),
                      ),
                      Text(
                        'Thông báo',
                        style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => showMovieMenuDialog(context, scale: scale),
                        icon: Icon(Icons.menu_rounded, size: 34 * scale, color: const Color(0xFFE14A4A)),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      _TabButton(
                        title: 'Thông báo',
                        selected: _tab == _NotificationTab.notification,
                        scale: scale,
                        onTap: () => setState(() => _tab = _NotificationTab.notification),
                      ),
                      _TabButton(
                        title: 'Hộp thư',
                        selected: _tab == _NotificationTab.inbox,
                        scale: scale,
                        onTap: () => setState(() => _tab = _NotificationTab.inbox),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : items.isEmpty
                              ? _EmptyState(scale: scale)
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  child: ListView.separated(
                                    padding: EdgeInsets.fromLTRB(10 * scale, 10 * scale, 10 * scale, 12 * scale),
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return Container(
                                        padding: EdgeInsets.all(10 * scale),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(12 * scale),
                                          border: Border.all(color: const Color(0xFFFFD1CF)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 34 * scale,
                                              height: 34 * scale,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFEFEF),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Icon(Icons.notifications_active_outlined, color: const Color(0xFFE14A4A), size: 18 * scale),
                                            ),
                                            SizedBox(width: 10 * scale),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.title,
                                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12 * scale),
                                                        ),
                                                      ),
                                                      Text(
                                                        _timeText(item.createdAt),
                                                        style: TextStyle(fontSize: 10 * scale, color: const Color(0xFF707070)),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4 * scale),
                                                  Text(item.message, style: TextStyle(fontSize: 11 * scale, height: 1.3)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
                                    itemCount: items.length,
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

class _TabButton extends StatelessWidget {
  const _TabButton({required this.title, required this.selected, required this.scale, required this.onTap});

  final String title;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(bottom: 8 * scale, top: 8 * scale),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFFFF2B2B) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12 * scale,
              color: selected ? const Color(0xFFFF2B2B) : const Color(0xFF303030),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scale});

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
