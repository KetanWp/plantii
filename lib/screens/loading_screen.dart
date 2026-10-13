import 'dart:io';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/diagnosis.dart';
import '../models/scan_record.dart';
import '../routes.dart';
import '../services/mock_diagnosis_service.dart';
import '../services/scan_history_service.dart';
import '../theme/app_theme.dart';

/// Screen 5: Friendly loading screen simulating 2-second AI diagnosis
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final MockDiagnosisService _diagnosisService = MockDiagnosisService();
  bool _startedDiagnosis = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_startedDiagnosis) {
      _startedDiagnosis = true;
      _runDiagnosisSimulation();
    }
  }

  Future<void> _runDiagnosisSimulation() async {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String cropId = args?['cropId'] as String? ?? 'tomato';
    final String? imagePath = args?['imagePath'] as String?;
    final String? cropName = args?['cropName'] as String?;
    final String languageCode = Localizations.localeOf(context).languageCode;

    // Simulate 2 seconds of AI processing
    final stopwatch = Stopwatch()..start();
    final Diagnosis diagnosis = await _diagnosisService.getDiagnosis(
      cropId: cropId,
      languageCode: languageCode,
    );
    // Save scan record locally for offline history
    final scanRecord = ScanRecord(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      photoPath: imagePath ?? '',
      cropId: cropId,
      cropName: cropName ?? cropId,
      diseaseName: diagnosis.diseaseName,
      severity: diagnosis.severity,
      scannedAt: DateTime.now(),
      diagnosis: diagnosis,
    );
    await ScanHistoryService().saveScan(scanRecord);

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.result,
      arguments: {
        'diagnosis': diagnosis,
        'imagePath': imagePath,
        'cropName': cropName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? imagePath = args?['imagePath'] as String?;
    final String? cropName = args?['cropName'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.earthSand,
      appBar: AppBar(
        title: Text(l10n.loadingTitle),
        automaticallyImplyLeading: false, // Prevent navigation while analyzing
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
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

                if (cropName != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
                    ),
                    child: Text(
                      l10n.selectedCrop(cropName),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
