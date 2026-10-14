import 'package:flutter/material.dart';

import 'screens/language_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/crop_selection_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';

import 'screens/consent_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/settings_screen.dart';

/// Centralized named route definitions for the application
class AppRoutes {
  static const String language = '/language';
  static const String consent = '/consent';
  static const String home = '/home';
  static const String cropSelection = '/crop-selection';
  static const String camera = '/camera';
  static const String loading = '/loading';
  static const String result = '/result';
  static const String history = '/history';
  static const String privacyPolicy = '/privacy-policy';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        language: (context) => const LanguageSelectionScreen(),
        consent: (context) => const ConsentScreen(),
        home: (context) => const HomeScreen(),
        cropSelection: (context) => const CropSelectionScreen(),
        camera: (context) => const CameraScreen(),
        loading: (context) => const LoadingScreen(),
        result: (context) => const ResultScreen(),
        history: (context) => const HistoryScreen(),
        privacyPolicy: (context) => const PrivacyPolicyScreen(),
        settings: (context) => const SettingsScreen(),
      };
}
