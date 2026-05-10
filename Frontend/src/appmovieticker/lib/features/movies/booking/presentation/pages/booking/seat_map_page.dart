import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:appmovieticker/core/realtime/seat_realtime_client.dart';
import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/core/network/dio_client.dart';
import 'package:appmovieticker/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:appmovieticker/features/auth/presentation/pages/login_page.dart';
import 'package:appmovieticker/features/movies/movie/data/datasources/movie/movies_remote_datasource.dart';
import 'package:appmovieticker/features/movies/ticker/data/models/realtime/seat_realtime_event_item.dart';
import 'package:appmovieticker/features/movies/booking/data/models/booking/seat_map_item.dart';
import 'package:appmovieticker/features/movies/product/presentation/pages/product/combo_selection_page.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_bottom_bar.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_content.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_empty_state.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_header.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_legend_row.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_screen_header.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_top_info.dart';

class SeatMapPage extends StatefulWidget {
  const SeatMapPage({
    super.key,
    required this.showId,
    required this.movieTitle,
    this.moviePosterUrl,
    required this.cinemaName,
    required this.cinemaAddress,
    required this.hallName,
    required this.experienceType,
    required this.startTime,
    required this.showDate,
    this.movieRuntime,
    this.movieAge,
    this.movieGenre,
  });

  final int showId;
  final String movieTitle;
  final String? moviePosterUrl;
  final String cinemaName;
  final String cinemaAddress;
  final String hallName;
  final String experienceType;
  final String startTime;
  final DateTime? showDate;
  final int? movieRuntime;
  final String? movieAge;
  final String? movieGenre;

  @override
  State<SeatMapPage> createState() => _SeatMapPageState();
}

class _SeatMapPageState extends State<SeatMapPage> {
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();
  final AuthLocalDataSource _localDataSource = di.sl<AuthLocalDataSource>();
  final DioClient _dioClient = di.sl<DioClient>();
  final TransformationController _transformController = TransformationController();
  final Set<int> _selectedSeatIds = <int>{};
  final SeatRealtimeClient _seatRealtimeClient = SeatRealtimeClient();
  Timer? _autoRefreshTimer;

  SeatMapResponseItem? _seatMap;
  bool _loading = true;
  String? _message;
  bool _requestedLogin = false;
  bool _hasPersistedToken = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadSeatMap();
    _startAutoRefresh();
    _connectRealtime();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _disconnectRealtime();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _connectRealtime() async {
    try {
      await _seatRealtimeClient.connect(
        showId: widget.showId,
        onSeatChanged: (payload) {
          if (!mounted) return;
          final event = SeatRealtimeEventItem.fromJson(payload);
          if (event.showId != widget.showId || event.seatIds.isEmpty) {
            return;
          }
          _applyRealtimeSeatState(event);
        },
      );
    } catch (_) {
      // Seat map still works with polling fallback when realtime connection fails.
    }
  }

  Future<void> _disconnectRealtime() async {
    try {
      await _seatRealtimeClient.leaveRoom(widget.showId);
      await _seatRealtimeClient.disconnect();
    } catch (_) {
      // ignore teardown errors
    }
  }

