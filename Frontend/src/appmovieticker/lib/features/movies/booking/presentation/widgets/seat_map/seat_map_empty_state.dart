import 'package:flutter/material.dart';

class SeatMapEmptyState extends StatelessWidget {
  const SeatMapEmptyState({super.key, required this.message, required this.onRetry});

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
