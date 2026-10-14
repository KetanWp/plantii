import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/consent_service.dart';
import '../services/real_diagnosis_service.dart';
import '../theme/app_theme.dart';

/// Screen 8: Settings & Privacy Management
/// Provides access to:
/// - In-App Privacy Policy
/// - Withdraw Consent (blocks scanning)
/// - Delete My Data (authenticated Play Store compliance endpoint DELETE /account)
/// - Contact Support (mailto link)
/// - App & Policy Version info
class SettingsScreen extends StatefulWidget {
  final RealDiagnosisService? diagnosisService;
  final ConsentService? consentService;

  const SettingsScreen({
    super.key,
    this.diagnosisService,
    this.consentService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final RealDiagnosisService _diagnosisService;
  late final ConsentService _consentService;
  bool _hasConsent = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _diagnosisService = widget.diagnosisService ?? RealDiagnosisService();
    _consentService = widget.consentService ?? ConsentService.instance;
    _checkConsentStatus();
  }

  Future<void> _checkConsentStatus() async {
    final hasConsent = await _consentService.hasValidConsent();
    if (mounted) {
      setState(() {
        _hasConsent = hasConsent;
      });
    }
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

    // Show persistent progress indicator dialog
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
    // Dismiss progress dialog
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

      // Return to language screen and wipe navigation stack
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

    // Fallback: Copy to clipboard and inform user
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          children: [
            // Section 1: Privacy & Legal
            _buildSectionHeader('Privacy & Compliance'),
            _buildSettingsCard([
              // 1. Privacy Policy
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppTheme.forestGreen,
                title: l10n.settingsPrivacyPolicy,
                subtitle: l10n.settingsPrivacyPolicyDesc,
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // 2. Withdraw Consent
              _buildSettingsTile(
                icon: Icons.pause_circle_outline_rounded,
                iconColor: _hasConsent ? AppTheme.severityMedium : Colors.grey,
                title: l10n.settingsWithdrawConsent,
                subtitle: _hasConsent
                    ? l10n.settingsWithdrawConsentDesc
                    : 'Consent currently withdrawn (scanning blocked)',
                trailing: _hasConsent
                    ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Paused', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                onTap: _hasConsent ? () => _handleWithdrawConsent(l10n) : null,
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // 3. Delete My Data (Dangerous action)
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
            const SizedBox(height: 24),

            // Section 2: Support & Application Info
            _buildSectionHeader('Support & About'),
            _buildSettingsCard([
              // 4. Contact Support
              _buildSettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF1967D2),
                title: l10n.settingsContactSupport,
                subtitle: l10n.settingsContactSupportDesc,
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: _handleContactSupport,
              ),
              const Divider(height: 1, indent: 64, color: AppTheme.borderSubtle),

              // 5. App Version
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppTheme.forestGreen,
                title: l10n.settingsAppVersion,
                subtitle: 'Plantii v1.0.0 (Policy v1.0 • 14-10-2026)',
                trailing: null,
                onTap: null,
              ),
            ]),
            const SizedBox(height: 32),

            // Plain Language Compliance Footnote
            Center(
              child: Text(
                'Prakuty Tech • Chhattisgarh, India\nAI crop diagnosis with zero advertising & zero tracking',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppTheme.mutedDark,
        ),
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
