import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plantii/l10n/app_localizations.dart';
import 'package:plantii/models/diagnosis.dart';
import 'package:plantii/models/scan_record.dart';
import 'package:plantii/screens/history_screen.dart';
import 'package:plantii/screens/home_screen.dart';
import 'package:plantii/screens/language_selection_screen.dart';
import 'package:plantii/screens/permissions_screen.dart';
import 'package:plantii/screens/result_screen.dart';
import 'package:plantii/screens/settings_screen.dart';
import 'package:plantii/services/locale_provider.dart';
import 'package:plantii/services/scan_history_service.dart';
import 'package:plantii/theme/app_theme.dart';

/// Test harness rendering screens at small phone viewport (320x640)
/// with maximum allowed system font scale (1.25), in both Hindi and English.
Widget buildClampedSmallViewportApp({
  required Widget child,
  required Locale locale,
}) {
  return ChangeNotifierProvider(
    create: (_) => LocaleProvider(initialLocale: locale),
    child: MaterialApp(
      locale: locale,
      theme: AppTheme.lightTheme,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, rootWidget) {
        // Enforces the 0.9 to 1.25 text scale cap
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.25),
          ),
          child: rootWidget!,
        );
      },
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Size smallPhoneSize = Size(320, 640);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_permissions': true,
      'user_language': 'en',
    });
  });

  group('Small Screen (320x640) & Max TextScale (1.25) Overflow Tests', () {
    for (final locale in const [Locale('en'), Locale('hi')]) {
      final lang = locale.languageCode;

      testWidgets('PermissionsScreen renders without overflow in $lang', (tester) async {
        tester.view.physicalSize = smallPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildClampedSmallViewportApp(
            child: const PermissionsScreen(),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('allow_permissions_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('skip_permissions_button')), findsOneWidget);
      });

      testWidgets('LanguageSelectionScreen renders without overflow in $lang', (tester) async {
        tester.view.physicalSize = smallPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildClampedSmallViewportApp(
            child: const LanguageSelectionScreen(),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('हिंदी'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
      });

      testWidgets('HomeScreen renders without overflow in $lang', (tester) async {
        tester.view.physicalSize = smallPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildClampedSmallViewportApp(
            child: const HomeScreen(),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('home_circular_scan_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('home_weather_card')), findsOneWidget);
      });

      testWidgets('SettingsScreen renders without overflow in $lang', (tester) async {
        tester.view.physicalSize = smallPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildClampedSmallViewportApp(
            child: const SettingsScreen(),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(lang == 'hi' ? 'गोपनीयता नीति' : 'Privacy Policy'), findsOneWidget);
      });

      testWidgets('HistoryScreen renders without overflow with items in $lang', (tester) async {
        tester.view.physicalSize = smallPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final historyService = ScanHistoryService();
        await historyService.saveScan(
          ScanRecord(
            id: 'rec_overflow_1',
            cropId: 'tomato',
            cropName: lang == 'hi' ? 'टमाटर' : 'Tomato',
            diseaseName: lang == 'hi' ? 'टमाटर का अगेती झुलसा रोग' : 'Tomato Early Blight Disease',
            severity: DiagnosisSeverity.severe,
            scannedAt: DateTime.now(),
            photoPath: '',
            diagnosis: const Diagnosis(
              id: 'diag_1',
              cropId: 'tomato',
              status: DiagnosisStatus.diseased,
              diseaseName: 'Tomato Early Blight',
              scientificName: 'Alternaria solani',
              severity: DiagnosisSeverity.severe,
              description: 'Sample description for overflow verification.',
              confidenceLevel: 'High (95%)',
              immediateActions: ['Remove leaves'],
              organicTreatments: ['Neem oil'],
              chemicalTreatments: ['Mancozeb'],
              safetyNote: 'Wear gloves',
              preventionTips: ['Rotate crops'],
            ),
          ),
        );

        await tester.pumpWidget(
          buildClampedSmallViewportApp(
            child: const HistoryScreen(),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(Card), findsAtLeastNWidgets(1));
      });

      testWidgets('ResultScreen (Diseased) renders without overflow in $lang', (tester) async {
        tester.view.physicalSize = smallPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final diseasedDiagnosis = Diagnosis(
          id: 'diag_diseased_small',
          cropId: 'tomato',
          detectedCrop: lang == 'hi' ? 'टमाटर' : 'Tomato',
          cropConfidence: 'very_likely',
          status: DiagnosisStatus.diseased,
          diseaseName: lang == 'hi' ? 'टमाटर का अगेती झुलसा' : 'Tomato Early Blight',
          scientificName: 'Alternaria solani',
          severity: DiagnosisSeverity.moderate,
          confidenceLevel: lang == 'hi' ? 'अत्यधिक संभावित (95%)' : 'High (95%)',
          spokenSummary: lang == 'hi'
              ? 'टमाटर में अगेती झुलसा रोग है। रोगग्रस्त पत्तियों को तुरंत हटा दें।'
              : 'Tomato early blight detected. Prune infected leaves immediately.',
          description: lang == 'hi'
              ? 'पत्तियों पर भूरे रंग के छल्लेदार धब्बे दिखाई देते हैं।'
              : 'Concentric brown leaf lesions with yellow halos.',
          immediateActions: [lang == 'hi' ? 'रोगग्रस्त पत्तियां हटाएं' : 'Remove infected leaves'],
          organicTreatments: [lang == 'hi' ? 'नीम का तेल छिड़कें' : 'Spray neem oil'],
          chemicalTreatments: [lang == 'hi' ? 'मैनकोजेब का छिड़काव' : 'Mancozeb spray'],
          safetyNote: lang == 'hi' ? 'मास्क और दस्ताने पहनें' : 'Wear protective gear',
          preventionTips: [lang == 'hi' ? 'फसल चक्र अपनाएं' : 'Crop rotation'],
          fromCache: true,
        );

        await tester.pumpWidget(
          buildClampedSmallViewportApp(
            child: Builder(
              builder: (ctx) => TextButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (c) => const ResultScreen(),
                      settings: RouteSettings(
                        arguments: {
                          'diagnosis': diseasedDiagnosis,
                          'imagePath': null,
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('detected_crop_badge')), findsOneWidget);
        expect(find.byKey(const ValueKey('wrong_crop_button')), findsNothing);
        expect(find.byKey(const ValueKey('recheck_button')), findsNothing);
      });

      testWidgets('ResultScreen (Healthy) renders without overflow in $lang', (tester) async {
        tester.view.physicalSize = smallPhoneSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const healthyDiagnosis = Diagnosis(
          id: 'diag_healthy_small',
          cropId: 'wheat',
          status: DiagnosisStatus.healthy,
          diseaseName: 'Healthy Wheat',
          scientificName: 'Triticum aestivum',
          severity: DiagnosisSeverity.none,
          description: 'Foliage is green, sturdy, and disease-free.',
          confidenceLevel: 'Very Likely (98%)',
          immediateActions: [],
          organicTreatments: [],
          chemicalTreatments: [],
          safetyNote: '',
          preventionTips: ['Water adequately'],
        );

        await tester.pumpWidget(
          buildClampedSmallViewportApp(
            child: Builder(
              builder: (ctx) => TextButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (c) => const ResultScreen(),
                      settings: const RouteSettings(
                        arguments: {
                          'diagnosis': healthyDiagnosis,
                          'imagePath': null,
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(lang == 'hi' ? 'स्वस्थ पौधा' : 'Healthy Plant'), findsOneWidget);
      });
    }
  });
}
