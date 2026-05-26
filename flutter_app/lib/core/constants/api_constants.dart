/// ─────────────────────────────────────────────────────────────────────────────
/// API Constants
///
/// All backend URLs and endpoint paths in one place.
/// The base URL is read from the environment at runtime, allowing different
/// values for local dev, staging, and production without code changes.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // ── Base URLs ────────────────────────────────────────────────────────────────
  // Loaded dynamically from .env file via flutter_dotenv
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? 'http://10.0.2.2:3000';

  // ── Auth ─────────────────────────────────────────────────────────────────────
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authMe = '/api/auth/me';
  static const String authRefresh = '/api/auth/refresh';
  static const String authLogout = '/api/auth/logout';

  // ── Routes ───────────────────────────────────────────────────────────────────
  static const String routes = '/api/routes';
  static String routeById(String id) => '/api/routes/$id';

  // ── Buses ────────────────────────────────────────────────────────────────────
  static const String buses = '/api/buses';
  static String busById(String id) => '/api/buses/$id';

  // ── Trips ────────────────────────────────────────────────────────────────────
  static const String tripStart = '/api/trips/start';
  static const String tripEnd = '/api/trips/end';
  static const String tripsActive = '/api/trips/active';
  static String tripTrail(String id) => '/api/trips/$id/trail';

  // ── Admin ────────────────────────────────────────────────────────────────────
  static const String adminStats = '/api/admin/stats';
  static const String adminDrivers = '/api/admin/drivers';

  // ── Health ───────────────────────────────────────────────────────────────────
  static const String health = '/api/health';
}
