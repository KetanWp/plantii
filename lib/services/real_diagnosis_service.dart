import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/diagnosis.dart';
import 'auth_service.dart';
import 'scan_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Distinct error categories for diagnosis failures
enum DiagnosisErrorType {
  noInternet,
  networkError,
  timeout,
  rateLimited,
  serviceBusy,
  badImage,
  aiFailed,
  quotaExceeded,
  safetyBlock,
  aiAuthError,
  unauthorized,
  unknown,
}

/// Custom structured exception thrown when /diagnose fails
class DiagnosisException implements Exception {
  final DiagnosisErrorType type;
  final String messageEn;
  final String messageHi;
  final String? serverMessage;

  const DiagnosisException({
    required this.type,
    required this.messageEn,
    required this.messageHi,
    this.serverMessage,
  });

  /// Returns localized message based on the active language code ('hi' or 'en')
  String getLocalizedMessage(String languageCode) {
    if (serverMessage != null && serverMessage!.isNotEmpty) {
      return serverMessage!;
    }
    return languageCode == 'hi' ? messageHi : messageEn;
  }

  @override
  String toString() => 'DiagnosisException($type): $messageEn';
}

/// Production diagnosis service that calls the Firebase Cloud Functions 2nd gen
/// /diagnose and /feedback REST endpoints.
class RealDiagnosisService {
  /// Default production Cloud Functions endpoint URL
  static const String defaultProdUrl =
      'https://asia-south1-plantii-4fb2e.cloudfunctions.net/api';

  /// Default Android Emulator host URL
  static const String defaultAndroidEmulatorUrl =
      'http://10.0.2.2:5001/plantii-4fb2e/asia-south1/api';

  /// Default Localhost URL (iOS simulator, Web, macOS, Windows)
  static const String defaultLocalhostUrl =
      'http://127.0.0.1:5001/plantii-4fb2e/asia-south1/api';

  /// Allows global override of the base API URL (e.g. for testing or emulator mode)
  static String? customBaseUrl;

  final String _baseUrl;
  final http.Client _httpClient;
  final AuthService _authService;

  RealDiagnosisService({
    String? baseUrl,
    http.Client? httpClient,
    AuthService? authService,
  })  : _baseUrl = baseUrl ??
            customBaseUrl ??
            const String.fromEnvironment('API_BASE_URL', defaultValue: defaultProdUrl),
        _httpClient = httpClient ?? http.Client(),
        _authService = authService ?? AuthService.instance;

  String get baseUrl => _baseUrl;