  void _applyRealtimeSeatState(SeatRealtimeEventItem event) {
    final current = _seatMap;
    if (current == null) {
      return;
    }

    final updates = event.seatIds.toSet();
    final rows = current.rows
        .map((row) {
          final cells = row.cells
              .map((cell) {
                if (cell.seatId == null || !updates.contains(cell.seatId)) {
                  return cell;
                }

                final isAvailable = event.state == 'available';
                final nextState = isAvailable
                    ? 'available'
                    : event.state == 'booked'
                        ? 'booked'
                        : 'held';

                return SeatMapCellItem(
                  colSeat: cell.colSeat,
                  cellType: cell.cellType,
                  state: nextState,
                  selectable: isAvailable,
                  isCoupleSeat: cell.isCoupleSeat,
                  isOddEdgeRisk: cell.isOddEdgeRisk,
                  seatId: cell.seatId,
                  seatNumber: cell.seatNumber,
                  seatClass: cell.seatClass,
                  seatPrice: cell.seatPrice,
                  pairId: cell.pairId,
                  pairSeatId: cell.pairSeatId,
                );
              })
              .toList();

          return SeatMapRowItem(rowSeat: row.rowSeat, cells: cells);
        })
        .toList();

    setState(() {
      _seatMap = SeatMapResponseItem(
        showId: current.showId,
        movieId: current.movieId,
        movieTitle: current.movieTitle,
        showDate: current.showDate,
        startTime: current.startTime,
        cinemaId: current.cinemaId,
        cinemaName: current.cinemaName,
        cinemaAddress: current.cinemaAddress,
        hallId: current.hallId,
        hallName: current.hallName,
        rows: rows,
        legend: current.legend,
        validationWarnings: current.validationWarnings,
      );

      if (event.state != 'available') {
        _selectedSeatIds.removeWhere((x) => updates.contains(x));
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted || _loading) {
        return;
      }
      _loadSeatMap(silent: true);
    });
  }

  Future<void> _loadSeatMap({bool silent = false}) async {
    final token = await _localDataSource.getToken();
    _hasPersistedToken = token != null && token.isNotEmpty;

    setState(() {
      if (!silent) {
        _loading = true;
      }
      if (!silent) {
        _message = null;
      }
    });

    try {
      final seatMap = await _remoteDataSource.getSeatMap(showId: widget.showId);
      if (!mounted) return;
      setState(() {
        _seatMap = seatMap;
        _syncSelectedSeatsWithLatestMap(seatMap);
        _message = seatMap.rows.isEmpty ? 'Không có sơ đồ ghế cho suất chiếu này.' : null;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 401) {
        await _localDataSource.clearToken();
        _hasPersistedToken = false;
      }

      if (e.response?.statusCode == 401 && !_requestedLogin) {
        _requestedLogin = true;
        final loggedIn = await _openLogin();
        if (!mounted) return;
        _requestedLogin = false;
        if (loggedIn == true) {
          await _loadSeatMap(silent: silent);
          return;
        }
      }

      setState(() {
        _seatMap = null;
        _message = e.response?.statusCode == 401 && _hasPersistedToken
            ? 'Đã có phiên đăng nhập lưu, nhưng không tải được sơ đồ ghế. Vui lòng thử lại.'
            : _parseErrorMessage(e) ?? 'Không tải được sơ đồ ghế. Vui lòng thử lại.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _seatMap = null;
        _message = 'Không tải được sơ đồ ghế. Vui lòng thử lại.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _loading = false;
        }
      });
    }
  }

  void _syncSelectedSeatsWithLatestMap(SeatMapResponseItem seatMap) {
    final latestSelectableSeatIds = <int>{};
    for (final row in seatMap.rows) {
      for (final cell in row.cells) {
        if (cell.seatId != null && cell.selectable) {
          latestSelectableSeatIds.add(cell.seatId!);
        }
      }
    }

    _selectedSeatIds.removeWhere((seatId) => !latestSelectableSeatIds.contains(seatId));
  }

