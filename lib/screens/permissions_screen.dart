import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes.dart';
import '../theme/app_theme.dart';
import '../widgets/big_touch_button.dart';

/// Screen: Friendly Permissions Explanation Screen (shown on first launch after language selection)
/// Explains why the app requests Camera (to take plant photos) and Location (for local weather & disease risk).
/// Buttons: "Allow" (triggers system permission dialogs) and "Skip for now".
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isRequesting = false;

  Future<void> _proceedToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  Future<void> _handleAllow() async {
    setState(() => _isRequesting = true);
    try {
      // 1. Request Camera permission
      await Permission.camera.request();
      // 2. Request Location permission
      await Permission.location.request();
    } catch (e) {
      debugPrint('PermissionsScreen: Error requesting permissions: $e');
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
        await _proceedToHome();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Text(isHindi ? 'अनुमतियां' : 'App Permissions'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Friendly header icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreenSubtle,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 38,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                isHindi ? 'बेहतर अनुभव के लिए अनुमति दें' : 'Permissions for Better Care',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                isHindi
                  ? 'Plantii को आपकी फसल की सही जांच और स्थानीय मौसम की जानकारी के लिए इन सुविधाओं की आवश्यकता है:'
                  : 'Plantii needs these features to accurately diagnose crop health and show local weather:',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Card 1: Camera Permission
              _buildPermissionCard(
                icon: Icons.camera_alt_rounded,
                iconColor: AppTheme.forestGreen,
                iconBgColor: AppTheme.leafGreenSubtle,
                title: isHindi ? 'कैमरा (Camera)' : 'Camera',
                description: isHindi
                  ? 'पौधे की पत्ती की फोटो लेने के लिए (रोग की सही पहचान हेतु)।'
                  : 'Used to take photos of plant leaves for disease diagnosis.',
              ),
              const SizedBox(height: 16),

              // Card 2: Location Permission
              _buildPermissionCard(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF1967D2),
                iconBgColor: const Color(0xFFE8F0FE),
                title: isHindi ? 'स्थान (Location)' : 'Location',
                description: isHindi
                  ? 'आपके क्षेत्र के लाइव मौसम और फसल रोग जोखिम अलर्ट हेतु।'
                  : 'To provide local weather forecasts and crop disease risk hints.',
              ),
              const SizedBox(height: 20),

              // Friendly notice: App works even if denied
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isHindi
                          ? 'यदि आप छोड़ते हैं, तो भी आप गैलरी या मैन्युअल स्थान चुनकर ऐप का उपयोग कर सकते हैं।'
                          : 'If you skip, you can still use the app by selecting photos or choosing your district manually.',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // "Allow" Button
              BigTouchButton(
                key: const ValueKey('allow_permissions_button'),
                label: _isRequesting
                  ? (isHindi ? 'प्रतीक्षा करें...' : 'Please wait...')
                  : (isHindi ? 'अनुमति दें (Allow)' : 'Allow'),
                icon: Icons.check_circle_rounded,
                isPrimary: true,
                onPressed: _isRequesting ? null : _handleAllow,
              ),
              const SizedBox(height: 14),

              // "Skip for now" Button
              BigTouchButton(
                key: const ValueKey('skip_permissions_button'),
                label: isHindi ? 'अभी छोड़ें (Skip for now)' : 'Skip for now',
                isPrimary: false,
                onPressed: _isRequesting ? null : _proceedToHome,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.cardBorderRadius,
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
