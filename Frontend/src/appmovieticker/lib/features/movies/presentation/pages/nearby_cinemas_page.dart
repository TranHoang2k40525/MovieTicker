import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/nearby_cinema_item.dart';
import '../widgets/movie_menu_dialog.dart';

class NearbyCinemasPage extends StatefulWidget {
  const NearbyCinemasPage({super.key});

  @override
  State<NearbyCinemasPage> createState() => _NearbyCinemasPageState();
}

class _NearbyCinemasPageState extends State<NearbyCinemasPage> {
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();

  bool _loading = false;
  String? _message;
  List<NearbyCinemaItem> _cinemas = const [];

  @override
  void initState() {
    super.initState();
    _loadNearbyCinemas();
  }

  Future<void> _loadNearbyCinemas() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final position = await _resolvePosition();
      final cinemas = await _remoteDataSource.getNearbyCinemas(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _cinemas = cinemas;
        _message = cinemas.isEmpty ? 'Chua tim thay rap gan ban.' : null;
      });
    } on LocationPermissionException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _cinemas = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Khong the lay danh sach rap gan ban. Hay thu lai.';
        _cinemas = const [];
      });
    } finally {}

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationPermissionException('Hay bat dich vu vi tri tren thiet bi cua ban.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionException('Quyen vi tri bi tu choi. Hay cap quyen de xem rap gan ban.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException('Quyen vi tri bi chan vinh vien. Hay mo lai trong cai dat he thong.');
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
                Container(height: 54 * scale, color: const Color(0xFFE8D66C), alignment: Alignment.centerLeft, padding: EdgeInsets.symmetric(horizontal: 14 * scale), child: Text('GỢI Ý CHO BẠN', style: TextStyle(fontSize: 13 * scale, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700))),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadNearbyCinemas,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        if (_loading)
                          Padding(
                            padding: EdgeInsets.only(top: 30 * scale),
                            child: const Center(child: CircularProgressIndicator()),
                          )
                        else if (_message != null)
                          _EmptyState(message: _message!, onRetry: _loadNearbyCinemas)
                        else ...[
                          ..._cinemas.map(
                            (cinema) => _CinemaRow(
                              cinema: cinema,
                              scale: scale,
                            ),
                          ),
                          SizedBox(height: 70 * scale),
                          Container(height: 54 * scale, color: const Color(0xFFE8D66C)),
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFE6C94E))),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 14 * scale),
                            child: Row(
                              children: [
                                Text('Hà Nội', style: TextStyle(fontSize: 13 * scale, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text('${_cinemas.length}', style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700)),
                                SizedBox(width: 8 * scale),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 22 * scale),
                              ],
                            ),
                          ),
                        ],
                      ],
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
          Icon(Icons.send_outlined, size: 22 * scale, color: const Color(0xFFD0BFA3)),
          SizedBox(width: 14 * scale),
          IconButton(
            onPressed: onMenuTap,
            icon: Icon(Icons.menu_rounded, size: 34 * scale, color: const Color(0xFFE14A4A)),
          ),
        ],
      ),
    );
  }
}

class _CinemaRow extends StatelessWidget {
  const _CinemaRow({required this.cinema, required this.scale});

  final NearbyCinemaItem cinema;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE4C85C))),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 16 * scale),
      child: Row(
        children: [
          Expanded(
            child: Text(
              cinema.cinemaName,
              style: TextStyle(fontSize: 13 * scale, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${cinema.distanceInKm.toStringAsFixed(1)}Km',
            style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: const Color(0xFFFF3B30)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 48, color: Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Thu lai')),
        ],
      ),
    );
  }
}

class LocationPermissionException implements Exception {
  const LocationPermissionException(this.message);

  final String message;
}