import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../../../../services/socket_service.dart';

final _log = Logger();

class BusMapState {
  final Map<String, Marker> busMarkers;
  final Map<PolylineId, Polyline> polylines;
  final String? error;
  final bool isLoading;

  BusMapState({
    this.busMarkers = const {},
    this.polylines = const {},
    this.error,
    this.isLoading = false,
  });

  BusMapState copyWith({
    Map<String, Marker>? busMarkers,
    Map<PolylineId, Polyline>? polylines,
    String? error,
    bool? isLoading,
  }) {
    return BusMapState(
      busMarkers: busMarkers ?? this.busMarkers,
      polylines: polylines ?? this.polylines,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final mapProvider =
    StateNotifierProvider<MapNotifier, BusMapState>((ref) {
  final socketService = ref.read(socketServiceProvider);
  return MapNotifier(socketService);
});

class MapNotifier extends StateNotifier<BusMapState> {
  final SocketService _socketService;
  StreamSubscription<Map<String, dynamic>>? _locationSub;

  MapNotifier(this._socketService) : super(BusMapState()) {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _locationSub = _socketService.onBusLocation.listen((data) {
      final busId = data['busId'] as String?;
      final lat = data['lat'] as double?;
      final lng = data['lng'] as double?;
      
      if (busId != null && lat != null && lng != null) {
        _updateBusMarker(busId, LatLng(lat, lng));
      }
    });
  }

  void _updateBusMarker(String busId, LatLng position) {
    final updatedMarkers = Map<String, Marker>.from(state.busMarkers);
    
    // In a real production app, we would use a custom bus icon BitmapDescriptor here
    updatedMarkers[busId] = Marker(
      markerId: MarkerId(busId),
      position: position,
      infoWindow: InfoWindow(title: 'Bus $busId'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      // Set to true to allow animation/movement transition via third-party packages if needed
    );

    state = state.copyWith(busMarkers: updatedMarkers);
  }

  /// Subscribe to a route to get live updates for its bus
  void subscribeToRoute(String routeId) {
    _socketService.subscribeToRoute(routeId);
    _log.i('[MapProvider] Subscribed to route $routeId');
  }

  /// Load static route polyline to display on the map
  void loadRoutePolyline(String routeId, List<LatLng> points, String colorHex) {
    final polylineId = PolylineId(routeId);
    
    // Convert hex string (e.g. #E53935) to Color int
    int colorValue = 0xFF42A5F5; // Default blue
    if (colorHex.startsWith('#') && colorHex.length == 7) {
      colorValue = int.tryParse(colorHex.replaceFirst('#', '0xFF')) ?? colorValue;
    }

    final polyline = Polyline(
      polylineId: polylineId,
      points: points,
      color: Color(colorValue),
      width: 5,
      geodesic: true,
    );

    final updatedPolylines = Map<PolylineId, Polyline>.from(state.polylines);
    updatedPolylines[polylineId] = polyline;

    state = state.copyWith(polylines: updatedPolylines);
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }
}
