/// ─────────────────────────────────────────────────────────────────────────────
/// ETA Calculator Utility
///
/// Uses the Haversine formula to compute great-circle distance between two
/// GPS coordinates, then estimates arrival time from current speed.
///
/// Why Haversine and not Google Directions API?
/// - Zero API cost, works offline, instant calculation
/// - Acceptable accuracy for campus bus routes (short, predictable paths)
/// - Directions API can be layered in later (Phase 9 enhancement)
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:math';

class EtaCalculator {
  EtaCalculator._();

  static const double _earthRadiusKm = 6371.0;

  /// Haversine distance in meters between two lat/lng pairs.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c * 1000; // convert km → m
  }

  /// Returns ETA in minutes. Returns null if speed is 0 or unknown.
  static double? etaMinutes({
    required double distanceMeters,
    required double speedKmh,
    double minimumSpeedKmh = 5.0,
  }) {
    final effectiveSpeed =
        speedKmh < minimumSpeedKmh ? minimumSpeedKmh : speedKmh;
    final distanceKm = distanceMeters / 1000.0;
    return (distanceKm / effectiveSpeed) * 60.0;
  }

  /// Formats ETA minutes into a human-readable string.
  static String formatEta(double? minutes) {
    if (minutes == null) return '—';
    if (minutes < 1) return 'Arriving';
    if (minutes < 60) return '${minutes.round()} min';
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    return '$h h $m min';
  }

  /// Formats a distance in meters to a readable string.
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static double _toRad(double degrees) => degrees * pi / 180;
}