  Future<bool?> _openLogin() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginPage(returnToPreviousOnSuccess: true),
      ),
    );
    return loggedIn;
  }

  String? _parseErrorMessage(DioException exception) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['Message'];
      if (message != null) {
        return message.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final seatMap = _seatMap;
    final scale = _uiScale(context);
    final movieAgeLabel = widget.movieAge ?? 'P';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 * scale, 6 * scale, 8 * scale, 8 * scale),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28 * scale),
            ),
            child: Column(
              children: [
                  SeatMapHeader(
                  scale: scale,
                  title: widget.movieTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  onRefresh: () => _loadSeatMap(),
                ),
                  SeatMapTopInfo(
                    scale: scale,
                    seatMap: seatMap,
                    fallbackCinema: widget.cinemaName,
                    fallbackHall: widget.hallName,
                    experienceType: widget.experienceType,
                    startTime: widget.startTime,
                    showDate: widget.showDate,
                  ),
                Expanded(
                  child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _message != null
                            ? SeatMapEmptyState(message: _message!, onRetry: _loadSeatMap)
                          : Container(
                              color: const Color(0xFFEAD86A),
                              child: Column(
                                children: [
                                    SeatMapScreenHeader(scale: scale),
                                  SizedBox(height: 8 * scale),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                            final content = SeatMapContent(
                                            seatMap: seatMap!,
                                            selectedSeatIds: _selectedSeatIds,
                                            onSeatTap: (cell) => _toggleSeat(cell),
                                            scale: scale,
                                            cellSize: 25 * scale,
                                            miniCellSize: math.max(2.0, (25 * scale) * 0.7 / 5),
                                            transformationController: _transformController,
                                            viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
                                          );

                                          return Column(
                                            children: [
                                              Expanded(child: content),
                                              SizedBox(height: 10 * scale),
                                              SeatMapLegendRow(scale: scale, legend: seatMap.legend),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
                SeatMapBottomBar(
                  scale: scale,
                  movieTitle: widget.movieTitle,
                  movieAge: movieAgeLabel,
                  movieRuntime: widget.movieRuntime,
                  selectedCount: _selectedSeatIds.length,
                  selectedPrice: _selectedPrice(seatMap),
                  onBook: _selectedSeatIds.isEmpty ? null : _handleBook,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSeat(SeatMapCellItem cell) {
    if (!cell.selectable || cell.seatId == null) {
      return;
    }

    final pairCell = cell.isCoupleSeat ? _resolveCouplePair(cell) : null;
    final pairSeatId = pairCell?.seatId;
    final validationError = _selectionValidationError(cell, pairCell);
    if (validationError != null) {
      _showSeatWarning(validationError);
      return;
    }

    if (cell.isCoupleSeat) {
      if (pairCell == null) {
        _showSeatWarning('Ghế này là ghế lẻ cuối hàng, không thể đặt.');
        return;
      }

      if (!pairCell.selectable && !_selectedSeatIds.contains(pairCell.seatId)) {
        _showSeatWarning('Không thể chọn ghế này vì ghế ghép đang bị khóa hoặc đã bán.');
        return;
      }
    }

    setState(() {
      if (cell.isCoupleSeat && pairSeatId != null) {
        final bothSelected = _selectedSeatIds.contains(cell.seatId) && _selectedSeatIds.contains(pairSeatId);
        if (bothSelected) {
          _selectedSeatIds.remove(cell.seatId);
          _selectedSeatIds.remove(pairSeatId);
        } else {
          _selectedSeatIds.add(cell.seatId!);
          _selectedSeatIds.add(pairSeatId);
        }
      } else {
        if (_selectedSeatIds.contains(cell.seatId)) {
          _selectedSeatIds.remove(cell.seatId);
        } else {
          _selectedSeatIds.add(cell.seatId!);
        }
      }
    });

    if (cell.isOddEdgeRisk) {
      _showSeatWarning('Ghế này có nguy cơ tạo ghế lẻ ở biên.');
    }
  }

  String? _selectionValidationError(SeatMapCellItem cell, SeatMapCellItem? pairCell) {
    final seatMap = _seatMap;
    if (seatMap == null) return null;

    final row = seatMap.rows.firstWhere(
      (item) => item.cells.any((seat) => seat.seatId == cell.seatId),
      orElse: () => const SeatMapRowItem(rowSeat: '', cells: []),
    );
    if (row.cells.isEmpty) return null;

    final seatCells = row.cells.where((item) => item.cellType == 'SEAT').toList();
    final cellIndex = seatCells.indexWhere((item) => item.seatId == cell.seatId);
    if (cellIndex < 0) return null;

    final availableIndexes = seatCells
        .asMap()
        .entries
        .where((entry) => _isAvailableSeatCell(entry.value))
        .map((entry) => entry.key)
        .toSet();

    final isCurrentlySelected = _selectedSeatIds.contains(cell.seatId);

    // Business exception: if the row only has 2 sellable seats left, allow them
    // even when they would otherwise violate rule 1 or rule 2.
    if (!isCurrentlySelected && availableIndexes.length == 2 && availableIndexes.contains(cellIndex)) {
      return null;
    }

    final selectedIndexes = seatCells
        .asMap()
        .entries
        .where((entry) => _selectedSeatIds.contains(entry.value.seatId))
        .map((entry) => entry.key)
        .toSet();

    final occupiedIndexes = seatCells
        .asMap()
        .entries
        .where((entry) => _isOccupiedSeatCell(entry.value))
        .map((entry) => entry.key)
        .toSet();

    final nextSelectedIndexes = <int>{...selectedIndexes, ...occupiedIndexes};
    if (isCurrentlySelected) {
      nextSelectedIndexes.remove(cellIndex);
    } else {
      nextSelectedIndexes.add(cellIndex);
    }

    if (pairCell?.seatId != null) {
      final pairIndex = seatCells.indexWhere((item) => item.seatId == pairCell!.seatId);
      if (pairIndex >= 0) {
        if (isCurrentlySelected) {
          nextSelectedIndexes.remove(pairIndex);
        } else {
          nextSelectedIndexes.add(pairIndex);
        }
      }
    }

    final leftEdgeIndex = 0;
    final rightEdgeIndex = seatCells.length - 1;
    final leftAdjacentIndex = 1;
    final rightAdjacentIndex = seatCells.length - 2;

    if (nextSelectedIndexes.contains(leftAdjacentIndex) && !nextSelectedIndexes.contains(leftEdgeIndex)) {
      return 'Không thể chọn ghế ở cạnh ngoài cùng bên trái khi ghế mép chưa được chọn.';
    }

    if (nextSelectedIndexes.contains(rightAdjacentIndex) && !nextSelectedIndexes.contains(rightEdgeIndex)) {
      return 'Không thể chọn ghế ở cạnh ngoài cùng bên phải khi ghế mép chưa được chọn.';
    }

    final sortedIndexes = nextSelectedIndexes.toList()..sort();
    if (sortedIndexes.length < 2) {
      return null;
    }

    for (var i = 0; i < sortedIndexes.length - 1; i++) {
      final gap = sortedIndexes[i + 1] - sortedIndexes[i] - 1;
      if (gap == 1) {
        return 'Không thể để trống đúng 1 ghế giữa 2 ghế đang chọn.';
      }
    }

    if (cell.isCoupleSeat && pairCell == null) {
      return 'Ghế này là ghế lẻ cuối hàng, không thể đặt.';
    }

    return null;
  }

  bool _isOccupiedSeatCell(SeatMapCellItem cell) {
    if (cell.cellType != 'SEAT') {
      return false;
    }

    return cell.state.toLowerCase() != 'available' || !cell.selectable;
  }

  bool _isAvailableSeatCell(SeatMapCellItem cell) {
    if (cell.cellType != 'SEAT') {
      return false;
    }

    return cell.state.toLowerCase() == 'available' && cell.selectable;
  }

  SeatMapCellItem? _resolveCouplePair(SeatMapCellItem cell) {
    final seatMap = _seatMap;

    if (seatMap == null) {
      return null;
    }

    final row = seatMap.rows.firstWhere(
      (item) => item.cells.any((seat) => seat.seatId == cell.seatId),
      orElse: () => const SeatMapRowItem(rowSeat: '', cells: []),
    );
    if (row.cells.isEmpty) {
      return null;
    }

    final seatIndex = row.cells.indexWhere((item) => item.seatId == cell.seatId);
    if (seatIndex < 0) {
      return null;
    }

    final seatCells = row.cells.where((item) => item.cellType == 'SEAT').toList();
    final seatPosition = seatCells.indexWhere((item) => item.seatId == cell.seatId);
    if (seatPosition < 0) {
      return null;
    }

    final isLeftSeatInPair = seatPosition.isEven;
    final pairPosition = isLeftSeatInPair ? seatPosition + 1 : seatPosition - 1;
    if (pairPosition < 0 || pairPosition >= seatCells.length) {
      return null;
    }

    final pairCandidate = seatCells[pairPosition];
    if (!pairCandidate.isCoupleSeat) {
      return null;
    }

    return pairCandidate;
  }

  void _showSeatWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double _selectedPrice(SeatMapResponseItem? seatMap) {
    if (seatMap == null) return 0;

    final seats = <int, SeatMapCellItem>{};
    for (final row in seatMap.rows) {
      for (final cell in row.cells) {
        if (cell.seatId != null) {
          seats[cell.seatId!] = cell;
        }
      }
    }

    var total = 0.0;
    for (final seatId in _selectedSeatIds) {
      total += seats[seatId]?.seatPrice ?? 0;
    }
    return total;
  }

  void _handleBook() {
    _proceedToComboSelection();
  }

  Future<void> _proceedToComboSelection() async {
    final scale = _uiScale(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            SizedBox(width: 16 * scale),
            const Expanded(child: Text('Đang xác nhận ghế...')),
          ],
        ),
      ),
    );

    try {
      final token = await _localDataSource.getToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập lại')),
        );
        return;
      }

      // Call backend API to hold seats
      final selectedSeatsList = _selectedSeatIds.toList();
      final response = await _dioClient.dio.post(
        '/bookings/holds',
        data: {
          'showId': widget.showId,
          'seatIds': selectedSeatsList,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      final responseData = response.data;
      final success = responseData['success'] ?? false;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Không thể giữ ghế')),
        );
        return;
      }

      final holdData = responseData['data'] ?? responseData;
      final holdId = holdData['holdId'] as int?;
      final expiresAtUtc = holdData['expiresAtUtc'] as String?;

      if (holdId == null || expiresAtUtc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dữ liệu phản hồi không hợp lệ')),
        );
        return;
      }

      if (!mounted) return;

      // Navigate to combo selection page
      final seatMap = _seatMap;
      if (seatMap != null) {
        final selectedSeatNumbers = selectedSeatsList.map((seatId) {
          for (final row in seatMap.rows) {
            for (final cell in row.cells) {
              if (cell.seatId == seatId) {
                return cell.seatNumber ?? 'N/A';
              }
            }
          }
          return 'N/A';
        }).toList();

        final flowResult = await Navigator.of(context).push<dynamic>(
          MaterialPageRoute(
            builder: (_) => ComboSelectionPage(
              movieTitle: widget.movieTitle,
              moviePosterUrl: widget.moviePosterUrl,
              cinemaName: widget.cinemaName,
              cinemaAddress: widget.cinemaAddress,
              holdId: holdId,
              expiresAt: DateTime.parse(expiresAtUtc),
              selectedSeats: selectedSeatNumbers,
              selectedSeatTotalPrice: _selectedPrice(seatMap),
              showId: widget.showId,
            ),
          ),
        );

        if (!mounted) return;
        if (flowResult == 'hold_expired') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hết thời gian giữ ghế. Vui lòng chọn lại suất chiếu.')),
          );
          Navigator.of(context).pop();
          return;
        }

        await _loadSeatMap();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      
      final errorMsg = _parseErrorMessage(e) ?? 'Không thể giữ ghế. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  double _uiScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < 700) {
      return (size.width / 430).clamp(0.88, 1.06);
    }
    return (size.width / 1200).clamp(0.9, 1.25);
  }
}