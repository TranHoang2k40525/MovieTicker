import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/seat_map_item.dart';
import 'combo_selection_page.dart';

class SeatMapPage extends StatefulWidget {
  const SeatMapPage({
    super.key,
    required this.showId,
    required this.movieTitle,
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
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadSeatMap() async {
    final token = await _localDataSource.getToken();
    _hasPersistedToken = token != null && token.isNotEmpty;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final seatMap = await _remoteDataSource.getSeatMap(showId: widget.showId);
      if (!mounted) return;
      setState(() {
        _seatMap = seatMap;
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
          await _loadSeatMap();
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
        _loading = false;
      });
    }
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
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1.2),
            ),
            child: Column(
              children: [
                _Header(
                  scale: scale,
                  title: widget.movieTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                _buildTopInfo(scale, seatMap),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _message != null
                          ? _EmptyState(message: _message!, onRetry: _loadSeatMap)
                          : Container(
                              color: const Color(0xFFEAD86A),
                              child: Column(
                                children: [
                                  _ScreenHeader(scale: scale),
                                  SizedBox(height: 8 * scale),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final content = _SeatMapContent(
                                            seatMap: seatMap!,
                                            selectedSeatIds: _selectedSeatIds,
                                            onSeatTap: (cell) => _toggleSeat(cell),
                                            scale: scale,
                                            cellSize: 25 * scale,
                                            miniCellSize: math.max(2.0, (25 * scale) / 5),
                                            transformationController: _transformController,
                                            viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
                                          );

                                          return Column(
                                            children: [
                                              Expanded(child: content),
                                              SizedBox(height: 10 * scale),
                                              _LegendRow(scale: scale, legend: seatMap.legend),
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
                _BottomBar(
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

  Widget _buildTopInfo(double scale, SeatMapResponseItem? seatMap) {
    final displayCinema = seatMap?.cinemaName.isNotEmpty == true ? seatMap!.cinemaName : widget.cinemaName;
    final displayHall = seatMap?.hallName.isNotEmpty == true ? seatMap!.hallName : widget.hallName;
    final showDate = seatMap?.showDate ?? widget.showDate;
    final showDateText = showDate == null
        ? ''
        : '${showDate.day.toString().padLeft(2, '0')}-${showDate.month.toString().padLeft(2, '0')}-${showDate.year}';

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
                  '$displayHall • ${widget.experienceType} • ${widget.startTime}${showDateText.isNotEmpty ? ' • $showDateText' : ''}',
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

  void _toggleSeat(SeatMapCellItem cell) {
    if (!cell.selectable || cell.seatId == null) {
      return;
    }

    if (cell.isCoupleSeat) {
      final pairCell = _resolveCouplePair(cell);
      if (pairCell == null) {
        _showSeatWarning('Ghế này là ghế lẻ cuối hàng, không thể đặt.');
        return;
      }

      if (!pairCell.selectable && !_selectedSeatIds.contains(pairCell.seatId)) {
        _showSeatWarning('Không thể chọn ghế này vì ghế ghép đang bị khóa hoặc đã bán.');
        return;
      }
    }

    final pairCell = cell.isCoupleSeat ? _resolveCouplePair(cell) : null;
    final pairSeatId = pairCell?.seatId;

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

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ComboSelectionPage(
              movieTitle: widget.movieTitle,
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

class _SeatMapContent extends StatelessWidget {
  const _SeatMapContent({
    required this.seatMap,
    required this.selectedSeatIds,
    required this.onSeatTap,
    required this.scale,
    required this.cellSize,
    required this.miniCellSize,
    required this.transformationController,
    required this.viewportSize,
  });

  final SeatMapResponseItem seatMap;
  final Set<int> selectedSeatIds;
  final ValueChanged<SeatMapCellItem> onSeatTap;
  final double scale;
  final double cellSize;
  final double miniCellSize;
  final TransformationController transformationController;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final grid = _buildGrid(scale, cellSize);
    final contentWidth = _gridWidth(scale, cellSize);
    final contentHeight = _gridHeight(scale, cellSize);

    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            transformationController: transformationController,
            minScale: 0.8,
            maxScale: 2.8,
            boundaryMargin: const EdgeInsets.all(80),
            constrained: false,
            child: SizedBox(
              width: contentWidth,
              height: contentHeight,
              child: grid,
            ),
          ),
        ),
        Positioned(
          top: 8 * scale,
          right: 8 * scale,
          child: _MiniMap(
            seatMap: seatMap,
            selectedSeatIds: selectedSeatIds,
            scale: scale,
            mainCellSize: cellSize,
            miniCellSize: miniCellSize,
            viewportSize: viewportSize,
            transformationController: transformationController,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(double scale, double cellSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: seatMap.rows.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 1.5 * scale),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...row.cells.map(
                (cell) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.7 * scale),
                  child: GestureDetector(
                    onTap: cell.selectable ? () => onSeatTap(cell) : null,
                    child: _SeatCell(
                      cell: cell,
                      isSelected: cell.seatId != null && selectedSeatIds.contains(cell.seatId),
                      size: cellSize,
                      scale: scale,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  double _gridWidth(double scale, double cellSize) {
    final maxColumns = seatMap.rows.fold<int>(0, (maxValue, row) => math.max(maxValue, row.cells.length));
    final cellGap = 0.7 * scale;
    return (maxColumns * (cellSize + (cellGap * 2))) + (8 * scale);
  }

  double _gridHeight(double scale, double cellSize) {
    final rowGap = 1.5 * scale;
    return (seatMap.rows.length * (cellSize + (rowGap * 2))) + (8 * scale);
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({
    required this.seatMap,
    required this.selectedSeatIds,
    required this.scale,
    required this.mainCellSize,
    required this.miniCellSize,
    required this.viewportSize,
    required this.transformationController,
  });

  final SeatMapResponseItem seatMap;
  final Set<int> selectedSeatIds;
  final double scale;
  final double mainCellSize;
  final double miniCellSize;
  final Size viewportSize;
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    final transform = transformationController.value;
    final boxWidth = 118 * scale;
    final boxHeight = 118 * scale;
    final padding = 6 * scale;
    final innerWidth = boxWidth - (padding * 2);
    final innerHeight = boxHeight - (padding * 2);
    final contentWidth = _contentWidth();
    final contentHeight = _contentHeight();
    final fitScale = math.min(innerWidth / contentWidth, innerHeight / contentHeight);

    Rect? visibleRect;
    try {
      final inverse = Matrix4.inverted(transform);
      final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
      final bottomRight = MatrixUtils.transformPoint(inverse, Offset(viewportSize.width, viewportSize.height));
      visibleRect = Rect.fromPoints(topLeft, bottomRight);
    } catch (_) {
      visibleRect = null;
    }

    return Container(
      width: boxWidth,
      height: boxHeight,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: const Color(0xFF2D2D2D), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Transform.scale(
                scale: fitScale,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: contentWidth,
                  height: contentHeight,
                  child: _MiniGrid(
                    seatMap: seatMap,
                    selectedSeatIds: selectedSeatIds,
                    miniCellSize: miniCellSize,
                    labelWidth: 20 * scale,
                    cellGap: 0.7 * scale,
                    rowGap: 1.5 * scale,
                  ),
                ),
              ),
            ),
          ),
          if (visibleRect != null)
            Positioned(
              left: padding + (visibleRect.left * (miniCellSize / mainCellSize) * fitScale),
              top: padding + (visibleRect.top * (miniCellSize / mainCellSize) * fitScale),
              child: Container(
                width: math.max(18 * scale, visibleRect.width * (miniCellSize / mainCellSize) * fitScale),
                height: math.max(18 * scale, visibleRect.height * (miniCellSize / mainCellSize) * fitScale),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1D4ED8), width: 1.1),
                  color: const Color(0x331D4ED8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _contentWidth() {
    final maxColumns = seatMap.rows.fold<int>(0, (maxValue, row) => math.max(maxValue, row.cells.length));
    final cellGap = 0.7 * scale;
    return (maxColumns * (miniCellSize + (cellGap * 2))) + (8 * scale);
  }

  double _contentHeight() {
    final rowGap = 1.5 * scale;
    return (seatMap.rows.length * (miniCellSize + (rowGap * 2))) + (8 * scale);
  }
}

class _MiniGrid extends StatelessWidget {
  const _MiniGrid({
    required this.seatMap,
    required this.selectedSeatIds,
    required this.miniCellSize,
    required this.labelWidth,
    required this.cellGap,
    required this.rowGap,
  });

  final SeatMapResponseItem seatMap;
  final Set<int> selectedSeatIds;
  final double miniCellSize;
  final double labelWidth;
  final double cellGap;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: seatMap.rows.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: rowGap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...row.cells.map((cell) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: cellGap),
                  child: cell.cellType != 'SEAT'
                      ? SizedBox(width: miniCellSize, height: miniCellSize)
                      : Container(
                          width: miniCellSize,
                          height: miniCellSize,
                          decoration: BoxDecoration(
                            color: _seatColor(cell, selectedSeatIds.contains(cell.seatId)),
                            borderRadius: BorderRadius.circular(1.4),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.4),
                          ),
                        ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SeatCell extends StatelessWidget {
  const _SeatCell({required this.cell, required this.isSelected, required this.size, required this.scale});

  final SeatMapCellItem cell;
  final bool isSelected;
  final double size;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (cell.cellType != 'SEAT') {
      return SizedBox(width: size, height: size);
    }

    final bgColor = _seatColor(cell, isSelected);
    final borderColor = isSelected
        ? const Color(0xFF163FCC)
        : cell.state == 'booked'
            ? const Color(0xFF9B6C62)
            : Colors.black.withValues(alpha: 0.08);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(1.5 * scale),
        border: Border.all(color: borderColor, width: 0.7),
      ),
      child: Text(
        _shortSeatLabel(cell.seatNumber ?? ''),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: 7.5 * scale,
          fontWeight: FontWeight.w700,
          color: _foregroundColor(cell, isSelected),
        ),
      ),
    );
  }
}

Color _seatColor(SeatMapCellItem cell, bool isSelected) {
  if (isSelected) return const Color(0xFF163FCC);
  switch (cell.state) {
    case 'booked':
      return const Color(0xFFA46F62);
    case 'held':
      return const Color(0xFFB3A06B);
    default:
      if (cell.isCoupleSeat) return const Color(0xFFD81CBF);
      if (cell.seatClass == 'VIP') return const Color(0xFFF31818);
      return const Color(0xFFE3E0D7);
  }
}

Color _foregroundColor(SeatMapCellItem cell, bool isSelected) {
  if (isSelected) return Colors.white;
  if (cell.state == 'booked') return Colors.white;
  if (cell.seatClass == 'VIP' || cell.isCoupleSeat) return Colors.white;
  return Colors.black;
}

String _shortSeatLabel(String seatNumber) {
  if (seatNumber.length <= 3) {
    return seatNumber;
  }
  return seatNumber.substring(0, 3);
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.scale});

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

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.scale, required this.legend});

  final double scale;
  final List<SeatLegendItem> legend;

  @override
  Widget build(BuildContext context) {
    final items = legend.isNotEmpty
        ? legend
        : const [
            SeatLegendItem(key: 'booked', label: 'Đã đặt'),
            SeatLegendItem(key: 'selected', label: 'Đang chọn'),
            SeatLegendItem(key: 'VIP', label: 'VIP'),
            SeatLegendItem(key: 'THUONG', label: 'Thường'),
            SeatLegendItem(key: 'SWEET_BOX', label: 'Sweet box'),
          ];

    return Wrap(
      spacing: 16 * scale,
      runSpacing: 10 * scale,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16 * scale,
                  height: 16 * scale,
                  color: _legendColor(item.key),
                ),
                SizedBox(width: 6 * scale),
                Text(item.label, style: TextStyle(fontSize: 10 * scale)),
              ],
            ),
          )
          .toList(),
    );
  }
}

Color _legendColor(String key) {
  switch (key) {
    case 'booked':
      return const Color(0xFFA46F62);
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.scale,
    required this.movieTitle,
    required this.movieAge,
    required this.movieRuntime,
    required this.selectedCount,
    required this.selectedPrice,
    required this.onBook,
  });

  final double scale;
  final String movieTitle;
  final String movieAge;
  final int? movieRuntime;
  final int selectedCount;
  final double selectedPrice;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 12 * scale),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0D7B0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(movieTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.w700)),
                SizedBox(height: 2 * scale),
                Text(
                  '$movieAge${movieRuntime != null ? ' • ${movieRuntime} phút' : ''}',
                  style: TextStyle(fontSize: 10 * scale, color: const Color(0xFF666666)),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  selectedCount == 0 ? 'Chưa chọn ghế' : '$selectedCount ghế • ${selectedPrice.toStringAsFixed(0)}đ',
                  style: TextStyle(fontSize: 10 * scale, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onBook,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE21B1B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text('Đặt vé', style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scale, required this.title, required this.onBack});

  final double scale;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, size: 24 * scale, color: const Color(0xFFE14A4A)),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 40, color: Color(0xFF606060)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(onPressed: () => onRetry(), child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}