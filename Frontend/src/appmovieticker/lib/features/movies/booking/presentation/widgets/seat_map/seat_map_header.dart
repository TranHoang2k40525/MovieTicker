import 'package:flutter/material.dart';

class SeatMapHeader extends StatelessWidget {
  const SeatMapHeader({super.key, required this.scale, required this.title, required this.onBack, required this.onRefresh});

  final double scale;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, size: 24 * scale, color: const Color(0xFFE14A4A)),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, size: 24 * scale, color: const Color(0xFF1D4ED8)),
            tooltip: 'Tải lại sơ đồ ghế',
          ),
        ],
      ),
    );
  }
}
