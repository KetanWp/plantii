import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/big_touch_button.dart';

/// Screen 1: Language Selection (shown on first launch)
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
              Text(
                l10n.languageTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 36),
              // Hindi option
              BigTouchButton(
                label: 'हिन्दी (Hindi)',
                isPrimary: localeProvider.isHindi,
                onPressed: () {
                  localeProvider.setLocale(const Locale('hi'));
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
              ),
              const SizedBox(height: 16),
              // English option
              BigTouchButton(
                label: 'English',
                isPrimary: !localeProvider.isHindi,
                onPressed: () {
                  localeProvider.setLocale(const Locale('en'));
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
