/// ─────────────────────────────────────────────────────────────────────────────
/// Location Service
///
/// Wrapper around Geolocator.
/// Handles permission requests, checking location services, and provides
/// a continuous stream of location updates.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import '../core/errors/failures.dart';

final _log = Logger();

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  LocationService();

  /// Requests location permission.
  /// Throws [Failure] if permission is denied or location services are disabled.
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _log.w('[Location] Location services are disabled.');
      throw const LocationFailure('Location services are disabled. Please enable them in settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _log.w('[Location] Location permissions are denied');
        throw const LocationFailure('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _log.e('[Location] Location permissions are permanently denied');
      throw const LocationFailure(
          'Location permissions are permanently denied. We cannot request permissions. Please enable them from system settings.');
    }

    _log.i('[Location] Permission granted: $permission');
    return true;
  }

  /// Get current exact position
  Future<Position> getCurrentPosition() async {
    await requestPermission();
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Returns a stream of location updates
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Only emit when moving more than 10 meters
      ),
    );
  }
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}
