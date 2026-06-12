import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebSocketService {
  StompClient? _client;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(VoidCallback onConnectCallback) {
    if (_isConnected) {
      onConnectCallback();
      return;
    }

    _client = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/api/ws',
        onConnect: (frame) {
          _isConnected = true;
          debugPrint('STOMP WebSocket Connected successfully');
          onConnectCallback();
        },
        onWebSocketError: (dynamic error) {
          debugPrint('STOMP WebSocket Error: $error');
        },
        onStompError: (frame) {
          debugPrint('STOMP Frame Error: ${frame.body}');
        },
        onDisconnect: (frame) {
          _isConnected = false;
          debugPrint('STOMP WebSocket Disconnected');
        },
      ),
    );

    _client?.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _isConnected = false;
  }

  VoidCallback subscribeToDriverLocation(
    int driverId,
    void Function(Map<String, dynamic> data) onUpdate,
  ) {
    if (_client == null || !_isConnected) {
      debugPrint('Cannot subscribe: STOMP client is not connected.');
      return () {};
    }

    final unsubscribeFn = _client!.subscribe(
      destination: '/topic/drivers/$driverId/location',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            onUpdate(data);
          } catch (e) {
            debugPrint('Error parsing STOMP driver location message: $e');
          }
        }
      },
    );

    return unsubscribeFn;
  }

  VoidCallback subscribeToFleetLocations(
    int managerId,
    void Function(Map<String, dynamic> data) onUpdate,
  ) {
    if (_client == null || !_isConnected) {
      debugPrint('Cannot subscribe: STOMP client is not connected.');
      return () {};
    }

    final unsubscribeFn = _client!.subscribe(
      destination: '/topic/managers/$managerId/drivers',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            onUpdate(data);
          } catch (e) {
            debugPrint('Error parsing STOMP fleet locations message: $e');
          }
        }
      },
    );

    return unsubscribeFn;
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});
