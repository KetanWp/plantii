import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'routes.dart';
import 'services/locale_provider.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
