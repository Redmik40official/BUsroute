import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/routing/app_router.dart';
import 'shared/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AURCM Route — App Entry Point
///
/// Architecture decisions at this layer:
///
/// 1. ProviderScope wraps everything so Riverpod can manage state globally.
///
/// 2. GoogleFonts.config.allowRuntimeFetching = false ensures the app uses
///    bundled fonts, avoiding a flash of unstyled text on first launch.
///
/// 3. The router is consumed via ref.watch() inside ConsumerWidget so
///    GoRouter automatically rebuilds when auth state changes (triggering
///    redirect guards on login/logout immediately).
///
/// 4. SystemChrome sets transparent status bar + light icons to match the
///    dark theme without needing per-screen AnnotatedRegion.
/// ─────────────────────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow runtime fetching of fonts since we removed local assets
  GoogleFonts.config.allowRuntimeFetching = true;

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Hive local cache initialization
  await Hive.initFlutter();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: AurcmRouteApp(),
    ),
  );
}

class AurcmRouteApp extends ConsumerWidget {
  const AurcmRouteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router — rebuilds whenever auth state changes,
    // triggering redirect guards automatically.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AURCM Route',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,

      // Enforce max text scale to prevent layout breaks with accessibility settings
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
