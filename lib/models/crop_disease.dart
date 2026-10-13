/// Disease severity level
enum DiseaseSeverity { low, medium, high }

/// Data model representing crop disease diagnosis information
class CropDisease {
  final String id;
  final String cropName;
  final String diseaseName;
  final DiseaseSeverity severity;
  final String confidenceLevel; // e.g. "Very likely" / "Possibly"
  final String description;
  final String immediateAction;
  final String preventionTips;
  final String organicTreatment;
  final String chemicalTreatment;
  final String safetyNote;
  final DateTime scannedAt;

  const CropDisease({
    required this.id,
    required this.cropName,
    required this.diseaseName,
    required this.severity,
    required this.confidenceLevel,
    required this.description,
    required this.immediateAction,
    required this.preventionTips,
    required this.organicTreatment,
    required this.chemicalTreatment,
    required this.safetyNote,
    required this.scannedAt,
  });
}
