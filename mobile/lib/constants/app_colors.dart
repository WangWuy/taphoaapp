import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color primaryStart = Color(0xFF4F46E5);
  static const Color primaryEnd = Color(0xFF7C3AED);

  // Accent
  static const Color accent = Color(0xFFEC4899);
  static const Color accentLight = Color(0xFFFCE7F3);

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color surface = cardBackground;
  static const Color surfaceLight = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Divider
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFF0F9FF);

  // Price
  static const Color priceColor = Color(0xFFDC2626);
  static const Color originalPriceColor = Color(0xFF94A3B8);

  // Star rating
  static const Color starColor = Color(0xFFFBBF24);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  // Overlay
  static const Color overlayDark = Color(0x66000000);
  static const Color overlayLight = Color(0xE6FFFFFF);

  // Banner gradients
  static const List<Color> bannerEmerald = [Color(0xFF059669), Color(0xFF0D9488)];
  static const List<Color> bannerAmber = [Color(0xFFF59E0B), Color(0xFFEF4444)];
  static const List<Color> bannerBlue = [Color(0xFF3B82F6), Color(0xFF8B5CF6)];

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryStart.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> bottomBarShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];
}
