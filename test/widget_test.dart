import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plantii/l10n/app_localizations.dart';
import 'package:plantii/models/crop_item.dart';
import 'package:plantii/models/diagnosis.dart';
import 'package:plantii/models/scan_record.dart';
import 'package:plantii/routes.dart';
import 'package:plantii/screens/crop_selection_screen.dart';
import 'package:plantii/screens/history_screen.dart';
import 'package:plantii/screens/result_screen.dart';
import 'package:plantii/services/image_processing_service.dart';
import 'package:plantii/services/locale_provider.dart';
import 'package:plantii/services/mock_diagnosis_service.dart';
import 'package:plantii/services/scan_history_service.dart';
import 'package:plantii/services/tts_service.dart';
import 'package:plantii/theme/app_theme.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CropSelectionScreen Tests', () {
    testWidgets('renders all 5 crops with large cards and titles',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('hi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CropSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all 5 crops are present in CropItem
      expect(CropItem.supportedCrops.length, 5);

      // Verify grid items exist
      expect(find.byType(Card), findsNWidgets(5));
      expect(find.text('टमाटर'), findsOneWidget); // Hindi default
      expect(find.text('आलू'), findsOneWidget);
    });
  });

  group('ImageProcessingService Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('crop_doctor_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('rejects empty or sub-10KB file with PhotoValidationException', () async {
      final tinyFile = File('${tempDir.path}/tiny.jpg');
      await tinyFile.writeAsBytes([1, 2, 3]);

      expect(
        () => ImageProcessingService.validateAndCompress(tinyFile),
        throwsA(isA<PhotoValidationException>()),
      );
    });

    test('validates and compresses an image over 1024px down to 1024px', () async {
      final validImage = img.Image(width: 1200, height: 1600);
      img.fill(validImage, color: img.ColorRgb8(34, 139, 34));
      final encodedJpg = img.encodeJpg(validImage);

      final validFile = File('${tempDir.path}/large_leaf.jpg');
      await validFile.writeAsBytes(encodedJpg);

      final compressedFile =
          await ImageProcessingService.validateAndCompress(validFile);

      expect(await compressedFile.exists(), isTrue);
      final decodedCompressed = img.decodeImage(await compressedFile.readAsBytes());
      expect(decodedCompressed, isNotNull);
      expect(decodedCompressed!.height, 1024);
      expect(decodedCompressed.width, lessThan(1024));
    });
  });

  group('MockDiagnosisService Tests', () {
    const service = MockDiagnosisService();

    test('provides complete 3 crop diagnoses in English', () async {
      final tomato = await service.getDiagnosis(cropId: 'tomato', languageCode: 'en');
      final potato = await service.getDiagnosis(cropId: 'potato', languageCode: 'en');
      final rice = await service.getDiagnosis(cropId: 'rice', languageCode: 'en');

      expect(tomato.diseaseName, 'Tomato Early Blight');
      expect(tomato.severity, DiagnosisSeverity.moderate);
      expect(tomato.organicTreatments, isNotEmpty);
      expect(tomato.chemicalTreatments, isNotEmpty);
      expect(tomato.safetyNote, isNotEmpty);

      expect(potato.diseaseName, 'Potato Late Blight');
      expect(potato.severity, DiagnosisSeverity.severe);

      expect(rice.diseaseName, 'Rice Leaf Blast');
      expect(rice.severity, DiagnosisSeverity.mild);
    });

    test('provides complete 3 crop diagnoses in Hindi', () async {
      final tomato = await service.getDiagnosis(cropId: 'tomato', languageCode: 'hi');
      final potato = await service.getDiagnosis(cropId: 'potato', languageCode: 'hi');
      final rice = await service.getDiagnosis(cropId: 'rice', languageCode: 'hi');

      expect(tomato.diseaseName, contains('टमाटर'));
      expect(potato.diseaseName, contains('आलू'));
      expect(rice.diseaseName, contains('धान'));
    });
  });

  group('TtsService Unit Tests', () {
    const mockDiagnosis = Diagnosis(
      id: 'tomato_early_blight',
      cropId: 'tomato',
      diseaseName: 'Tomato Early Blight',
      scientificName: 'Alternaria solani',
      severity: DiagnosisSeverity.moderate,
      confidenceLevel: 'Very likely (95%)',
      description: 'Test description',
      immediateActions: ['Remove lower leaves', 'Avoid overhead watering'],
      organicTreatments: ['Neem oil spray'],
      chemicalTreatments: ['Mancozeb 75% WP'],
      safetyNote: 'Wear gloves',
      preventionTips: ['Rotate crops'],
    );

    const mockHindiDiagnosis = Diagnosis(
      id: 'tomato_early_blight',
      cropId: 'tomato',
      diseaseName: 'टमाटर का अगेती झुलसा',
      scientificName: 'Alternaria solani',
      severity: DiagnosisSeverity.moderate,
      confidenceLevel: 'अत्यधिक संभावित (95%)',
      description: 'विवरण',
      immediateActions: ['पत्तियां तोड़ें', 'जड़ों में पानी दें'],
      organicTreatments: ['नीम का तेल'],
      chemicalTreatments: ['मैनकोजेब'],
      safetyNote: 'मास्क पहनें',
      preventionTips: ['फसल चक्र'],
    );

    test('buildDiagnosisSpeechText correctly formats speech text in English', () {
      final ttsService = TtsService();
      final speechText = ttsService.buildDiagnosisSpeechText(
        diagnosis: mockDiagnosis,
        languageCode: 'en',
        diseaseNameLabel: 'Disease name',
        severityLabel: 'Severity',
        severityText: 'Moderate',
        whatToDoLabel: 'What to do now',
        treatmentLabel: 'Treatment',
        organicLabel: 'Organic Treatment',
        chemicalLabel: 'Chemical Treatment',
      );

      expect(speechText, contains('Disease name: Tomato Early Blight.'));
      expect(speechText, contains('Severity: Moderate.'));
      expect(speechText, contains('What to do now: Remove lower leaves. Avoid overhead watering.'));
      expect(speechText, contains('Treatment.'));
      expect(speechText, contains('Organic Treatment: Neem oil spray.'));
      expect(speechText, contains('Chemical Treatment: Mancozeb 75% WP.'));
      // Prevention tips and scientific name are deliberately omitted from the audio readout
      expect(speechText, isNot(contains('Alternaria solani')));
      expect(speechText, isNot(contains('Rotate crops')));
    });

    test('buildDiagnosisSpeechText correctly formats speech text in Hindi', () {
      final ttsService = TtsService();
      final speechText = ttsService.buildDiagnosisSpeechText(
        diagnosis: mockHindiDiagnosis,
        languageCode: 'hi',
        diseaseNameLabel: 'रोग का नाम',
        severityLabel: 'गंभीरता',
        severityText: 'मध्यम',
        whatToDoLabel: 'अभी क्या करें',
        treatmentLabel: 'उपचार',
        organicLabel: 'जैविक उपचार',
        chemicalLabel: 'रासायनिक उपचार',
      );

      expect(speechText, contains('रोग का नाम: टमाटर का अगेती झुलसा।'));
      expect(speechText, contains('गंभीरता: मध्यम।'));
      expect(speechText, contains('अभी क्या करें: पत्तियां तोड़ें। जड़ों में पानी दें।'));
      expect(speechText, contains('उपचार।'));
      expect(speechText, contains('जैविक उपचार: नीम का तेल।'));
      expect(speechText, contains('रासायनिक उपचार: मैनकोजेब।'));
    });
  });

  group('ResultScreen Widget & TTS Tests', () {
    testWidgets('renders all required Result sections and responds to thumbs up',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResultScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check disease title & scientific name
      expect(find.text('Tomato Early Blight'), findsOneWidget);
      expect(find.text('Alternaria solani'), findsOneWidget);

      // Check severity & listen button
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);

      // Check sections
      expect(find.text('What it is'), findsOneWidget);
      expect(find.text('What to do now'), findsOneWidget);
      expect(find.text('Organic Treatment'), findsOneWidget);
      expect(find.text('Chemical Treatment'), findsOneWidget);
      expect(find.text('Safety Note'), findsOneWidget);
      expect(find.text('Prevention'), findsOneWidget);
      expect(find.text('Ask an Expert'), findsOneWidget);

      // Tap thumbs up and verify feedback message
      await tester.tap(find.text('👍 Yes'));
      await tester.pumpAndSettle();
      expect(find.text('Thank you for your feedback!'), findsOneWidget);
    });

    testWidgets('shows friendly dialog explaining how to install Hindi voice when missing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Mock platform channel: Hindi voice is missing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
        if (call.method == 'isLanguageInstalled' || call.method == 'isLanguageAvailable') {
          return false;
        }
        if (call.method == 'getLanguages') {
          return <String>['en-US', 'en-GB'];
        }
        return 1;
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('hi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResultScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Listen button in Hindi mode
      await tester.tap(find.byKey(const ValueKey('listen_button')));
      await tester.pumpAndSettle();

      // Verify Hindi voice missing dialog is displayed
      expect(find.text('हिंदी आवाज उपलब्ध नहीं है'), findsOneWidget);
      expect(find.textContaining('सेटिंग्स'), findsOneWidget);
      expect(find.textContaining('टेक्स्ट-टू-स्पीच'), findsOneWidget);

      // Tap dismiss "समझ गया"
      await tester.tap(find.text('समझ गया'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed
      expect(find.text('हिंदी आवाज उपलब्ध नहीं है'), findsNothing);
    });

    testWidgets('displays stop button and persistent audio control bar when TTS is speaking',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Mock platform channel: English is available
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
        if (call.method == 'isLanguageInstalled' || call.method == 'isLanguageAvailable') {
          return true;
        }
        if (call.method == 'getLanguages') {
          return <String>['en-US'];
        }
        return 1;
      });

      final testTts = TtsService();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResultScreen(ttsService: testTts),
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows Listen
      expect(find.text('Listen'), findsOneWidget);
      expect(find.byKey(const ValueKey('stop_audio_button')), findsNothing);

      // Tap Listen button to trigger speaking
      await tester.tap(find.byKey(const ValueKey('listen_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // When speaking:
      // 1. AppBar button changes to Stop
      expect(find.text('Stop'), findsAtLeastNWidgets(1));
      // 2. Bottom playing bar appears with status and stop button
      expect(find.text('Reading diagnosis aloud...'), findsOneWidget);
      expect(find.byKey(const ValueKey('stop_audio_button')), findsOneWidget);

      // Tap the stop button on the bottom bar
      await tester.tap(find.byKey(const ValueKey('stop_audio_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Expect speech stopped and UI returned to normal
      expect(testTts.isSpeaking, isFalse);
      expect(find.text('Listen'), findsOneWidget);
      expect(find.byKey(const ValueKey('stop_audio_button')), findsNothing);
    });
  });

  group('ScanHistoryService & HistoryScreen Tests', () {
    final historyService = ScanHistoryService();

    test('saves, retrieves, and deletes scans offline in SharedPreferences', () async {
      const mockDiag = Diagnosis(
        id: 'diag_1',
        cropId: 'tomato',
        diseaseName: 'Tomato Early Blight',
        scientificName: 'Alternaria solani',
        severity: DiagnosisSeverity.moderate,
        confidenceLevel: 'Very likely (95%)',
        description: 'Test description',
        immediateActions: ['Action 1'],
        organicTreatments: ['Organic 1'],
        chemicalTreatments: ['Chemical 1'],
        safetyNote: 'Safety note',
        preventionTips: ['Tip 1'],
      );

      final record = ScanRecord(
        id: 'scan_1',
        photoPath: '/mock/path.jpg',
        cropId: 'tomato',
        cropName: 'Tomato',
        diseaseName: 'Tomato Early Blight',
        severity: DiagnosisSeverity.moderate,
        scannedAt: DateTime.now(),
        diagnosis: mockDiag,
      );

      await historyService.saveScan(record);
      final list = await historyService.getHistory();
      expect(list.length, 1);
      expect(list.first.diseaseName, 'Tomato Early Blight');

      await historyService.deleteScan('scan_1');
      final emptyList = await historyService.getHistory();
      expect(emptyList, isEmpty);
    });

    testWidgets('HistoryScreen displays empty state when no history exists',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No past scans yet'), findsOneWidget);
      expect(find.text('Scan Your First Plant'), findsOneWidget);
    });

    testWidgets('HistoryScreen displays saved scans and navigates to Result on tap',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const mockDiag = Diagnosis(
        id: 'diag_1',
        cropId: 'potato',
        diseaseName: 'Potato Late Blight',
        scientificName: 'Phytophthora infestans',
        severity: DiagnosisSeverity.severe,
        confidenceLevel: 'Very likely (92%)',
        description: 'Late blight rot',
        immediateActions: ['Remove infected leaves'],
        organicTreatments: ['Copper spray'],
        chemicalTreatments: ['Ridomil MZ'],
        safetyNote: 'Wear mask',
        preventionTips: ['Certified seed'],
      );

      final record = ScanRecord(
        id: 'scan_potato',
        photoPath: '',
        cropId: 'potato',
        cropName: 'Potato',
        diseaseName: 'Potato Late Blight',
        severity: DiagnosisSeverity.severe,
        scannedAt: DateTime.now(),
        diagnosis: mockDiag,
      );

      await historyService.saveScan(record);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            ...AppRoutes.routes,
            '/': (context) => const HistoryScreen(),
          },
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Potato Late Blight'), findsOneWidget);
      expect(find.text('Severe'), findsOneWidget);

      // Tap saved item to open full result screen
      await tester.tap(find.text('Potato Late Blight'));
      await tester.pumpAndSettle();

      // Verify Result screen opened with diagnosis details
      expect(find.text('Phytophthora infestans'), findsOneWidget);
      expect(find.text('Late blight rot'), findsOneWidget);
    });
  });

  group('Diagnosis Status & Screen Mode Tests', () {
    test('Diagnosis model correctly serializes and deserializes all 4 status categories', () {
      // 1. Healthy plant
      final healthyMap = {
        'id': 'diag_healthy_1',
        'cropId': 'tomato',
        'status': 'healthy',
        'confidence': 'very_likely',
        'confidenceLevel': 'Very Likely',
        'description': 'Plant looks vibrant and healthy.',
        'immediateActions': <String>[],
        'organicTreatments': <String>[],
        'chemicalTreatments': <String>[],
        'safetyNote': '',
        'preventionTips': ['Ensure 6-8 hours of sunlight'],
      };
      final healthyDiag = Diagnosis.fromMap(healthyMap);
      expect(healthyDiag.status, DiagnosisStatus.healthy);
      expect(healthyDiag.isHealthy, isTrue);
      expect(healthyDiag.isDiseased, isFalse);
      expect(healthyDiag.confidence, DiagnosisConfidence.veryLikely);
      expect(healthyDiag.organicTreatments, isEmpty);
      expect(healthyDiag.toMap()['status'], 'healthy');

      // 2. Not a plant
      final notPlantMap = {
        'id': 'diag_not_plant_1',
        'cropId': 'potato',
        'status': 'not_a_plant',
        'confidence': 'possible',
        'confidenceLevel': 'Possible',
        'description': 'No plant detected in frame.',
        'immediateActions': <String>[],
        'organicTreatments': <String>[],
        'chemicalTreatments': <String>[],
        'safetyNote': '',
        'preventionTips': <String>[],
      };
      final notPlantDiag = Diagnosis.fromMap(notPlantMap);
      expect(notPlantDiag.status, DiagnosisStatus.notAPlant);
      expect(notPlantDiag.isNotAPlant, isTrue);
      expect(notPlantDiag.confidence, DiagnosisConfidence.possible);
      expect(notPlantDiag.toMap()['status'], 'not_a_plant');

      // 3. Poor photo
      final poorPhotoMap = {
        'id': 'diag_poor_photo_1',
        'cropId': 'rice',
        'status': 'poor_photo',
        'confidence': 'possible',
        'confidenceLevel': 'Possible',
        'description': 'Photo is blurry or out of focus.',
        'immediateActions': <String>[],
        'organicTreatments': <String>[],
        'chemicalTreatments': <String>[],
        'safetyNote': '',
        'preventionTips': <String>[],
      };
      final poorPhotoDiag = Diagnosis.fromMap(poorPhotoMap);
      expect(poorPhotoDiag.status, DiagnosisStatus.poorPhoto);
      expect(poorPhotoDiag.isPoorPhoto, isTrue);
      expect(poorPhotoDiag.toMap()['status'], 'poor_photo');

      // 4. Diseased plant
      final diseasedMap = {
        'id': 'diag_diseased_1',
        'cropId': 'tomato',
        'status': 'diseased',
        'diseaseName': 'Early Blight',
        'scientificName': 'Alternaria solani',
        'severity': 'moderate',
        'confidence': 'likely',
        'confidenceLevel': 'Likely',
        'description': 'Concentric brown rings on leaves.',
        'immediateActions': ['Remove lower leaves'],
        'organicTreatments': ['Neem oil'],
        'chemicalTreatments': ['Mancozeb'],
        'safetyNote': 'Wear gloves',
        'preventionTips': ['Crop rotation'],
      };
      final diseasedDiag = Diagnosis.fromMap(diseasedMap);
      expect(diseasedDiag.status, DiagnosisStatus.diseased);
      expect(diseasedDiag.isDiseased, isTrue);
      expect(diseasedDiag.confidence, DiagnosisConfidence.likely);
      expect(diseasedDiag.severity, DiagnosisSeverity.moderate);
      expect(diseasedDiag.organicTreatments, isNotEmpty);
      expect(diseasedDiag.toMap()['status'], 'diseased');
    });

    testWidgets('ResultScreen renders Healthy view without treatments or severity',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const healthyDiag = Diagnosis(
        id: 'h1',
        cropId: 'tomato',
        status: DiagnosisStatus.healthy,
        diseaseName: 'Healthy Plant',
        scientificName: 'Solanum lycopersicum',
        severity: DiagnosisSeverity.none,
        confidence: DiagnosisConfidence.veryLikely,
        confidenceLevel: 'Very Likely',
        description: 'Plant is thriving with strong green foliage.',
        immediateActions: [],
        organicTreatments: [],
        chemicalTreatments: [],
        safetyNote: '',
        preventionTips: ['Maintain regular watering at soil level.'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => const SizedBox(),
            '/result': (context) => const ResultScreen(),
          },
          initialRoute: '/',
        ),
      );

      // Push ResultScreen with healthy diagnosis argument
      final navKey = tester.element(find.byType(SizedBox)).findAncestorStateOfType<NavigatorState>()!;
      navKey.pushNamed('/result', arguments: {'diagnosis': healthyDiag});
      await tester.pumpAndSettle();

      // Check Healthy UI elements
      expect(find.text('Healthy Plant'), findsOneWidget);
      expect(find.text('No signs of disease or pest infestation detected'), findsOneWidget);
      expect(find.text('Routine Care Advice'), findsOneWidget);
      expect(find.text('Scan Another Leaf'), findsOneWidget);

      // Verify diseased sections are completely absent
      expect(find.text('Organic Treatment'), findsNothing);
      expect(find.text('Chemical Treatment'), findsNothing);
      expect(find.text('What to do now'), findsNothing);
      expect(find.text('Safety Note'), findsNothing);
    });

    testWidgets('ResultScreen renders Poor Photo view with retake instructions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const poorPhotoDiag = Diagnosis(
        id: 'pp1',
        cropId: 'tomato',
        status: DiagnosisStatus.poorPhoto,
        diseaseName: 'Photo Not Clear',
        scientificName: '',
        severity: DiagnosisSeverity.none,
        confidence: DiagnosisConfidence.possible,
        confidenceLevel: 'Possible',
        description: 'Image was blurry or too far away for reliable disease diagnosis.',
        immediateActions: [],
        organicTreatments: [],
        chemicalTreatments: [],
        safetyNote: '',
        preventionTips: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => const SizedBox(),
            '/result': (context) => const ResultScreen(),
          },
          initialRoute: '/',
        ),
      );

      final navKey = tester.element(find.byType(SizedBox)).findAncestorStateOfType<NavigatorState>()!;
      navKey.pushNamed('/result', arguments: {'diagnosis': poorPhotoDiag});
      await tester.pumpAndSettle();

      // Check Poor Photo UI elements
      expect(find.text('Photo Not Clear'), findsOneWidget);
      expect(find.text('Photography Guidelines'), findsOneWidget);
      expect(find.text('Retake Photo'), findsOneWidget);

      // Verify diseased sections are absent
      expect(find.text('Organic Treatment'), findsNothing);
      expect(find.text('Chemical Treatment'), findsNothing);
    });

    testWidgets('ResultScreen renders Not a Plant view with retake button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const notPlantDiag = Diagnosis(
        id: 'np1',
        cropId: 'tomato',
        status: DiagnosisStatus.notAPlant,
        diseaseName: 'Not a Plant',
        scientificName: '',
        severity: DiagnosisSeverity.none,
        confidence: DiagnosisConfidence.possible,
        confidenceLevel: 'Possible',
        description: 'The uploaded image does not appear to contain a crop leaf or plant.',
        immediateActions: [],
        organicTreatments: [],
        chemicalTreatments: [],
        safetyNote: '',
        preventionTips: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/': (context) => const SizedBox(),
            '/result': (context) => const ResultScreen(),
          },
          initialRoute: '/',
        ),
      );

      final navKey = tester.element(find.byType(SizedBox)).findAncestorStateOfType<NavigatorState>()!;
      navKey.pushNamed('/result', arguments: {'diagnosis': notPlantDiag});
      await tester.pumpAndSettle();

      // Check Not a Plant UI elements
      expect(find.text('Not a Plant'), findsOneWidget);
      expect(find.text('Retake Photo'), findsOneWidget);
      expect(find.text('Organic Treatment'), findsNothing);
    });
  });
}

