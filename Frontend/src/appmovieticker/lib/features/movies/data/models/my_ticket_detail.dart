class MyTicketDetail {
  const MyTicketDetail({
    required this.bookingId,
    required this.ticketCode,
    required this.movieTitle,
    required this.movieImageUrl,
    required this.movieAge,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.hallName,
    required this.showDate,
    required this.showTime,
    required this.isExpired,
    required this.statusLabel,
    required this.seats,
    required this.seatTotal,
    required this.comboTotal,
    required this.voucherDiscount,
    required this.vatRate,
    required this.vatAmount,
    required this.grandTotal,
    required this.barcodeValue,
    required this.serialNumber,
  });

  final int bookingId;
  final String ticketCode;
  final String movieTitle;
  final String movieImageUrl;
  final String movieAge;
  final String cinemaName;
  final String cinemaAddress;
  final String hallName;
  final DateTime? showDate;
  final String showTime;
  final bool isExpired;
  final String statusLabel;
  final List<TicketSeatItem> seats;
  final double seatTotal;
  final double comboTotal;
  final double voucherDiscount;
  final double vatRate;
  final double vatAmount;
  final double grandTotal;
  final String barcodeValue;
  final String serialNumber;

  factory MyTicketDetail.fromJson(Map<String, dynamic> json) {
    double readDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? readDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final rawSeats = (json['seats'] is List) ? json['seats'] as List : const [];

    return MyTicketDetail(
      bookingId: (json['bookingId'] is int) ? json['bookingId'] as int : int.tryParse('${json['bookingId']}') ?? 0,
      ticketCode: (json['ticketCode'] ?? '').toString(),
      movieTitle: (json['movieTitle'] ?? '').toString(),
      movieImageUrl: (json['movieImageUrl'] ?? '').toString(),
      movieAge: (json['movieAge'] ?? '').toString(),
      cinemaName: (json['cinemaName'] ?? '').toString(),
      cinemaAddress: (json['cinemaAddress'] ?? '').toString(),
      hallName: (json['hallName'] ?? '').toString(),
      showDate: readDate(json['showDate']),
      showTime: (json['showTime'] ?? '').toString(),
      isExpired: json['isExpired'] == true,
      statusLabel: (json['statusLabel'] ?? '').toString(),
      seats: rawSeats
          .whereType<Map>()
          .map((e) => TicketSeatItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      seatTotal: readDouble(json['seatTotal']),
      comboTotal: readDouble(json['comboTotal']),
      voucherDiscount: readDouble(json['voucherDiscount']),
      vatRate: readDouble(json['vatRate']),
      vatAmount: readDouble(json['vatAmount']),
      grandTotal: readDouble(json['grandTotal']),
      barcodeValue: (json['barcodeValue'] ?? '').toString(),
      serialNumber: (json['serialNumber'] ?? '').toString(),
    );
  }
}

class TicketSeatItem {
  const TicketSeatItem({
    required this.seatNumber,
    required this.seatClass,
    required this.ticketPrice,
  });

  final String seatNumber;
  final String seatClass;
  final double ticketPrice;

  factory TicketSeatItem.fromJson(Map<String, dynamic> json) {
    double readDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return TicketSeatItem(
      seatNumber: (json['seatNumber'] ?? '').toString(),
      seatClass: (json['seatClass'] ?? '').toString(),
      ticketPrice: readDouble(json['ticketPrice']),
    );
  }
}
