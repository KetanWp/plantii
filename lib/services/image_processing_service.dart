import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Custom exception thrown when a photo fails clarity, size, or integrity checks.
class PhotoValidationException implements Exception {
  final String message;
  const PhotoValidationException(this.message);

  @override
  String toString() => message;
}

/// Service responsible for validating photo clarity/size and compressing
/// images for low-RAM devices and patchy network conditions.
class ImageProcessingService {
  static const int minSizeBytes = 10 * 1024; // 10 KB minimum
  static const int minDimensionPx = 150; // Minimum 150x150 resolution
  static const int maxDimensionPx = 1024; // Scale down to max 1024 for low RAM
  static const int jpegQuality = 75; // Optimal balance for leaf disease clarity

  /// Validates that an image file is non-empty, above minimum dimension thresholds,
  /// and compresses it down to optimize RAM and upload speed.
  /// Throws [PhotoValidationException] if the image is too tiny, blank, or unreadable.
  static Future<File> validateAndCompress(File rawFile) async {
    // 1. File presence and raw byte length check
    if (!await rawFile.exists()) {
      throw const PhotoValidationException('Photo file does not exist');
    }

    final int fileLength = await rawFile.length();
    if (fileLength < minSizeBytes) {
      throw const PhotoValidationException('Photo is not clear, please try again');
    }

    // 2. Decode image in isolate or compute to prevent UI freezing on low-end phones
    final Uint8List rawBytes = await rawFile.readAsBytes();

    final Uint8List? compressedBytes = await compute(_decodeAndCompress, rawBytes);

    if (compressedBytes == null) {
      throw const PhotoValidationException('Photo is not clear, please try again');
    }

    // 3. Save compressed image to temporary file
    final String targetPath =
        '${rawFile.parent.path}/crop_${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
    final File compressedFile = File(targetPath);
    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }

  /// Top-level helper run via compute isolate for responsive UI on low-end devices
  static Uint8List? _decodeAndCompress(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    // Check minimum dimensions to reject accidental blurry or thumbnail photos
    if (decoded.width < minDimensionPx || decoded.height < minDimensionPx) {
      return null;
    }

    // Downscale if image is larger than 1024px along the longest edge
    img.Image processed = decoded;
    if (decoded.width > maxDimensionPx || decoded.height > maxDimensionPx) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(decoded, width: maxDimensionPx);
      } else {
        processed = img.copyResize(decoded, height: maxDimensionPx);
      }
    }

    // Compress to JPEG format with 75% quality
    final List<int> jpegBytes = img.encodeJpg(processed, quality: jpegQuality);
    return Uint8List.fromList(jpegBytes);
  }
}
