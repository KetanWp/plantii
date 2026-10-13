import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/crop_item.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

/// Screen 3: Crop Selection Screen
/// Displays large, high-contrast cards for the 5 primary crops
/// with large tap targets tailored for farmers under outdoor sunlight.
class CropSelectionScreen extends StatelessWidget {
  const CropSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final crops = CropItem.supportedCrops;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cropSelectionTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Friendly instruction banner with outdoor contrast
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: AppTheme.primaryGreenLight,
              child: Row(
                children: [
                  const Icon(
                    Icons.eco,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.selectCropPrompt,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.highContrastDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Responsive grid of large crop cards
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemCount: crops.length,
                itemBuilder: (context, index) {
                  final crop = crops[index];
                  final cropName = crop.getName(l10n);

                  return _CropGridCard(
                    crop: crop,
                    cropName: cropName,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.camera,
                        arguments: {
                          'cropId': crop.id,
                          'cropName': cropName,
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large, sunlight-optimized interactive card for an individual crop
class _CropGridCard extends StatelessWidget {
  final CropItem crop;
  final String cropName;
  final VoidCallback onTap;

  const _CropGridCard({
    required this.crop,
    required this.cropName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.primaryGreenLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // High contrast icon badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: crop.badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: crop.iconColor.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Icon(
                  crop.icon,
                  size: 42,
                  color: crop.iconColor,
                ),
              ),
              const SizedBox(height: 14),
              // High contrast bold crop title
              Text(
                cropName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.highContrastDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
