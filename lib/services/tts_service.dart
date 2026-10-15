import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/diagnosis.dart';

/// Result status when attempting to speak diagnosis text
enum TtsPlaybackResult {
  started,
  hindiVoiceNotInstalled,
  error,
}

/// Playback state for TTS audio controls
enum TtsPlaybackState {
  stopped,
  playing,
  paused,
}

/// Speech speed options stored in settings
enum TtsSpeed {
  slow,
  normal;

  double get rate => this == TtsSpeed.slow ? 0.42 : 0.47;

  String get labelEn => this == TtsSpeed.slow ? 'Slow' : 'Normal';
  String get labelHi => this == TtsSpeed.slow ? 'धीमी' : 'सामान्य';

  static TtsSpeed fromString(String? val) {
    if (val?.toLowerCase().trim() == 'slow') return TtsSpeed.slow;
    return TtsSpeed.normal;
  }
}

/// Centralized Text-To-Speech Service
/// Encapsulates flutter_tts, slow rate tuning (0.42-0.48), speed preferences,
/// sentence-by-sentence queue with pauses, voice quality selection, and playback controls.
class TtsService {
  static const String prefSpeedKey = 'tts_speech_speed';
  static const String prefAutoPlayKey = 'tts_auto_play';

  final FlutterTts _flutterTts;
  final ValueNotifier<TtsPlaybackState> stateNotifier =
      ValueNotifier<TtsPlaybackState>(TtsPlaybackState.stopped);
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);

  TtsSpeed _speed = TtsSpeed.normal;
  List<String> _currentQueue = [];
  int _currentIndex = 0;
  bool _isDisposed = false;
  Completer<void>? _sentenceCompleter;

  VoidCallback? onStart;
  VoidCallback? onDone;
  void Function(dynamic error)? onError;

  TtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts() {
    _initHandlers();
    _loadPreferences();
  }

  bool get isSpeaking => stateNotifier.value == TtsPlaybackState.playing;
  bool get isPaused => stateNotifier.value == TtsPlaybackState.paused;
  TtsSpeed get speed => _speed;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSpeed = prefs.getString(prefSpeedKey);
      _speed = TtsSpeed.fromString(savedSpeed);
    } catch (e) {
      debugPrint('TtsService: Error loading preferences: $e');
    }
  }

  Future<void> setSpeed(TtsSpeed newSpeed) async {
    _speed = newSpeed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefSpeedKey, newSpeed == TtsSpeed.slow ? 'slow' : 'normal');
      await _flutterTts.setSpeechRate(newSpeed.rate);
    } catch (e) {
      debugPrint('TtsService: Error saving speed preference: $e');
    }
  }

  static Future<bool> isAutoPlayEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefAutoPlayKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setAutoPlayEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefAutoPlayKey, enabled);
    } catch (_) {}
  }

  void _initHandlers() {
    try {
      _flutterTts.setStartHandler(() {
        isSpeakingNotifier.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        if (_sentenceCompleter != null && !_sentenceCompleter!.isCompleted) {
          _sentenceCompleter!.complete();
        }
      });

      _flutterTts.setCancelHandler(() {
        if (_sentenceCompleter != null && !_sentenceCompleter!.isCompleted) {
          _sentenceCompleter!.complete();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TtsService: ErrorHandler: $msg');
        if (_sentenceCompleter != null && !_sentenceCompleter!.isCompleted) {
          _sentenceCompleter!.complete();
        }
        onError?.call(msg);
      });
    } catch (e) {
      debugPrint('TtsService: Handler setup exception: $e');
    }
  }

  /// Lists installed voices and selects the highest-quality (enhanced/network) Hindi voice
  Future<bool> _configureVoiceForLanguage(String languageCode) async {
    final bool isHindi = languageCode == 'hi';

    try {
      await _flutterTts.setSpeechRate(_speed.rate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      if (isHindi) {
        final bool hindiInstalled = await isHindiVoiceInstalled();
        if (!hindiInstalled) return false;

        dynamic setResult = await _flutterTts.setLanguage('hi-IN');
        if (setResult == 0) {
          setResult = await _flutterTts.setLanguage('hi');
        }
        if (setResult == 0) return false;

        // Query installed voices to pick network/enhanced voice if available
        try {
          final voices = await _flutterTts.getVoices;
          if (voices is List && voices.isNotEmpty) {
            Map? bestVoice;
            for (final v in voices) {
              if (v is Map) {
                final locale = (v['locale'] ?? '').toString().toLowerCase();
                final name = (v['name'] ?? '').toString().toLowerCase();
                if (locale.contains('hi') || name.contains('hi-in') || name.contains('hindi')) {
                  // Prefer enhanced, network, or google voices
                  if (name.contains('network') || name.contains('enhanced') || name.contains('c-network')) {
                    bestVoice = v;
                    break;
                  }
                  bestVoice ??= v;
                }
              }
            }
            if (bestVoice != null) {
              await _flutterTts.setVoice({
                'name': bestVoice['name'].toString(),
                'locale': bestVoice['locale'].toString(),
              });
            }
          }
        } catch (e) {
          debugPrint('TtsService: Error selecting specific voice: $e');
        }
      } else {
        dynamic setResult = await _flutterTts.setLanguage('en-IN');
        if (setResult == 0) {
          await _flutterTts.setLanguage('en-US');
        }
      }
      return true;
    } catch (e) {
      debugPrint('TtsService: Voice configuration error: $e');
      return false;
    }
  }

  /// Checks if Hindi speech voice data is installed and available on the device
  Future<bool> isHindiVoiceInstalled() async {
    try {
      for (final tag in const ['hi-IN', 'hi']) {
        final installed = await _flutterTts.isLanguageInstalled(tag);
        if (installed == true) return true;
      }

      for (final tag in const ['hi-IN', 'hi']) {
        final available = await _flutterTts.isLanguageAvailable(tag);
        if (available == true) return true;
      }

      final languages = await _flutterTts.getLanguages;
      if (languages is List) {
        final hasHindi = languages.any((lang) =>
            lang.toString().toLowerCase().startsWith('hi') ||
            lang.toString().toLowerCase().contains('hin'));
        if (hasHindi) return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking Hindi voice availability: $e');
      return false;
    }
  }

  /// Splits text into short natural sentences by punctuation for queued playback
  List<String> splitIntoSentences(String text) {
    if (text.trim().isEmpty) return [];

    // Split on Hindi full stop (।), Latin full stop, exclamation, question mark, or newlines
    final rawParts = text.split(RegExp(r'[।\.\?\!\n]+'));
    return rawParts
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 2)
        .toList();
  }

  /// Formats diagnosis fields into a full speech string
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
    final buffer = StringBuffer();
    final p = languageCode == 'hi' ? '।' : '.';

    buffer.write('$diseaseNameLabel: ${diagnosis.diseaseName}$p ');

    if (severityText.isNotEmpty) {
      buffer.write('$severityLabel: $severityText$p ');
    }

    if (diagnosis.immediateActions.isNotEmpty) {
      buffer.write('$whatToDoLabel: ${diagnosis.immediateActions.join(p == '।' ? '। ' : '. ')}$p ');
    }

    if (diagnosis.organicTreatments.isNotEmpty || diagnosis.chemicalTreatments.isNotEmpty) {
      buffer.write('$treatmentLabel$p ');
      if (diagnosis.organicTreatments.isNotEmpty) {
        buffer.write('$organicLabel: ${diagnosis.organicTreatments.join(p == '।' ? '। ' : '. ')}$p ');
      }
      if (diagnosis.chemicalTreatments.isNotEmpty) {
        buffer.write('$chemicalLabel: ${diagnosis.chemicalTreatments.join(p == '।' ? '। ' : '. ')}$p ');
      }
    }

    if (diagnosis.safetyNote.isNotEmpty) {
      buffer.write('${diagnosis.safetyNote}$p ');
    }

    return buffer.toString().trim();
  }

  /// Internal playback loop that plays a list of sentences one by one with short pauses
  Future<TtsPlaybackResult> _playSentenceQueue(
    List<String> sentences, {
    required String languageCode,
  }) async {
    await stop();

    final ready = await _configureVoiceForLanguage(languageCode);
    if (!ready && languageCode == 'hi') {
      return TtsPlaybackResult.hindiVoiceNotInstalled;
    }

    _currentQueue = sentences;
    _currentIndex = 0;
    stateNotifier.value = TtsPlaybackState.playing;
    isSpeakingNotifier.value = true;
    onStart?.call();

    // Start playback loop in background
    _runQueueLoop(languageCode);
    return TtsPlaybackResult.started;
  }

  Future<void> _runQueueLoop(String languageCode) async {
    while (_currentIndex < _currentQueue.length &&
        stateNotifier.value != TtsPlaybackState.stopped &&
        !_isDisposed) {
      // If paused, wait until resumed or stopped
      if (stateNotifier.value == TtsPlaybackState.paused) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      final sentence = _currentQueue[_currentIndex];
      _sentenceCompleter = Completer<void>();

      try {
        await _flutterTts.speak(sentence);
        // Wait for this sentence to complete
        await _sentenceCompleter!.future.timeout(
          const Duration(seconds: 25),
          onTimeout: () => debugPrint('TtsService: Sentence timeout'),
        );
      } catch (e) {
        debugPrint('TtsService: Error speaking sentence: $e');
      }

      _currentIndex++;

      // Small pause between sentences (350ms) for natural comprehension
      if (_currentIndex < _currentQueue.length &&
          stateNotifier.value == TtsPlaybackState.playing &&
          !_isDisposed) {
        await Future.delayed(const Duration(milliseconds: 350));
      }
    }

    if (stateNotifier.value != TtsPlaybackState.paused) {
      stateNotifier.value = TtsPlaybackState.stopped;
      isSpeakingNotifier.value = false;
      onDone?.call();
    }
  }

  /// Reads the 3-5 sentence spokenSummary first (Requirement 5)
  Future<TtsPlaybackResult> speakSpokenSummary({
    required Diagnosis diagnosis,
    required String languageCode,
  }) async {
    final isHindi = languageCode == 'hi';

    String textToSpeak = diagnosis.spokenSummary;
    if (textToSpeak.trim().isEmpty) {
      if (diagnosis.isHealthy) {
        textToSpeak = isHindi
            ? 'आपकी फसल की पत्ती पूरी तरह स्वस्थ है। इसमें किसी रोग के लक्षण नहीं हैं।'
            : 'Your crop leaf is healthy with no disease symptoms.';
      } else if (diagnosis.isDiseased) {
        final buffer = StringBuffer();
        buffer.write(isHindi
            ? 'पौधे में ${diagnosis.diseaseName} के लक्षण पाए गए हैं। '
            : 'The plant shows symptoms of ${diagnosis.diseaseName}. ');
        if (diagnosis.immediateActions.isNotEmpty) {
          buffer.write(isHindi
              ? 'तुरंत यह करें: ${diagnosis.immediateActions.first}। '
              : 'First action: ${diagnosis.immediateActions.first}. ');
        }
        if (diagnosis.organicTreatments.isNotEmpty) {
          buffer.write(isHindi
              ? 'जैविक उपाय: ${diagnosis.organicTreatments.first}। '
              : 'Organic remedy: ${diagnosis.organicTreatments.first}. ');
        }
        if (diagnosis.safetyNote.isNotEmpty) {
          buffer.write(isHindi
              ? 'सावधानी: ${diagnosis.safetyNote}'
              : 'Safety: ${diagnosis.safetyNote}');
        }
        textToSpeak = buffer.toString();
      } else {
        textToSpeak = diagnosis.description;
      }
    }

    final sentences = splitIntoSentences(textToSpeak);
    if (sentences.isEmpty) {
      sentences.add(textToSpeak);
    }

    return _playSentenceQueue(sentences, languageCode: languageCode);
  }

  /// Reads the full details section-by-section with small pauses
  Future<TtsPlaybackResult> speakFullDetails({
    required Diagnosis diagnosis,
    required String languageCode,
  }) async {
    final isHindi = languageCode == 'hi';
    final List<String> sections = [];

    if (diagnosis.isHealthy) {
      sections.add(isHindi
          ? 'पौधा पूरी तरह स्वस्थ है।'
          : 'The plant is healthy.');
      sections.add(diagnosis.description);
      return _playSentenceQueue(sections, languageCode: languageCode);
    }

    if (diagnosis.isNotAPlant || diagnosis.isPoorPhoto) {
      return _playSentenceQueue(splitIntoSentences(diagnosis.description), languageCode: languageCode);
    }

    // 1. Disease name & Severity
    sections.add(isHindi
        ? 'रोग का नाम: ${diagnosis.diseaseName}।'
        : 'Disease name: ${diagnosis.diseaseName}.');
    if (diagnosis.severity != DiagnosisSeverity.none) {
      final sevText = isHindi
          ? (diagnosis.severity == DiagnosisSeverity.mild
              ? 'गंभीरता: हल्की।'
              : (diagnosis.severity == DiagnosisSeverity.severe
                  ? 'गंभीरता: गंभीर।'
                  : 'गंभीरता: मध्यम।'))
          : 'Severity: ${diagnosis.severity.name}.';
      sections.add(sevText);
    }

    // 2. What it is (Description)
    if (diagnosis.description.isNotEmpty) {
      sections.addAll(splitIntoSentences(diagnosis.description));
    }

    // 3. Immediate Actions
    if (diagnosis.immediateActions.isNotEmpty) {
      sections.add(isHindi ? 'तुरंत करने योग्य कार्य:' : 'Immediate actions:');
      for (final action in diagnosis.immediateActions) {
        sections.add(action);
      }
    }

    // 4. Treatments
    if (diagnosis.organicTreatments.isNotEmpty) {
      sections.add(isHindi ? 'जैविक उपचार:' : 'Organic treatments:');
      for (final treat in diagnosis.organicTreatments) {
        sections.add(treat);
      }
    }
    if (diagnosis.chemicalTreatments.isNotEmpty) {
      sections.add(isHindi ? 'रासायनिक उपचार:' : 'Chemical treatments:');
      for (final chem in diagnosis.chemicalTreatments) {
        sections.add(chem);
      }
    }

    // 5. Safety note
    if (diagnosis.safetyNote.isNotEmpty) {
      sections.add(isHindi ? 'सुरक्षा निर्देश: ${diagnosis.safetyNote}' : 'Safety note: ${diagnosis.safetyNote}');
    }

    // 6. Prevention
    if (diagnosis.preventionTips.isNotEmpty) {
      sections.add(isHindi ? 'बचाव के उपाय:' : 'Prevention tips:');
      for (final prev in diagnosis.preventionTips) {
        sections.add(prev);
      }
    }

    return _playSentenceQueue(sections, languageCode: languageCode);
  }

  /// Plays a short test voice sample in the chosen language (for Settings screen)
  Future<TtsPlaybackResult> speakTestVoice(String languageCode) async {
    final isHindi = languageCode == 'hi';
    final sample = isHindi
        ? 'नमस्ते किसान साथी, यह प्लांटाई फसल डॉक्टर की आवाज़ है।'
        : 'Hello farmer, this is your crop doctor Plantii speaking.';
    return _playSentenceQueue([sample], languageCode: languageCode);
  }

  /// Pauses active speech playback
  Future<void> pause() async {
    try {
      stateNotifier.value = TtsPlaybackState.paused;
      isSpeakingNotifier.value = false;
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('TtsService: Error pausing: $e');
    }
  }

  /// Resumes paused speech playback
  Future<void> resume() async {
    if (stateNotifier.value == TtsPlaybackState.paused) {
      stateNotifier.value = TtsPlaybackState.playing;
      isSpeakingNotifier.value = true;
    }
  }

  /// Immediately stops audio speech and clears the sentence queue
  Future<void> stop() async {
    try {
      stateNotifier.value = TtsPlaybackState.stopped;
      isSpeakingNotifier.value = false;
      _currentQueue = [];
      _currentIndex = 0;
      if (_sentenceCompleter != null && !_sentenceCompleter!.isCompleted) {
        _sentenceCompleter!.complete();
      }
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TtsService: Error stopping TTS: $e');
    }
  }

  /// Cleans up resources
  void dispose() {
    _isDisposed = true;
    stop();
    stateNotifier.dispose();
    isSpeakingNotifier.dispose();
  }
}
