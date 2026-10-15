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

/// Disease severity level
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
  final String cropConfidence; // 'very_likely' | 'likely' | 'possible'
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
  final String spokenSummary;
  final bool fromCache;

  const Diagnosis({
    required this.id,
    required this.cropId,
    this.detectedCrop = '',
    this.cropConfidence = 'very_likely',
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
    this.spokenSummary = '',
    this.fromCache = false,
  });

  bool get isDiseased => status == DiagnosisStatus.diseased;
  bool get isHealthy => status == DiagnosisStatus.healthy;
  bool get isNotAPlant => status == DiagnosisStatus.notAPlant;
  bool get isPoorPhoto => status == DiagnosisStatus.poorPhoto;

  Diagnosis copyWith({
    String? id,
    String? cropId,
    String? detectedCrop,
    String? cropConfidence,
    DiagnosisStatus? status,
    String? diseaseName,
    String? scientificName,
    DiagnosisSeverity? severity,
    DiagnosisConfidence? confidence,
    String? confidenceLevel,
    String? description,
    List<String>? immediateActions,
    List<String>? organicTreatments,
    List<String>? chemicalTreatments,
    String? safetyNote,
    List<String>? preventionTips,
    String? photoQuality,
    List<String>? possibleCauses,
    String? spokenSummary,
    bool? fromCache,
  }) {
    return Diagnosis(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      detectedCrop: detectedCrop ?? this.detectedCrop,
      cropConfidence: cropConfidence ?? this.cropConfidence,
      status: status ?? this.status,
      diseaseName: diseaseName ?? this.diseaseName,
      scientificName: scientificName ?? this.scientificName,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      description: description ?? this.description,
      immediateActions: immediateActions ?? this.immediateActions,
      organicTreatments: organicTreatments ?? this.organicTreatments,
      chemicalTreatments: chemicalTreatments ?? this.chemicalTreatments,
      safetyNote: safetyNote ?? this.safetyNote,
      preventionTips: preventionTips ?? this.preventionTips,
      photoQuality: photoQuality ?? this.photoQuality,
      possibleCauses: possibleCauses ?? this.possibleCauses,
      spokenSummary: spokenSummary ?? this.spokenSummary,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropId': cropId,
      'detectedCrop': detectedCrop,
      'cropConfidence': cropConfidence,
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
      'spokenSummary': spokenSummary,
      'fromCache': fromCache,
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
      cropConfidence: map['cropConfidence'] as String? ?? 'very_likely',
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
      spokenSummary: map['spokenSummary'] as String? ?? '',
      fromCache: map['fromCache'] as bool? ?? false,
    );
  }
}
