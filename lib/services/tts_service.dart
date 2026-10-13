import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/diagnosis.dart';

/// Result status when attempting to speak diagnosis text
enum TtsPlaybackResult {
  started,
  hindiVoiceNotInstalled,
  error,
}

/// Service that manages Text-To-Speech playback for rural farmers
/// Handles language checks, slow/clear speech rate, audio stop, and voice availability.
class TtsService {
  final FlutterTts _flutterTts;
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);

  VoidCallback? onStart;
  VoidCallback? onDone;
  void Function(dynamic error)? onError;

  TtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts() {
    _initHandlers();
  }

  bool get isSpeaking => isSpeakingNotifier.value;

  void _initHandlers() {
    try {
      _flutterTts.setStartHandler(() {
        isSpeakingNotifier.value = true;
        onStart?.call();
      });

      _flutterTts.setCompletionHandler(() {
        isSpeakingNotifier.value = false;
        onDone?.call();
      });

      _flutterTts.setCancelHandler(() {
        isSpeakingNotifier.value = false;
        onDone?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        isSpeakingNotifier.value = false;
        onError?.call(msg);
      });
    } catch (e) {
      debugPrint('TtsService handler setup exception: $e');
    }
  }

  /// Checks if Hindi speech voice data is installed and available on the device
  Future<bool> isHindiVoiceInstalled() async {
    try {
      // 1. Check isLanguageInstalled (Android specific query for voice pack)
      for (final tag in const ['hi-IN', 'hi']) {
        final installed = await _flutterTts.isLanguageInstalled(tag);
        if (installed == true) {
          return true;
        }
      }

      // 2. Check isLanguageAvailable
      for (final tag in const ['hi-IN', 'hi']) {
        final available = await _flutterTts.isLanguageAvailable(tag);
        if (available == true) {
          return true;
        }
      }

      // 3. Inspect available languages list
      final languages = await _flutterTts.getLanguages;
      if (languages is List) {
        final hasHindi = languages.any((lang) =>
            lang.toString().toLowerCase().startsWith('hi') ||
            lang.toString().toLowerCase().contains('hin'));
        if (hasHindi) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking Hindi voice availability: $e');
      return false;
    }
  }

  /// Formats the spoken text with disease name, severity, immediate actions, and treatment
  String buildDiagnosisSpeechText({
    required Diagnosis diagnosis,
    required String languageCode,
    required String diseaseNameLabel,
    required String severityLabel,
    required String severityText,
    required String whatToDoLabel,
    required String treatmentLabel,
    required String organicLabel,
    required String chemicalLabel,
  }) {
    final bool isHindi = languageCode == 'hi';
    final String punct = isHindi ? '।' : '.';
    final String colon = ': ';
    final buffer = StringBuffer();

    // 1. Disease Name
    buffer.write('$diseaseNameLabel$colon${diagnosis.diseaseName}$punct ');

    // 2. Severity
    buffer.write('$severityLabel$colon$severityText$punct ');

    // 3. What to do now (Immediate actions)
    if (diagnosis.immediateActions.isNotEmpty) {
      buffer.write('$whatToDoLabel$colon');
      buffer.write(diagnosis.immediateActions.join('$punct '));
      buffer.write('$punct ');
    }

    // 4. Treatment (Organic & Chemical)
    buffer.write('$treatmentLabel$punct ');
    if (diagnosis.organicTreatments.isNotEmpty) {
      buffer.write('$organicLabel$colon');
      buffer.write(diagnosis.organicTreatments.join('$punct '));
      buffer.write('$punct ');
    }
    if (diagnosis.chemicalTreatments.isNotEmpty) {
      buffer.write('$chemicalLabel$colon');
      buffer.write(diagnosis.chemicalTreatments.join('$punct '));
      buffer.write(punct);
    }

    return buffer.toString().trim();
  }

  /// Begins reading aloud the diagnosis in Hindi or English
  /// Returns [TtsPlaybackResult.hindiVoiceNotInstalled] if Hindi voice is missing
  Future<TtsPlaybackResult> speakDiagnosis({
    required Diagnosis diagnosis,
    required String languageCode,
    required String diseaseNameLabel,
    required String severityLabel,
    required String severityText,
    required String whatToDoLabel,
    required String treatmentLabel,
    required String organicLabel,
    required String chemicalLabel,
  }) async {
    try {
      // Always stop previous speech before re-starting
      await stop();

      // Configure speech parameters tailored for rural outdoor comprehension
      await _flutterTts.setSpeechRate(0.45); // Slower, clearer rate
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      if (languageCode == 'hi') {
        final bool hindiInstalled = await isHindiVoiceInstalled();
        if (!hindiInstalled) {
          return TtsPlaybackResult.hindiVoiceNotInstalled;
        }

        // Try setting Hindi locale
        dynamic setResult = await _flutterTts.setLanguage('hi-IN');
        if (setResult == 0) {
          setResult = await _flutterTts.setLanguage('hi');
        }
        if (setResult == 0) {
          return TtsPlaybackResult.hindiVoiceNotInstalled;
        }
      } else {
        // English (default to Indian English if available, or en-US)
        dynamic setResult = await _flutterTts.setLanguage('en-IN');
        if (setResult == 0) {
          await _flutterTts.setLanguage('en-US');
        }
      }

      final speechText = buildDiagnosisSpeechText(
        diagnosis: diagnosis,
        languageCode: languageCode,
        diseaseNameLabel: diseaseNameLabel,
        severityLabel: severityLabel,
        severityText: severityText,
        whatToDoLabel: whatToDoLabel,
        treatmentLabel: treatmentLabel,
        organicLabel: organicLabel,
        chemicalLabel: chemicalLabel,
      );

      isSpeakingNotifier.value = true;
      await _flutterTts.speak(speechText);
      return TtsPlaybackResult.started;
    } catch (e) {
      debugPrint('Error starting TTS playback: $e');
      isSpeakingNotifier.value = false;
      return TtsPlaybackResult.error;
    }
  }

  /// Immediately stops audio speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    } finally {
      isSpeakingNotifier.value = false;
    }
  }

  /// Cleans up resources and stops audio
  void dispose() {
    stop();
    isSpeakingNotifier.dispose();
  }
}
