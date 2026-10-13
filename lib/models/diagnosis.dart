/// Disease severity level for traffic light display
enum DiagnosisSeverity {
  mild,
  moderate,
  severe,
}

/// Comprehensive diagnosis data model for diseased crop leaf analysis
class Diagnosis {
  final String id;
  final String cropId;
  final String diseaseName;
  final String scientificName;
  final DiagnosisSeverity severity;
  final String confidenceLevel; // Confidence in words (e.g. "Very likely" / "बहुत संभावित")
  final String description;
  final List<String> immediateActions;
  final List<String> organicTreatments;
  final List<String> chemicalTreatments;
  final String safetyNote;
  final List<String> preventionTips;

  const Diagnosis({
    required this.id,
    required this.cropId,
    required this.diseaseName,
    required this.scientificName,
    required this.severity,
    required this.confidenceLevel,
    required this.description,
    required this.immediateActions,
    required this.organicTreatments,
    required this.chemicalTreatments,
    required this.safetyNote,
    required this.preventionTips,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropId': cropId,
      'diseaseName': diseaseName,
      'scientificName': scientificName,
      'severity': severity.name,
      'confidenceLevel': confidenceLevel,
      'description': description,
      'immediateActions': immediateActions,
      'organicTreatments': organicTreatments,
      'chemicalTreatments': chemicalTreatments,
      'safetyNote': safetyNote,
      'preventionTips': preventionTips,
    };
  }

  factory Diagnosis.fromMap(Map<String, dynamic> map) {
    return Diagnosis(
      id: map['id'] as String? ?? '',
      cropId: map['cropId'] as String? ?? '',
      diseaseName: map['diseaseName'] as String? ?? '',
      scientificName: map['scientificName'] as String? ?? '',
      severity: DiagnosisSeverity.values.firstWhere(
        (s) => s.name == map['severity'],
        orElse: () => DiagnosisSeverity.moderate,
      ),
      confidenceLevel: map['confidenceLevel'] as String? ?? '',
      description: map['description'] as String? ?? '',
      immediateActions: List<String>.from(map['immediateActions'] as List? ?? []),
      organicTreatments: List<String>.from(map['organicTreatments'] as List? ?? []),
      chemicalTreatments: List<String>.from(map['chemicalTreatments'] as List? ?? []),
      safetyNote: map['safetyNote'] as String? ?? '',
      preventionTips: List<String>.from(map['preventionTips'] as List? ?? []),
    );
  }
}
