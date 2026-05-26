import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/map_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/eta_calculator.dart';
import 'dart:async';

class LiveMapScreen extends ConsumerStatefulWidget {
  final String routeId;
  final String routeName;

  const LiveMapScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  GoogleMapController? _mapController;

  // Center of Madurai / AURCM area as default
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(9.9252, 78.1198), // Default approx Madurai center
    zoom: 13,
  );

  Position? _studentPosition;
  Timer? _etaTimer;
  String _etaText = 'Calculating...';
  String _distanceText = '--';

  @override
  void initState() {
    super.initState();
    
    _initLocation();

    // Subscribe to socket events for this route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapProvider.notifier).init(widget.routeId);
    });

    _etaTimer = Timer.periodic(const Duration(seconds: 5), (_) => _calculateETA());
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _studentPosition = position;
          });
          _calculateETA();
        }
      }
    } catch (e) {
      // Handle location errors silently for now
    }
  }

  void _calculateETA() {
    if (_studentPosition == null) return;
    
    final mapState = ref.read(mapProvider);
    if (mapState.busMarkers.isEmpty) return;

    final busMarker = mapState.busMarkers.values.first;
    final busLat = busMarker.position.latitude;
    final busLng = busMarker.position.longitude;
    
    // In a real scenario, we'd get the actual speed from the socket.
    // For now, we assume a constant average campus speed (30 km/h) if not provided.
    final speed = 30.0; 

    final distance = EtaCalculator.distanceMeters(
      busLat, busLng,
      _studentPosition!.latitude, _studentPosition!.longitude,
    );

    final etaMins = EtaCalculator.etaMinutes(distanceMeters: distance, speedKmh: speed);
    
    if (mounted) {
      setState(() {
        _distanceText = EtaCalculator.formatDistance(distance);
        _etaText = EtaCalculator.formatEta(etaMins);
      });
    }
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Re-center on the first bus if available
              if (mapState.busMarkers.isNotEmpty) {
                final marker = mapState.busMarkers.values.first;
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(marker.position, 16),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true, // Show student's own location
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            markers: Set<Marker>.of(mapState.busMarkers.values),
            polylines: Set<Polyline>.of(mapState.polylines.values),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          
          if (mapState.busMarkers.isEmpty)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _buildStatusBanner('Waiting for bus location...', Colors.orange),
            )
          else
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _buildStatusBanner('Bus is active', Colors.green),
            ),

          // ETA Bottom Panel
          if (mapState.busMarkers.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildEtaPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildEtaPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ETA to you',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _etaText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route, color: Colors.blue.shade700, size: 20),
                const SizedBox(height: 4),
                Text(
                  _distanceText,
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
