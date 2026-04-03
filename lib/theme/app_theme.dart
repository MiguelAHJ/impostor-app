import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background / Surface
  static const background = Color(0xFF15161E);
  static const card = Color(0xFF1C1D2A);
  static const secondary = Color(0xFF252638);

  // Text
  static const foreground = Color(0xFFE4E8EE);
  static const mutedForeground = Color(0xFF7C8294);

  // Primary (green)
  static const primary = Color(0xFF1DB86A);
  static const primaryForeground = Color(0xFF15161E);

  // Accent (pink/red)
  static const accent = Color(0xFFE8365D);
  static const accentForeground = Color(0xFFF0F2F5);

  // Impostor (red)
  static const impostor = Color(0xFFE53935);
  static const impostorForeground = Color(0xFFF0F2F5);

  // Border
  static const border = Color(0xFF2A2B3D);

  // Light theme colors
  static const lightBg1 = Color(0xFFF8F0FF);
  static const lightBg2 = Color(0xFFEDE4FF);
  static const lightBg3 = Color(0xFFE8DEFF);
  static const cardWhite = Color(0xFFFFFFFF);
  static const blue = Color(0xFF5B8DEF);
  static const darkText = Color(0xFF1E1E2E);
  static const subtitleText = Color(0xFF9E9EB0);
  static const lightInputBg = Color(0xFFF5F5F8);
  static const lightBorder = Color(0xFFE8E8F0);
  static const teal = Color(0xFF4ECDC4);

  static const avatarColors = [
    Color(0xFFFF8A80),
    Color(0xFF82B1FF),
    Color(0xFFB388FF),
    Color(0xFFFFD180),
    Color(0xFF80CBC4),
    Color(0xFFF48FB1),
    Color(0xFFA5D6A7),
    Color(0xFFFFE082),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: AppColors.impostor,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
      ),
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  static TextStyle displayStyle({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.foreground,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle bodyStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.foreground,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
