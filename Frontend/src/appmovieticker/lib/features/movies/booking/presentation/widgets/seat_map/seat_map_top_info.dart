import 'package:flutter/material.dart';

import 'package:appmovieticker/features/movies/booking/data/models/booking/seat_map_item.dart';

class SeatMapTopInfo extends StatelessWidget {
  const SeatMapTopInfo({
    super.key,
    required this.scale,
    required this.seatMap,
    required this.fallbackCinema,
    required this.fallbackHall,
    required this.experienceType,
    required this.startTime,
    required this.showDate,
  });

  final double scale;
  final SeatMapResponseItem? seatMap;
  final String fallbackCinema;
  final String fallbackHall;
  final String experienceType;
  final String startTime;
  final DateTime? showDate;

  @override
  Widget build(BuildContext context) {
    final displayCinema = seatMap?.cinemaName.isNotEmpty == true ? seatMap!.cinemaName : fallbackCinema;
    final displayHall = seatMap?.hallName.isNotEmpty == true ? seatMap!.hallName : fallbackHall;
    final activeShowDate = seatMap?.showDate ?? showDate;
    final showDateText = activeShowDate == null
        ? ''
        : '${activeShowDate.day.toString().padLeft(2, '0')}-${activeShowDate.month.toString().padLeft(2, '0')}-${activeShowDate.year}';

    return Padding(
      padding: EdgeInsets.fromLTRB(12 * scale, 0, 12 * scale, 6 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayCinema,
                  style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  '$displayHall • $experienceType • $startTime${showDateText.isNotEmpty ? ' • $showDateText' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5 * scale, color: const Color(0xFF555555)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
