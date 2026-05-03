class SeatMapResponseItem {
  const SeatMapResponseItem({
    required this.showId,
    required this.movieId,
    required this.movieTitle,
    required this.showDate,
    required this.startTime,
    required this.cinemaId,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.hallId,
    required this.hallName,
    required this.rows,
    required this.legend,
    required this.validationWarnings,
  });

  final int showId;
  final int movieId;
  final String movieTitle;
  final DateTime? showDate;
  final String startTime;
  final int cinemaId;
  final String cinemaName;
  final String cinemaAddress;
  final int hallId;
  final String hallName;
  final List<SeatMapRowItem> rows;
  final List<SeatLegendItem> legend;
  final List<String> validationWarnings;

  factory SeatMapResponseItem.fromJson(Map<String, dynamic> json) {
    final rowsData = json['rows'] ?? json['Rows'];
    final legendData = json['legend'] ?? json['Legend'];
    final warningsData = json['validationWarnings'] ?? json['ValidationWarnings'];

    return SeatMapResponseItem(
      showId: _readInt(json['showId'] ?? json['ShowId']),
      movieId: _readInt(json['movieId'] ?? json['MovieId']),
      movieTitle: _readString(json['movieTitle'] ?? json['MovieTitle']),
      showDate: _readDate(json['showDate'] ?? json['ShowDate']),
      startTime: _readString(json['startTime'] ?? json['StartTime']),
      cinemaId: _readInt(json['cinemaId'] ?? json['CinemaId']),
      cinemaName: _readString(json['cinemaName'] ?? json['CinemaName']),
      cinemaAddress: _readString(json['cinemaAddress'] ?? json['CinemaAddress']),
      hallId: _readInt(json['hallId'] ?? json['HallId']),
      hallName: _readString(json['hallName'] ?? json['HallName']),
      rows: _readRows(rowsData),
      legend: _readLegend(legendData),
      validationWarnings: _readWarnings(warningsData),
    );
  }

  static List<SeatMapRowItem> _readRows(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => SeatMapRowItem.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static List<SeatLegendItem> _readLegend(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => SeatLegendItem.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static List<String> _readWarnings(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class SeatMapRowItem {
  const SeatMapRowItem({required this.rowSeat, required this.cells});

  final String rowSeat;
  final List<SeatMapCellItem> cells;

  factory SeatMapRowItem.fromJson(Map<String, dynamic> json) {
    final cellsData = json['cells'] ?? json['Cells'];
    return SeatMapRowItem(
      rowSeat: _readString(json['rowSeat'] ?? json['RowSeat']),
      cells: _readCells(cellsData),
    );
  }

  static List<SeatMapCellItem> _readCells(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => SeatMapCellItem.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static String _readString(dynamic value) => value?.toString() ?? '';
}

class SeatMapCellItem {
  const SeatMapCellItem({
    required this.colSeat,
    required this.cellType,
    required this.state,
    required this.selectable,
    required this.isCoupleSeat,
    required this.isOddEdgeRisk,
    this.seatId,
    this.seatNumber,
    this.seatClass,
    this.seatPrice,
    this.pairId,
    this.pairSeatId,
  });

  final int colSeat;
  final String cellType;
  final int? seatId;
  final String? seatNumber;
  final String? seatClass;
  final double? seatPrice;
  final int? pairId;
  final int? pairSeatId;
  final bool isCoupleSeat;
  final bool isOddEdgeRisk;
  final String state;
  final bool selectable;

  factory SeatMapCellItem.fromJson(Map<String, dynamic> json) {
    return SeatMapCellItem(
      colSeat: _readInt(json['colSeat'] ?? json['ColSeat']),
      cellType: _readString(json['cellType'] ?? json['CellType']),
      seatId: _readNullableInt(json['seatId'] ?? json['SeatId']),
      seatNumber: _readNullableString(json['seatNumber'] ?? json['SeatNumber']),
      seatClass: _readNullableString(json['seatClass'] ?? json['SeatClass']),
      seatPrice: _readNullableDouble(json['seatPrice'] ?? json['SeatPrice']),
      pairId: _readNullableInt(json['pairId'] ?? json['PairId']),
      pairSeatId: _readNullableInt(json['pairSeatId'] ?? json['PairSeatId']),
      isCoupleSeat: _readBool(json['isCoupleSeat'] ?? json['IsCoupleSeat']),
      isOddEdgeRisk: _readBool(json['isOddEdgeRisk'] ?? json['IsOddEdgeRisk']),
      state: _readString(json['state'] ?? json['State']),
      selectable: _readBool(json['selectable'] ?? json['Selectable']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static String _readString(dynamic value) => value?.toString() ?? '';
  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}

class SeatLegendItem {
  const SeatLegendItem({required this.key, required this.label});

  final String key;
  final String label;

  factory SeatLegendItem.fromJson(Map<String, dynamic> json) {
    return SeatLegendItem(
      key: _readString(json['key'] ?? json['Key']),
      label: _readString(json['label'] ?? json['Label']),
    );
  }

  static String _readString(dynamic value) => value?.toString() ?? '';
}