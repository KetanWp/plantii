import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/consent_service.dart';
import '../services/locale_provider.dart';
import '../services/real_diagnosis_service.dart';
import '../services/tts_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_detail_sheet.dart';

/// Screen 8: Settings & Preferences Screen
/// Organised into 5 distinct cards with icons and headings:
/// 1. Language: Change language (Hindi/English)
/// 2. Voice: Speech speed slider, voice on/off by default, test voice button
/// 3. Location: Weather location (auto GPS or choose a place)
/// 4. Privacy & Data: Privacy Policy, Withdraw consent, Delete my data
/// 5. About & Support: App version, Contact support (mailto), Share app
class SettingsScreen extends StatefulWidget {
  final RealDiagnosisService? diagnosisService;
  final ConsentService? consentService;
  final WeatherService? weatherService;

  const SettingsScreen({
    super.key,
    this.diagnosisService,
    this.consentService,
    this.weatherService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final RealDiagnosisService _diagnosisService;
  late final ConsentService _consentService;
  late final WeatherService _weatherService;
  late final TtsService _ttsService;

  bool _hasConsent = true;
  bool _isDeleting = false;
  bool _autoPlayVoice = false;
  double _speechRate = 0.47;
  bool _isTestingVoice = false;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _diagnosisService = widget.diagnosisService ?? RealDiagnosisService();
    _consentService = widget.consentService ?? ConsentService.instance;
    _weatherService = widget.weatherService ?? WeatherService();
    _ttsService = TtsService();

    _checkConsentStatus();
    _loadVoiceSettings();
    _loadLocationSetting();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _checkConsentStatus() async {
    final hasConsent = await _consentService.hasValidConsent();
    if (mounted) {
      setState(() {
        _hasConsent = hasConsent;
      });
    }
  }

  Future<void> _loadVoiceSettings() async {
    final autoPlay = await TtsService.isAutoPlayEnabled();
    final prefs = await SharedPreferences.getInstance();
    final speed = prefs.getString(TtsService.prefSpeedKey);
    final rate = (speed == 'slow') ? 0.42 : 0.47;
    if (mounted) {
      setState(() {
        _autoPlayVoice = autoPlay;
        _speechRate = rate;
      });
    }
  }

  Future<void> _loadLocationSetting() async {
    final saved = await _weatherService.getSavedLocation();
    if (mounted) {
      setState(() {
        _locationName = saved?.name ?? '';
      });
    }
  }

  Future<void> _toggleTestVoice(String languageCode) async {
    if (_isTestingVoice) {
      await _ttsService.stop();
      if (mounted) setState(() => _isTestingVoice = false);
    } else {
      if (mounted) setState(() => _isTestingVoice = true);
      final result = await _ttsService.speakTestVoice(languageCode);
      if (result == TtsPlaybackResult.hindiVoiceNotInstalled && mounted) {
        _showInstallVoiceDialog();
      }
      if (mounted) setState(() => _isTestingVoice = false);
    }
  }

  void _showInstallVoiceDialog() {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.record_voice_over_rounded, color: AppTheme.forestGreen, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isHindi ? 'हिंदी आवाज़ इंस्टॉल करें' : 'Install Hindi Voice',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHindi
                  ? 'उच्च गुणवत्ता वाली हिंदी आवाज़ के लिए कृपया इन आसान चरणों का पालन करें:'
                  : 'To enable high-quality Hindi speech, please follow these steps:',
              style: const TextStyle(fontSize: 14.5, color: AppTheme.textDark, height: 1.4),
            ),
            const SizedBox(height: 12),
            _buildStepRow('1', isHindi ? 'फोन की सेटिंग्स खोलें' : 'Open phone Settings'),
            _buildStepRow('2', isHindi ? 'System > Languages & input > Text-to-speech पर जाएं' : 'Go to System > Languages & input > Text-to-speech'),
            _buildStepRow('3', isHindi ? 'Google TTS के आगे गियर आइकन पर टैप करें' : 'Tap gear icon next to Google TTS engine'),
            _buildStepRow('4', isHindi ? 'Install voice data > Hindi (India) डाउनलोड करें' : 'Tap Install voice data > Download Hindi (India)'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isHindi ? 'समझ गया' : 'Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppTheme.leafGreenSubtle,
            child: Text(step, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.forestGreen)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13.5, color: AppTheme.textDark)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWithdrawConsent(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.severityMedium, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.withdrawConfirmTitle,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.withdrawConfirmDesc,
          style: const TextStyle(fontSize: 15.5, height: 1.45, color: AppTheme.highContrastDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontSize: 16, color: AppTheme.mutedDark),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('confirm_withdraw_consent_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.severityMedium,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.withdrawConfirmButton,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _consentService.withdrawConsent();
      if (!mounted) return;
      setState(() {
        _hasConsent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.withdrawSuccess),
          backgroundColor: AppTheme.highContrastDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleDeleteMyData(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: AppTheme.severityHigh, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.deleteConfirmTitle,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.deleteConfirmDesc,
          style: const TextStyle(fontSize: 15.5, height: 1.45, color: AppTheme.highContrastDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontSize: 16, color: AppTheme.mutedDark),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('confirm_delete_everything_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.severityHigh,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.deleteConfirmButton,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isDeleting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              const CircularProgressIndicator(color: AppTheme.severityHigh),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  l10n.deletingDataProgress,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final languageCode = Localizations.localeOf(context).languageCode;
    final success = await _diagnosisService.deleteAccount(language: languageCode);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteDataSuccess),
          backgroundColor: AppTheme.forestGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.language,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteDataError),
          backgroundColor: AppTheme.severityHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleContactSupport() async {
    const email = 'info@prakruty.com';
    final Uri mailUri = Uri.parse(
      'mailto:$email?subject=Plantii%20Support%20Request',
    );

    try {
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('SettingsScreen: Could not launch email client: $e');
    }

    await Clipboard.setData(const ClipboardData(text: email));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Support email copied to clipboard: info@prakruty.com',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleShareApp(bool isHindi) async {
    final shareText = isHindi
        ? 'प्लांटाई (Plantii) ऐप से अपनी फसलों के रोगों की तुरंत पहचान करें और जैविक उपचार पाएं: https://plantii.prakruty.com'
        : 'Diagnose crop diseases instantly and get organic remedies with Plantii: https://plantii.prakruty.com';

    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isHindi
                    ? 'शेयर लिंक कॉपी हो गया है! इसे अन्य किसान मित्रों के साथ साझा करें।'
                    : 'Share link copied to clipboard! Share Plantii with other farmers.',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showChangeLanguageDialog(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isHindi = localeProvider.isHindi;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.language_rounded, color: AppTheme.forestGreen, size: 26),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Select Language / भाषा चुनें',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('settings_lang_hi'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: isHindi ? AppTheme.leafGreenSubtle : Colors.transparent,
              leading: Icon(
                isHindi ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: AppTheme.forestGreen,
              ),
              title: const Text('हिंदी', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Text('Hindi', style: TextStyle(color: AppTheme.mutedDark, fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                await localeProvider.setLocale(const Locale('hi'));
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              key: const ValueKey('settings_lang_en'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: !isHindi ? AppTheme.leafGreenSubtle : Colors.transparent,
              leading: Icon(
                !isHindi ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: AppTheme.forestGreen,
              ),
              title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(ctx);
                await localeProvider.setLocale(const Locale('en'));
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
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
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          children: [
            // 1. Language Card
            _buildSectionHeader(Icons.language_rounded, isHindi ? 'भाषा' : 'Language'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.translate_rounded,
                iconColor: AppTheme.forestGreen,
                title: isHindi ? 'भाषा बदलें (Change Language)' : 'Change Language',
                subtitle: isHindi ? 'वर्तमान: हिन्दी (Hindi)' : 'Current: English',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreenSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    isHindi ? 'हिन्दी' : 'English',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                ),
                onTap: () => _showChangeLanguageDialog(context),
              ),
            ]),
            const SizedBox(height: 20),

            // 2. Voice Card
            _buildSectionHeader(Icons.record_voice_over_rounded, isHindi ? 'आवाज़ और भाषण' : 'Voice & Speech'),
            _buildSettingsCard([
              // Voice Speed Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.forestGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.speed_rounded, color: AppTheme.forestGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'बोलने की गति' : 'Speech Speed',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                              ),
                              Text(
                                _speechRate <= 0.44
                                    ? (isHindi ? 'धीमी गति (0.42x)' : 'Slow rate (0.42x)')
                                    : (isHindi ? 'सामान्य गति (0.47x)' : 'Normal rate (0.47x)'),
                                style: const TextStyle(fontSize: 13, color: AppTheme.mutedDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                isHindi ? 'धीमी (0.42x)' : 'Slow (0.42x)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _speechRate <= 0.44 ? AppTheme.forestGreen : AppTheme.textDark,
                                ),
                              ),
                            ),
                            selected: _speechRate <= 0.44,
                            selectedColor: AppTheme.leafGreenSubtle,
                            backgroundColor: Colors.grey.shade100,
                            onSelected: (val) async {
                              if (val) {
                                await _ttsService.setSpeed(TtsSpeed.slow);
                                setState(() => _speechRate = 0.42);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                isHindi ? 'सामान्य (0.47x)' : 'Normal (0.47x)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _speechRate > 0.44 ? AppTheme.forestGreen : AppTheme.textDark,
                                ),
                              ),
                            ),
                            selected: _speechRate > 0.44,
                            selectedColor: AppTheme.leafGreenSubtle,
                            backgroundColor: Colors.grey.shade100,
                            onSelected: (val) async {
                              if (val) {
                                await _ttsService.setSpeed(TtsSpeed.normal);
                                setState(() => _speechRate = 0.47);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // Voice On/Off by Default Switch
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.volume_up_rounded, color: AppTheme.forestGreen, size: 20),
                ),
                title: Text(
                  isHindi ? 'आवाज़ अपने आप शुरू करें' : 'Voice on by default',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                ),
                subtitle: Text(
                  isHindi
                      ? 'परिणाम खुलते ही विवरण बोलकर सुनाएं'
                      : 'Automatically read diagnosis results aloud',
                  style: const TextStyle(fontSize: 13, color: AppTheme.mutedDark),
                ),
                activeThumbColor: AppTheme.forestGreen,
                value: _autoPlayVoice,
                onChanged: (val) async {
                  await TtsService.setAutoPlayEnabled(val);
                  setState(() => _autoPlayVoice = val);
                },
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // Test Voice Button
              _buildSettingsTile(
                icon: _isTestingVoice ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                iconColor: _isTestingVoice ? AppTheme.severityHigh : AppTheme.forestGreen,
                title: isHindi ? 'आवाज़ का परीक्षण करें' : 'Test Voice',
                subtitle: isHindi ? 'प्लांटाई की आवाज़ सुनकर जांचें' : 'Listen to a sample voice',
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTestingVoice ? AppTheme.severityHigh : AppTheme.forestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: Icon(_isTestingVoice ? Icons.stop : Icons.volume_up, size: 16),
                  label: Text(
                    _isTestingVoice ? (isHindi ? 'रोकें' : 'Stop') : (isHindi ? 'सुनें' : 'Play'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _toggleTestVoice(isHindi ? 'hi' : 'en'),
                ),
                onTap: () => _toggleTestVoice(isHindi ? 'hi' : 'en'),
              ),
            ]),
            const SizedBox(height: 20),

            // 3. Location Card
            _buildSectionHeader(Icons.location_on_rounded, isHindi ? 'मौसम का स्थान' : 'Weather Location'),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.my_location_rounded,
                iconColor: const Color(0xFF1967D2),
                title: isHindi ? 'मौसम स्थान' : 'Weather Location',
                subtitle: _locationName.isNotEmpty
                    ? _locationName
                    : (isHindi ? 'स्वचालित स्थान (GPS) सक्रिय' : 'Auto GPS location active'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isHindi ? 'बदलें' : 'Change',
                    style: const TextStyle(
                      color: Color(0xFF1967D2),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                onTap: () {
                  WeatherDetailSheet.show(context, weatherService: _weatherService)
                      .then((_) => _loadLocationSetting());
                },
              ),
            ]),
            const SizedBox(height: 20),

            // 4. Privacy & Data Card
            _buildSectionHeader(Icons.security_rounded, isHindi ? 'गोपनीयता और डेटा' : 'Privacy & Data'),
            _buildSettingsCard([
              // Privacy Policy
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppTheme.forestGreen,
                title: l10n.settingsPrivacyPolicy,
                subtitle: l10n.settingsPrivacyPolicyDesc,
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // Withdraw Consent
              _buildSettingsTile(
                icon: Icons.pause_circle_outline_rounded,
                iconColor: _hasConsent ? AppTheme.severityMedium : Colors.grey,
                title: l10n.settingsWithdrawConsent,
                subtitle: _hasConsent
                    ? l10n.settingsWithdrawConsentDesc
                    : (isHindi ? 'सहमति वापस ली गई है (स्कैनिंग रुकी हुई है)' : 'Consent withdrawn (scanning paused)'),
                trailing: _hasConsent
                    ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isHindi ? 'रुका हुआ' : 'Paused',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                onTap: _hasConsent ? () => _handleWithdrawConsent(l10n) : null,
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // Delete My Data
              _buildSettingsTile(
                icon: Icons.delete_forever_rounded,
                iconColor: AppTheme.severityHigh,
                title: l10n.settingsDeleteData,
                subtitle: l10n.settingsDeleteDataDesc,
                titleColor: AppTheme.severityHigh,
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.severityHigh),
                onTap: _isDeleting ? null : () => _handleDeleteMyData(l10n),
              ),
            ]),
            const SizedBox(height: 20),

            // 5. About & Support Card
            _buildSectionHeader(Icons.help_outline_rounded, isHindi ? 'ऐप विवरण और सहायता' : 'About & Support'),
            _buildSettingsCard([
              // App Version
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppTheme.forestGreen,
                title: l10n.settingsAppVersion,
                subtitle: 'Plantii v1.0.0 (DPDP 2023 Compliant • 15-10-2026)',
                trailing: null,
                onTap: null,
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // Contact Support
              _buildSettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF1967D2),
                title: l10n.settingsContactSupport,
                subtitle: '${l10n.settingsContactSupportDesc} (info@prakruty.com)',
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: _handleContactSupport,
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // Share App
              _buildSettingsTile(
                icon: Icons.share_rounded,
                iconColor: const Color(0xFFD97706),
                title: isHindi ? 'ऐप साझा करें' : 'Share App',
                subtitle: isHindi ? 'अन्य किसान साथियों के साथ प्लांटाई साझा करें' : 'Share Plantii with fellow farmers',
                trailing: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFFD97706)),
                onTap: () => _handleShareApp(isHindi),
              ),
            ]),
            const SizedBox(height: 30),

            // Plain Language Compliance Footnote
            Center(
              child: Text(
                'Prakruty Tech • Chhattisgarh, India\nAI crop doctor with zero ads & zero trackers',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedDark,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.forestGreen),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppTheme.forestGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 1.5),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: titleColor ?? AppTheme.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppTheme.mutedDark,
            height: 1.3,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
