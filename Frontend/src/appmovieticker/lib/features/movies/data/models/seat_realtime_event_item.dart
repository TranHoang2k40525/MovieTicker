class SeatRealtimeEventItem {
  const SeatRealtimeEventItem({
    required this.showId,
    required this.holdId,
    required this.state,
    required this.reason,
    required this.seatIds,
    required this.expiresAtUtc,
    required this.occurredAtUtc,
  });

  final int showId;
  final int holdId;
  final String state;
  final String reason;
  final List<int> seatIds;
  final DateTime? expiresAtUtc;
  final DateTime? occurredAtUtc;

  factory SeatRealtimeEventItem.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? readDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    List<int> readSeatIds(dynamic value) {
      if (value is List) {
        return value
            .map((e) => readInt(e))
            .where((e) => e > 0)
            .toList();
      }
      return const [];
    }

    return SeatRealtimeEventItem(
      showId: readInt(json['showId']),
      holdId: readInt(json['holdId']),
      state: (json['state'] ?? '').toString().toLowerCase(),
      reason: (json['reason'] ?? '').toString().toLowerCase(),
      seatIds: readSeatIds(json['seatIds']),
      expiresAtUtc: readDate(json['expiresAtUtc']),
      occurredAtUtc: readDate(json['occurredAtUtc']),
    );
  }
}
