import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/app_theme.dart';

/// Legacy Crop Selection Screen - Bypassed as crops are now auto-identified by AI vision.
/// Automatically forwards to camera flow to prevent broken navigation links.
class CropSelectionScreen extends StatefulWidget {
  const CropSelectionScreen({super.key});

  @override
  State<CropSelectionScreen> createState() => _CropSelectionScreenState();
}

class _CropSelectionScreenState extends State<CropSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.camera);
      }
    });
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
