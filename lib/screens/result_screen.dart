import 'dart:io';
import 'package:flutter/foundation.dart';
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
    _ttsService.stop();
    if (widget.ttsService == null) {
      _ttsService.dispose();
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
    final Diagnosis? passedDiagnosis = args?['diagnosis'] as Diagnosis?;

    // In production release builds, never fall back to mock data
    if (passedDiagnosis == null) {
      if (!kDebugMode) {
        return Scaffold(
          backgroundColor: AppTheme.earthSand,
          appBar: AppBar(title: Text(l10n.resultTitle)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppTheme.severitySevere),
                  const SizedBox(height: 16),
                  Text(
                    languageCode == 'hi'
                        ? 'कोई जांच परिणाम उपलब्ध नहीं है। कृपया नया स्कैन करें।'
                        : 'No diagnosis result available. Please start a new scan.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  BigTouchButton(
                    icon: Icons.home,
                    label: languageCode == 'hi' ? 'होम पर वापस जाएं' : 'Return to Home',
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Fallback strictly for debug/test mode when running widget harnesses without route args
    final Diagnosis diagnosis = passedDiagnosis ??
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
          // Audio read-aloud button for low-literacy farmers (reads spokenSummary first)
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
                    // User's captured photo
                    _buildPhotoCard(imagePath),
                    const SizedBox(height: 14),

                    // Render content according to Diagnosis status
                    if (diagnosis.status == DiagnosisStatus.healthy)
                      ..._buildHealthyContent(context, diagnosis, languageCode, l10n)
                    else if (diagnosis.status == DiagnosisStatus.poorPhoto ||
                        diagnosis.status == DiagnosisStatus.notAPlant)
                      ..._buildRetakeContent(context, diagnosis, languageCode, l10n)
                    else
                      ..._buildDiseasedContent(context, diagnosis, languageCode, l10n),
                  ],
                ),
              ),
            ),
            if (_ttsService.isSpeaking || _ttsService.isPaused)
              _buildAudioPlayingBar(diagnosis, l10n, languageCode),
          ],
        ),
      ),
    );
  }

  /// Healthy plant screen content
  List<Widget> _buildHealthyContent(
    BuildContext context,
    Diagnosis diagnosis,
    String languageCode,
    AppLocalizations l10n,
  ) {
    final isHindi = languageCode == 'hi';
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryGreen, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primaryGreen,
              size: 56,
            ),
            const SizedBox(height: 10),
            Text(
              isHindi ? 'स्वस्थ पौधा' : 'Healthy Plant',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isHindi
                  ? 'फसल में कोई बीमारी या कीट के लक्षण नहीं दिखे'
                  : 'No signs of disease or pest infestation detected',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.highContrastDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${isHindi ? "सटीकता" : "Confidence"}: ${diagnosis.confidence.displayLabel(languageCode: languageCode)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildCardSection(
        title: isHindi ? 'देखभाल एवं सुझाव' : 'Routine Care Advice',
        icon: Icons.spa_outlined,
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
      const SizedBox(height: 24),
      BigTouchButton(
        icon: Icons.camera_alt,
        label: isHindi ? 'दूसरी पत्ती स्कैन करें' : 'Scan Another Leaf',
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/camera', (r) => false),
      ),
      const SizedBox(height: 14),
      BigTouchButton(
        icon: Icons.home,
        label: isHindi ? 'होम पर वापस जाएं' : 'Return to Home',
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
      ),
      const SizedBox(height: 16),
    ];
  }

  /// Retake photo screen content (for poor photo or not a plant)
  List<Widget> _buildRetakeContent(
    BuildContext context,
    Diagnosis diagnosis,
    String languageCode,
    AppLocalizations l10n,
  ) {
    final isHindi = languageCode == 'hi';
    final bool isNotPlant = diagnosis.status == DiagnosisStatus.notAPlant;

    final String title = isNotPlant
        ? (isHindi ? 'पौधा नहीं दिखा' : 'Not a Plant')
        : (isHindi ? 'फोटो स्पष्ट नहीं है' : 'Photo Not Clear');

    final String subtitle = isNotPlant
        ? (isHindi
            ? 'तस्वीर में फसल या पत्ती की पहचान नहीं हो सकी'
            : 'No crop foliage or plant recognized in this image')
        : (isHindi
            ? 'फोटो धुंधली या अंधेरी होने के कारण जांच संभव नहीं है'
            : 'Image is too blurry or dark for accurate diagnosis');

    final List<String> tips = isNotPlant
        ? [
            isHindi ? 'केवल फसल या पौधे की पत्ती को कैमरे में रखें' : 'Keep only the crop leaf in the frame',
            isHindi ? 'इंसान, जमीन या अन्य सामान की फोटो न लें' : 'Avoid photographing people, ground, or objects',
            isHindi ? 'पत्ती को केंद्र में रखकर स्पष्ट फोटो लें' : 'Keep the leaf centered in clear focus',
          ]
        : [
            isHindi ? 'अच्छी प्राकृतिक रोशनी में फोटो लें' : 'Take photo under good natural daylight',
            isHindi ? 'कैमरे को पत्ती के करीब (15-20 सेमी) स्थिर रखें' : 'Hold camera steady and close (15-20 cm)',
            isHindi ? 'स्क्रीन पर पत्ती को छूकर फोकस करें' : 'Tap on the leaf to lock focus before snapping',
          ];

    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade800, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              isNotPlant ? Icons.hide_image_outlined : Icons.blur_on_rounded,
              color: Colors.orange.shade900,
              size: 56,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.highContrastDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildCardSection(
        title: isHindi ? 'मार्गदर्शन एवं टिप्स' : 'Photography Guidelines',
        icon: Icons.lightbulb_outline,
        iconColor: Colors.orange.shade900,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diagnosis.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppTheme.highContrastDark,
              ),
            ),
            const SizedBox(height: 12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(fontSize: 15, height: 1.4, color: AppTheme.highContrastDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      BigTouchButton(
        icon: Icons.camera_alt,
        label: isHindi ? 'फोटो दोबारा लें' : 'Retake Photo',
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/camera', (r) => false),
      ),
      const SizedBox(height: 14),
      BigTouchButton(
        icon: Icons.home,
        label: isHindi ? 'होम पर वापस जाएं' : 'Return to Home',
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
      ),
      const SizedBox(height: 16),
    ];
  }

  /// Diseased plant screen content (shows severity, treatments, safety, and actions)
  List<Widget> _buildDiseasedContent(
    BuildContext context,
    Diagnosis diagnosis,
    String languageCode,
    AppLocalizations l10n,
  ) {
    return [
      // Disease name, Detected Crop badge & Scientific name
      _buildDiseaseHeader(diagnosis, languageCode),
      const SizedBox(height: 14),

      // Traffic-light severity & Confidence in words
      _buildSeverityAndConfidence(context, diagnosis, l10n),
      const SizedBox(height: 12),

      // Short AI disclaimer notice
      Container(
        key: const ValueKey('ai_guidance_disclaimer'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.leafGreenSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.forestGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.aiDisclaimer,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.forestGreen,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Card: What it is
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

      // Card: What to do now (Immediate actions)
      _buildCardSection(
        title: l10n.whatToDoNow,
        icon: Icons.bolt,
        iconColor: AppTheme.severityMedium,
        content: _buildBulletList(diagnosis.immediateActions),
      ),
      const SizedBox(height: 14),

      // Split Treatment: Organic vs Chemical
      _buildSplitTreatmentSection(diagnosis, l10n),
      const SizedBox(height: 14),

      // Safety Note
      _buildSafetyNoteCard(diagnosis.safetyNote, l10n),
      const SizedBox(height: 14),

      // Card: Prevention
      _buildCardSection(
        title: l10n.preventionTips,
        icon: Icons.verified_user_outlined,
        iconColor: AppTheme.primaryGreen,
        content: _buildBulletList(diagnosis.preventionTips),
      ),
      const SizedBox(height: 24),

      // "Ask an Expert" Button
      BigTouchButton(
        icon: Icons.support_agent,
        label: l10n.askAnExpert,
        onPressed: () => _showExpertDialog(context, l10n),
      ),
      const SizedBox(height: 20),

      // "Was this helpful?" feedback section
      _buildHelpfulFeedback(l10n, diagnosis, languageCode),
      const SizedBox(height: 16),
    ];
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

  /// Disease Title, Detected Crop badge, and Scientific name header
  Widget _buildDiseaseHeader(Diagnosis diagnosis, String languageCode) {
    final isHindi = languageCode == 'hi';
    final String cropDisplay = diagnosis.detectedCrop.isNotEmpty
        ? diagnosis.detectedCrop
        : (diagnosis.cropId.isNotEmpty
            ? diagnosis.cropId
            : (isHindi ? 'अज्ञात पौधा' : 'Unknown Plant'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detected Crop Badge
        Container(
          key: const ValueKey('detected_crop_badge'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.leafGreenSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, size: 18, color: AppTheme.forestGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${isHindi ? "पहचाना गया पौधा" : "Detected Crop"}: $cropDisplay',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        // Disease title (20-22 sp, maxLines: 2, ellipsis, non-overflowing)
        Text(
          diagnosis.diseaseName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.highContrastDark,
            height: 1.25,
          ),
        ),
        if (diagnosis.scientificName.isNotEmpty && diagnosis.scientificName != 'N/A') ...[
          const SizedBox(height: 4),
          Text(
            diagnosis.scientificName,
            style: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: AppTheme.mutedDark,
            ),
          ),
        ],

        // Spoken Summary Card (Requirement 5)
        if (diagnosis.spokenSummary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _toggleAudioReadout(diagnosis, languageCode, AppLocalizations.of(context)!),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.leafGreenSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _ttsService.isSpeaking ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                      color: AppTheme.forestGreen,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'ऑडियो सारांश' : 'Voice Summary',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diagnosis.spokenSummary,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Plain severity chip and confidence in words (NO traffic light dots)
  Widget _buildSeverityAndConfidence(
    BuildContext context,
    Diagnosis diagnosis,
    AppLocalizations l10n,
  ) {
    if (diagnosis.severity == DiagnosisSeverity.none) {
      return const SizedBox.shrink();
    }

    final (Color activeColor, String severityLabel) = switch (diagnosis.severity) {
      DiagnosisSeverity.mild => (AppTheme.severityLow, l10n.severityMild),
      DiagnosisSeverity.moderate => (AppTheme.severityMedium, l10n.severityModerate),
      DiagnosisSeverity.severe => (AppTheme.severityHigh, l10n.severitySevere),
      DiagnosisSeverity.none => (AppTheme.severityLow, ''),
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
          // Plain text severity label in simple chip (no traffic dots)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: activeColor.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Text(
              severityLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Confidence level in words
          Expanded(
            child: Text(
              diagnosis.confidenceLevel,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedDark,
              ),
            ),
          ),
        ],
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.highContrastDark,
                    ),
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
                Expanded(
                  child: Text(
                    l10n.organicTreatment,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
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
                Expanded(
                  child: Text(
                    l10n.chemicalTreatment,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.earthBrown,
                    ),
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
              Expanded(
                child: Text(
                  l10n.safetyNote,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
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
              Expanded(
                child: InkWell(
                  key: const ValueKey('thumbs_up_button'),
                  onTap: _isSubmittingFeedback
                      ? null
                      : () => _submitFeedback(diagnosis, true, languageCode, l10n),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isHelpful == true
                              ? Icons.thumb_up
                              : Icons.thumb_up_alt_outlined,
                          color: _isHelpful == true
                              ? AppTheme.primaryGreen
                              : AppTheme.mutedDark,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '👍 Yes',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isHelpful == true
                                  ? AppTheme.primaryGreen
                                  : AppTheme.mutedDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Thumbs down button (large touch target >= 56px)
              Expanded(
                child: InkWell(
                  key: const ValueKey('thumbs_down_button'),
                  onTap: _isSubmittingFeedback
                      ? null
                      : () => _submitFeedback(diagnosis, false, languageCode, l10n),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isHelpful == false
                              ? Icons.thumb_down
                              : Icons.thumb_down_alt_outlined,
                          color: _isHelpful == false
                              ? AppTheme.severityHigh
                              : AppTheme.mutedDark,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '👎 No',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isHelpful == false
                                  ? AppTheme.severityHigh
                                  : AppTheme.mutedDark,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  /// Toggles TTS read-aloud of the diagnosis details (reads spokenSummary first)
  Future<void> _toggleAudioReadout(
    Diagnosis diagnosis,
    String languageCode,
    AppLocalizations l10n,
  ) async {
    if (_ttsService.isSpeaking) {
      await _ttsService.stop();
      if (mounted) setState(() {});
      return;
    }

    final result = await _ttsService.speakSpokenSummary(
      diagnosis: diagnosis,
      languageCode: languageCode,
    );

    if (!mounted) return;
    setState(() {});

    if (result == TtsPlaybackResult.hindiVoiceNotInstalled) {
      _showHindiVoiceHelpDialog(context, l10n);
    }
  }

  /// Displays instructions on how to install Hindi voice data in Android settings
  void _showHindiVoiceHelpDialog(BuildContext context, AppLocalizations l10n) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.voiceNotInstalledDesc,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.highContrastDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isHindi
                      ? 'चरण: 1. सेटिंग्स खोलें > 2. भाषा व इनपुट > 3. टेक्स्ट-टू-स्पीच > 4. हिंदी वॉयस डेटा डाउनलोड करें।'
                      : 'Steps: 1. Open Settings > 2. Languages & Input > 3. Text-to-speech > 4. Download Hindi voice data.',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.forestGreen),
                ),
              ],
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
  Widget _buildAudioPlayingBar(Diagnosis diagnosis, AppLocalizations l10n, String languageCode) {
    final isHindi = languageCode == 'hi';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.record_voice_over,
                  color: AppTheme.severityLow,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ttsService.isPaused
                            ? (isHindi ? 'आवाज़ रुकी हुई है' : 'Audio paused')
                            : l10n.readingAloud,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        diagnosis.diseaseName.isNotEmpty ? diagnosis.diseaseName : (isHindi ? 'स्वस्थ पौधा' : 'Healthy Plant'),
                        style: const TextStyle(
                          color: AppTheme.borderSubtle,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Play / Pause toggle
                IconButton(
                  icon: Icon(
                    _ttsService.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    if (_ttsService.isPaused) {
                      _ttsService.resume();
                    } else {
                      _ttsService.pause();
                    }
                    setState(() {});
                  },
                ),
                // Stop button
                TextButton.icon(
                  key: const ValueKey('stop_audio_button'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _ttsService.stop();
                    setState(() {});
                  },
                  icon: const Icon(Icons.stop, size: 18, color: Colors.white),
                  label: Text(
                    l10n.stopAudio,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // "Read full details" button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amberAccent,
                  side: const BorderSide(color: Colors.amberAccent),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: Text(
                  isHindi ? 'पूरा विवरण क्रम से सुनें' : 'Read full details section by section',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _ttsService.speakFullDetails(diagnosis: diagnosis, languageCode: languageCode);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
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
