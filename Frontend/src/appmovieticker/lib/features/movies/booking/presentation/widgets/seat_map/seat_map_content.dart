import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:appmovieticker/features/movies/booking/data/models/booking/seat_map_item.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_styles.dart';

class SeatMapContent extends StatefulWidget {
  const SeatMapContent({
    super.key,
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
  State<SeatMapContent> createState() => _SeatMapContentState();
}

class _SeatMapContentState extends State<SeatMapContent> {
  bool _initialized = false;

  @override
  void didUpdateWidget(covariant SeatMapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seatMap != widget.seatMap) {
      _initialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grid = _buildGrid();
    final contentWidth = _gridWidth();
    final contentHeight = _gridHeight();

    // Tính scale range dựa trên màn hình
    final screenSize = MediaQuery.sizeOf(context);
    final minScale = screenSize.shortestSide > 1000 ? 0.6 : 0.7;
    final maxScale = screenSize.shortestSide > 1000 ? 3.5 : 3.0;
    final boundaryMargin = screenSize.shortestSide > 1000 ? 140.0 : 100.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialized) return;
      final controller = widget.transformationController;
      final current = controller.value;
      final isIdentity = current.storage.every((v) => v == 0) || (current.getTranslation().x == 0 && current.getTranslation().y == 0);
      if (!mounted) return;
      if (isIdentity) {
        final vx = widget.viewportSize.width;
        final vy = widget.viewportSize.height;
        final dx = (vx - contentWidth) / 2.0;
        final dy = (vy - contentHeight) / 2.0;
        final matrix = Matrix4.translationValues(dx, dy, 0);
        controller.value = matrix;
      }
      _initialized = true;
    });

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MiniMap(
              seatMap: widget.seatMap,
              selectedSeatIds: widget.selectedSeatIds,
              scale: widget.scale,
              mainCellSize: widget.cellSize,
              miniCellSize: widget.miniCellSize,
              viewportSize: widget.viewportSize,
              transformationController: widget.transformationController,
            ),
            Expanded(child: SizedBox.shrink()),
          ],
        ),
        Expanded(
          child: Center(
            child: InteractiveViewer(
              transformationController: widget.transformationController,
              minScale: minScale,
              maxScale: maxScale,
              boundaryMargin: EdgeInsets.all(boundaryMargin),
              constrained: false,
              child: SizedBox(
                width: contentWidth,
                height: contentHeight,
                child: grid,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.seatMap.rows.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 1.5 * widget.scale),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...row.cells.map(
                (cell) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.7 * widget.scale),
                  child: GestureDetector(
                    onTap: cell.selectable ? () => widget.onSeatTap(cell) : null,
                    child: _SeatCell(
                      cell: cell,
                      isSelected: cell.seatId != null && widget.selectedSeatIds.contains(cell.seatId),
                      size: widget.cellSize,
                      scale: widget.scale,
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

  double _gridWidth() {
    final maxColumns = widget.seatMap.rows.fold<int>(0, (maxValue, row) => math.max(maxValue, row.cells.length));
    final cellGap = 0.7 * widget.scale;
    return (maxColumns * (widget.cellSize + (cellGap * 2))) + (8 * widget.scale);
  }

  double _gridHeight() {
    final rowGap = 1.5 * widget.scale;
    return (widget.seatMap.rows.length * (widget.cellSize + (rowGap * 2))) + (8 * widget.scale);
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
    final boxWidth = 140 * scale;
    final boxHeight = 210 * scale;
    final padding = 8 * scale;
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
        color: const Color(0xFF5A5A5A),
        borderRadius: BorderRadius.circular(2 * scale),
        border: Border.all(color: const Color(0xFFB33A35), width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6 * scale,
            left: 0,
            right: 0,
            child: Text(
              'MÀN HÌNH',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11 * scale, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: 28 * scale),
              child: ClipRect(
                child: Center(
                  child: Transform.scale(
                    scale: fitScale,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: contentWidth,
                      height: contentHeight,
                      child: _MiniGrid(
                        seatMap: seatMap,
                        selectedSeatIds: selectedSeatIds,
                        miniCellSize: miniCellSize,
                        cellGap: 0.7 * scale,
                        rowGap: 1.5 * scale,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (visibleRect != null)
            Positioned(
              left: padding + ((innerWidth - (contentWidth * fitScale)) / 2) + (visibleRect.left * (miniCellSize / mainCellSize) * fitScale),
              top: padding + 28 * scale + ((innerHeight - (contentHeight * fitScale)) / 2) + (visibleRect.top * (miniCellSize / mainCellSize) * fitScale),
              child: Container(
                width: math.max(18 * scale, visibleRect.width * (miniCellSize / mainCellSize) * fitScale),
                height: math.max(18 * scale, visibleRect.height * (miniCellSize / mainCellSize) * fitScale),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF4D14C), width: 1.1),
                  color: const Color(0x33F4D14C),
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
    required this.cellGap,
    required this.rowGap,
  });

  final SeatMapResponseItem seatMap;
  final Set<int> selectedSeatIds;
  final double miniCellSize;
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
                            color: seatMapColor(cell, selectedSeatIds.contains(cell.seatId)),
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

    final bgColor = seatMapColor(cell, isSelected);
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
        seatMapShortSeatLabel(cell.seatNumber ?? ''),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: 7.5 * scale,
          fontWeight: FontWeight.w700,
          color: seatMapForegroundColor(cell, isSelected),
        ),
      ),
    );
  }
}
