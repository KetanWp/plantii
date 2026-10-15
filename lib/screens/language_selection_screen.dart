import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/big_touch_button.dart';

/// Screen 1: Language Selection (shown only on first launch when no language is saved)
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.language,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose Language / भाषा चुनें',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 36),
              // Hindi option
              BigTouchButton(
                key: const ValueKey('choose_hindi_button'),
                label: 'हिंदी',
                isPrimary: localeProvider.isHindi,
                onPressed: () async {
                  // Await the write to shared_preferences before navigating
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(LocaleProvider.languageKey, 'hi');
                  await localeProvider.setLocale(const Locale('hi'));
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
              ),
              const SizedBox(height: 16),
              // English option
              BigTouchButton(
                key: const ValueKey('choose_english_button'),
                label: 'English',
                isPrimary: !localeProvider.isHindi,
                onPressed: () async {
                  // Await the write to shared_preferences before navigating
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(LocaleProvider.languageKey, 'en');
                  await localeProvider.setLocale(const Locale('en'));
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
