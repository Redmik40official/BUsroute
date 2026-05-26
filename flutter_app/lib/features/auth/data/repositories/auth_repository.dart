/// ─────────────────────────────────────────────────────────────────────────────
/// Auth Repository Implementation
///
/// Bridges the datasource (raw HTTP) and the presentation layer (providers).
/// Catches Dio exceptions and maps them to typed Failure objects.
///
/// Returns Either<Failure, T> — callers must handle both cases explicitly.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:aurcm_route/core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource _dataSource;

  const AuthRepository(this._dataSource);

  Future<Either<Failure, Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    return _safeCall(() => _dataSource.register(
          name: name,
          email: email,
          password: password,
          role: role,
        ));
  }

  Future<Either<Failure, Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    return _safeCall(
        () => _dataSource.login(email: email, password: password));
  }

  Future<Either<Failure, Map<String, dynamic>>> getMe() async {
    return _safeCall(() => _dataSource.getMe());
  }

  Future<Either<Failure, void>> logout() async {
    return _safeCall(() => _dataSource.logout());
  }

  // ── Internal helper — maps Dio exceptions to typed Failures ─────────────────
  Future<Either<Failure, T>> _safeCall<T>(
      Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        return Left(const NetworkFailure());
      }
      final statusCode = e.response?.statusCode;
      final message = _extractMessage(e.response?.data);
      if (statusCode == 401) return Left(AuthFailure(message));
      if (statusCode == 409) return Left(ServerFailure(message, statusCode: 409));
      if (statusCode == 422) return Left(ValidationFailure(message));
      return Left(ServerFailure(message, statusCode: statusCode));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  String _extractMessage(dynamic data) {
    if (data is Map) {
      return data['error'] as String? ??
          data['message'] as String? ??
          'Something went wrong';
    }
    return 'Something went wrong';
  }
}
