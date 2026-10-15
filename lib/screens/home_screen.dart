import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/consent_service.dart';
import '../services/image_processing_service.dart';
import '../services/locale_provider.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/camera_permission_helper.dart';
import '../widgets/circular_scan_button.dart';
import '../widgets/photo_tips_sheet.dart';
import '../widgets/privacy_consent_sheet.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/weather_detail_sheet.dart';

/// Screen 1: Home Screen
///
/// Features:
/// - Dark green header with live Open-Meteo weather chip
/// - Direct camera flow: Photo Tips sheet -> Native Phone Camera or Gallery
/// - One-time bottom sheet privacy consent before user's first scan
/// - Android lost-data recovery (retrieveLostData) on process death
/// - Quick-action cards (Gallery, History, Expert Helpline)
/// - Bottom navigation bar (Home, History, Weather, Settings)
class HomeScreen extends StatefulWidget {
  final WeatherService? weatherService;
  final ConsentService? consentService;
  final ImagePicker? imagePicker;

  const HomeScreen({
    super.key,
    this.weatherService,
    this.consentService,
    this.imagePicker,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final WeatherService _weatherService;
  late final ConsentService _consentService;
  late final ImagePicker _imagePicker;

  WeatherData? _weatherData;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _weatherService = widget.weatherService ?? WeatherService();
    _consentService = widget.consentService ?? ConsentService.instance;
    _imagePicker = widget.imagePicker ?? ImagePicker();

    _loadWeather();
    _checkLostCameraData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLostCameraData();
    }
  }

  /// Handles Android killing the app while camera is open
  Future<void> _checkLostCameraData() async {
    try {
      final LostDataResponse response = await _imagePicker.retrieveLostData();
      if (response.isEmpty) return;

      if (response.file != null) {
        final rawFile = File(response.file!.path);
        if (rawFile.existsSync()) {
          final compressed = await ImageProcessingService.validateAndCompress(rawFile);
          if (mounted) {
            Navigator.pushNamed(
              context,
              AppRoutes.loading,
              arguments: {
                'imagePath': compressed.path,
              },
            );
          }
        }
      } else if (response.exception != null) {
        debugPrint('HomeScreen: Error from lost camera data: ${response.exception}');
      }
    } catch (e) {
      debugPrint('HomeScreen: Error checking lost camera data: $e');
    }
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    try {
      final data = await _weatherService.fetchWeather(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen: Could not fetch weather: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  /// Initiates the scan flow:
  /// 1. Verifies one-time Privacy Consent (shows PrivacyConsentSheet if not consented)
  /// 2. Ensures Camera Permission at point-of-use (friendly explanation, Open Settings if permanently denied)
  /// 3. Opens PhotoTipsSheet (displays tips + Open Camera / Choose from Gallery)
  /// 4. Compresses photo and navigates straight to LoadingScreen
  Future<void> _proceedToScan(BuildContext context) async {
    // 1. Consent check: if first scan, show PrivacyConsentSheet
    final hasConsent = await _consentService.hasValidConsent();
    if (!hasConsent) {
      if (!context.mounted) return;
      final agreed = await PrivacyConsentSheet.show(context, consentService: _consentService);
      if (!agreed) {
        return; // Block scan until user agrees
      }
    }

    if (!context.mounted) return;

    // 2. Camera permission at point of use: friendly prompt if not granted, Open Settings if permanently denied
    await CameraPermissionHelper.ensureCameraPermission(context);

    if (!context.mounted) return;

    // 3. Open PhotoTipsSheet with tips and native camera / gallery choices
    final File? photoFile = await PhotoTipsSheet.show(context, imagePicker: _imagePicker);
    if (photoFile != null && context.mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.loading,
        arguments: {
          'imagePath': photoFile.path,
        },
      );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isHindi = localeProvider.isHindi;

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dark Green Hero Header
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Column(
                    children: [
                      // Top Row: App Brand & Quick Action Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    color: AppTheme.leafGreenAccent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    l10n.appTitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Language Immediate Toggle Switch (हिं / EN)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: const ValueKey('home_language_switch'),
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    localeProvider.toggleLocale();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isHindi ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'हिं',
                                            style: TextStyle(
                                              color: isHindi ? AppTheme.forestGreen : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: !isHindi ? Colors.white : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'EN',
                                            style: TextStyle(
                                              color: !isHindi ? AppTheme.forestGreen : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Settings Button
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

                      // Compact Real-Weather Card (Tapping opens full weather screen)
                      InkWell(
                        key: const ValueKey('home_weather_card'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          WeatherDetailSheet.show(context, weatherService: _weatherService)
                              .then((_) => _loadWeather());
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: _isLoadingWeather
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        isHindi ? 'मौसम लोड हो रहा है...' : 'Loading weather...',
                                        style: const TextStyle(
                                          color: AppTheme.textLight,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : _weatherData != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    _getWeatherEmoji(_weatherData!.weatherCode),
                                                    style: const TextStyle(fontSize: 20),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${_weatherData!.temperature.round()}°C',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      _weatherData!.placeName,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.water_drop_outlined,
                                                      size: 14,
                                                      color: AppTheme.leafGreenAccent,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${_weatherData!.humidity}%',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 8),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.umbrella_outlined,
                                                      size: 14,
                                                      color: Colors.lightBlueAccent,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${_weatherData!.rainChance}%',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getRiskBadgeColor(_weatherData!.diseaseRiskLevel),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _getRiskLabel(_weatherData!.diseaseRiskLevel, isHindi),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                isHindi
                                                    ? _weatherData!.diseaseRiskHintHi
                                                    : _weatherData!.diseaseRiskHintEn,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              size: 16,
                                              color: Colors.white70,
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        const Icon(
                                          Icons.cloud_outlined,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isHindi
                                                ? 'मौसम और रोग जोखिम देखें • टैप करें'
                                                : 'View weather & disease risk • Tap here',
                                            style: const TextStyle(
                                              color: AppTheme.textLight,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Hero Circular Scan Button (Direct Camera Flow)
                      CircularScanButton(
                        key: const ValueKey('home_circular_scan_button'),
                        label: l10n.tapToScanLeaf,
                        onTap: () => _proceedToScan(context),
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

                  // Card 1: Choose from Gallery (Directly triggers photo tips & gallery)
                  QuickActionCard(
                    icon: Icons.photo_library_rounded,
                    title: l10n.actionGalleryTitle,
                    subtitle: l10n.actionGallerySubtitle,
                    iconBgColor: AppTheme.leafGreenSubtle,
                    iconColor: AppTheme.forestGreen,
                    onTap: () => _proceedToScan(context),
                  ),

                  // Card 2: Recent Scans History
                  QuickActionCard(
                    key: const ValueKey('quick_action_history'),
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
    );
  }

  String _getWeatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 82) return '🌦️';
    if (code >= 95) return '⛈️';
    return '🌤️';
  }

  Color _getRiskBadgeColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return const Color(0xFFD32F2F);
      case 'moderate':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _getRiskLabel(String level, bool isHindi) {
    switch (level.toLowerCase()) {
      case 'high':
        return isHindi ? 'उच्च जोखिम' : 'High Risk';
      case 'moderate':
        return isHindi ? 'मध्यम जोखिम' : 'Moderate';
      default:
        return isHindi ? 'कम जोखिम' : 'Low Risk';
    }
  }
}
