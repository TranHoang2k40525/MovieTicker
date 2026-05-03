import 'package:flutter/material.dart';

class SeatMapScreenHeader extends StatelessWidget {
  const SeatMapScreenHeader({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10 * scale),
        Container(
          width: 140 * scale,
          height: 36 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF8F4D4B),
            borderRadius: BorderRadius.circular(18 * scale),
          ),
          alignment: Alignment.center,
          child: Text(
            'Màn hình',
            style: TextStyle(fontSize: 11 * scale, color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(height: 10 * scale),
      ],
    );
  }
}
