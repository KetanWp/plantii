import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/consent_service.dart';
import '../theme/app_theme.dart';
import '../widgets/big_touch_button.dart';

/// Screen presented on first launch (after language selection) or when policy version changes.
/// Explains key data practices and requests explicit farmer consent before scanning.
class ConsentScreen extends StatefulWidget {
  final VoidCallback? onConsentGranted;
  final bool isModal;

  const ConsentScreen({
    super.key,
    this.onConsentGranted,
    this.isModal = false,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _isSaving = false;

  Future<void> _handleAgree() async {
    setState(() => _isSaving = true);
    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      await ConsentService.instance.saveConsent(language: languageCode);
    } catch (e) {
      debugPrint('ConsentScreen: Error saving consent: $e');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (widget.onConsentGranted != null) {
      widget.onConsentGranted!();
    } else if (widget.isModal && Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  void _handleDecline(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.severityMedium, size: 28),
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
              l10n.consentReview,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestGreen,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: AppTheme.highContrastDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              if (widget.isModal && Navigator.canPop(context)) {
                Navigator.pop(context, false);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
            child: Text(
              l10n.backToHome,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final consentPoints = [
      (
        icon: Icons.psychology_alt_rounded,
        iconColor: AppTheme.forestGreen,
        text: l10n.consentLine1,
      ),
      (
        icon: Icons.history_edu_rounded,
        iconColor: const Color(0xFF1967D2),
        text: l10n.consentLine2,
      ),
      (
        icon: Icons.security_rounded,
        iconColor: AppTheme.forestGreen,
        text: l10n.consentLine3,
      ),
      (
        icon: Icons.support_agent_rounded,
        iconColor: const Color(0xFFD97706),
        text: l10n.consentLine4,
      ),
      (
        icon: Icons.delete_outline_rounded,
        iconColor: AppTheme.severityHigh,
        text: l10n.consentLine5,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Text(l10n.consentTitle),
        automaticallyImplyLeading: widget.isModal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.forestHeaderGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.consentTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.consentSubtitle,
                            style: const TextStyle(
                              color: AppTheme.textLightMuted,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5 Clear consent items with large text and distinct icons
              ...consentPoints.map((point) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: point.iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(point.icon, color: point.iconColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          point.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.highContrastDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Link to full Privacy Policy
              Center(
                child: TextButton.icon(
                  key: const ValueKey('view_full_privacy_policy_btn'),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                  },
                  icon: const Icon(Icons.launch_rounded, size: 20, color: AppTheme.forestGreen),
                  label: Text(
                    l10n.readFullPrivacyPolicy,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.forestGreen,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons: I Agree & No Thanks
              BigTouchButton(
                key: const ValueKey('consent_agree_button'),
                icon: Icons.check_circle_rounded,
                label: _isSaving ? '...' : l10n.consentAgree,
                isPrimary: true,
                onPressed: _isSaving ? null : () => _handleAgree(),
              ),
              const SizedBox(height: 14),
              BigTouchButton(
                key: const ValueKey('consent_decline_button'),
                icon: Icons.close_rounded,
                label: l10n.consentDecline,
                isPrimary: false,
                onPressed: _isSaving ? null : () => _handleDecline(l10n),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
