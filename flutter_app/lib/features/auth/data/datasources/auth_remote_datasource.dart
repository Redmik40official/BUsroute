/// ─────────────────────────────────────────────────────────────────────────────
/// Auth Remote Data Source
///
/// Handles all HTTP calls to the auth API.
/// Returns raw data maps — transformation to domain entities happens
/// in the repository layer above this.
///
/// Why separate datasource from repository?
/// - Datasource: knows about Dio, HTTP, JSON
/// - Repository: knows about domain entities and failure types
/// This makes swapping the network layer (e.g., GraphQL, gRPC) trivial.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:dio/dio.dart';
import 'package:aurcm_route/core/constants/api_constants.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSource(this._dio);

  /// POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post(
      ApiConstants.authRegister,
      data: {'name': name, 'email': email, 'password': password, 'role': role},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.authLogin,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/auth/me
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiConstants.authMe);
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/auth/logout
  Future<void> logout() async {
    await _dio.post(ApiConstants.authLogout);
  }
}
