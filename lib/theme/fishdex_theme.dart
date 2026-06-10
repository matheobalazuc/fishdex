import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FishdexTheme {
  // Palette — deep ocean with bioluminescent accents
  static const Color deepOcean = Color(0xFF0A1628);
  static const Color midnight = Color(0xFF0D1F3C);
  static const Color abyss = Color(0xFF071019);
  static const Color waterSurface = Color(0xFF1A3A5C);
  static const Color bioluminescent = Color(0xFF00E5FF);
  static const Color goldenScales = Color(0xFFFFB830);
  static const Color coralAccent = Color(0xFFFF6B6B);
  static const Color seafoam = Color(0xFF64FFDA);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color textPrimary = Color(0xFFF0F8FF);
  static const Color textSecondary = Color(0xFF8BADC4);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: abyss,
    colorScheme: const ColorScheme.dark(
      primary: bioluminescent,
      secondary: goldenScales,
      surface: midnight,
      onPrimary: deepOcean,
      onSecondary: deepOcean,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        color: textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.dmSans(
        color: textSecondary,
        fontSize: 14,
      ),
      labelLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}