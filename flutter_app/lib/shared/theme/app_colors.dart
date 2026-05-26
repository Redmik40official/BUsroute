/// ─────────────────────────────────────────────────────────────────────────────
/// App Color Palette
///
/// A curated design token system. Using HSL-derived colors for consistency.
/// All colors reference this file — never hardcoded hex strings in widgets.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────────
  /// Deep navy — primary brand color
  static const Color primary = Color(0xFF1A2B4A);
  static const Color primaryLight = Color(0xFF2E4A7A);
  static const Color primaryDark = Color(0xFF0F1A2E);

  /// Vivid electric blue — accent / CTA color
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentDark = Color(0xFF2563EB);

  // ── Semantic ──────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color live = Color(0xFF22C55E); // same as success — "LIVE" badge

  // ── Dark Theme Surfaces ────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D1117);      // page background
  static const Color surface = Color(0xFF161B22);          // card/sheet background
  static const Color surfaceElevated = Color(0xFF21262D);  // elevated cards
  static const Color surfaceTint = Color(0xFF30363D);      // dividers, borders
  static const Color glass = Color(0x1AFFFFFF);            // glassmorphism overlay

  // ── Text ──────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Route Colors (match routes.json palette exactly) ─────────────────────────
  static const Color routeRed = Color(0xFFE53935);
  static const Color routeBlue = Color(0xFF1E88E5);
  static const Color routeGreen = Color(0xFF43A047);
  static const Color routeOrange = Color(0xFFFB8C00);
  static const Color routePurple = Color(0xFF8E24AA);
  static const Color routeTeal = Color(0xFF00897B);
  static const Color routeDeepOrange = Color(0xFFF4511E);
  static const Color routeIndigo = Color(0xFF3949AB);
  static const Color routeLime = Color(0xFFC0CA33);
  static const Color routePink = Color(0xFFD81B60);

  // ── Gradients ─────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2B4A), Color(0xFF0F1A2E)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161B22), Color(0xFF21262D)],
  );
}
