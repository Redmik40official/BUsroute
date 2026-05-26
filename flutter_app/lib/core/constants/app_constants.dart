/// ─────────────────────────────────────────────────────────────────────────────
/// App Constants
///
/// Centralizes all application-wide constants. Using a single source of truth
/// prevents magic strings from scattering across the codebase.
/// ─────────────────────────────────────────────────────────────────────────────
library;

class AppConstants {
  AppConstants._();

  // ── App Identity ─────────────────────────────────────────────────────────────
  static const String appName = 'AURCM Route';
  static const String appTagline = 'Anna University Regional Campus Madurai';
  static const String appVersion = '1.0.0';

  // ── GPS & Tracking ───────────────────────────────────────────────────────────
  /// How often the driver sends location updates (milliseconds).
  static const int locationUpdateIntervalMs = 3000;

  /// Minimum distance (meters) before a new GPS point is recorded.
  static const int locationDistanceFilterM = 5;

  /// Number of location history points kept in memory for trail drawing.
  static const int maxTrailPoints = 150;

  /// Radius (meters) within which a stop is considered "arrived".
  static const int stopArrivalRadiusM = 100;

  // ── Network ──────────────────────────────────────────────────────────────────
  /// How long before an HTTP request times out.
  static const int httpTimeoutSeconds = 30;

  /// Socket.IO reconnection delay (ms).
  static const int socketReconnectDelayMs = 1000;

  // ── Map ──────────────────────────────────────────────────────────────────────
  static const double defaultMapZoom = 15.5;
  static const double defaultMapZoomCity = 12.0;

  /// AURCM Campus coordinates — default camera target.
  static const double campusLat = 9.8760;
  static const double campusLng = 78.0880;

  // ── UI ───────────────────────────────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 600);
  static const Duration markerAnimationDuration = Duration(milliseconds: 800);

  // ── Storage Keys ─────────────────────────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keySelectedRouteId = 'selected_route_id';
  static const String keyLastKnownLocation = 'last_known_location';
}
