import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists the application locale (Hindi / English).
class LocaleProvider extends ChangeNotifier {
  static const String languageKey = 'plantii_selected_language';

  Locale _locale;

  LocaleProvider({Locale? initialLocale})
      : _locale = initialLocale ?? const Locale('hi');

  Locale get locale => _locale;

  bool get isHindi => _locale.languageCode == 'hi';

  /// Updates active locale and persists the chosen language code to SharedPreferences
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(languageKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('LocaleProvider: Error persisting language: $e');
    }
  }

  void toggleLocale() {
    if (_locale.languageCode == 'hi') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('hi'));
    }
  }

  /// Reads stored language preference from SharedPreferences
  static Future<String?> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(languageKey);
    } catch (e) {
      debugPrint('LocaleProvider: Error reading saved language: $e');
      return null;
    }
  }
}
