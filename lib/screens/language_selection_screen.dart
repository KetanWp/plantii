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

  Future<void> _selectLanguage(BuildContext context, String langCode) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocaleProvider.languageKey, langCode);
    await localeProvider.setLocale(Locale(langCode));

    if (!context.mounted) return;

    final hasSeenPermissions = prefs.getBool('has_seen_permissions') ?? false;
    if (!hasSeenPermissions) {
      Navigator.pushReplacementNamed(context, AppRoutes.permissions);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                  onPressed: () => _selectLanguage(context, 'hi'),
                ),
                const SizedBox(height: 16),
                // English option
                BigTouchButton(
                  key: const ValueKey('choose_english_button'),
                  label: 'English',
                  isPrimary: !localeProvider.isHindi,
                  onPressed: () => _selectLanguage(context, 'en'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
