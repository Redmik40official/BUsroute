/// ─────────────────────────────────────────────────────────────────────────────
/// Socket Service
///
/// Wrapper around socket_io_client.
/// Handles connection lifecycle, authentication injection, and exposes
/// typed streams for real-time events.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

final _log = Logger();

final socketServiceProvider = Provider<SocketService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return SocketService(storage);
});

class SocketService {
  final SecureStorageService _storage;
  io.Socket? _socket;

  // ── Event Streams ─────────────────────────────────────────────────────────
  final _locationController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripEndedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onBusLocation => _locationController.stream;
  Stream<Map<String, dynamic>> get onTripStarted => _tripStartedController.stream;
  Stream<Map<String, dynamic>> get onTripEnded => _tripEndedController.stream;

  SocketService(this._storage);

  /// Connects to the Socket.IO server.
  /// Automatically injects the JWT token for authentication if available.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _storage.getAccessToken();
    
    // Parse the base URL to match Socket.IO requirements
    // ApiConstants.baseUrl might be http://192.168.x.x:3000/api
    // Socket requires http://192.168.x.x:3000
    final uri = Uri.parse(ApiConstants.baseUrl);
    final socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _log.i('[Socket] Connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      _log.w('[Socket] Disconnected');
    });

    _socket!.onError((err) {
      _log.e('[Socket] Error: $err');
    });

    // ── Listeners ───────────────────────────────────────────────────────────
    _socket!.on('bus:location', (data) {
      _locationController.add(data as Map<String, dynamic>);
    });

    _socket!.on('student:snapshot', (data) {
      // Data contains an array of buses. We can push them down the same stream.
      if (data != null && data['buses'] is List) {
        for (final bus in data['buses']) {
          _locationController.add(bus as Map<String, dynamic>);
        }
      }
    });

    _socket!.on('trip:started', (data) {
      _tripStartedController.add(data as Map<String, dynamic>);
    });

    _socket!.on('trip:ended', (data) {
      _tripEndedController.add(data as Map<String, dynamic>);
    });

    _socket!.connect();
  }

  /// Disconnect and cleanup
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _log.i('[Socket] Manually disconnected');
  }

  // ── Emit Methods ──────────────────────────────────────────────────────────

  /// Student: Subscribe to a specific route room
  void subscribeToRoute(String routeId) {
    _socket?.emit('student:subscribe', {'routeId': routeId});
    _log.i('[Socket] Subscribed to route: $routeId');
  }

  /// Student: Unsubscribe from a route room
  void unsubscribeFromRoute(String routeId) {
    _socket?.emit('student:unsubscribe', {'routeId': routeId});
    _log.i('[Socket] Unsubscribed from route: $routeId');
  }

  /// Driver: Start a trip
  void startTrip({
    required String tripId,
    required String busId,
    required String routeId,
  }) {
    _socket?.emit('trip:start', {
      'tripId': tripId,
      'busId': busId,
      'routeId': routeId,
    });
    _log.i('[Socket] Emitted trip:start for trip $tripId');
  }

  /// Driver: End a trip
  void endTrip({
    required String tripId,
    required String busId,
    required String routeId,
  }) {
    _socket?.emit('trip:end', {
      'tripId': tripId,
      'busId': busId,
      'routeId': routeId,
    });
    _log.i('[Socket] Emitted trip:end for trip $tripId');
  }

  /// Driver: Send live GPS location
  void updateLocation({
    required String tripId,
    required String busId,
    required String routeId,
    required double lat,
    required double lng,
    required double speed,
    required double heading,
    required double accuracy,
  }) {
    _socket?.emit('location:update', {
      'tripId': tripId,
      'busId': busId,
      'routeId': routeId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
