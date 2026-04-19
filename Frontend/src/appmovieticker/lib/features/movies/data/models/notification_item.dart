class NotificationItem {
  const NotificationItem({
    required this.notificationId,
    required this.bookingId,
    required this.channel,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  final String notificationId;
  final int? bookingId;
  final String channel;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return NotificationItem(
      notificationId: (json['notificationId'] ?? '').toString(),
      bookingId: parseInt(json['bookingId']),
      channel: (json['channel'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
      isRead: json['isRead'] == true,
    );
  }
}
