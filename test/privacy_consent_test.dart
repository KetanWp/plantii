import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantii/l10n/app_localizations.dart';
import 'package:plantii/models/diagnosis.dart';
import 'package:plantii/routes.dart';
import 'package:plantii/screens/consent_screen.dart';
import 'package:plantii/screens/home_screen.dart';
import 'package:plantii/screens/result_screen.dart';
import 'package:plantii/screens/settings_screen.dart';
import 'package:plantii/services/consent_service.dart';
import 'package:plantii/services/locale_provider.dart';
import 'package:plantii/widgets/privacy_consent_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  Map<String, WidgetBuilder>? extraRoutes,
}) {
  return ChangeNotifierProvider(
    create: (_) => LocaleProvider(initialLocale: locale),
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        ...?extraRoutes,
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.consent: (context) => const ConsentScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
        AppRoutes.privacyPolicy: (context) => const Scaffold(body: Text('Privacy Policy Dummy')),
      },
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ConsentService Unit Tests', () {
    test('initially hasValidConsent is false', () async {
      final consentService = ConsentService();
      final hasConsent = await consentService.hasValidConsent();
      expect(hasConsent, false);
    });

    test('saveConsent stores version 1.0 and timestamp', () async {
      final consentService = ConsentService();
      await consentService.saveConsent(version: '1.0');

      final hasConsent = await consentService.hasValidConsent();
      expect(hasConsent, true);

      final version = await consentService.getConsentedVersion();
      expect(version, '1.0');

      final date = await consentService.getConsentedDate();
      expect(date, isNotNull);
    });

    test('withdrawConsent resets consent state', () async {
      final consentService = ConsentService();
      await consentService.saveConsent(version: '1.0');
      expect(await consentService.hasValidConsent(), true);

      await consentService.withdrawConsent();
      expect(await consentService.hasValidConsent(), false);
    });
  });

  group('PrivacyConsentSheet Widget Tests', () {
    testWidgets('renders Hindi/English notice, I agree button, Privacy Policy link, and Cancel button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool? agreedResult;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const ValueKey('trigger_sheet_btn'),
                onPressed: () async {
                  agreedResult = await PrivacyConsentSheet.show(context);
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('trigger_sheet_btn')));
      await tester.pumpAndSettle();

      // Check sheet presence
      expect(find.byKey(const ValueKey('privacy_consent_bottom_sheet')), findsOneWidget);

      // Check bilingual lines
      expect(find.textContaining('Your plant photo is sent to an AI service to diagnose it'), findsOneWidget);
      expect(find.textContaining("We don't sell your data"), findsOneWidget);
      expect(find.textContaining('पौधे की फोटो रोग की पहचान के लिए AI सेवा को भेजी जाती है'), findsOneWidget);

      // Check buttons and links
      expect(find.byKey(const ValueKey('privacy_agree_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('privacy_cancel_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('privacy_policy_link')), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.byKey(const ValueKey('privacy_cancel_button')));
      await tester.pumpAndSettle();

      expect(agreedResult, isFalse);
      expect(await ConsentService.instance.hasValidConsent(), isFalse);
    });

    testWidgets('tapping I Agree saves consent locally and returns true', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool? agreedResult;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const ValueKey('trigger_sheet_btn'),
                onPressed: () async {
                  agreedResult = await PrivacyConsentSheet.show(context);
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('trigger_sheet_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('privacy_agree_button')));
      await tester.pumpAndSettle();

      expect(agreedResult, isTrue);
      expect(await ConsentService.instance.hasValidConsent(), isTrue);
      expect(await ConsentService.instance.getConsentedVersion(), '1.0');
    });
  });

  group('HomeScreen First-Scan Consent Flow Tests', () {
    testWidgets('tapping scan on first use shows PrivacyConsentSheet', (tester) async {
      SharedPreferences.setMockInitialValues({}); // No consent
      await tester.pumpWidget(createTestApp(child: const HomeScreen()));
      await tester.pumpAndSettle();

      // Tap circular scan button
      await tester.tap(find.byKey(const ValueKey('home_circular_scan_button')));
      await tester.pumpAndSettle();

      // One-time bottom sheet appears
      expect(find.byKey(const ValueKey('privacy_consent_bottom_sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('privacy_agree_button')), findsOneWidget);

      // Tap I agree
      await tester.tap(find.byKey(const ValueKey('privacy_agree_button')));
      await tester.pumpAndSettle();

      // Consent is saved
      expect(await ConsentService.instance.hasValidConsent(), isTrue);

      // Now photo tips sheet is displayed (scan flow continues)
      expect(find.byKey(const ValueKey('photo_tips_bottom_sheet')), findsOneWidget);
    });

    testWidgets('top settings button navigates to SettingsScreen', (tester) async {
      await tester.pumpWidget(createTestApp(child: const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home_settings_button')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home_settings_button')));
      await tester.pumpAndSettle();

      // Should be on settings screen
      expect(find.text('Settings & Privacy'), findsOneWidget);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all required settings options including Change Language, Privacy Policy and Delete My Data', (tester) async {
      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Change Language'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Withdraw Consent'), findsOneWidget);
      expect(find.text('Delete My Data'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
      expect(find.textContaining('info@prakruty.com'), findsWidgets);
    });

    testWidgets('tapping Change Language opens language picker dialog', (tester) async {
      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Language'));
      await tester.pumpAndSettle();

      expect(find.text('Select Language / भाषा चुनें'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('English'), findsAtLeastNWidgets(1));
    });

    testWidgets('withdraw consent shows confirmation dialog', (tester) async {
      final consentService = ConsentService();
      await consentService.saveConsent(version: '1.0');

      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Withdraw Consent'));
      await tester.pumpAndSettle();

      expect(find.text('Withdraw Consent?'), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm_withdraw_consent_btn')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm_withdraw_consent_btn')));
      await tester.pumpAndSettle();

      expect(await consentService.hasValidConsent(), false);
    });

    testWidgets('delete my data shows confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete My Data'));
      await tester.pumpAndSettle();

      expect(find.text('Permanently Delete Data?'), findsOneWidget);
      expect(find.textContaining('permanently delete your account'), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm_delete_everything_btn')), findsOneWidget);
    });
  });

  group('ResultScreen AI Disclaimer Tests', () {
    testWidgets('diseased result screen displays AI guidance disclaimer line', (tester) async {
      const diseasedDiagnosis = Diagnosis(
        id: 'test_disease_1',
        cropId: 'tomato',
        diseaseName: 'Tomato Early Blight',
        scientificName: 'Alternaria solani',
        severity: DiagnosisSeverity.moderate,
        confidenceLevel: 'High (95%)',
        description: 'Dark concentric spots on foliage.',
        immediateActions: ['Remove infected leaves'],
        organicTreatments: ['Neem oil spray'],
        chemicalTreatments: ['Mancozeb spray'],
        safetyNote: 'Wear gloves and mask',
        preventionTips: ['Rotate crops'],
      );

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ResultScreen(),
                    settings: const RouteSettings(
                      arguments: {
                        'diagnosis': diseasedDiagnosis,
                        'imagePath': null,
                      },
                    ),
                  ),
                );
              },
              child: const Text('Open Result'),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Result'));
      await tester.pumpAndSettle();

      // Disclaimer must be present
      expect(find.byKey(const ValueKey('ai_guidance_disclaimer')), findsOneWidget);
      expect(find.text('AI guidance, not a guarantee.'), findsOneWidget);
    });
  });
}
