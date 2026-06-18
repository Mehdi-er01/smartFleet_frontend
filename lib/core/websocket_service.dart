import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/core/storage_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebSocketService {
  static const String _socketUrl = 'ws://localhost:8080/api/ws';

  StompClient? _client;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect(VoidCallback onConnectCallback) async {
    if (_isConnected) {
      onConnectCallback();
      return;
    }

    _client?.deactivate();

    final token = await StorageService.getToken();
    final stompConnectHeaders = <String, String>{};
    final webSocketConnectHeaders = <String, dynamic>{};
    final socketUrl = (token != null && token.isNotEmpty)
        ? '$_socketUrl?token=${Uri.encodeQueryComponent(token)}'
        : _socketUrl;

    if (token == null || token.isEmpty) {
      debugPrint('STOMP WebSocket connecting without auth token.');
    } else {
      stompConnectHeaders['Authorization'] = 'Bearer $token';
      webSocketConnectHeaders['Authorization'] = 'Bearer $token';
    }

    _client = StompClient(
      config: StompConfig(
        url: socketUrl,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        stompConnectHeaders: stompConnectHeaders,
        webSocketConnectHeaders: webSocketConnectHeaders,
        beforeConnect: () async {
          return ;
        },
        onConnect: (frame) {
          _isConnected = true;
          debugPrint('STOMP WebSocket connected successfully.');
          onConnectCallback();
        },
        onWebSocketError: (dynamic error) {
          debugPrint('STOMP WebSocket error: $error');
        },
        onStompError: (frame) {
          debugPrint('STOMP error frame: ${frame.body}');
        },
        onDisconnect: (frame) {
          _isConnected = false;
          debugPrint('STOMP WebSocket disconnected: ${frame.body}');
        },
      ),
    );

    _client?.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _isConnected = false;
  }

  void sendDriverLocation(Map<String, dynamic> payload) {
    if (_client == null || !_client!.connected) {
      debugPrint('Cannot send driver location: STOMP client is not connected.');
      return;
    }

    _client!.send(
      destination: '/app/drivers/location',
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  VoidCallback subscribeToDriverLocation(
    int driverId,
    void Function(dynamic data) onUpdate,
  ) {
    if (_client == null || !_isConnected) {
      debugPrint('Cannot subscribe: STOMP client is not connected.');
      return () {};
    }

    final unsubscribeFn = _client!.subscribe(
      destination: '/topic/drivers/$driverId/location',
      callback: (frame) => _emitFrameData(frame, onUpdate, 'driver location'),
    );

    return unsubscribeFn;
  }

  VoidCallback subscribeToFleetLocations(
    int managerId,
    void Function(dynamic data) onUpdate,
  ) {
    if (_client == null || !_isConnected) {
      debugPrint('Cannot subscribe: STOMP client is not connected.');
      return () {};
    }

    final unsubscribeFn = _client!.subscribe(
      destination: '/topic/managers/$managerId/drivers',
      callback: (frame) => _emitFrameData(frame, onUpdate, 'fleet locations'),
    );

    return unsubscribeFn;
  }

  VoidCallback subscribeToOrderLocation(
    int orderId,
    void Function(dynamic data) onUpdate,
  ) {
    if (_client == null || !_isConnected) {
      debugPrint('Cannot subscribe: STOMP client is not connected.');
      return () {};
    }

    final unsubscribeFn = _client!.subscribe(
      destination: '/topic/orders/$orderId/location',
      callback: (frame) => _emitFrameData(frame, onUpdate, 'order location'),
    );

    return unsubscribeFn;
  }

  void _emitFrameData(
    StompFrame frame,
    void Function(dynamic data) onUpdate,
    String label,
  ) {
    if (frame.body == null) return;

    try {
      final data = jsonDecode(frame.body!);
      onUpdate(data);
    } catch (e) {
      debugPrint('Error parsing STOMP $label message: $e');
    }
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});
