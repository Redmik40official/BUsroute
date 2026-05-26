/// ─────────────────────────────────────────────────────────────────────────────
/// Dio HTTP Client with JWT Interceptor
///
/// Uses an interceptor chain to:
/// 1. Inject the JWT Bearer token on every request automatically
/// 2. On 401 response → silently refresh the token and retry the request
/// 3. On refresh failure → clear storage and redirect to login
///
/// This prevents users from being logged out mid-session when the short-lived
/// access token expires.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

final _log = Logger();

/// Creates and configures the singleton Dio instance.
Dio createDioClient(SecureStorageService storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout:
          const Duration(seconds: AppConstants.httpTimeoutSeconds),
      receiveTimeout:
          const Duration(seconds: AppConstants.httpTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Attach interceptors in order
  dio.interceptors.add(_AuthInterceptor(dio, storage));
  dio.interceptors.add(_LoggingInterceptor());

  return dio;
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Interceptor — Injects JWT + handles silent token refresh
// ─────────────────────────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          await _storage.clearAll();
          return handler.next(err);
        }

        // Attempt token refresh
        final response = await _dio.post(
          ApiConstants.authRefresh,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': ''}), // skip interceptor
        );

        final newAccessToken = response.data['accessToken'] as String;
        await _storage.setAccessToken(newAccessToken);

        // Retry the original request with the new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        await _storage.clearAll();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logging Interceptor — Pretty-prints requests/responses in debug mode
// ─────────────────────────────────────────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.d('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.d('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.e(
      '✗ ${err.response?.statusCode} ${err.requestOptions.path}',
      error: err.message,
    );
    handler.next(err);
  }
}
