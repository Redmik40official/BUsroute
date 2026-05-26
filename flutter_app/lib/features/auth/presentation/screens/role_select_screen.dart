/// ─────────────────────────────────────────────────────────────────────────────
/// Role Select Screen
///
/// Shown to a freshly-registered user who hasn't been routed yet,
/// or used as a standalone role switcher.
/// Two large animated cards (Student / Driver) fill the screen.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:aurcm_route/core/routing/app_router.dart';
import 'package:aurcm_route/shared/theme/app_colors.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Header ───────────────────────────────────────────────────
              Text(
                'Who are you?',
                style: Theme.of(context).textTheme.headlineLarge,
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              Text(
                'Choose your role to get started',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 48),

              // ── Role Cards ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    _BigRoleCard(
                      icon: Icons.school_rounded,
                      title: 'Student',
                      description:
                          'Track your college bus in realtime.\nSee live location, route, ETA and stops.',
                      gradient: AppColors.accentGradient,
                      glowColor: AppColors.accent,
                      delay: 200.ms,
                      onTap: () => context.go(AppRoutes.studentRoutes),
                    ),

                    const SizedBox(height: 20),

                    _BigRoleCard(
                      icon: Icons.local_shipping_rounded,
                      title: 'Driver / Captain',
                      description:
                          'Share your live GPS location with students.\nStart and manage bus trips.',
                      gradient: AppColors.successGradient,
                      glowColor: AppColors.success,
                      delay: 350.ms,
                      onTap: () => context.go(AppRoutes.driverHome),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Footer note ──────────────────────────────────────────────
              Center(
                child: Text(
                  'Anna University Regional Campus Madurai',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Big Role Card
// ─────────────────────────────────────────────────────────────────────────────
class _BigRoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;
  final Color glowColor;
  final Duration delay;
  final VoidCallback onTap;

  const _BigRoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.glowColor,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_BigRoleCard> createState() => _BigRoleCardState();
}

class _BigRoleCardState extends State<_BigRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 38,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 20),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: widget.delay, duration: 500.ms)
            .slideY(begin: 0.15, end: 0),
      ),
    );
  }
}
