import 'dart:io';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/diagnosis.dart';
import '../services/mock_diagnosis_service.dart';
import '../services/real_diagnosis_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/big_touch_button.dart';

/// Screen 6: Diagnosis Result Screen
/// Displays the captured leaf photo, large disease title, traffic light severity,
/// confidence rating, treatment splits (Organic & Chemical), safety notes,
/// and interactive farmer assistance actions.
class ResultScreen extends StatefulWidget {
  final TtsService? ttsService;
  final RealDiagnosisService? diagnosisService;

  const ResultScreen({super.key, this.ttsService, this.diagnosisService});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool? _isHelpful; // null = unanswered, true = thumbs up, false = thumbs down
  bool _isSubmittingFeedback = false;
  late final TtsService _ttsService;
  late final RealDiagnosisService _diagnosisService;

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? TtsService();
    _ttsService.isSpeakingNotifier.addListener(_onTtsSpeakingChanged);
    _diagnosisService = widget.diagnosisService ?? RealDiagnosisService();
  }

  void _onTtsSpeakingChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ttsService.isSpeakingNotifier.removeListener(_onTtsSpeakingChanged);
    if (widget.ttsService == null) {
      _ttsService.dispose();
    } else {
      _ttsService.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String? imagePath = args?['imagePath'] as String?;
    final String languageCode = Localizations.localeOf(context).languageCode;

    // Use passed diagnosis or fallback to mock tomato early blight for standalone runs
    final Diagnosis diagnosis = args?['diagnosis'] as Diagnosis? ??
        (languageCode == 'hi'
            ? const MockDiagnosisService()
                .getDiagnosisSyncFallback('tomato', true)
            : const MockDiagnosisService()
                .getDiagnosisSyncFallback('tomato', false));

    return Scaffold(
      backgroundColor: AppTheme.earthSand,
      appBar: AppBar(
        title: Text(l10n.resultTitle),
        elevation: 0,
        actions: [
          // Audio read-aloud button for low-literacy farmers
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              key: const ValueKey('listen_button'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _ttsService.isSpeaking
                    ? Colors.amber.shade900
                    : Colors.white.withValues(alpha: 0.18),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: _ttsService.isSpeaking
                      ? const BorderSide(color: Colors.white, width: 1.5)
                      : BorderSide.none,
                ),
              ),
              onPressed: () => _toggleAudioReadout(diagnosis, languageCode, l10n),
              icon: Icon(
                _ttsService.isSpeaking ? Icons.stop_circle : Icons.volume_up,
                color: Colors.white,
                size: 24,
              ),
              label: Text(
                _ttsService.isSpeaking ? l10n.stopAudio : l10n.listen,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. User's photo
                    _buildPhotoCard(imagePath),
                    const SizedBox(height: 16),

                    // 2. Disease name (large) & Scientific name
                    _buildDiseaseHeader(diagnosis),
                    const SizedBox(height: 14),

                    // 3. Traffic-light severity & Confidence in words
                    _buildSeverityAndConfidence(context, diagnosis, l10n),
                    const SizedBox(height: 20),

                    // 4. Card: What it is
                    _buildCardSection(
                      title: l10n.whatItIs,
                      icon: Icons.info_outline,
                      iconColor: AppTheme.primaryGreen,
                      content: Text(
                        diagnosis.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: AppTheme.highContrastDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Card: What to do now (Immediate actions)
                    _buildCardSection(
                      title: l10n.whatToDoNow,
                      icon: Icons.bolt,
                      iconColor: AppTheme.severityMedium,
                      content: _buildBulletList(diagnosis.immediateActions),
                    ),
                    const SizedBox(height: 14),

                    // 6. Split Treatment: Organic vs Chemical
                    _buildSplitTreatmentSection(diagnosis, l10n),
                    const SizedBox(height: 14),

                    // 7. Safety Note
                    _buildSafetyNoteCard(diagnosis.safetyNote, l10n),
                    const SizedBox(height: 14),

                    // 8. Card: Prevention
                    _buildCardSection(
                      title: l10n.preventionTips,
                      icon: Icons.verified_user_outlined,
                      iconColor: AppTheme.primaryGreen,
                      content: _buildBulletList(diagnosis.preventionTips),
                    ),
                    const SizedBox(height: 24),

                    // 9. "Ask an Expert" Button
                    BigTouchButton(
                      icon: Icons.support_agent,
                      label: l10n.askAnExpert,
                      onPressed: () => _showExpertDialog(context, l10n),
                    ),
                    const SizedBox(height: 20),

                    // 10. "Was this helpful?" feedback section
                    _buildHelpfulFeedback(l10n, diagnosis, languageCode),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_ttsService.isSpeaking)
              _buildAudioPlayingBar(diagnosis, l10n),
          ],
        ),
      ),
    );
  }

  /// Displays the user's captured or selected photo
  Widget _buildPhotoCard(String? imagePath) {
    if (imagePath != null && File(imagePath).existsSync()) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSubtle, width: 2),
          image: DecorationImage(
            image: FileImage(File(imagePath)),
            fit: BoxFit.cover,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 2),
      ),
      child: const Center(
        child: Icon(
          Icons.eco,
          size: 64,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  /// Disease Title and Scientific name header
  Widget _buildDiseaseHeader(Diagnosis diagnosis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diagnosis.diseaseName,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.highContrastDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          diagnosis.scientificName,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: AppTheme.mutedDark,
          ),
        ),
      ],
    );
  }

  /// Traffic-light severity bar and confidence in words
  Widget _buildSeverityAndConfidence(
    BuildContext context,
    Diagnosis diagnosis,
    AppLocalizations l10n,
  ) {
    final (Color activeColor, String severityLabel) = switch (diagnosis.severity) {
      DiagnosisSeverity.mild => (AppTheme.severityLow, l10n.severityMild),
      DiagnosisSeverity.moderate => (AppTheme.severityMedium, l10n.severityModerate),
      DiagnosisSeverity.severe => (AppTheme.severityHigh, l10n.severitySevere),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
      ),
      child: Row(
        children: [
          // Visual traffic-light indicator (3 dots)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF212121),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTrafficDot(
                  AppTheme.severityLow,
                  isActive: diagnosis.severity == DiagnosisSeverity.mild,
                ),
                const SizedBox(width: 6),
                _buildTrafficDot(
                  AppTheme.severityMedium,
                  isActive: diagnosis.severity == DiagnosisSeverity.moderate,
                ),
                const SizedBox(width: 6),
                _buildTrafficDot(
                  AppTheme.severityHigh,
                  isActive: diagnosis.severity == DiagnosisSeverity.severe,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Severity text badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activeColor, width: 1.5),
            ),
            child: Text(
              severityLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ),
          const Spacer(),

          // Confidence level in words
          Flexible(
            child: Text(
              diagnosis.confidenceLevel,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficDot(Color color, {required bool isActive}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.7),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }

  /// General section card with sunlight outline
  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.highContrastDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Color(0xFFE0E0E0)),
            content,
          ],
        ),
      ),
    );
  }

  /// Treatment card explicitly splitting Organic and Chemical treatments
  Widget _buildSplitTreatmentSection(Diagnosis diagnosis, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Organic treatment block
            Row(
              children: [
                const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.organicTreatment,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildBulletList(diagnosis.organicTreatments),

            const Divider(height: 24, thickness: 1.2, color: Color(0xFFE0E0E0)),

            // Chemical treatment block
            Row(
              children: [
                const Icon(Icons.science, color: AppTheme.earthBrown, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.chemicalTreatment,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.earthBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildBulletList(diagnosis.chemicalTreatments),
          ],
        ),
      ),
    );
  }

  /// Clearly highlighted safety note warning card
  Widget _buildSafetyNoteCard(String safetyNote, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Warm amber background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF57F17), width: 2), // High contrast amber border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE65100),
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.safetyNote,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            safetyNote,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppTheme.highContrastDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Bullet points list
  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.4,
                    color: AppTheme.highContrastDark,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Sends feedback (thumbs up / thumbs down) to the /feedback endpoint
  Future<void> _submitFeedback(
    Diagnosis diagnosis,
    bool helpful,
    String languageCode,
    AppLocalizations l10n,
  ) async {
    if (_isSubmittingFeedback) return;

    setState(() {
      _isHelpful = helpful;
      _isSubmittingFeedback = true;
    });

    await _diagnosisService.sendFeedback(
      scanId: diagnosis.id,
      helpful: helpful,
      language: languageCode,
    );

    if (!mounted) return;
    setState(() {
      _isSubmittingFeedback = false;
    });
  }

  /// Interactive thumbs up / down feedback widget
  Widget _buildHelpfulFeedback(
    AppLocalizations l10n,
    Diagnosis diagnosis,
    String languageCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            _isHelpful == null ? l10n.wasThisHelpful : l10n.feedbackThanks,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.highContrastDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Thumbs up button (large touch target >= 56px)
              InkWell(
                key: const ValueKey('thumbs_up_button'),
                onTap: _isSubmittingFeedback
                    ? null
                    : () => _submitFeedback(diagnosis, true, languageCode, l10n),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isHelpful == true
                        ? AppTheme.primaryGreenLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isHelpful == true
                          ? AppTheme.primaryGreen
                          : AppTheme.borderSubtle,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isHelpful == true
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        color: _isHelpful == true
                            ? AppTheme.primaryGreen
                            : AppTheme.mutedDark,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '👍 Yes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isHelpful == true
                              ? AppTheme.primaryGreen
                              : AppTheme.mutedDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Thumbs down button (large touch target >= 56px)
              InkWell(
                key: const ValueKey('thumbs_down_button'),
                onTap: _isSubmittingFeedback
                    ? null
                    : () => _submitFeedback(diagnosis, false, languageCode, l10n),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isHelpful == false
                        ? const Color(0xFFFFEBEE)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isHelpful == false
                          ? AppTheme.severityHigh
                          : AppTheme.borderSubtle,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isHelpful == false
                            ? Icons.thumb_down
                            : Icons.thumb_down_alt_outlined,
                        color: _isHelpful == false
                            ? AppTheme.severityHigh
                            : AppTheme.mutedDark,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '👎 No',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isHelpful == false
                              ? AppTheme.severityHigh
                              : AppTheme.mutedDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dialog connecting farmers to agricultural experts
  void _showExpertDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.support_agent, color: AppTheme.primaryGreen, size: 28),
              const SizedBox(width: 10),
              Text(l10n.expertModalTitle),
            ],
          ),
          content: Text(
            l10n.expertModalDesc,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.close,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Toggles TTS read-aloud of the diagnosis details
  Future<void> _toggleAudioReadout(
    Diagnosis diagnosis,
    String languageCode,
    AppLocalizations l10n,
  ) async {
    if (_ttsService.isSpeaking) {
      await _ttsService.stop();
      return;
    }

    final String severityText = switch (diagnosis.severity) {
      DiagnosisSeverity.mild => l10n.severityMild,
      DiagnosisSeverity.moderate => l10n.severityModerate,
      DiagnosisSeverity.severe => l10n.severitySevere,
    };

    final result = await _ttsService.speakDiagnosis(
      diagnosis: diagnosis,
      languageCode: languageCode,
      diseaseNameLabel: l10n.diseaseNameLabel,
      severityLabel: l10n.severityLabel,
      severityText: severityText,
      whatToDoLabel: l10n.whatToDoNow,
      treatmentLabel: l10n.treatmentLabel,
      organicLabel: l10n.organicTreatment,
      chemicalLabel: l10n.chemicalTreatment,
    );

    if (!mounted) return;

    if (result == TtsPlaybackResult.hindiVoiceNotInstalled) {
      _showHindiVoiceHelpDialog(context, l10n);
    }
  }

  /// Displays instructions on how to install Hindi voice data in Android settings
  void _showHindiVoiceHelpDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.severityMedium.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.record_voice_over_outlined,
                  color: AppTheme.severityMedium,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.voiceNotInstalledTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.highContrastDark,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              l10n.voiceNotInstalledDesc,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppTheme.highContrastDark,
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l10n.voiceNotInstalledDismiss,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Persistent bottom audio bar visible while TTS is reading aloud
  Widget _buildAudioPlayingBar(Diagnosis diagnosis, AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.highContrastDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.record_voice_over,
            color: AppTheme.severityLow,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.readingAloud,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  diagnosis.diseaseName,
                  style: const TextStyle(
                    color: AppTheme.borderSubtle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            key: const ValueKey('stop_audio_button'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _ttsService.stop(),
            icon: const Icon(Icons.stop, size: 20, color: Colors.white),
            label: Text(
              l10n.stopAudio,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper extension on MockDiagnosisService for synchronous fallback
extension MockDiagnosisServiceSync on MockDiagnosisService {
  Diagnosis getDiagnosisSyncFallback(String cropId, bool isHindi) {
    // Returns Tomato early blight as synchronous fallback
    return isHindi
        ? const Diagnosis(
            id: 'tomato_early_blight',
            cropId: 'tomato',
            diseaseName: 'टमाटर का अगेती झुलसा',
            scientificName: 'Alternaria solani',
            severity: DiagnosisSeverity.moderate,
            confidenceLevel: 'अत्यधिक संभावित (95%)',
            description:
                'यह फफूंद जनित रोग है। पत्तियों पर भूरे-काले गोल छल्ले बनते हैं और पत्तियां पीली होकर सूखने लगती हैं।',
            immediateActions: [
              'रोगग्रस्त निचली पत्तियों को तुरंत तोड़कर जलाएं।',
              'फव्वारा सिंचाई बंद करें, पानी सिर्फ जड़ों में दें।',
            ],
            organicTreatments: [
              'नीम का तेल (5 मि.ली. प्रति लीटर) 7 दिन पर छिड़कें।',
              'ट्राइकोडर्मा विरिडी (5 ग्राम प्रति लीटर) का छिड़काव करें।',
            ],
            chemicalTreatments: [
              'मैनकोजेब 75% WP (2.5 ग्राम प्रति लीटर) छिड़कें।',
            ],
            safetyNote:
                'दवा छिड़कते समय मास्क और दस्ताने पहनें। पशुओं को 24 घंटे दूर रखें।',
            preventionTips: [
              '3 साल का फसल चक्र अपनाएं।',
              'पौधों के बीच 60 सेमी की दूरी रखें।',
            ],
          )
        : const Diagnosis(
            id: 'tomato_early_blight',
            cropId: 'tomato',
            diseaseName: 'Tomato Early Blight',
            scientificName: 'Alternaria solani',
            severity: DiagnosisSeverity.moderate,
            confidenceLevel: 'Very likely (95%)',
            description:
                'A fungal disease creating dark concentric rings on older foliage. Causes yellowing and premature leaf drop.',
            immediateActions: [
              'Prune and destroy infected lower leaves immediately.',
              'Avoid overhead watering; irrigate strictly at the base.',
            ],
            organicTreatments: [
              'Spray cold-pressed Neem oil (5ml per litre) every 7 days.',
              'Apply Trichoderma viride bio-fungicide (5g per litre).',
            ],
            chemicalTreatments: [
              'Apply Mancozeb 75% WP (2.5g per litre) at 10-day intervals.',
            ],
            safetyNote:
                'Wear protective mask and gloves while spraying. Keep livestock away for 24 hours.',
            preventionTips: [
              'Rotate crops for 3 years; avoid planting after potatoes.',
              'Ensure 60cm spacing between plants for adequate ventilation.',
            ],
          );
  }
}
