import '../models/crop_disease.dart';

/// Service providing mock disease data for development and testing.
/// Can be replaced with a real API service later without modifying UI code.
class MockCropService {
  /// Simulates analyzing a crop image and returning diagnosis
  Future<CropDisease> diagnoseCrop({
    required String cropId,
    required String imagePath,
  }) async {
    // Simulate network or AI processing latency
    await Future.delayed(const Duration(seconds: 2));

    return CropDisease(
      id: 'diag_${DateTime.now().millisecondsSinceEpoch}',
      cropName: 'Tomato',
      diseaseName: 'Early Blight',
      severity: DiseaseSeverity.medium,
      confidenceLevel: 'Very likely',
      description: 'A common fungal disease causing concentric dark rings on leaves.',
      immediateAction: 'Remove and destroy infected bottom leaves immediately.',
      preventionTips: 'Avoid overhead watering and rotate crops every 2-3 years.',
      organicTreatment: 'Spray neem oil or copper-based organic fungicide every 7 days.',
      chemicalTreatment: 'Apply Mancozeb or Chlorothalonil fungicide according to package instructions.',
      safetyNote: 'Always wear gloves and mask when applying any spray.',
      scannedAt: DateTime.now(),
    );
  }
}
