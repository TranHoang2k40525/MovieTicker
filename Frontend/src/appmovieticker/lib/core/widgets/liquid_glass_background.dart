import 'package:flutter/material.dart';

class LiquidGlassBackground extends StatelessWidget {
  const LiquidGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF2FF),
            Color(0xFFF8ECFF),
            Color(0xFFEAFDF5),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -80,
            top: -60,
            child: _Blob(size: 220, color: Color(0x66FFFFFF)),
          ),
          Positioned(
            right: -70,
            top: 120,
            child: _Blob(size: 200, color: Color(0x66DDEBFF)),
          ),
          Positioned(
            left: 30,
            bottom: -90,
            child: _Blob(size: 260, color: Color(0x66FFE8EE)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}
