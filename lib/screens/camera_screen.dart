import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../services/image_processing_service.dart';
import '../theme/app_theme.dart';

/// Screen 4: Camera flow with live guide overlay, tips banner,
/// gallery selection, validation, compression, and permission handling.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Attempts to initialize the camera hardware
  Future<void> _initializeCamera() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      final camera = _cameras[_selectedCameraIndex];
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      setState(() {
        if (e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt') {
          _errorMessage = 'permission_denied';
        } else {
          _errorMessage = e.description ?? 'Camera error occurred.';
        }
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'permission_denied';
      });
    }
  }

  /// Captures a photo using the active camera controller
  Future<void> _takePicture(Map<String, dynamic>? cropArgs) async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    try {
      setState(() => _isProcessing = true);
      final XFile photo = await _controller!.takePicture();
      await _processAndNavigate(File(photo.path), cropArgs);
    } catch (e) {
      if (mounted) {
        _showErrorNotice(AppLocalizations.of(context)!.photoNotClear);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Opens the device gallery as an alternative input
  Future<void> _pickFromGallery(Map<String, dynamic>? cropArgs) async {
    if (_isProcessing) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked == null) return;

      setState(() => _isProcessing = true);
      await _processAndNavigate(File(picked.path), cropArgs);
    } catch (e) {
      if (mounted) {
        _showErrorNotice(AppLocalizations.of(context)!.photoNotClear);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Validates photo integrity, compresses it, and navigates to the next stage
  Future<void> _processAndNavigate(File rawImage, Map<String, dynamic>? cropArgs) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final File compressedImage = await ImageProcessingService.validateAndCompress(rawImage);

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.loading,
        arguments: {
          ...?cropArgs,
          'imagePath': compressedImage.path,
        },
      );
    } on PhotoValidationException {
      if (mounted) {
        _showErrorNotice(l10n.photoNotClear);
      }
    } catch (e) {
      if (mounted) {
        _showErrorNotice(l10n.photoNotClear);
      }
    }
  }

  void _showErrorNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.severityHigh,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, dynamic>? cropArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? cropName = cropArgs?['cropName'] as String?;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          cropName != null ? l10n.selectedCrop(cropName) : l10n.cameraTitle,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Camera feed or fallback UI
            if (_isCameraInitialized && _controller != null)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              )
            else
              _buildPermissionOrUnavailableView(l10n, cropArgs),

            // Top guide tip banner (visible if camera active)
            if (_isCameraInitialized)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildTipBanner(l10n),
              ),

            // Guide Frame Viewfinder overlay (visible if camera active)
            if (_isCameraInitialized)
              Center(
                child: _buildGuideFrame(),
              ),

            // Bottom action controls (visible if camera active)
            if (_isCameraInitialized)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: _buildBottomControls(l10n, cropArgs),
              ),

            // Processing overlay during compression & validation
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.processingImage,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.highContrastDark,
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
    );
  }

  /// High contrast guide tips banner at top of the screen
  Widget _buildTipBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.highContrastDark.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wb_sunny_outlined,
            color: Color(0xFFFFD54F),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.cameraTipMoveCloser,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.cameraTipFrameLeaf,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Viewfinder guide frame overlay with high contrast corners
  Widget _buildGuideFrame() {
    return Container(
      width: 280,
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF66BB6A), // Bright green outline
          width: 3.5,
        ),
      ),
      child: Stack(
        children: [
          // Subtle leaf silhouette guide icon in center
          Center(
            child: Icon(
              Icons.eco_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  /// Big bottom controls: Shutter button & Gallery button
  Widget _buildBottomControls(AppLocalizations l10n, Map<String, dynamic>? cropArgs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery alternative button (large tap target >= 56px)
          InkWell(
            onTap: () => _pickFromGallery(cropArgs),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // Main Shutter Button (large >= 76px tap target)
          GestureDetector(
            onTap: () => _takePicture(cropArgs),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          // Flip camera toggle if multiple cameras exist
          if (_cameras.length > 1)
            InkWell(
              onTap: () {
                setState(() {
                  _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
                  _isCameraInitialized = false;
                });
                _initializeCamera();
              },
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          else
            const SizedBox(width: 58),
        ],
      ),
    );
  }

  /// Friendly permission denial or hardware unavailable screen
  Widget _buildPermissionOrUnavailableView(
    AppLocalizations l10n,
    Map<String, dynamic>? cropArgs,
  ) {
    return Container(
      color: AppTheme.earthSand,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.severityHigh, width: 2),
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                size: 64,
                color: AppTheme.severityHigh,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.cameraPermissionDenied,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.highContrastDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage != null && _errorMessage != 'permission_denied'
                  ? _errorMessage!
                  : l10n.cameraPermissionDeniedHelp,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.mutedDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),

            // Main Action: Choose from Gallery (minimum 56px height)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _pickFromGallery(cropArgs),
              icon: const Icon(Icons.photo_library, size: 26),
              label: Text(
                l10n.openGallery,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Secondary Action: Retry camera (minimum 56px height)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh, size: 26),
              label: Text(
                l10n.retry,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
