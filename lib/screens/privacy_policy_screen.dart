import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Screen displaying the complete, editable Privacy Policy
/// Loaded dynamically from assets/privacy_policy.json so text can be updated
/// without code recompilation.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Map<String, dynamic>? _policyData;
  bool _isLoading = true;
  String? _selectedLang; // 'hi' or 'en'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLang ??=
        Localizations.localeOf(context).languageCode == 'hi' ? 'hi' : 'en';
    _loadPolicyAsset();
  }

  Future<void> _loadPolicyAsset() async {
    try {
      final jsonStr = await DefaultAssetBundle.of(context)
          .loadString('assets/privacy_policy.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _policyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PrivacyPolicyScreen: Error loading assets/privacy_policy.json: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = _selectedLang == 'hi';
    final langKey = isHindi ? 'hi' : 'en';

    final langData = _policyData?[langKey] as Map<String, dynamic>?;
    final String title = langData?['title'] as String? ??
        (isHindi ? 'गोपनीयता नीति' : 'Privacy Policy');
    final String summary = langData?['summary'] as String? ?? '';
    final List<dynamic> sections = langData?['sections'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.forestDark,
        foregroundColor: Colors.white,
        title: Text(
          isHindi ? 'गोपनीयता नीति' : 'Privacy Policy',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.forestGreen),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // High-contrast language selector with clearly visible selected state
                    Container(
                      key: const ValueKey('privacy_policy_lang_selector'),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              key: const ValueKey('privacy_lang_hi'),
                              onTap: () => setState(() => _selectedLang = 'hi'),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: isHindi ? AppTheme.forestGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isHindi) ...[
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      'हिन्दी (Hindi)',
                                      style: TextStyle(
                                        color: isHindi ? Colors.white : AppTheme.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              key: const ValueKey('privacy_lang_en'),
                              onTap: () => setState(() => _selectedLang = 'en'),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: !isHindi ? AppTheme.forestGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!isHindi) ...[
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      'English',
                                      style: TextStyle(
                                        color: !isHindi ? Colors.white : AppTheme.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header card with company and effective date
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.forestHeaderGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${isHindi ? "प्रभावी तिथि" : "Effective Date"}: 14-10-2026 • v1.0',
                                      style: const TextStyle(
                                        color: Color(0xFFE0EAE3),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (summary.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                summary,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Plain-language highlight note for AI processing & zero photo storage
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.forestGreen, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.cloud_done_rounded, color: AppTheme.forestGreen, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isHindi
                                  ? 'विशेष ध्यान: आपके पौधे की फोटो रोग विश्लेषण के लिए सुरक्षित रूप से गूगल जेमिनी एआई द्वारा प्रोसेस की जाती है। यह फोटो हमारे बैकएंड सर्वर पर कभी स्टोर नहीं होती।'
                                  : 'Key Note: Your plant leaf photo is processed in-memory by Google Gemini AI for diagnosis. It is never stored on our backend servers.',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.forestGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic sections (Dark text on clean white card for maximum outdoor contrast)
                    ...sections.map((section) {
                      final sec = section as Map<String, dynamic>;
                      final secTitle = sec['title'] as String? ?? '';
                      final secContent = sec['content'] as String? ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              secTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.forestGreen,
                                height: 1.3,
                              ),
                            ),
                            const Divider(height: 20, thickness: 1, color: Color(0xFFEEEEEE)),
                            Text(
                              secContent,
                              style: const TextStyle(
                                fontSize: 15.5,
                                color: AppTheme.textDark,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
