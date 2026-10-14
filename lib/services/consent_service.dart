import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'real_diagnosis_service.dart';

/// Manages user consent state locally in SharedPreferences and syncs to backend
class ConsentService {
  static const String currentPolicyVersion = '1.0';
  static const String _keyConsentVersion = 'plantii_consent_policy_version';
  static const String _keyConsentTimestamp = 'plantii_consent_timestamp';

  static ConsentService? _instance;
  static ConsentService get instance => _instance ??= ConsentService();

  /// Visible for testing to inject mock instance
  static void setMockInstance(ConsentService mock) {
    _instance = mock;
  }

  final RealDiagnosisService _diagnosisService;

  ConsentService({RealDiagnosisService? diagnosisService})
      : _diagnosisService = diagnosisService ?? RealDiagnosisService();

  /// Checks whether user has valid consent for the current policy version
  Future<bool> hasValidConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final String? version = prefs.getString(_keyConsentVersion);
    final String? timestamp = prefs.getString(_keyConsentTimestamp);

    if (version == null || timestamp == null) {
      return false;
    }

    // Policy version must match current version
    return version == currentPolicyVersion;
  }

  /// Returns the stored policy version
  Future<String?> getConsentedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConsentVersion);
  }

  /// Returns the consent timestamp
  Future<DateTime?> getConsentedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timestamp = prefs.getString(_keyConsentTimestamp);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Saves consent locally and syncs to the backend
  Future<void> saveConsent({String version = currentPolicyVersion, String? language}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setString(_keyConsentVersion, version);
    await prefs.setString(_keyConsentTimestamp, now.toIso8601String());

    // Record on backend asynchronously without blocking user if offline
    try {
      await _diagnosisService.recordConsent(
        consentVersion: version,
        language: language,
      );
    } catch (e) {
      debugPrint('ConsentService: Warning - failed to record consent on backend: $e');
    }
  }

  /// Withdraws user consent (blocks scanning until re-consented)
  Future<void> withdrawConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyConsentVersion);
    await prefs.remove(_keyConsentTimestamp);
    debugPrint('ConsentService: User consent withdrawn successfully.');
  }

  /// Clears consent completely
  Future<void> clearConsent() async {
    await withdrawConsent();
  }
}
