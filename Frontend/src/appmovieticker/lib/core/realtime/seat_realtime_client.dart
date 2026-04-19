import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../constants/api_constants.dart';

class SeatRealtimeClient {
  SeatRealtimeClient();

  HubConnection? _connection;

  Future<void> connect({
    required int showId,
    required void Function(Map<String, dynamic> payload) onSeatChanged,
  }) async {
    await disconnect();

    final url = '${ApiConstants.mediaBaseUrl}/hubs/seat-booking';
    _connection = HubConnectionBuilder().withUrl(url).withAutomaticReconnect().build();

    _connection!.on('SeatStateChanged', (args) {
      if (args == null || args.isEmpty) return;
      final first = args.first;
      if (first is Map<String, dynamic>) {
        onSeatChanged(first);
        return;
      }
      if (first is Map) {
        onSeatChanged(first.map((key, value) => MapEntry(key.toString(), value)));
      }
    });

    await _connection!.start();
    await _connection!.invoke('JoinShowRoom', args: [showId]);
  }

  Future<void> leaveRoom(int showId) async {
    if (_connection == null) return;
    if (_connection!.state != HubConnectionState.Connected) return;

    try {
      await _connection!.invoke('LeaveShowRoom', args: [showId]);
    } catch (_) {
      // Ignore leave errors on app navigation.
    }
  }

  Future<void> disconnect() async {
    if (_connection == null) return;

    try {
      await _connection!.stop();
    } catch (_) {
      // Ignore shutdown errors.
    } finally {
      _connection = null;
    }
  }
}
