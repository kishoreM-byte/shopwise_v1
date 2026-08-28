import 'package:flutter/material.dart';

class ShopWiseColors {
  ShopWiseColors._();

  // Core brand
  static const Color emerald = Color(0xFF0B8F6A);
  static const Color emeraldDeep = Color(0xFF067A5B);
  static const Color emeraldSoft = Color(0xFFE8F7F2);

  // Page identities
  static const Color search = Color(0xFF2563EB);
  static const Color compare = Color(0xFF635BDB);
  static const Color wishlist = Color(0xFFE11D48);
  static const Color enquiries = Color(0xFFD97706);
  static const Color smart = Color(0xFF7C3AED);
  static const Color trip = Color(0xFF2563EB);

  // Surfaces
  static const Color background = Color(0xFFF6F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF9FAFB);
  static const Color border = Color(0xFFE7EBEF);

  // Typography
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF526071);
  static const Color textMuted = Color(0xFF98A2B3);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
}

class ShopWiseMotion {
  ShopWiseMotion._();

  static const Duration micro = Duration(milliseconds: 160);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration smooth = Duration(milliseconds: 380);
  static const Duration page = Duration(milliseconds: 420);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve entranceCurve = Curves.easeOutQuart;
}

class ShopWiseRadius {
  ShopWiseRadius._();

  static const double small = 12;
  static const double medium = 16;
  static const double large = 20;
  static const double xLarge = 24;
  static const double sheet = 28;
  static const double pill = 999;
}

class ShopWiseElevation {
  ShopWiseElevation._();

  static const double none = 0;
  static const double subtle = 2;
  static const double floating = 6;
}
