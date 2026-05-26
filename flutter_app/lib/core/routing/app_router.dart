/// ─────────────────────────────────────────────────────────────────────────────
/// App Router (GoRouter)
///
/// Declarative, type-safe routing with:
/// - Redirect guards (unauthenticated → /login, authenticated → role home)
/// - Deep-link support (student can open a specific route via URL)
/// - Role-based routing (driver → /driver/home, student → /student/routes)
///
/// GoRouter is preferred over Navigator 2.0 directly because it supports
/// URL-based navigation, nested routes, and redirect guards without boilerplate.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/role_select_screen.dart';
import '../../features/driver/presentation/screens/driver_home_screen.dart';
import '../../features/tracking/presentation/screens/active_trip_screen.dart';
import '../../features/routes/presentation/screens/student_home_screen.dart';
import '../../features/tracking/presentation/screens/live_map_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// ── Route Paths ───────────────────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelect = '/role-select';

  // Driver routes
  static const String driverHome = '/driver/home';
  static const String activeTrip = '/driver/trip/:tripId';
  static String activeTripPath(String tripId) => '/driver/trip/$tripId';

  // Student routes
  static const String studentRoutes = '/student/routes';
  static const String liveMap = '/student/map/:routeId';
  static String liveMapPath(String routeId) => '/student/map/$routeId';
}

// ── Router Provider ───────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final userRole = authState.valueOrNull?.role;
      final isGoingToAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash;

      // Still loading auth state — stay on splash
      if (authState.isLoading) return AppRoutes.splash;

      // Not authenticated and not going to an auth screen → redirect to login
      if (!isAuthenticated && !isGoingToAuth) {
        return AppRoutes.login;
      }

      // Authenticated and trying to hit auth screens → redirect to role home
      if (isAuthenticated && isGoingToAuth) {
        return userRole == 'driver'
            ? AppRoutes.driverHome
            : AppRoutes.studentRoutes;
      }

      return null; // no redirect needed
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.roleSelect,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const RoleSelectScreen(),
        ),
      ),

      // ── Driver ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.driverHome,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const DriverHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.activeTrip,
        pageBuilder: (context, state) {
          return _slideTransition(state, const ActiveTripScreen());
        },
      ),

      // ── Student ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.studentRoutes,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const StudentHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.liveMap,
        pageBuilder: (context, state) {
          final routeId = state.pathParameters['routeId']!;
          final routeName = state.extra as String? ?? 'Live Tracking';
          return _slideTransition(
            state,
            LiveMapScreen(
              routeId: routeId,
              routeName: routeName,
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
});

// ── Page Transitions ──────────────────────────────────────────────────────────
CustomTransitionPage _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

// ── Error Screen ──────────────────────────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final Exception? error;
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Page not found\n${error?.toString() ?? ''}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
