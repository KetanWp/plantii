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

  runApp(const PlantiiApp());
}

/// Backward compatibility alias
typedef CropDoctorApp = PlantiiApp;

/// Root widget of Plantii application
class PlantiiApp extends StatelessWidget {
  const PlantiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
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
            initialRoute: AppRoutes.language,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
