/// ─────────────────────────────────────────────────────────────────────────────
/// Typed Failure Classes
///
/// Using typed failures (rather than raw exceptions) forces callers to handle
/// every error case explicitly. This is the Either<Failure, T> pattern from
/// functional programming (dartz package).
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Network / HTTP errors
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection.']);
}

/// Server returned a 4xx/5xx with a body
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// Authentication / authorization errors
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

/// JWT token expired or invalid
class TokenExpiredFailure extends Failure {
  const TokenExpiredFailure() : super('Session expired. Please log in again.');
}

/// Local cache / storage errors
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to read local data.']);
}

/// Location / GPS permission denied or unavailable
class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Location unavailable.']);
}

/// WebSocket / Socket.IO connection errors
class SocketFailure extends Failure {
  const SocketFailure([super.message = 'Realtime connection failed.']);
}

/// Validation errors (form input, missing fields)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Generic unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
