import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/image_processing_service.dart';
import '../theme/app_theme.dart';
import 'camera_permission_helper.dart';

/// Bottom sheet displaying photo clarity tips and allowing farmer to
/// choose between Phone's Native Camera and Gallery.
class PhotoTipsSheet extends StatefulWidget {
  final ImagePicker? imagePicker;

  const PhotoTipsSheet({super.key, this.imagePicker});

  /// Shows the photo tips sheet and returns compressed photo File or null if cancelled
  static Future<File?> show(BuildContext context, {ImagePicker? imagePicker}) {
    return showModalBottomSheet<File?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => PhotoTipsSheet(imagePicker: imagePicker),
    );
  }

  @override
  State<PhotoTipsSheet> createState() => _PhotoTipsSheetState();
}

class _PhotoTipsSheetState extends State<PhotoTipsSheet> {
  late final ImagePicker _picker;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
  }

  Future<void> _pickImage(ImageSource source) async {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    // Check camera permission first to guarantee image_picker camera never crashes on denied permission
    if (source == ImageSource.camera) {
      final hasPermission = await CameraPermissionHelper.ensureCameraPermission(context);
      if (!hasPermission) {
        return;
      }
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        // User cancelled gracefully - no crash
        debugPrint('PhotoTipsSheet: User cancelled image picking.');
        return;
      }

      setState(() => _isProcessing = true);

      // Validate & Compress photo
      final rawFile = File(pickedFile.path);
      final compressed = await ImageProcessingService.validateAndCompress(rawFile);

      if (!mounted) return;
      Navigator.pop(context, compressed);
    } on PlatformException catch (e) {
      debugPrint('PhotoTipsSheet: PlatformException: $e');
      if (!mounted) return;
      final isPermissionError = e.code.toLowerCase().contains('permission') ||
          e.message?.toLowerCase().contains('permission') == true;
      final message = isPermissionError
          ? (isHindi
              ? 'कैमरा या गैलरी की अनुमति अस्वीकार है। कृपया सेटिंग्स में अनुमति दें।'
              : 'Permission denied. Please grant camera/storage access in settings.')
          : (isHindi
              ? 'फोटो लेने में समस्या आई: ${e.message ?? ""}'
              : 'Unable to capture photo: ${e.message ?? ""}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.severityHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: isPermissionError
              ? SnackBarAction(
                  label: isHindi ? 'सेटिंग्स' : 'Settings',
                  textColor: Colors.yellowAccent,
                  onPressed: () {
                    openAppSettings();
                  },
                )
              : null,
        ),
      );
    } on PhotoValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHindi
                ? 'फोटो स्पष्ट नहीं है। कृपया पत्ती की साफ फोटो लें।'
                : e.message,
          ),
          backgroundColor: AppTheme.severityMedium,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('PhotoTipsSheet: General error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHindi
                ? 'फोटो लोड करने में त्रुटि हुई। कृपया पुनः प्रयास करें।'
                : 'An error occurred while selecting the photo. Please retry.',
          ),
          backgroundColor: AppTheme.severityHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return SafeArea(
      key: const ValueKey('photo_tips_bottom_sheet'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreenSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_enhance_rounded,
                    color: AppTheme.forestGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'पत्ती की सही फोटो लें' : 'How to Take a Good Photo',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        isHindi ? 'सटीक एआई जांच के लिए सुझाव' : 'Quick tips for accurate diagnosis',
                        style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Small Photo Tips Cards
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.creamBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildTipRow(
                    Icons.center_focus_strong_rounded,
                    isHindi ? 'पत्ती के करीब जाएं (15–20 सेमी)' : 'Move closer (15–20 cm) to the leaf',
                  ),
                  const SizedBox(height: 10),
                  _buildTipRow(
                    Icons.wb_sunny_outlined,
                    isHindi ? 'छाया और चकाचौंध से बचें, साफ रोशनी में लें' : 'Avoid heavy shadows and direct glare',
                  ),
                  const SizedBox(height: 10),
                  _buildTipRow(
                    Icons.check_circle_outline_rounded,
                    isHindi ? 'रोग के धब्बों पर स्पष्ट फोकस रखें' : 'Keep infected spots in sharp focus',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.forestGreen),
                ),
              )
            else ...[
              // Primary button: Open Phone's Native Camera
              ElevatedButton.icon(
                key: const ValueKey('open_camera_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 24),
                label: Text(
                  isHindi ? 'कैमरा खोलें (फोटो लें)' : 'Open Camera (Take Photo)',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 12),

              // Secondary button: Choose from Gallery
              OutlinedButton.icon(
                key: const ValueKey('open_gallery_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.forestGreen, width: 1.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.photo_library_outlined, size: 22),
                label: Text(
                  isHindi ? 'गैलरी से चुनें' : 'Choose from Gallery',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String tipText) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.forestGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tipText,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
