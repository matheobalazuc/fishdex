import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FishdexTheme {
  // Light palette — eau claire, épuré, moderne
  static const Color background   = Color(0xFFF0F6FF);
  static const Color surface      = Colors.white;
  static const Color primary      = Color(0xFF0094C6);   // bleu pêche
  static const Color primaryDeep  = Color(0xFF005E8A);
  static const Color golden       = Color(0xFFFF9F0A);   // iOS orange / écailles
  static const Color coral        = Color(0xFFFF453A);   // iOS red
  static const Color mint         = Color(0xFF30D158);   // iOS green
  static const Color textPrimary  = Color(0xFF1C1C1E);
  static const Color textSecondary= Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFAEAEB2);

  // Liquid Glass tokens
  static const Color glassWhite   = Color(0xB8FFFFFF);   // 72% white
  static const Color glassBorder  = Color(0xCCFFFFFF);   // specular
  static const Color glassShadow  = Color(0x14000000);

  // Legacy compat (conserve les refs dans les autres fichiers)
  static const Color abyss        = background;
  static const Color deepOcean    = Color(0xFFDDEEF8);
  static const Color midnight     = Color(0xFFEBF4FB);
  static const Color waterSurface = Color(0xFFCCE6F4);
  static const Color bioluminescent = primary;
  static const Color goldenScales   = golden;
  static const Color coralAccent    = coral;
  static const Color seafoam        = mint;

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: golden,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      displayMedium: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      bodyLarge: GoogleFonts.dmSans(color: textPrimary, fontSize: 16),
      bodyMedium: GoogleFonts.dmSans(color: textSecondary, fontSize: 14),
      labelLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  );
}
