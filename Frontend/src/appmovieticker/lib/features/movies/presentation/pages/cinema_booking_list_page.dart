import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/nearby_cinema_item.dart';
import 'cinema_showtime_page.dart';
import '../widgets/movie_menu_dialog.dart';

class CinemaBookingListPage extends StatefulWidget {
  const CinemaBookingListPage({super.key});

  @override
  State<CinemaBookingListPage> createState() => _CinemaBookingListPageState();
}

class _CinemaBookingListPageState extends State<CinemaBookingListPage> {
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();

  bool _loading = false;
  String? _message;
  List<NearbyCinemaItem> _cinemas = const [];

  @override
  void initState() {
    super.initState();
    _loadCinemas();
  }

  Future<void> _loadCinemas() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final position = await _resolvePosition();
      if (position == null) {
        if (!mounted) return;
        setState(() {
          _message = 'Vui lòng bật định vị để hiển thị danh sách rạp.';
          _cinemas = const [];
        });
        return;
      }

      final cinemas = await _remoteDataSource.getNearbyCinemas(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _cinemas = cinemas;
        _message = cinemas.isEmpty ? 'Không có rạp khả dụng.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Không tải được danh sách rạp. Hãy thử lại.';
        _cinemas = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Position?> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 * scale, 6 * scale, 8 * scale, 8 * scale),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1.2),
            ),
            child: Column(
              children: [
                _Header(scale: scale, onMenuTap: () => showMovieMenuDialog(context, scale: scale)),
                Container(
                  height: 52 * scale,
                  color: const Color(0xFFE8D66C),
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 14 * scale),
                  child: Text(
                    'Tìm phim theo rạp',
                    style: TextStyle(fontSize: 13 * scale, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _message != null
                          ? _EmptyState(message: _message!, onRetry: _loadCinemas)
                          : RefreshIndicator(
                              onRefresh: _loadCinemas,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _cinemas.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE6C94E)),
                                itemBuilder: (context, index) {
                                  final cinema = _cinemas[index];
                                  return ListTile(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => CinemaShowtimePage(cinema: cinema)),
                                      );
                                    },
                                    title: Text(
                                      cinema.cinemaName,
                                      style: TextStyle(fontSize: 13 * scale, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      cinema.cityAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11 * scale),
                                    ),
                                    trailing: Text(
                                      '${cinema.distanceInKm.toStringAsFixed(1)}Km',
                                      style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.w700, color: const Color(0xFFFF3B30)),
                                    ),
                                  );
                                },
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
            'Rạp phim',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => onRetry(), child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
