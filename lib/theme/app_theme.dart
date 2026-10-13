import 'package:flutter/material.dart';

/// App theme configured for outdoor sunlight legibility and high contrast.
/// Uses a deep green and earthy palette with large touch targets (min 56px).
class AppTheme {
  // Brand colors: High contrast green and earthy tones
  static const Color primaryGreen = Color(0xFF1B5E20); // Deep forest green
  static const Color primaryGreenLight = Color(0xFFE8F5E9);
  static const Color earthBrown = Color(0xFF5D4037); // Warm rich earth
  static const Color earthSand = Color(0xFFF5F2EB); // Soft outdoor-friendly neutral
  static const Color highContrastDark = Color(0xFF111A11); // Near-black for crisp text in sunlight
  static const Color mutedDark = Color(0xFF333E33); // Secondary text
  static const Color borderSubtle = Color(0xFFB0BEAF); // Sunlight-visible outline
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Status & severity traffic light colors (high-contrast for sunlight)
  static const Color severityLow = Color(0xFF2E7D32); // Vibrant green
  static const Color severityMedium = Color(0xFFE65100); // Deep amber/orange (better than yellow in sunlight)
  static const Color severityHigh = Color(0xFFC62828); // Bold red

  // Minimum touch target size
  static const double minTouchTargetSize = 56.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: earthSand,

      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: earthBrown,
        onSecondary: Colors.white,
        surface: surfaceWhite,
        onSurface: highContrastDark,
        error: severityHigh,
        onError: Colors.white,
      ),

      // Crisp, large typography for easy outdoor reading
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: highContrastDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: highContrastDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: highContrastDark,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: highContrastDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: highContrastDark,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: mutedDark,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),

      // App Bar theme with bold high contrast
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 28,
        ),
      ),

      // Primary buttons with minimum 56px height for big finger taps
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Secondary outlined buttons (high contrast border)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size.fromHeight(minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: primaryGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Cards with crisp outlines so they don't wash out in sunlight
      cardTheme: const CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borderSubtle, width: 1.5),
        ),
      ),
    );
  }
}