  /// Calls the /diagnose Cloud Functions endpoint with the Firebase ID token,
  /// compressed leaf image (base64 encoded), crop type, and preferred language.
  ///
  /// Throws [DiagnosisException] for handled error types:
  /// - [DiagnosisErrorType.noInternet]
  /// - [DiagnosisErrorType.timeout]
  /// - [DiagnosisErrorType.rateLimited]
  /// - [DiagnosisErrorType.badImage]
  /// - [DiagnosisErrorType.aiFailed]
  Future<Diagnosis> diagnose({
    required File imageFile,
    required String language,
    String? cropHint,
    bool forceRefresh = false,
    @Deprecated('Crops are auto-identified by AI; use cropHint if farmer confirms crop')
    String? crop,
  }) async {
    final bool isHindi = language.toLowerCase().trim() == 'hi';

    // 1. Verify local image exists and is readable
    if (!imageFile.existsSync()) {
      throw const DiagnosisException(
        type: DiagnosisErrorType.badImage,
        messageEn: 'Leaf image file was not found. Please retake the photo.',
        messageHi: 'पत्ती की फोटो नहीं मिली। कृपया फोटो दोबारा लें।',
      );
    }

    final int fileLength = imageFile.lengthSync();
    // 2 MB limit enforced by backend middleware
    if (fileLength > 2 * 1024 * 1024 || fileLength == 0) {
      throw const DiagnosisException(
        type: DiagnosisErrorType.badImage,
        messageEn: 'Image size is invalid or exceeds 2MB limit. Please retake photo.',
        messageHi: 'छवि का आकार 2MB से अधिक है या अमान्य है। कृपया फोटो दोबारा लें।',
      );
    }

    // 2. Obtain Firebase Auth ID token
    String? idToken;
    try {
      idToken = await _authService.getIdToken();
    } catch (_) {
      throw const DiagnosisException(
        type: DiagnosisErrorType.noInternet,
        messageEn: 'No internet connection. Please check your network and try again.',
        messageHi: 'इंटरनेट कनेक्शन नहीं है। कृपया अपना नेटवर्क जांचें और पुनः प्रयास करें।',
      );
    }

    if (idToken == null || idToken.isEmpty) {
      throw const DiagnosisException(
        type: DiagnosisErrorType.noInternet,
        messageEn: 'Unable to connect to authentication service. Please check your internet connection.',
        messageHi: 'प्रमाणीकरण सेवा से कनेक्ट करने में असमर्थ। कृपया इंटरनेट कनेक्शन जांचें।',
      );
    }

    // 3. Prepare payload with base64 encoded image (Do not send crop)
    final Uint8List imageBytes = imageFile.readAsBytesSync();
    final String base64Image = base64Encode(imageBytes);

    final Uri diagnoseUri = Uri.parse('$_baseUrl/diagnose');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
    final Map<String, dynamic> payload = {
      'language': isHindi ? 'hi' : 'en',
      'image': base64Image,
    };
    final effectiveHint = (cropHint != null && cropHint.trim().isNotEmpty)
        ? cropHint.trim()
        : '';
    if (effectiveHint.isNotEmpty) {
      payload['cropHint'] = effectiveHint;
    }
    if (forceRefresh) {
      payload['forceRefresh'] = true;
    }
    final String requestBody = jsonEncode(payload);

    // 4. Send HTTP request with 60s timeout
    http.Response response;
    try {
      response = await _httpClient
          .post(diagnoseUri, headers: headers, body: requestBody)
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw DiagnosisException(
        type: DiagnosisErrorType.timeout,
        messageEn: 'The diagnosis request timed out after 60 seconds. Please try again.',
        messageHi: 'अनुरोध का समय समाप्त हो गया (60 सेकंड)। कृपया पुनः प्रयास करें।',
      );
    } on SocketException {
      throw DiagnosisException(
        type: DiagnosisErrorType.noInternet,
        messageEn: 'No internet connection. Please check your network and try again.',
        messageHi: 'इंटरनेट कनेक्शन नहीं है। कृपया अपना नेटवर्क जांचें और पुनः प्रयास करें।',
      );
    } on http.ClientException {
      throw DiagnosisException(
        type: DiagnosisErrorType.noInternet,
        messageEn: 'Network connection error. Please verify your connection and try again.',
        messageHi: 'नेटवर्क कनेक्शन त्रुटि। कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।',
      );
    } catch (e) {
      debugPrint('RealDiagnosisService: Network error during diagnose call: $e');
      throw DiagnosisException(
        type: DiagnosisErrorType.noInternet,
        messageEn: 'Network communication failed. Please check your connection.',
        messageHi: 'नेटवर्क संचार विफल रहा। कृपया अपना कनेक्शन जांचें।',
      );
    }

    // 5. Parse response body and status code
    Map<String, dynamic> responseJson = {};
    try {
      if (response.bodyBytes.isNotEmpty) {
        final decodedBody = utf8.decode(response.bodyBytes);
        responseJson = jsonDecode(decodedBody) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('RealDiagnosisService: Failed to parse response JSON: $e');
    }

    final String? serverErrorCode = responseJson['error']?['code'] as String?;
    final String? serverErrorMessage = responseJson['error']?['message'] as String?;

    if (response.statusCode == 200) {
      return Diagnosis.fromMap(responseJson);
    }

    // Handle specific HTTP error status codes and server codes
    if (response.statusCode == 429 || serverErrorCode == 'rate_limited') {
      throw DiagnosisException(
        type: DiagnosisErrorType.rateLimited,
        messageEn: 'Daily scan limit reached. Please try again tomorrow.',
        messageHi: 'दैनिक स्कैन सीमा समाप्त हो गई है। कृपया कल पुनः प्रयास करें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (serverErrorCode == 'quota_exceeded') {
      throw DiagnosisException(
        type: DiagnosisErrorType.quotaExceeded,
        messageEn: 'AI diagnosis service capacity reached. Please try again shortly.',
        messageHi: 'एआई सेवा की दैनिक सीमा पूरी हो गई है। कृपया कुछ समय बाद पुनः प्रयास करें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (response.statusCode == 503 || serverErrorCode == 'service_busy') {
      throw DiagnosisException(
        type: DiagnosisErrorType.serviceBusy,
        messageEn: 'The service is temporarily busy due to high demand. Please try again in a moment.',
        messageHi: 'सर्वर पर वर्तमान में अत्यधिक ट्रैफ़िक है। कृपया कुछ समय बाद पुनः प्रयास करें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (response.statusCode == 504 || serverErrorCode == 'timeout') {
      throw DiagnosisException(
        type: DiagnosisErrorType.timeout,
        messageEn: 'The diagnosis request timed out after 45 seconds. Please try again.',
        messageHi: 'अनुरोध का समय समाप्त हो गया। कृपया पुनः प्रयास करें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (serverErrorCode == 'safety_block') {
      throw DiagnosisException(
        type: DiagnosisErrorType.safetyBlock,
        messageEn: 'The photo could not be processed due to safety guidelines. Please take a clear photo of the plant leaf.',
        messageHi: 'सुरक्षा नियमों के कारण फोटो संसाधित नहीं हो सकी। कृपया पत्ती की स्पष्ट फोटो लें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (response.statusCode == 400 || serverErrorCode == 'bad_image') {
      throw DiagnosisException(
        type: DiagnosisErrorType.badImage,
        messageEn: 'The leaf photo was not clear enough or unsupported. Please retake a clear photo.',
        messageHi: 'पत्ती की फोटो स्पष्ट नहीं है या अमान्य है। कृपया स्पष्ट फोटो दोबारा लें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (serverErrorCode == 'ai_auth_error') {
      throw DiagnosisException(
        type: DiagnosisErrorType.aiAuthError,
        messageEn: 'Internal AI authentication failed. Please contact support.',
        messageHi: 'एआई सेवा प्रमाणीकरण विफल रहा। कृपया सहायता से संपर्क करें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (serverErrorCode == 'network_error') {
      throw DiagnosisException(
        type: DiagnosisErrorType.networkError,
        messageEn: 'Network communication with AI service failed. Please check connection.',
        messageHi: 'एआई सेवा के साथ नेटवर्क संचार विफल रहा। कृपया अपना कनेक्शन जांचें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (response.statusCode == 502 || serverErrorCode == 'ai_failed') {
      throw DiagnosisException(
        type: DiagnosisErrorType.aiFailed,
        messageEn: 'Failed to analyze crop leaf. Please retry with a clearer photo.',
        messageHi: 'पौधे की जांच करने में समस्या आई। कृपया स्पष्ट फोटो के साथ पुनः प्रयास करें।',
        serverMessage: serverErrorMessage,
      );
    }

    if (response.statusCode == 401 || serverErrorCode == 'unauthorized') {
      throw DiagnosisException(
        type: DiagnosisErrorType.unauthorized,
        messageEn: 'Authentication failed. Please restart the app.',
        messageHi: 'प्रमाणीकरण विफल रहा। कृपया ऐप पुनः प्रारंभ करें।',
        serverMessage: serverErrorMessage,
      );
    }

    // Default fallback error
    throw DiagnosisException(
      type: DiagnosisErrorType.unknown,
      messageEn: serverErrorMessage ?? 'Diagnosis failed. Please try again.',
      messageHi: serverErrorMessage ?? 'जांच पूरी नहीं हो सकी। कृपया पुनः प्रयास करें।',
      serverMessage: serverErrorMessage,
    );
  }

  /// Sends farmer feedback (thumbs up / thumbs down) to the /feedback endpoint
  Future<bool> sendFeedback({
    required String scanId,
    required bool helpful,
    String? comment,
    String? language,
  }) async {
    // If empty or test scan id, acknowledge gracefully
    if (scanId.isEmpty) {
      debugPrint('RealDiagnosisService: Skipping feedback for empty scan ID');
      return true;
    }

    try {
      final String? idToken = await _authService.getIdToken();
      if (idToken == null) {
        debugPrint('RealDiagnosisService: Cannot submit feedback without auth token');
        return false;
      }

      final Uri feedbackUri = Uri.parse('$_baseUrl/feedback');
      final response = await _httpClient
          .post(
            feedbackUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'scanId': scanId,
              'helpful': helpful,
              'comment': comment ?? '',
              'language': language ?? 'en',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('RealDiagnosisService: Feedback submitted successfully for scan: $scanId');
        return true;
      } else {
        debugPrint('RealDiagnosisService: Feedback rejected with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('RealDiagnosisService: Error submitting feedback: $e');
      return false;
    }
  }

  /// Records user privacy consent on the backend
  Future<bool> recordConsent({
    String consentVersion = '1.0',
    String? language,
  }) async {
    try {
      final String? idToken = await _authService.getIdToken();
      if (idToken == null) {
        debugPrint('RealDiagnosisService: Cannot record consent without auth token');
        return false;
      }

      final Uri consentUri = Uri.parse('$_baseUrl/consent');
      final response = await _httpClient
          .post(
            consentUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'consentVersion': consentVersion,
              'language': language ?? 'en',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('RealDiagnosisService: Consent recorded on backend successfully');
        return true;
      } else {
        debugPrint('RealDiagnosisService: Consent failed with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('RealDiagnosisService: Error recording consent: $e');
      return false;
    }
  }

  /// Permanently deletes user account, scans, feedback, and Firestore document on backend,
  /// then wipes local photos, history, consent, and signs out.
  Future<bool> deleteAccount({String? language}) async {
    try {
      final String? idToken = await _authService.getIdToken();
      if (idToken == null) {
        debugPrint('RealDiagnosisService: Cannot delete account without auth token');
        return false;
      }

      final Uri accountUri = Uri.parse('$_baseUrl/account');
      final response = await _httpClient
          .delete(
            accountUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'language': language ?? 'en',
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        debugPrint('RealDiagnosisService: Backend account and data deleted successfully');

        // 1. Delete local photo files from disk
        final historyService = ScanHistoryService();
        final scans = await historyService.getHistory();
        for (final scan in scans) {
          if (scan.photoPath.isNotEmpty) {
            try {
              final file = File(scan.photoPath);
              if (file.existsSync()) {
                file.deleteSync();
              }
            } catch (err) {
              debugPrint('RealDiagnosisService: Failed to delete local photo ${scan.photoPath}: $err');
            }
          }
        }

        // 2. Clear local history records
        await historyService.clearHistory();

        // 3. Clear consent stored in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('plantii_consent_policy_version');
        await prefs.remove('plantii_consent_timestamp');

        // 4. Sign out
        await _authService.signOut();

        return true;
      } else {
        debugPrint('RealDiagnosisService: Account deletion rejected (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('RealDiagnosisService: Error during deleteAccount: $e');
      return false;
    }
  }
}
