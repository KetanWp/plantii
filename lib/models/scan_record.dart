import 'diagnosis.dart';

/// Represents a persistent historical scan record saved offline
class ScanRecord {
  final String id;
  final String photoPath;
  final String cropId;
  final String cropName;
  final String diseaseName;
  final DiagnosisSeverity severity;
  final DateTime scannedAt;
  final Diagnosis diagnosis;

  const ScanRecord({
    required this.id,
    required this.photoPath,
    required this.cropId,
    required this.cropName,
    required this.diseaseName,
    required this.severity,
    required this.scannedAt,
    required this.diagnosis,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPath': photoPath,
      'cropId': cropId,
      'cropName': cropName,
      'diseaseName': diseaseName,
      'severity': severity.name,
      'scannedAt': scannedAt.toIso8601String(),
      'diagnosis': diagnosis.toMap(),
    };
  }

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] as String? ?? '',
      photoPath: map['photoPath'] as String? ?? '',
      cropId: map['cropId'] as String? ?? '',
      cropName: map['cropName'] as String? ?? '',
      diseaseName: map['diseaseName'] as String? ?? '',
      severity: DiagnosisSeverity.values.firstWhere(
        (s) => s.name == map['severity'],
        orElse: () => DiagnosisSeverity.moderate,
      ),
      scannedAt: DateTime.tryParse(map['scannedAt'] as String? ?? '') ?? DateTime.now(),
      diagnosis: Diagnosis.fromMap(
        Map<String, dynamic>.from(map['diagnosis'] as Map? ?? {}),
      ),
    );
  }
}
