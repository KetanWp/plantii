/// Status category for leaf diagnosis
enum DiagnosisStatus {
  diseased,
  healthy,
  notAPlant,
  poorPhoto;

  static DiagnosisStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'healthy':
        return DiagnosisStatus.healthy;
      case 'not_a_plant':
      case 'notaplant':
        return DiagnosisStatus.notAPlant;
      case 'poor_photo':
      case 'poorphoto':
        return DiagnosisStatus.poorPhoto;
      case 'diseased':
      default:
        return DiagnosisStatus.diseased;
    }
  }

  String get wireName {
    switch (this) {
      case DiagnosisStatus.healthy:
        return 'healthy';
      case DiagnosisStatus.notAPlant:
        return 'not_a_plant';
      case DiagnosisStatus.poorPhoto:
        return 'poor_photo';
      case DiagnosisStatus.diseased:
        return 'diseased';
    }
  }
}

/// Confidence level for diagnostic accuracy
enum DiagnosisConfidence {
  veryLikely,
  likely,
  possible;

  static DiagnosisConfidence fromString(String? val) {
    final s = val?.toLowerCase().trim() ?? '';
    if (s.contains('very') || s == 'high' || s.contains('उच्च')) {
      return DiagnosisConfidence.veryLikely;
    } else if (s == 'possible' || s == 'low' || s.contains('कम')) {
      return DiagnosisConfidence.possible;
    } else {
      return DiagnosisConfidence.likely;
    }
  }

  String get wireName {
    switch (this) {
      case DiagnosisConfidence.veryLikely:
        return 'very_likely';
      case DiagnosisConfidence.likely:
        return 'likely';
      case DiagnosisConfidence.possible:
        return 'possible';
    }
  }

  String displayLabel({String languageCode = 'en'}) {
    final isHindi = languageCode == 'hi';
    switch (this) {
      case DiagnosisConfidence.veryLikely:
        return isHindi ? 'अत्यधिक संभावित' : 'Very Likely';
      case DiagnosisConfidence.likely:
        return isHindi ? 'संभावित' : 'Likely';
      case DiagnosisConfidence.possible:
        return isHindi ? 'हो सकता है' : 'Possible';
    }
  }
}

/// Disease severity level for traffic light display
enum DiagnosisSeverity {
  mild,
  moderate,
  severe,
  none;

  static DiagnosisSeverity fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'mild':
        return DiagnosisSeverity.mild;
      case 'severe':
        return DiagnosisSeverity.severe;
      case 'none':
        return DiagnosisSeverity.none;
      case 'moderate':
      default:
        return DiagnosisSeverity.moderate;
    }
  }
}

/// Comprehensive diagnosis data model for crop analysis
class Diagnosis {
  final String id;
  final String cropId;
  final String detectedCrop;
  final DiagnosisStatus status;
  final String diseaseName;
  final String scientificName;
  final DiagnosisSeverity severity;
  final DiagnosisConfidence confidence;
  final String confidenceLevel; // Backward-compatible string
  final String description;
  final List<String> immediateActions;
  final List<String> organicTreatments;
  final List<String> chemicalTreatments;
  final String safetyNote;
  final List<String> preventionTips;
  final String photoQuality;
  final List<String> possibleCauses;

  const Diagnosis({
    required this.id,
    required this.cropId,
    this.detectedCrop = '',
    this.status = DiagnosisStatus.diseased,
    required this.diseaseName,
    required this.scientificName,
    required this.severity,
    this.confidence = DiagnosisConfidence.likely,
    required this.confidenceLevel,
    required this.description,
    required this.immediateActions,
    required this.organicTreatments,
    required this.chemicalTreatments,
    required this.safetyNote,
    required this.preventionTips,
    this.photoQuality = 'good',
    this.possibleCauses = const [],
  });

  bool get isDiseased => status == DiagnosisStatus.diseased;
  bool get isHealthy => status == DiagnosisStatus.healthy;
  bool get isNotAPlant => status == DiagnosisStatus.notAPlant;
  bool get isPoorPhoto => status == DiagnosisStatus.poorPhoto;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropId': cropId,
      'detectedCrop': detectedCrop,
      'status': status.wireName,
      'diseaseName': diseaseName,
      'scientificName': scientificName,
      'severity': severity.name,
      'confidence': confidence.wireName,
      'confidenceLevel': confidenceLevel,
      'description': description,
      'immediateActions': immediateActions,
      'organicTreatments': organicTreatments,
      'chemicalTreatments': chemicalTreatments,
      'safetyNote': safetyNote,
      'preventionTips': preventionTips,
      'photoQuality': photoQuality,
      'possibleCauses': possibleCauses,
    };
  }

  factory Diagnosis.fromMap(Map<String, dynamic> map) {
    final status = DiagnosisStatus.fromString(map['status'] as String?);
    final confidence = DiagnosisConfidence.fromString(
      map['confidence'] as String? ?? map['confidenceLevel'] as String?,
    );
    final rawSeverity = map['severity'] as String?;
    final severity = status == DiagnosisStatus.diseased
        ? DiagnosisSeverity.fromString(rawSeverity)
        : DiagnosisSeverity.none;

    final rawConfidenceLevel = map['confidenceLevel'] as String?;
    final confidenceLevel = (rawConfidenceLevel != null && rawConfidenceLevel.isNotEmpty)
        ? rawConfidenceLevel
        : confidence.displayLabel();

    final preventionList = List<String>.from(
      map['prevention'] as List? ?? map['preventionTips'] as List? ?? [],
    );

    return Diagnosis(
      id: map['id'] as String? ?? '',
      cropId: map['cropId'] as String? ?? '',
      detectedCrop: map['detectedCrop'] as String? ?? (map['cropId'] as String? ?? ''),
      status: status,
      diseaseName: map['diseaseName'] as String? ?? '',
      scientificName: map['scientificName'] as String? ?? '',
      severity: severity,
      confidence: confidence,
      confidenceLevel: confidenceLevel,
      description: map['description'] as String? ?? '',
      immediateActions: List<String>.from(map['immediateActions'] as List? ?? []),
      organicTreatments: List<String>.from(map['organicTreatments'] as List? ?? []),
      chemicalTreatments: List<String>.from(map['chemicalTreatments'] as List? ?? []),
      safetyNote: map['safetyNote'] as String? ?? '',
      preventionTips: preventionList,
      photoQuality: map['photoQuality'] as String? ?? 'good',
      possibleCauses: List<String>.from(map['possibleCauses'] as List? ?? []),
    );
  }
}
