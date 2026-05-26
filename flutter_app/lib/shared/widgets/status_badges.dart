/// ─────────────────────────────────────────────────────────────────────────────
/// Live Status Badge
///
/// Animated pulsing "LIVE" indicator shown on active buses.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class LiveBadge extends StatelessWidget {
  final bool isLive;
  final double fontSize;

  const LiveBadge({super.key, this.isLive = true, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive ? AppColors.success : AppColors.textMuted,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLive ? AppColors.success : AppColors.textMuted,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.3, 1.3),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.3, 1.3),
                end: const Offset(0.8, 0.8),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 5),
          Text(
            isLive ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: isLive ? AppColors.success : AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Speed chip: "42 km/h"
class SpeedChip extends StatelessWidget {
  final double speedKmh;

  const SpeedChip({super.key, required this.speedKmh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed_rounded, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            '${speedKmh.toInt()} km/h',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// ETA chip: "12 min"
class EtaChip extends StatelessWidget {
  final String eta;

  const EtaChip({super.key, required this.eta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded,
              size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            eta,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
