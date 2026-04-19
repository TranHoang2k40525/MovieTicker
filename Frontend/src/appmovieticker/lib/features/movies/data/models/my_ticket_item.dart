class MyTicketItem {
  const MyTicketItem({
    required this.bookingId,
    required this.ticketCode,
    required this.movieTitle,
    required this.movieImageUrl,
    required this.cinemaName,
    required this.showDate,
    required this.showTime,
    required this.totalPrice,
    required this.isExpired,
    required this.statusLabel,
  });

  final int bookingId;
  final String ticketCode;
  final DateTime? showDate;
  final String showTime;
  final String movieTitle;
  final String movieImageUrl;
  final String cinemaName;
  final double totalPrice;
  final bool isExpired;
  final String statusLabel;

  factory MyTicketItem.fromJson(Map<String, dynamic> json) {
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

    return MyTicketItem(
      bookingId: (json['bookingId'] is int) ? json['bookingId'] as int : int.tryParse('${json['bookingId']}') ?? 0,
      ticketCode: (json['ticketCode'] ?? '').toString(),
      movieTitle: (json['movieTitle'] ?? '').toString(),
      movieImageUrl: (json['movieImageUrl'] ?? '').toString(),
      cinemaName: (json['cinemaName'] ?? '').toString(),
      showDate: readDate(json['showDate']),
      showTime: (json['showTime'] ?? '').toString(),
      totalPrice: readDouble(json['totalPrice']),
      isExpired: json['isExpired'] == true,
      statusLabel: (json['statusLabel'] ?? '').toString(),
    );
  }
}
