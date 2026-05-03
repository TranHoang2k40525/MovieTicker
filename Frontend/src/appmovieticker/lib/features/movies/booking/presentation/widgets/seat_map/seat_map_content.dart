import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:appmovieticker/features/movies/booking/data/models/booking/seat_map_item.dart';
import 'package:appmovieticker/features/movies/booking/presentation/widgets/seat_map/seat_map_styles.dart';

class SeatMapContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final grid = _buildGrid();
    final contentWidth = _gridWidth();
    final contentHeight = _gridHeight();

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

  Widget _buildGrid() {
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

  double _gridWidth() {
    final maxColumns = seatMap.rows.fold<int>(0, (maxValue, row) => math.max(maxValue, row.cells.length));
    final cellGap = 0.7 * scale;
    return (maxColumns * (cellSize + (cellGap * 2))) + (8 * scale);
  }

  double _gridHeight() {
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
