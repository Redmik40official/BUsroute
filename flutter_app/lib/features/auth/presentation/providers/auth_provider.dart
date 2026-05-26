/// ─────────────────────────────────────────────────────────────────────────────
/// Auth Provider — Full Implementation
///
/// Three providers work together:
/// 1. authRepositoryProvider — creates and provides AuthRepository
/// 2. authStateProvider — AsyncNotifier that holds session state
/// 3. authActionProvider — exposes login/register/logout actions to UI
///
/// The router watches authStateProvider to auto-redirect on auth changes.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:aurcm_route/core/storage/secure_storage.dart';
import 'package:aurcm_route/core/network/dio_client.dart';
import 'package:aurcm_route/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:aurcm_route/features/auth/data/repositories/auth_repository.dart';

// ── Auth State Model ──────────────────────────────────────────────────────────
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? name;
  final String? email;
  final String? role; // 'driver' | 'student' | 'admin'
  final String? accessToken;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.name,
    this.email,
    this.role,
    this.accessToken,
  });

  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      isAuthenticated: true,
      userId: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      accessToken: json['accessToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': userId,
        'name': name,
        'email': email,
        'role': role,
      };
}

// ── Infrastructure Providers ──────────────────────────────────────────────────
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  return createDioClient(storage);
});

final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.read(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authDataSourceProvider));
});

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return _restoreSession();
  }

  Future<AuthState> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    final userData = await storage.getUserData();

    if (token == null || userData == null) return const AuthState();

    try {
      final json = jsonDecode(userData) as Map<String, dynamic>;
      return AuthState.fromJson({...json, 'accessToken': token});
    } catch (_) {
      await storage.clearAll();
      return const AuthState();
    }
  }

  /// Login — calls API, stores tokens, updates state.
  /// Returns an error message string or null on success.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(email: email, password: password);

    return result.fold(
      (failure) {
        // Restore previous state (not loading) so UI can show error
        state = const AsyncData(AuthState());
        return failure.message;
      },
      (data) async {
        await _persistAndSetState(data);
        return null; // null = success
      },
    );
  }

  /// Register — calls API, stores tokens, updates state.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AsyncLoading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );

    return result.fold(
      (failure) {
        state = const AsyncData(AuthState());
        return failure.message;
      },
      (data) async {
        await _persistAndSetState(data);
        return null;
      },
    );
  }

  /// Logout — clears storage, resets state.
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {} // Best effort — always clear local state

    final storage = ref.read(secureStorageProvider);
    await storage.clearAll();
    state = const AsyncData(AuthState());
  }

  /// Dev bypass: mock login without API call
  void mockLogin(String role) {
    state = AsyncData(AuthState(
      isAuthenticated: true,
      userId: 'dev-user-123',
      name: 'Developer',
      email: 'dev@example.com',
      role: role,
      accessToken: 'mock-token',
    ));
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  Future<void> _persistAndSetState(Map<String, dynamic> data) async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final user = data['user'] as Map<String, dynamic>;

    try {
      await storage.setAccessToken(accessToken);
      await storage.setRefreshToken(refreshToken);
      await storage.setUserData(jsonEncode(user));
    } catch (_) {
      // If secure storage crashes (e.g. Android Keystore invalidation bug),
      // we gracefully ignore it so the user can still log in for this session.
      await storage.clearAll();
    }

    state = AsyncData(
      AuthState.fromJson({...user, 'accessToken': accessToken}),
    );
  }
}

// ── Public Provider ───────────────────────────────────────────────────────────
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
