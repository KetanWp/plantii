import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Hero circular scan button with a subtle concentric ring
/// Designed for low-literacy clarity and immediate primary action recognition.
class CircularScanButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const CircularScanButton({
    super.key,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Subtle concentric ring
              border: Border.all(
                color: AppTheme.leafGreenAccent.withValues(alpha: 0.35),
                width: 6,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E7ED957),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.leafGreenAccent,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x280E1712),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    splashColor: AppTheme.forestDark.withValues(alpha: 0.15),
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_rounded,
                          size: 46,
                          color: AppTheme.forestDark,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forestDark,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
