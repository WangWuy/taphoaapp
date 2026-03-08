import 'package:flutter/material.dart';

class AppSpacing {
  // Spacing scale
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 18;
  static const double radiusXxl = 24;
  static const double radiusChip = 22;
  static const double radiusFull = 999;

  // Rounded helpers
  static BorderRadius get roundedSm => BorderRadius.circular(radiusSm);
  static BorderRadius get roundedMd => BorderRadius.circular(radiusMd);
  static BorderRadius get roundedLg => BorderRadius.circular(radiusLg);
  static BorderRadius get roundedXl => BorderRadius.circular(radiusXl);
  static BorderRadius get roundedXxl => BorderRadius.circular(radiusXxl);
  static BorderRadius get roundedChip => BorderRadius.circular(radiusChip);
  static BorderRadius get roundedFull => BorderRadius.circular(radiusFull);

  // Edge insets helpers
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
}
