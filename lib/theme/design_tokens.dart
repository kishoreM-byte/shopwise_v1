import 'package:flutter/material.dart';

class ShopWiseColors {
  ShopWiseColors._();

  // Core brand
  static const Color emerald = Color(0xFF454832);
  static const Color emeraldDeep = Color(0xFF303321);
  static const Color emeraldSoft = Color(0xFFE9E2D5);
  static const Color olive = Color(0xFF666348);
  static const Color oliveSoft = Color(0xFFF0E8DA);

  // Page identities
  static const Color search = Color(0xFF796348);
  static const Color compare = Color(0xFF666348);
  static const Color wishlist = Color(0xFF986B59);
  static const Color enquiries = Color(0xFFAC824D);
  static const Color smart = Color(0xFF796348);
  static const Color trip = Color(0xFF74734F);

  // Surfaces
  static const Color background = Color(0xFFF5F0E7);
  static const Color surface = Color(0xFFFCF9F2);
  static const Color surfaceSoft = Color(0xFFEDE4D6);
  static const Color border = Color(0xFFE2D7C7);

  // Typography
  static const Color textPrimary = Color(0xFF302C24);
  static const Color textSecondary = Color(0xFF5F594D);
  static const Color textMuted = Color(0xFF716757);

  // Semantic
  static const Color success = Color(0xFF527653);
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
