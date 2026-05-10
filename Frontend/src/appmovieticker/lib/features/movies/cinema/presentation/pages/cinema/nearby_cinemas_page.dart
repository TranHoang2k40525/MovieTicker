import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/features/movies/movie/data/datasources/movie/movies_remote_datasource.dart';
import 'package:appmovieticker/features/movies/cinema/data/models/cinema/nearby_cinema_item.dart';
import 'cinema_detail_page.dart';
import 'package:appmovieticker/features/movies/movie/presentation/widgets/movie/movie_menu_dialog.dart';

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
  int? _expandedGroupIndex;

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
      if (position == null) {
        if (!mounted) return;
        setState(() {
          _message = 'Vi tri: N/A';
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

  Future<Position?> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
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
                          ..._cinemas.take(2).map(
                            (cinema) => _CinemaRow(
                              cinema: cinema,
                              scale: scale,
                            ),
                          ),
                          SizedBox(height: 70 * scale),
                          Container(height: 54 * scale, color: const Color(0xFFE8D66C)),
                          ..._buildCityGroups(scale),
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

  List<Widget> _buildCityGroups(double scale) {
    final grouped = <String, List<NearbyCinemaItem>>{};
    for (final cinema in _cinemas) {
      final city = _extractCityName(cinema.cityAddress);
      grouped.putIfAbsent(city, () => []).add(cinema);
    }

    final entries = grouped.entries.toList();
    return List<Widget>.generate(entries.length, (index) {
      final entry = entries[index];
      final expanded = _expandedGroupIndex == index;
      return _CityGroupTile(
        title: entry.key,
        count: entry.value.length,
        scale: scale,
        expanded: expanded,
        cinemas: entry.value,
        onToggle: () {
          setState(() {
            _expandedGroupIndex = expanded ? null : index;
          });
        },
      );
    });
  }

  String _extractCityName(String cityAddress) {
    final parts = cityAddress
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Hà Nội';
    return parts.first;
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
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CinemaDetailPage(cinema: cinema)),
        );
      },
      child: Container(
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

class _CityGroupTile extends StatelessWidget {
  const _CityGroupTile({
    required this.title,
    required this.count,
    required this.scale,
    required this.expanded,
    required this.cinemas,
    required this.onToggle,
  });

  final String title;
  final int count;
  final double scale;
  final bool expanded;
  final List<NearbyCinemaItem> cinemas;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE6C94E))),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 14 * scale),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8 * scale),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 22 * scale),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              color: const Color(0xFFFDF7D9),
              constraints: BoxConstraints(maxHeight: 180 * scale),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: cinemas.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEFD97D)),
                itemBuilder: (context, index) {
                  final cinema = cinemas[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CinemaDetailPage(cinema: cinema)),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cinema.cinemaName,
                              style: TextStyle(fontSize: 12 * scale, fontStyle: FontStyle.italic),
                            ),
                          ),
                          Text(
                            '${cinema.distanceInKm.toStringAsFixed(1)}Km',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}