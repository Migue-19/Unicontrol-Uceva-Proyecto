import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design System Colors - Light Mode
  static const Color background = Color(0xFFF5F7F6);
  static const Color foreground = Color(0xFF171C19);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF171C19);
  static const Color primary = Color(0xFF1E854A);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFE9EBEA);
  static const Color secondaryForeground = Color(0xFF171C19);
  static const Color muted = Color(0xFFEDF0EE);
  static const Color mutedForeground = Color(0xFF6B7670);
  static const Color accent = Color(0xFFD6F5E3);
  static const Color accentForeground = Color(0xFF176639);
  static const Color destructive = Color(0xFFDE2525);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDFE4E1);
  static const Color input = Color(0xFFDFE4E1);
  static const Color ring = Color(0xFF1E854A);
  static const Color success = Color(0xFF1E854A);
  static const Color warning = Color(0xFFF59E0B);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF059669)], // primary to emerald-600
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient authBackgroundGradient = LinearGradient(
    colors: [Color(0xFFE6F4EA), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: foreground,
      displayColor: foreground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        surface: card,
        onSurface: cardForeground,
        error: destructive,
        onError: destructiveForeground,
      ).copyWith(
        surfaceContainerHighest: muted,
      ),
      scaffoldBackgroundColor: background,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.spaceGrotesk(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 30,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: foreground,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: mutedForeground,
          fontSize: 12,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: card.withValues(alpha: 0.95),
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: foreground),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        labelStyle: GoogleFonts.inter(color: mutedForeground, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(color: mutedForeground, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: destructive, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: foreground,
        contentTextStyle: GoogleFonts.inter(
          color: card,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        modalBackgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: primaryForeground,
          backgroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: foreground,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondary,
        selectedColor: accent,
        disabledColor: muted,
        side: const BorderSide(color: border),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: GoogleFonts.inter(
          color: foreground,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          color: accentForeground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      dividerColor: border,
      splashColor: primary.withValues(alpha: 0.12),
      highlightColor: primary.withValues(alpha: 0.06),
    );
  }
}
