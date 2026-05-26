import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import '../../../../services/location_service.dart';
import '../../../../services/socket_service.dart';

final _log = Logger();

class ActiveTripState {
  final bool isTracking;
  final Position? lastPosition;
  final String? routeId;
  final String? busId;
  final String? tripId;
  final String? error;

  ActiveTripState({
    this.isTracking = false,
    this.lastPosition,
    this.routeId,
    this.busId,
    this.tripId,
    this.error,
  });

  ActiveTripState copyWith({
    bool? isTracking,
    Position? lastPosition,
    String? routeId,
    String? busId,
    String? tripId,
    String? error,
  }) {
    return ActiveTripState(
      isTracking: isTracking ?? this.isTracking,
      lastPosition: lastPosition ?? this.lastPosition,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      tripId: tripId ?? this.tripId,
      error: error,
    );
  }
}

final activeTripProvider =
    StateNotifierProvider<ActiveTripNotifier, ActiveTripState>((ref) {
  final locationService = ref.read(locationServiceProvider);
  final socketService = ref.read(socketServiceProvider);
  return ActiveTripNotifier(locationService, socketService);
});

class ActiveTripNotifier extends StateNotifier<ActiveTripState> {
  final LocationService _locationService;
  final SocketService _socketService;
  StreamSubscription<Position>? _locationSubscription;

  ActiveTripNotifier(this._locationService, this._socketService)
      : super(ActiveTripState());

  Future<void> startTrip({
    required String tripId,
    required String busId,
    required String routeId,
  }) async {
    try {
      state = state.copyWith(error: null);
      
      // Request location permission first
      await _locationService.requestPermission();
      
      // Connect socket
      await _socketService.connect();
      
      // Notify server that trip has started
      _socketService.startTrip(tripId: tripId, busId: busId, routeId: routeId);
      
      // Get initial position immediately
      final initialPos = await _locationService.getCurrentPosition();
      
      state = state.copyWith(
        isTracking: true,
        routeId: routeId,
        busId: busId,
        tripId: tripId,
        lastPosition: initialPos,
      );
      
      _emitLocation(initialPos);

      // Listen to continuous updates
      _locationSubscription = _locationService.getLocationStream().listen(
        (Position position) {
          _log.i('[Tracking] Location update: ${position.latitude}, ${position.longitude}');
          state = state.copyWith(lastPosition: position);
          _emitLocation(position);
        },
        onError: (e) {
          _log.e('[Tracking] Error in location stream: $e');
          state = state.copyWith(error: 'Lost GPS signal');
        },
      );
    } catch (e) {
      _log.e('[Tracking] Failed to start trip: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  void _emitLocation(Position position) {
    if (!state.isTracking || state.tripId == null || state.busId == null || state.routeId == null) {
      return;
    }
    
    _socketService.updateLocation(
      tripId: state.tripId!,
      busId: state.busId!,
      routeId: state.routeId!,
      lat: position.latitude,
      lng: position.longitude,
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
    );
  }

  Future<void> stopTrip() async {
    if (!state.isTracking) return;
    
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    
    if (state.tripId != null && state.busId != null && state.routeId != null) {
      _socketService.endTrip(
        tripId: state.tripId!,
        busId: state.busId!,
        routeId: state.routeId!,
      );
    }

    _socketService.disconnect();

    state = ActiveTripState(); // reset to default
    _log.i('[Tracking] Trip stopped');
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
