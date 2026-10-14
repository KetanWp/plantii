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
import 'package:plantii/services/real_diagnosis_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  Map<String, WidgetBuilder>? extraRoutes,
}) {
  return MaterialApp(
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

  group('ConsentScreen Widget Tests', () {
    testWidgets('renders all 5 consent points, policy link, and buttons', (tester) async {
      // Set larger test viewport size
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(child: const ConsentScreen()));
      await tester.pumpAndSettle();

      // Check header title
      expect(find.text('Important Privacy & AI Notice'), findsWidgets);

      // Verify all 5 lines are present
      expect(find.textContaining('Google Gemini'), findsOneWidget);
      expect(find.textContaining('anonymous account'), findsOneWidget);
      expect(find.textContaining("don't sell your data"), findsOneWidget);
      expect(find.textContaining('guidance, not a guarantee'), findsOneWidget);
      expect(find.textContaining('delete your data anytime'), findsOneWidget);

      // Verify full policy link
      expect(find.byKey(const ValueKey('view_full_privacy_policy_btn')), findsOneWidget);

      // Verify two main buttons
      expect(find.byKey(const ValueKey('consent_agree_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('consent_decline_button')), findsOneWidget);
    });

    testWidgets('tapping I Agree saves consent and triggers callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool consentGranted = false;
      await tester.pumpWidget(createTestApp(
        child: ConsentScreen(
          onConsentGranted: () => consentGranted = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('consent_agree_button')));
      await tester.tap(find.byKey(const ValueKey('consent_agree_button')));
      await tester.pumpAndSettle();

      expect(consentGranted, true);
      final hasConsent = await ConsentService.instance.hasValidConsent();
      expect(hasConsent, true);
    });

    testWidgets('tapping No Thanks displays explanation dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(child: const ConsentScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('consent_decline_button')));
      await tester.tap(find.byKey(const ValueKey('consent_decline_button')));
      await tester.pumpAndSettle();

      // Verify explanation dialog
      expect(find.text('Consent Required to Scan'), findsOneWidget);
      expect(find.textContaining('Without your consent, scanning features remain blocked'), findsOneWidget);
      expect(find.text('Review Consent'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });
  });

  group('HomeScreen Consent & Scan Blocking Tests', () {
    testWidgets('tapping scan button when consent missing shows blocked dialog', (tester) async {
      SharedPreferences.setMockInitialValues({}); // No consent
      await tester.pumpWidget(createTestApp(child: const HomeScreen()));
      await tester.pumpAndSettle();

      // Tap circular scan button by Key
      await tester.tap(find.byKey(const ValueKey('home_circular_scan_button')));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Consent Required to Scan'), findsOneWidget);
      expect(find.byKey(const ValueKey('review_consent_dialog_button')), findsOneWidget);
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
    testWidgets('renders all required settings options', (tester) async {
      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Withdraw Consent'), findsOneWidget);
      expect(find.text('Delete My Data'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
      expect(find.textContaining('info@prakruty.com'), findsWidgets);
    });

    testWidgets('withdraw consent shows confirmation dialog', (tester) async {
      // Pre-seed consent
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
