import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = ShopWiseColors.emerald;
  static const Color primaryDark = ShopWiseColors.emeraldDeep;
  static const Color primaryLight = ShopWiseColors.emeraldSoft;

  static const Color secondary = ShopWiseColors.olive;
  static const Color background = ShopWiseColors.background;
  static const Color surface = ShopWiseColors.surface;

  static const Color textPrimary = ShopWiseColors.textPrimary;
  static const Color textSecondary = ShopWiseColors.textSecondary;
  static const Color textMuted = ShopWiseColors.textMuted;

  static const Color border = ShopWiseColors.border;
  static const Color success = ShopWiseColors.success;
  static const Color warning = ShopWiseColors.warning;
  static const Color error = ShopWiseColors.error;

  static ThemeData get lightTheme {
    final TextTheme base = GoogleFonts.plusJakartaSansTextTheme();
    final TextTheme editorial = GoogleFonts.playfairDisplayTextTheme(base);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),

      splashFactory: InkSparkle.splashFactory,

      textTheme: base.copyWith(
        displayLarge: editorial.displayLarge?.copyWith(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.10,
          letterSpacing: -1.0,
        ),
        displayMedium: editorial.displayMedium?.copyWith(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: -0.8,
        ),
        displaySmall: editorial.displaySmall?.copyWith(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.18,
          letterSpacing: -0.5,
        ),
        headlineLarge: editorial.headlineLarge?.copyWith(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.35,
        ),
        headlineMedium: editorial.headlineMedium?.copyWith(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        headlineSmall: editorial.headlineSmall?.copyWith(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: editorial.titleLarge?.copyWith(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
        ),
        titleMedium: base.titleMedium?.copyWith(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.titleSmall?.copyWith(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          color: textSecondary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: base.bodySmall?.copyWith(
          color: textMuted,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: base.labelLarge?.copyWith(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: base.labelMedium?.copyWith(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: base.labelSmall?.copyWith(
          color: textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: ShopWiseElevation.none,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.large),
          side: const BorderSide(color: border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: const BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 13),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 76,
        indicatorColor: ShopWiseColors.emeraldSoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? ShopWiseColors.emeraldDeep
                : ShopWiseColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 24 : 22,
            color: selected
                ? ShopWiseColors.emeraldDeep
                : ShopWiseColors.textMuted,
          );
        }),
      ),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        elevation: ShopWiseElevation.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.medium),
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: ShopWiseElevation.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
