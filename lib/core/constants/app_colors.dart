import 'package:flutter/material.dart';

/// App-wide color constants with modern, vibrant palette
class AppColors {
  // Primary Colors - Green (eco-friendly theme)
  static const Color primary = Color(0xFF10B981); // Emerald green
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF6EE7B7);
  static const Color primarySurface = Color(0xFFD1FAE5);

  // Secondary Colors - Orange (food theme)
  static const Color secondary = Color(0xFFF59E0B); // Amber
  static const Color secondaryDark = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondarySurface = Color(0xFFFEF3C7);

  // Accent Colors
  static const Color accent = Color(0xFF8B5CF6); // Purple
  static const Color accentLight = Color(0xFFA78BFA);

  // Neutral Colors
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray
  static const Color textLight = Color(0xFFFFFFFF); // White

  // Background Colors
  static const Color background = Color(0xFFF9FAFB); // Very light gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceLight = Color(0xFFF3F4F6);

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // Semantic Surface Colors
  static const Color successSurface = Color(0xFFD1FAE5);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color infoSurface = Color(0xFFDBEAFE);

  // Border & Divider
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // Discount Badge
  static const Color discount = Color(0xFFDC2626); // Red for discount badges
  static const Color discountSurface = Color(0xFFFEE2E2);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
