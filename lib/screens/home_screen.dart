import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../widgets/big_touch_button.dart';

/// Screen 2: Home Screen
/// Prominently displays the primary plant scan action, gallery option,
/// and quick navigation for History, Weather, and Help.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.earthSand,
      appBar: AppBar(
        title: Text(l10n.appTitle),
        elevation: 0,
        actions: [
          // Quick language toggle in header
          IconButton(
            tooltip: l10n.languageTitle,
            icon: const Icon(Icons.language, size: 26),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.language);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Friendly welcome header with leaf illustration
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreenLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 60,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                l10n.appTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.highContrastDark,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                l10n.selectCropPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.mutedDark,
                ),
              ),

              const Spacer(),

              // Huge Primary Action: "Scan Your Plant" button (min 56px height)
              BigTouchButton(
                icon: Icons.camera_alt,
                label: l10n.scanPlantButton,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.cropSelection);
                },
              ),
              const SizedBox(height: 14),

              // Secondary Action: Choose from Gallery button
              BigTouchButton(
                isPrimary: false,
                icon: Icons.photo_library,
                label: l10n.chooseFromGallery,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.cropSelection);
                },
              ),

              const Spacer(),

              // Bottom quick-access row (History, Weather, Help)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // History button
                    _buildNavTab(
                      context,
                      icon: Icons.history,
                      label: l10n.historyNav,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.history);
                      },
                    ),

                    // Weather button
                    _buildNavTab(
                      context,
                      icon: Icons.wb_sunny_outlined,
                      label: l10n.weatherNav,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '☀️ ${l10n.weatherNav}: 28°C, Clear outdoor sunlight',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    // Help / Expert button
                    _buildNavTab(
                      context,
                      icon: Icons.help_outline,
                      label: l10n.helpNav,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            title: Text(l10n.expertModalTitle),
                            content: Text(l10n.expertModalDesc),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(l10n.close),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.highContrastDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
