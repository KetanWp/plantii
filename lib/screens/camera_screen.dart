import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../routes.dart';
import '../services/image_processing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_tips_sheet.dart';

/// Screen 4: Native Phone Camera Flow
/// Replaced custom in-app preview with native phone camera via image_picker.
/// Automatically presents photo tips and launches native camera or gallery.
class CameraScreen extends StatefulWidget {
  final ImagePicker? imagePicker;

  const CameraScreen({super.key, this.imagePicker});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final ImagePicker _imagePicker;
  bool _hasLaunched = false;

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePicker ?? ImagePicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLaunched) {
      _hasLaunched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchNativeCameraFlow();
      });
    }
  }

  Future<void> _launchNativeCameraFlow() async {
    final File? photoFile = await PhotoTipsSheet.show(context, imagePicker: _imagePicker);
    if (!mounted) return;

    if (photoFile != null) {
      final compressed = await ImageProcessingService.validateAndCompress(photoFile);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.loading,
        arguments: {
          'imagePath': compressed.path,
        },
      );
    } else {
      // User cancelled
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.forestGreen),
      ),
    );
  }
}
