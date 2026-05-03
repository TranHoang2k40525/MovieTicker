import 'package:flutter/material.dart';

class SeatMapBottomBar extends StatelessWidget {
  const SeatMapBottomBar({
    super.key,
    required this.scale,
    required this.movieTitle,
    required this.movieAge,
    required this.movieRuntime,
    required this.selectedCount,
    required this.selectedPrice,
    required this.onBook,
  });

  final double scale;
  final String movieTitle;
  final String movieAge;
  final int? movieRuntime;
  final int selectedCount;
  final double selectedPrice;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 12 * scale),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0D7B0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(movieTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700)),
                SizedBox(height: 2 * scale),
                Text(
                  '$movieAge${movieRuntime != null ? ' • $movieRuntime phút' : ''}',
                  style: TextStyle(fontSize: 10 * scale, color: const Color(0xFF666666)),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  selectedCount == 0 ? 'Chưa chọn ghế' : '$selectedCount ghế • ${selectedPrice.toStringAsFixed(0)}đ',
                  style: TextStyle(fontSize: 10 * scale, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onBook,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE21B1B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text('Đặt vé', style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
