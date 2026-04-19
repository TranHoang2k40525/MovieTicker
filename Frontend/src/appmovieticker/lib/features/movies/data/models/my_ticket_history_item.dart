class MyTicketHistoryItem {
  const MyTicketHistoryItem({
    required this.bookingId,
    required this.ticketCode,
    required this.serialNumber,
    required this.movieTitle,
    required this.cinemaName,
    required this.showDate,
    required this.showTime,
    required this.paymentDate,
    required this.paymentMethod,
    required this.amount,
    required this.isExpired,
    required this.statusLabel,
  });

  final int bookingId;
  final String ticketCode;
  final String serialNumber;
  final String movieTitle;
  final String cinemaName;
  final DateTime? showDate;
  final String showTime;
  final DateTime? paymentDate;
  final String paymentMethod;
  final double amount;
  final bool isExpired;
  final String statusLabel;

  factory MyTicketHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? readDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    double readDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return MyTicketHistoryItem(
      bookingId: (json['bookingId'] is int) ? json['bookingId'] as int : int.tryParse('${json['bookingId']}') ?? 0,
      ticketCode: (json['ticketCode'] ?? '').toString(),
      serialNumber: (json['serialNumber'] ?? '').toString(),
      movieTitle: (json['movieTitle'] ?? '').toString(),
      cinemaName: (json['cinemaName'] ?? '').toString(),
      showDate: readDate(json['showDate']),
      showTime: (json['showTime'] ?? '').toString(),
      paymentDate: readDate(json['paymentDate']),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      amount: readDouble(json['amount']),
      isExpired: json['isExpired'] == true,
      statusLabel: (json['statusLabel'] ?? '').toString(),
    );
  }
}
