import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'routes.dart';
import 'services/auth_service.dart';
import 'services/locale_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read saved language before runApp to decide initial route and avoid showing language screen on every restart
  final String? savedLanguage = await LocaleProvider.getSavedLanguage();

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // On first launch, sign in anonymously and preserve the session
    await AuthService.instance.initializeAuth();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(PlantiiApp(initialLanguage: savedLanguage));
}

/// Backward compatibility aliases
typedef CropDoctorApp = PlantiiApp;
typedef MyApp = PlantiiApp;

/// Root widget of Plantii application
class PlantiiApp extends StatelessWidget {
  final String? initialLanguage;
  final String? initialRoute;

  const PlantiiApp({
    super.key,
    this.initialLanguage,
    this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSavedLanguage =
        initialLanguage != null && initialLanguage!.trim().isNotEmpty;
    final String startRoute = initialRoute ??
        (hasSavedLanguage ? AppRoutes.home : AppRoutes.language);

    final Locale initialLocale = hasSavedLanguage
        ? Locale(initialLanguage!.trim())
        : const Locale('hi');

    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(initialLocale: initialLocale),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)?.appTitle ?? 'Plantii',
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            initialRoute: startRoute,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
