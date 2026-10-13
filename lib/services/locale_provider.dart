import 'package:flutter/material.dart';

/// Manages the application locale (Hindi / English).
/// Hindi is set as the primary default language.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('hi');

  Locale get locale => _locale;

  bool get isHindi => _locale.languageCode == 'hi';

  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
  }

  void toggleLocale() {
    if (_locale.languageCode == 'hi') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('hi'));
    }
  }
}
