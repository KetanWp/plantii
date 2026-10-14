import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/consent_service.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_scan_button.dart';
import '../widgets/quick_action_card.dart';

/// Screen 1: Home Screen
///
/// Redesigned with:
/// - Dark green top section with greeting and weather chip
/// - Prominent circular scan button with subtle concentric ring
/// - Quick-action cards (Gallery, History, Expert Helpline)
/// - Bottom navigation bar (Home, History, Weather, Profile)
/// - Zero hardcoded strings (100% localized)
/// - Full protection against Hindi text overflow
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  void _onBottomNavTapped(int index, AppLocalizations l10n) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.history).then((_) {
          if (mounted) setState(() => _selectedNavIndex = 0);
        });
        break;
      case 2:
        _showWeatherSnackBar(l10n);
        setState(() => _selectedNavIndex = 0);
        break;
      case 3:
        _showProfileModal(context, l10n);
        setState(() => _selectedNavIndex = 0);
        break;
    }
  }

  void _showWeatherSnackBar(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${l10n.weatherChipSunny} • ${l10n.weatherChipAdvisory}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.forestDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showConsentBlockedDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppTheme.forestGreen, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.consentRequiredTitle,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.consentRequiredDesc,
          style: const TextStyle(fontSize: 15.5, height: 1.45, color: AppTheme.highContrastDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontSize: 16, color: AppTheme.mutedDark),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('review_consent_dialog_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.consent);
            },
            child: Text(
              l10n.consentReview,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToScan(BuildContext context, AppLocalizations l10n) async {
    final hasConsent = await ConsentService.instance.hasValidConsent();
    if (!context.mounted) return;
    if (hasConsent) {
      Navigator.pushNamed(context, AppRoutes.cropSelection);
    } else {
      _showConsentBlockedDialog(context, l10n);
    }
  }

  void _showExpertDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardBorderRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.leafGreenSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppTheme.forestGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.expertModalTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.expertModalDesc,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textMuted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.forestGreen,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showProfileModal(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.profileTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                // Language Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.leafGreenSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.language_rounded, color: AppTheme.forestGreen),
                  ),
                  title: Text(
                    l10n.profileLanguage,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.language);
                  },
                ),
                const Divider(),
                // Settings & Privacy Option
                ListTile(
                  key: const ValueKey('profile_settings_tile'),
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.leafGreenSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_outlined, color: AppTheme.forestGreen),
                  ),
                  title: Text(
                    l10n.settingsTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
                const Divider(),
                // Helpline Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.leafGreenSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.forestGreen),
                  ),
                  title: Text(
                    l10n.profileHelpline,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(l10n.expertModalDesc.split('\n').first),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showExpertDialog(context, l10n);
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    l10n.profileVersion,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dark Green Top Section (Forest Header)
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.forestHeaderGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: App Brand & Language Selector Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Brand Pill
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.appTitle,
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),

                          // Quick Language Toggle Chip & Settings Button
                          Row(
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.pushNamed(context, AppRoutes.language);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.language_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: const ValueKey('home_settings_button'),
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.pushNamed(context, AppRoutes.settings);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.settings_outlined,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Farmer Greeting
                      Text(
                        l10n.greetingFarmer,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.homeSubtitle,
                        style: const TextStyle(
                          color: AppTheme.textLightMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Interactive Weather Chip
                      InkWell(
                        borderRadius: AppTheme.chipBorderRadius,
                        onTap: () => _showWeatherSnackBar(l10n),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: AppTheme.chipBorderRadius,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wb_sunny_rounded,
                                color: Color(0xFFFFC107),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.weatherChipSunny,
                                  style: const TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Hero Circular Scan Button
                      CircularScanButton(
                        key: const ValueKey('home_circular_scan_button'),
                        label: l10n.tapToScanLeaf,
                        onTap: () => _proceedToScan(context, l10n),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Cream Content Area: Quick Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quickActionsTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Card 1: Choose from Gallery
                  QuickActionCard(
                    icon: Icons.photo_library_rounded,
                    title: l10n.actionGalleryTitle,
                    subtitle: l10n.actionGallerySubtitle,
                    iconBgColor: AppTheme.leafGreenSubtle,
                    iconColor: AppTheme.forestGreen,
                    onTap: () => _proceedToScan(context, l10n),
                  ),

                  // Card 2: Recent Scans History
                  QuickActionCard(
                    icon: Icons.history_edu_rounded,
                    title: l10n.actionHistoryTitle,
                    subtitle: l10n.actionHistorySubtitle,
                    iconBgColor: const Color(0xFFE8F0FE),
                    iconColor: const Color(0xFF1967D2),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.history);
                    },
                  ),

                  // Card 3: Kisan Helpline Call
                  QuickActionCard(
                    icon: Icons.support_agent_rounded,
                    title: l10n.actionExpertTitle,
                    subtitle: l10n.actionExpertSubtitle,
                    iconBgColor: const Color(0xFFFEF3E2),
                    iconColor: const Color(0xFFD97706),
                    onTap: () {
                      _showExpertDialog(context, l10n);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 3. Bottom Navigation Bar (Home, History, Weather, Profile)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) => _onBottomNavTapped(index, l10n),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n.homeTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded),
              label: l10n.historyNav,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.wb_sunny_outlined),
              label: l10n.weatherNav,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              label: l10n.profileNav,
            ),
          ],
        ),
      ),
    );
  }
}
