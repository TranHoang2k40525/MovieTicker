import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/models/nearby_cinema_item.dart';
import '../widgets/movie_menu_dialog.dart';

class CinemaDetailPage extends StatelessWidget {
  const CinemaDetailPage({super.key, required this.cinema});

  final NearbyCinemaItem cinema;

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
    final googleMapSearchUrl = _buildGoogleMapsSearchUrl(cinema);
    final googleDirectionUrl = _buildGoogleMapsDirectionsUrl(cinema);

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
                _Header(
                  scale: scale,
                  title: 'Rạp phim 67CS',
                  onBack: () => Navigator.of(context).maybePop(),
                  onMenuTap: () => showMovieMenuDialog(context, scale: scale),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10 * scale, 2 * scale, 10 * scale, 10 * scale),
                  child: Row(
                    children: [
                      Text(
                        '67CS',
                        style: TextStyle(
                          color: const Color(0xFFE7352D),
                          fontSize: 14 * scale,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: Text(
                          cinema.cinemaName,
                          style: TextStyle(fontSize: 13 * scale, fontStyle: FontStyle.italic),
                        ),
                      ),
                      Text(
                        '${cinema.distanceInKm.toStringAsFixed(1)}Km',
                        style: TextStyle(
                          color: const Color(0xFFFF3B30),
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2 * scale),
                    child: _MapPreview(
                      cinema: cinema,
                      scale: scale,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10 * scale, 14 * scale, 10 * scale, 0),
                  child: Row(
                    children: [
                      _ActionTab(label: 'Giá vé', scale: scale),
                      SizedBox(width: 22 * scale),
                      _ActionTab(label: 'Suất chiếu', scale: scale),
                      SizedBox(width: 22 * scale),
                      _ActionTab(label: 'Gọi', scale: scale),
                    ],
                  ),
                ),
                SizedBox(height: 8 * scale),
                Container(height: 8 * scale, color: const Color(0xFFE8D66C)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(10 * scale, 10 * scale, 10 * scale, 16 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 18 * scale, color: Colors.black87),
                            SizedBox(width: 10 * scale),
                            Expanded(
                              child: Text(
                                cinema.cityAddress,
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10 * scale),
                        Text(
                          'Chỉ đường',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: const Color(0xFF555555),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 22 * scale),
                        _InfoRow(
                          label: 'Khoảng cách',
                          value: '${cinema.distanceInKm.toStringAsFixed(1)} km',
                          scale: scale,
                        ),
                        SizedBox(height: 12 * scale),
                        _InfoRow(
                          label: 'Tọa độ',
                          value: '${cinema.latitude.toStringAsFixed(6)}, ${cinema.longitude.toStringAsFixed(6)}',
                          scale: scale,
                        ),
                        SizedBox(height: 18 * scale),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: 'Mở Google Map',
                                scale: scale,
                                onTap: () => _launchUrl(googleMapSearchUrl),
                              ),
                            ),
                            SizedBox(width: 10 * scale),
                            Expanded(
                              child: _ActionButton(
                                label: 'Chỉ đường',
                                scale: scale,
                                onTap: () => _launchUrl(googleDirectionUrl),
                              ),
                            ),
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

  String _buildGoogleMapsSearchUrl(NearbyCinemaItem cinema) {
    final lat = cinema.latitude.toStringAsFixed(6);
    final lng = cinema.longitude.toStringAsFixed(6);
    final query = Uri.encodeComponent('${cinema.cinemaName}, ${cinema.cityAddress} ($lat,$lng)');
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }

  String _buildGoogleMapsDirectionsUrl(NearbyCinemaItem cinema) {
    final lat = cinema.latitude.toStringAsFixed(6);
    final lng = cinema.longitude.toStringAsFixed(6);
    final destination = Uri.encodeComponent('${cinema.cinemaName}, ${cinema.cityAddress} ($lat,$lng)');
    return 'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _MapPreview extends StatefulWidget {
  const _MapPreview({
    required this.cinema,
    required this.scale,
  });

  final NearbyCinemaItem cinema;
  final double scale;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  WebViewController? _controller;

  bool get _supportsEmbeddedMap =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_supportsEmbeddedMap) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..loadRequest(Uri.parse(_buildGoogleMapsUrl()));
    }
  }

  String _buildGoogleMapsUrl() {
    final lat = widget.cinema.latitude.toStringAsFixed(6);
    final lng = widget.cinema.longitude.toStringAsFixed(6);
    final query = Uri.encodeComponent('${widget.cinema.cinemaName}, ${widget.cinema.cityAddress}');
    return 'https://www.google.com/maps?q=$query&ll=$lat,$lng&z=16&output=embed';
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    if (!_supportsEmbeddedMap || _controller == null) {
      return Container(
        height: 220 * scale,
        width: double.infinity,
        color: const Color(0xFFF3F3F3),
        alignment: Alignment.center,
        child: Text(
          'Google Maps chỉ hỗ trợ nhúng trên Android/iOS',
          style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF666666)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 220 * scale,
      width: double.infinity,
      child: WebViewWidget(controller: _controller!),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.scale,
    required this.title,
    required this.onBack,
    required this.onMenuTap,
  });

  final double scale;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54 * scale,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, size: 24 * scale, color: const Color(0xFFE14A4A)),
          ),
          Text(
            title,
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

class _ActionTab extends StatelessWidget {
  const _ActionTab({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12 * scale,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: const Color(0xFF2B2B2B),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.scale});

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92 * scale,
          child: Text(
            label,
            style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12 * scale, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.scale, required this.onTap});

  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD4C15F)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12 * scale,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}