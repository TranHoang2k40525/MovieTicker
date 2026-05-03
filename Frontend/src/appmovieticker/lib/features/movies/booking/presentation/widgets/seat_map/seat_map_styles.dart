import 'package:flutter/material.dart';

import 'package:appmovieticker/features/movies/booking/data/models/booking/seat_map_item.dart';

Color seatMapColor(SeatMapCellItem cell, bool isSelected) {
  if (isSelected) return const Color(0xFF163FCC);
  switch (cell.state) {
    case 'booked':
      return const Color(0xFFA46F62);
    case 'held':
    case 'holding':
    case 'held_by_other':
      return const Color(0xFFF7D54A);
    default:
      if (cell.isCoupleSeat) return const Color(0xFFD81CBF);
      if (cell.seatClass == 'VIP') return const Color(0xFFF31818);
      return const Color(0xFFE3E0D7);
  }
}

Color seatMapForegroundColor(SeatMapCellItem cell, bool isSelected) {
  if (isSelected) return Colors.white;
  if (cell.state == 'booked') return Colors.white;
  if (cell.state == 'held' || cell.state == 'holding' || cell.state == 'held_by_other') {
    return Colors.black;
  }
  if (cell.seatClass == 'VIP' || cell.isCoupleSeat) return Colors.white;
  return Colors.black;
}

String seatMapShortSeatLabel(String seatNumber) {
  if (seatNumber.length <= 3) {
    return seatNumber;
  }
  return seatNumber.substring(0, 3);
}

Color seatMapLegendColor(String key) {
  switch (key) {
    case 'booked':
      return const Color(0xFFA46F62);
    case 'held':
    case 'holding':
    case 'held_by_other':
      return const Color(0xFFF7D54A);
    case 'selected':
      return const Color(0xFF163FCC);
    case 'VIP':
      return const Color(0xFFF31818);
    case 'THUONG':
      return const Color(0xFFE3E0D7);
    case 'SWEET_BOX':
      return const Color(0xFFD81CBF);
    default:
      return const Color(0xFFE3E0D7);
  }
}
