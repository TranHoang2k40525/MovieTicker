import 'package:flutter/material.dart';

import 'package:appmovieticker/features/movies/booking/data/models/booking/seat_map_item.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_styles.dart';

class SeatMapLegendRow extends StatelessWidget {
  const SeatMapLegendRow({super.key, required this.scale, required this.legend});

  final double scale;
  final List<SeatLegendItem> legend;

  @override
  Widget build(BuildContext context) {
    final items = legend.isNotEmpty
        ? legend
        : const [
            SeatLegendItem(key: 'booked', label: 'Đã đặt'),
            SeatLegendItem(key: 'held', label: 'Đang tạm giữ'),
            SeatLegendItem(key: 'selected', label: 'Đang chọn'),
            SeatLegendItem(key: 'VIP', label: 'VIP'),
            SeatLegendItem(key: 'THUONG', label: 'Thường'),
            SeatLegendItem(key: 'SWEET_BOX', label: 'Sweet box'),
          ];

    return Wrap(
      spacing: 16 * scale,
      runSpacing: 10 * scale,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16 * scale,
                  height: 16 * scale,
                  color: seatMapLegendColor(item.key),
                ),
                SizedBox(width: 6 * scale),
                Text(item.label, style: TextStyle(fontSize: 10 * scale)),
              ],
            ),
          )
          .toList(),
    );
  }
}
