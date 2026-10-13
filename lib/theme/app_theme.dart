import 'package:flutter/material.dart';

/// Central Design System & Theme for Crop Doctor
///
/// Designed for high sunlight visibility, low-end device performance,
/// and full Hindi (Devanagari) script support with Noto Sans typography.
class AppTheme {
  // Brand Palette: Deep forest greens, cream content backgrounds, leaf green accent
  static const Color forestDark = Color(0xFF0E1712); // Deepest forest green (almost black)
  static const Color forestGreen = Color(0xFF1B3A2B); // Rich forest green header/dark area
  static const Color forestGreenSurface = Color(0xFF14271D); // Subtle dark surface
  static const Color creamBackground = Color(0xFFF7F5EF); // Warm cream/off-white content background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Clean card surface
  static const Color leafGreenAccent = Color(0xFF7ED957); // Bright leaf-green primary accent
  static const Color leafGreenDark = Color(0xFF5AB834); // Deeper leaf green for active states
  static const Color leafGreenSubtle = Color(0xFFEAF8E6); // Light pastel green for chips

  // Neutral & Typography Colors
  static const Color textDark = Color(0xFF0E1712); // High-contrast text on cream/white in sunlight
  static const Color textMuted = Color(0xFF4A554E); // Secondary body text on light backgrounds
  static const Color textLight = Color(0xFFFFFFFF); // High-contrast text on dark forest areas
  static const Color textLightMuted = Color(0xFFB4C8BB); // Secondary text on dark forest areas
  static const Color borderSubtle = Color(0xFFE5E2D8); // Soft outdoor border for cards

  // Severity Colors (Strictly for green/yellow/red diagnostic indicators)
  static const Color severityMild = Color(0xFF2E7D32); // Vibrant green
  static const Color severityModerate = Color(0xFFE65100); // Deep amber/orange (sunlight visible)
  static const Color severitySevere = Color(0xFFD32F2F); // High-contrast red

  // Backward-compatibility aliases for existing code
  static const Color primaryGreen = forestGreen;
  static const Color primaryGreenLight = leafGreenSubtle;
  static const Color earthBrown = Color(0xFF5D4037);
  static const Color highContrastDark = textDark;
  static const Color mutedDark = textMuted;
  static const Color earthSand = creamBackground;
  static const Color severityLow = severityMild;
  static const Color severityMedium = severityModerate;
  static const Color severityHigh = severitySevere;

  // Font Family: Noto Sans with Hindi Devanagari fallbacks
  static const String fontName = 'Noto Sans';
  static const List<String> fontFallbacks = [
    'Noto Sans',
    'Noto Sans Devanagari',
    'Roboto',
    'sans-serif',
  ];

  // Radii & Layout Standards
  static const double cardRadius = 20.0;
  static final BorderRadius cardBorderRadius = BorderRadius.circular(cardRadius);
  static const double buttonRadius = 28.0; // Fully rounded for 56px height (Stadium shape)
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(buttonRadius);
  static const double chipRadius = 16.0;
  static final BorderRadius chipBorderRadius = BorderRadius.circular(chipRadius);

  // Spacing & Touch Target
  static const double minTouchTargetSize = 56.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(18.0);

  // Soft Ambient Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x247ED957),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  // Dark header gradient
  static const LinearGradient forestHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [forestDark, forestGreen],
  );

  /// Generates the complete ThemeData with Noto Sans typography
  static ThemeData get lightTheme {
    const textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontFamily: fontName,
        fontFamilyFallback: fontFallbacks,
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: textDark,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontName,
        fontFamilyFallback: fontFallbacks,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      titleLarge: TextStyle(
        fontFamily: fontName,
        fontFamilyFallback: fontFallbacks,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      titleMedium: TextStyle(
        fontFamily: fontName,
        fontFamilyFallback: fontFallbacks,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontName,
        fontFamilyFallback: fontFallbacks,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textDark,
        height: 1.45,
      ),
      // Minimum 16px body for clear reading under direct sunlight
      bodyMedium: TextStyle(
        fontFamily: fontName,
        fontFamilyFallback: fontFallbacks,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textMuted,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamily: fontName,
        fontFamilyFallback: fontFallbacks,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textMuted,
        height: 1.35,
      ),
      labelLarge: TextStyle(
        fontFamily: fontName,
        fontFamilyFallback: fontFallbacks,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textDark,
        letterSpacing: 0.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: forestGreen,
      scaffoldBackgroundColor: creamBackground,
      fontFamily: fontName,
      fontFamilyFallback: fontFallbacks,

      colorScheme: const ColorScheme.light(
        primary: forestGreen,
        onPrimary: Colors.white,
        secondary: leafGreenAccent,
        onSecondary: textDark,
        surface: surfaceWhite,
        onSurface: textDark,
        error: severitySevere,
        onError: Colors.white,
      ),

      textTheme: textTheme,

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: forestDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontName,
          fontFamilyFallback: fontFallbacks,
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 26,
        ),
      ),

      // Primary buttons: Leaf-green background with dark forest text for maximum contrast
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: leafGreenAccent,
          foregroundColor: textDark,
          minimumSize: const Size.fromHeight(minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontName,
            fontFamilyFallback: fontFallbacks,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Outlined buttons: High-contrast forest green border, fully rounded
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestGreen,
          minimumSize: const Size.fromHeight(minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: forestGreen, width: 2),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: fontName,
            fontFamilyFallback: fontFallbacks,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Card theme: 20px radius, soft subtle border on cream background
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: cardBorderRadius,
          side: const BorderSide(color: borderSubtle, width: 1.2),
        ),
      ),

      // Bottom Navigation Bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: forestGreen,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(
          fontFamily: fontName,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontName,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
