import 'dart:io';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/diagnosis.dart';
import '../models/scan_record.dart';
import '../routes.dart';
import '../services/real_diagnosis_service.dart';
import '../services/scan_history_service.dart';
import '../theme/app_theme.dart';

/// Screen 5: AI Diagnosis Loading & Error Resolution Screen
/// Calls the Cloud Functions /diagnose endpoint and provides farmer-friendly
/// recovery actions for timeout (retry), no internet (retry), bad_image (retake),
/// rate_limited (daily limit notification), and ai_failed.
class LoadingScreen extends StatefulWidget {
  final RealDiagnosisService? diagnosisService;

  const LoadingScreen({super.key, this.diagnosisService});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final RealDiagnosisService _diagnosisService;
  bool _startedDiagnosis = false;
  bool _isLoading = true;
  DiagnosisException? _activeError;

  @override
  void initState() {
    super.initState();
    _diagnosisService = widget.diagnosisService ?? RealDiagnosisService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_startedDiagnosis) {
      _startedDiagnosis = true;
      _executeDiagnosis();
    }
  }

  Future<void> _executeDiagnosis() async {
    setState(() {
      _isLoading = true;
      _activeError = null;
    });

    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? imagePath = args?['imagePath'] as String?;
    final String languageCode = Localizations.localeOf(context).languageCode;

    if (imagePath == null || !File(imagePath).existsSync()) {
      setState(() {
        _isLoading = false;
        _activeError = const DiagnosisException(
          type: DiagnosisErrorType.badImage,
          messageEn: 'Leaf image file not found. Please retake the photo.',
          messageHi: 'पत्ती की फोटो नहीं मिली। कृपया फोटो दोबारा लें।',
        );
      });
      return;
    }

    try {
      final Diagnosis diagnosis = await _diagnosisService.diagnose(
        imageFile: File(imagePath),
        language: languageCode,
      );

      final effectiveCrop = diagnosis.detectedCrop.isNotEmpty
          ? diagnosis.detectedCrop
          : 'Plant';

      // Persist to local offline history so it remains accessible without internet
      final scanRecord = ScanRecord(
        id: diagnosis.id.isNotEmpty
            ? diagnosis.id
            : 'scan_${DateTime.now().millisecondsSinceEpoch}',
        photoPath: imagePath,
        cropId: diagnosis.cropId.isNotEmpty ? diagnosis.cropId : 'plant',
        cropName: effectiveCrop,
        detectedCrop: diagnosis.detectedCrop.isNotEmpty ? diagnosis.detectedCrop : effectiveCrop,
        diseaseName: diagnosis.diseaseName,
        severity: diagnosis.severity,
        scannedAt: DateTime.now(),
        diagnosis: diagnosis,
      );
      await ScanHistoryService().saveScan(scanRecord);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: {
          'diagnosis': diagnosis,
          'imagePath': imagePath,
          'cropName': effectiveCrop,
        },
      );
    } on DiagnosisException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _activeError = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _activeError = DiagnosisException(
          type: DiagnosisErrorType.unknown,
          messageEn: 'Diagnosis failed. Please check your connection and try again.',
          messageHi: 'जांच पूरी नहीं हो सकी। कृपया अपना इंटरनेट जांचें और पुनः प्रयास करें।',
          serverMessage: e.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? imagePath = args?['imagePath'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.earthSand,
      appBar: AppBar(
        title: Text(l10n.loadingTitle),
        automaticallyImplyLeading: !_isLoading, // Allow back navigation when error occurs
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _isLoading
                ? _buildLoadingState(l10n, imagePath)
                : _buildErrorState(l10n, imagePath),
          ),
        ),
      ),
    );
  }

  /// Default analyzing animation view
  Widget _buildLoadingState(
    AppLocalizations l10n,
    String? imagePath,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Leaf photo thumbnail preview
        if (imagePath != null && File(imagePath).existsSync())
          Container(
            width: 130,
            height: 130,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryGreen, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              image: DecorationImage(
                image: FileImage(File(imagePath)),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreenLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryGreen, width: 2),
            ),
            child: const Icon(
              Icons.eco,
              size: 52,
              color: AppTheme.primaryGreen,
            ),
          ),

        // Large Progress indicator
        const SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 4.5,
          ),
        ),
        const SizedBox(height: 28),

        // Main friendly reassurance title
        Text(
          l10n.checkingPlant,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.highContrastDark,
          ),
        ),
        const SizedBox(height: 10),

        // AI progress subtext
        Text(
          l10n.analyzingLeafAi,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.mutedDark,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Farmer-friendly error card with actionable recovery buttons
  Widget _buildErrorState(AppLocalizations l10n, String? imagePath) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final error = _activeError ??
        DiagnosisException(
          type: DiagnosisErrorType.unknown,
          messageEn: 'Something went wrong.',
          messageHi: 'कुछ गलत हो गया।',
        );

    IconData errorIcon;
    Color iconColor;
    String titleText;
    String descriptionText = error.getLocalizedMessage(languageCode);
    bool showRetryButton = false;
    bool showRetakeButton = false;
    bool showHomeButton = false;

    switch (error.type) {
      case DiagnosisErrorType.noInternet:
      case DiagnosisErrorType.networkError:
        errorIcon = Icons.wifi_off_rounded;
        iconColor = AppTheme.severityHigh;
        titleText = l10n.errorNoInternet;
        showRetryButton = true;
        showHomeButton = true;
        break;

      case DiagnosisErrorType.timeout:
        errorIcon = Icons.timer_off_outlined;
        iconColor = AppTheme.severityMedium;
        titleText = l10n.errorTimeout;
        showRetryButton = true;
        showRetakeButton = true;
        break;

      case DiagnosisErrorType.rateLimited:
        errorIcon = Icons.hourglass_bottom_rounded;
        iconColor = AppTheme.severityMedium;
        titleText = l10n.errorRateLimited;
        showHomeButton = true;
        break;

      case DiagnosisErrorType.serviceBusy:
      case DiagnosisErrorType.quotaExceeded:
        errorIcon = Icons.cloud_off_rounded;
        iconColor = AppTheme.severityMedium;
        titleText = languageCode == 'hi' ? 'सर्वर व्यस्त है' : 'Service Busy';
        showRetryButton = true;
        showHomeButton = true;
        break;

      case DiagnosisErrorType.badImage:
        errorIcon = Icons.broken_image_rounded;
        iconColor = AppTheme.severityHigh;
        titleText = l10n.errorBadImage;
        showRetakeButton = true;
        break;

      case DiagnosisErrorType.safetyBlock:
        errorIcon = Icons.security_rounded;
        iconColor = AppTheme.severityHigh;
        titleText = languageCode == 'hi' ? 'सुरक्षा अवरोध' : 'Safety Notice';
        showRetakeButton = true;
        showHomeButton = true;
        break;

      case DiagnosisErrorType.aiAuthError:
        errorIcon = Icons.vpn_key_off_rounded;
        iconColor = AppTheme.severityHigh;
        titleText = languageCode == 'hi' ? 'प्रमाणीकरण त्रुटि' : 'Auth Error';
        showHomeButton = true;
        break;

      case DiagnosisErrorType.aiFailed:
        errorIcon = Icons.psychology_alt_rounded;
        iconColor = AppTheme.severityMedium;
        titleText = l10n.errorAiFailed;
        showRetryButton = true;
        showRetakeButton = true;
        break;

      case DiagnosisErrorType.unauthorized:
      case DiagnosisErrorType.unknown:
        errorIcon = Icons.error_outline_rounded;
        iconColor = AppTheme.severityHigh;
        titleText = languageCode == 'hi'
            ? 'जांच पूरी करने में समस्या आई'
            : 'Diagnosis Failed';
        showRetryButton = true;
        showHomeButton = true;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error Icon with background circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              errorIcon,
              size: 44,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 20),

          // Error Title
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.highContrastDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Informative description
          Text(
            descriptionText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.mutedDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Primary Action: Retry (if applicable)
          if (showRetryButton) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey('retry_diagnosis_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _executeDiagnosis,
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  label: Text(
                    l10n.retry,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Secondary Action: Retake Photo (if applicable)
          if (showRetakeButton) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey('retake_photo_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showRetryButton
                        ? Colors.grey.shade100
                        : AppTheme.primaryGreen,
                    foregroundColor: showRetryButton
                        ? AppTheme.highContrastDark
                        : Colors.white,
                    elevation: 0,
                    side: BorderSide(
                      color: showRetryButton
                          ? AppTheme.borderSubtle
                          : AppTheme.primaryGreen,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt_outlined, size: 24),
                  label: Text(
                    l10n.retakePhoto,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Tertiary Action: Back to Home
          if (showHomeButton) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const ValueKey('home_return_button'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.mutedDark,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_outlined, size: 22),
                  label: Text(
                    l10n.backToHome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
