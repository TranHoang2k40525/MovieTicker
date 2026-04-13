import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/liquid_glass_background.dart';
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/nearby_cinema_item.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rap gan ban'),
      ),
      body: LiquidGlassBackground(
        child: RefreshIndicator(
          onRefresh: _loadNearbyCinemas,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _GeoBanner(onRefresh: _loadNearbyCinemas),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_message != null)
                _EmptyState(message: _message!, onRetry: _loadNearbyCinemas)
              else
                ..._cinemas.map((cinema) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CinemaCard(cinema: cinema),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeoBanner extends StatelessWidget {
  const _GeoBanner({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.location_on_outlined, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rap gan ban',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Cap quyen vi tri de xep rap theo khoang cach thuc te.',
                  style: TextStyle(color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onRefresh,
            child: const Text('Tai lai'),
          ),
        ],
      ),
    );
  }
}

class _CinemaCard extends StatelessWidget {
  const _CinemaCard({required this.cinema});

  final NearbyCinemaItem cinema;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.theaters_outlined, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cinema.cinemaName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  cinema.cityAddress,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DistanceChip(label: '${cinema.distanceInKm.toStringAsFixed(1)} km'),
                    _DistanceChip(label: 'ID ${cinema.cinemaId}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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