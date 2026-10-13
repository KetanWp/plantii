import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Represents a crop available for diagnosis
class CropItem {
  final String id;
  final IconData icon;
  final Color badgeColor;
  final Color iconColor;
  final String Function(AppLocalizations l10n) getName;

  const CropItem({
    required this.id,
    required this.icon,
    required this.badgeColor,
    required this.iconColor,
    required this.getName,
  });

  /// The 5 supported crops from user specification
  static List<CropItem> get supportedCrops => [
        CropItem(
          id: 'tomato',
          icon: Icons.spa,
          badgeColor: const Color(0xFFFFEBEE), // Soft red badge
          iconColor: const Color(0xFFC62828), // Deep tomato red
          getName: (l10n) => l10n.tomato,
        ),
        CropItem(
          id: 'potato',
          icon: Icons.circle,
          badgeColor: const Color(0xFFEFEBE9), // Soft earthy potato badge
          iconColor: const Color(0xFF6D4C41), // Rich potato brown
          getName: (l10n) => l10n.potato,
        ),
        CropItem(
          id: 'rice',
          icon: Icons.grain,
          badgeColor: const Color(0xFFFFF8E1), // Warm grain yellow
          iconColor: const Color(0xFFF57F17), // Golden rice
          getName: (l10n) => l10n.rice,
        ),
        CropItem(
          id: 'wheat',
          icon: Icons.grass,
          badgeColor: const Color(0xFFFFF3E0), // Soft amber
          iconColor: const Color(0xFFE65100), // Rich wheat amber
          getName: (l10n) => l10n.wheat,
        ),
        CropItem(
          id: 'maize',
          icon: Icons.eco,
          badgeColor: const Color(0xFFE8F5E9), // Fresh green/maize badge
          iconColor: const Color(0xFF2E7D32), // Leafy corn green
          getName: (l10n) => l10n.maize,
        ),
      ];
}
