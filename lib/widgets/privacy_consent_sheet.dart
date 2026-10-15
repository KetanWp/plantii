import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/consent_service.dart';
import '../theme/app_theme.dart';

/// One-time Privacy Notice Bottom Sheet shown strictly before the user's FIRST scan.
/// Requires explicit agreement before scanning proceeds.
class PrivacyConsentSheet extends StatelessWidget {
  final ConsentService? consentService;

  const PrivacyConsentSheet({super.key, this.consentService});

  /// Displays the privacy consent bottom sheet and returns true if user agrees.
  static Future<bool> show(BuildContext context, {ConsentService? consentService}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => PrivacyConsentSheet(consentService: consentService),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final service = consentService ?? ConsentService.instance;

    return SafeArea(
      key: const ValueKey('privacy_consent_bottom_sheet'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreenSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppTheme.forestGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isHindi ? 'गोपनीयता एवं एआई जांच' : 'Privacy & AI Diagnosis',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Simple 1-2 lines in Hindi & English
            const Text(
              'Your plant photo is sent to an AI service to diagnose it. We don\'t sell your data.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'पौधे की फोटो रोग की पहचान के लिए AI सेवा को भेजी जाती है। हम आपका डेटा नहीं बेचते हैं।',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppTheme.mutedDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Privacy Policy Link
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                key: const ValueKey('privacy_policy_link'),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    isHindi ? 'गोपनीयता नीति पढ़ें →' : 'Read Privacy Policy →',
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppTheme.forestGreen,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons: "I agree" and "Cancel"
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('privacy_cancel_button'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.borderSubtle, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      isHindi ? 'रद्द करें' : 'Cancel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    key: const ValueKey('privacy_agree_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      await service.saveConsent(
                        version: ConsentService.currentPolicyVersion,
                        language: isHindi ? 'hi' : 'en',
                      );
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: Text(
                      isHindi ? 'मैं सहमत हूँ' : 'I agree',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
