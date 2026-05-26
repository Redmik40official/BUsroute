/// Splash Screen — shown while auth session is being restored from storage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aurcm_route/shared/theme/app_colors.dart';
import 'package:aurcm_route/core/constants/app_constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bus icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                size: 52,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: const Duration(milliseconds: 400)),

            const SizedBox(height: 24),

            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 500),
                )
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            const Text(
              AppConstants.appTagline,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 450),
                  duration: const Duration(milliseconds: 500),
                ),

            const SizedBox(height: 64),

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 600),
                  duration: const Duration(milliseconds: 400),
                ),
          ],
        ),
      ),
    );
  }
}
