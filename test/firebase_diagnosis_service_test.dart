import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plantii/l10n/app_localizations.dart';
import 'package:plantii/models/diagnosis.dart';
import 'package:plantii/routes.dart';
import 'package:plantii/screens/loading_screen.dart';
import 'package:plantii/screens/result_screen.dart';
import 'package:plantii/services/auth_service.dart';
import 'package:plantii/services/real_diagnosis_service.dart';
import 'package:plantii/services/scan_history_service.dart';
import 'package:plantii/theme/app_theme.dart';

/// Test mock auth service providing an in-memory ID token
class MockTestAuthService extends AuthService {
  final String? testToken;

  MockTestAuthService({this.testToken = 'valid_test_token_12345'});

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return testToken;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleImageFile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('firebase_diag_test_');
    sampleImageFile = File('${tempDir.path}/test_leaf.jpg');
    // Encode valid JPEG so FileImage can decode without hanging test pipeline
    final testImage = img.Image(width: 200, height: 200);
    img.fill(testImage, color: img.ColorRgb8(34, 139, 34));
    final encodedJpg = img.encodeJpg(testImage);
    await sampleImageFile.writeAsBytes(encodedJpg);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RealDiagnosisService API & Error Handling Tests', () {
    test('successfully parses 200 response into Diagnosis model', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.url.path, endsWith('/diagnose'));
        expect(request.headers['Authorization'], 'Bearer mock_token_abc');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('crop'), isFalse);
        expect(body['language'], 'en');
        expect(body['image'], isNotEmpty);

        return http.Response(
          jsonEncode({
            'id': 'scan_123',
            'cropId': 'tomato',
            'diseaseName': 'Tomato Early Blight',
            'scientificName': 'Alternaria solani',
            'severity': 'moderate',
            'confidenceLevel': 'High (92%)',
            'description': 'Target-board leaf spots observed.',
            'immediateActions': ['Isolate infected plant'],
            'organicTreatments': ['Spray neem extract'],
            'chemicalTreatments': ['Apply Mancozeb 75% WP'],
            'safetyNote': 'Wear gloves when handling chemical spray.',
            'preventionTips': ['Crop rotation every 2 years'],
            'language': 'en',
            'spokenSummary': 'Tomato early blight detected. Remove infected leaves immediately.',
            'fromCache': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(testToken: 'mock_token_abc'),
      );

      final diagnosis = await service.diagnose(
        imageFile: sampleImageFile,
        language: 'en',
      );

      expect(diagnosis.id, 'scan_123');
      expect(diagnosis.cropId, 'tomato');
      expect(diagnosis.diseaseName, 'Tomato Early Blight');
      expect(diagnosis.scientificName, 'Alternaria solani');
      expect(diagnosis.severity, DiagnosisSeverity.moderate);
      expect(diagnosis.immediateActions, ['Isolate infected plant']);
      expect(diagnosis.organicTreatments, ['Spray neem extract']);
      expect(diagnosis.chemicalTreatments, ['Apply Mancozeb 75% WP']);
      expect(diagnosis.spokenSummary, contains('early blight'));
    });

    test('passes optional cropHint and forceRefresh parameters in request body', () async {
      bool passedHint = false;
      bool passedRefresh = false;

      final mockHttpClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['cropHint'] == 'Cotton') passedHint = true;
        if (body['forceRefresh'] == true) passedRefresh = true;

        return http.Response(
          jsonEncode({
            'id': 'scan_hint_1',
            'status': 'diseased',
            'diseaseName': 'Cotton Leaf Curl',
            'confidenceLevel': 'High (90%)',
            'description': 'Curled leaves',
            'immediateActions': [],
            'organicTreatments': [],
            'chemicalTreatments': [],
            'safetyNote': '',
            'preventionTips': [],
            'language': 'en',
            'fromCache': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(),
      );

      final diag = await service.diagnose(
        imageFile: sampleImageFile,
        language: 'en',
        cropHint: 'Cotton',
        forceRefresh: true,
      );

      expect(passedHint, isTrue);
      expect(passedRefresh, isTrue);
      expect(diag.diseaseName, 'Cotton Leaf Curl');
    });

    test('throws DiagnosisErrorType.timeout on 504 status', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'timeout',
              'message': 'The diagnosis request timed out after 60 seconds.',
            }
          }),
          504,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(),
      );

      expect(
        () => service.diagnose(
          imageFile: sampleImageFile,
          language: 'en',
        ),
        throwsA(
          isA<DiagnosisException>().having(
            (e) => e.type,
            'type',
            DiagnosisErrorType.timeout,
          ),
        ),
      );
    });

    test('throws DiagnosisErrorType.rateLimited on 429 status', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'rate_limited',
              'message': 'Daily scan limit reached.',
            }
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(),
      );

      expect(
        () => service.diagnose(
          imageFile: sampleImageFile,
          language: 'hi',
        ),
        throwsA(
          isA<DiagnosisException>().having(
            (e) => e.type,
            'type',
            DiagnosisErrorType.rateLimited,
          ),
        ),
      );
    });

    test('throws DiagnosisErrorType.badImage on 400 bad_image code', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'bad_image',
              'message': 'Only JPEG and PNG formats are supported.',
            }
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(),
      );

      expect(
        () => service.diagnose(
          imageFile: sampleImageFile,
          language: 'en',
        ),
        throwsA(
          isA<DiagnosisException>().having(
            (e) => e.type,
            'type',
            DiagnosisErrorType.badImage,
          ),
        ),
      );
    });

    test('throws DiagnosisErrorType.aiFailed on 502 status', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'ai_failed',
              'message': 'AI diagnosis analysis failed after retry.',
            }
          }),
          502,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(),
      );

      expect(
        () => service.diagnose(
          imageFile: sampleImageFile,
          language: 'en',
        ),
        throwsA(
          isA<DiagnosisException>().having(
            (e) => e.type,
            'type',
            DiagnosisErrorType.aiFailed,
          ),
        ),
      );
    });

    test('throws DiagnosisErrorType.noInternet when Auth ID token is unavailable', () async {
      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: MockClient((r) async => http.Response('{}', 200)),
        authService: MockTestAuthService(testToken: null),
      );

      expect(
        () => service.diagnose(
          imageFile: sampleImageFile,
          language: 'hi',
        ),
        throwsA(
          isA<DiagnosisException>().having(
            (e) => e.type,
            'type',
            DiagnosisErrorType.noInternet,
          ),
        ),
      );
    });

    test('sends thumbs up feedback to /feedback endpoint successfully', () async {
      bool feedbackCalled = false;
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.endsWith('/feedback')) {
          feedbackCalled = true;
          expect(request.headers['Authorization'], 'Bearer valid_token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['scanId'], 'scan_999');
          expect(body['helpful'], true);
          expect(body['language'], 'hi');
          return http.Response(
            jsonEncode({'success': true, 'feedbackId': 'fb_1'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(testToken: 'valid_token'),
      );

      final result = await service.sendFeedback(
        scanId: 'scan_999',
        helpful: true,
        language: 'hi',
      );

      expect(result, isTrue);
      expect(feedbackCalled, isTrue);
    });
  });

  group('LoadingScreen Error State and Resolution Widget Tests', () {
    testWidgets('displays retry button and localized message on timeout error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'timeout', 'message': 'Timeout occurred'}
          }),
          504,
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            AppRoutes.loading: (context) => LoadingScreen(diagnosisService: service),
          },
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.loading,
                  arguments: {
                    'cropId': 'tomato',
                    'cropName': 'Tomato',
                    'imagePath': sampleImageFile.path,
                  },
                );
              },
              child: const Text('Start Scan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger navigation to LoadingScreen
      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify timeout error UI is displayed with retry button
      expect(find.byKey(const ValueKey('retry_diagnosis_button')), findsOneWidget);
      expect(find.text('The diagnosis request timed out after 60 seconds. Please try again.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byKey(const ValueKey('retake_photo_button')), findsOneWidget);
    });

    testWidgets('displays rate limit error state in Hindi',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockHttpClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'error': {
              'code': 'rate_limited',
              'message': 'दैनिक स्कैन सीमा समाप्त हो गई है (अधिकतम 10 स्कैन प्रतिदिन)। कृपया कल पुनः प्रयास करें।'
            }
          })),
          429,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('hi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            AppRoutes.loading: (context) => LoadingScreen(diagnosisService: service),
          },
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.loading,
                  arguments: {
                    'cropId': 'potato',
                    'cropName': 'आलू',
                    'imagePath': sampleImageFile.path,
                  },
                );
              },
              child: const Text('Start Scan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Hindi rate limit message and Home button
      expect(find.text('दैनिक स्कैन सीमा समाप्त हो गई है (अधिकतम 10 स्कैन प्रतिदिन)। कृपया कल पुनः प्रयास करें।'), findsAtLeastNWidgets(1));
      expect(find.byKey(const ValueKey('home_return_button')), findsOneWidget);
    });

    testWidgets('saves to offline history and navigates to ResultScreen on success',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'scan_test_success_1',
            'cropId': 'tomato',
            'diseaseName': 'Tomato Early Blight',
            'scientificName': 'Alternaria solani',
            'severity': 'moderate',
            'confidenceLevel': 'High',
            'description': 'Leaf spots detected.',
            'immediateActions': ['Action 1'],
            'organicTreatments': ['Organic 1'],
            'chemicalTreatments': ['Chemical 1'],
            'safetyNote': 'Safety notice',
            'preventionTips': ['Prevention 1'],
            'language': 'en',
          }),
          200,
        );
      });

      final service = RealDiagnosisService(
        baseUrl: 'https://example.com/api',
        httpClient: mockHttpClient,
        authService: MockTestAuthService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            AppRoutes.loading: (context) => LoadingScreen(diagnosisService: service),
            AppRoutes.result: (context) => const ResultScreen(),
          },
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.loading,
                  arguments: {
                    'cropId': 'tomato',
                    'cropName': 'Tomato',
                    'imagePath': sampleImageFile.path,
                  },
                );
              },
              child: const Text('Start Scan'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify navigated to ResultScreen with diagnosis details
      expect(find.text('Tomato Early Blight'), findsOneWidget);
      expect(find.text('Alternaria solani'), findsOneWidget);

      // Verify saved in offline ScanHistoryService
      final history = await ScanHistoryService().getHistory();
      expect(history.length, 1);
      expect(history.first.id, 'scan_test_success_1');
      expect(history.first.diseaseName, 'Tomato Early Blight');
    });
  });
}
