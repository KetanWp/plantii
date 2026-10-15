import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable large tap target button meeting the min 56px height requirement.
/// Designed to grow with its text instead of clipping, supporting Hindi text
/// and scaled system fonts smoothly.
class BigTouchButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const BigTouchButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonFontSize = AppTheme.responsiveButton(context);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 24),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontSize: buttonFontSize,
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppTheme.forestDark : AppTheme.forestGreen,
              height: 1.25,
            ),
          ),
        ),
      ],
    );

    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.leafGreenAccent,
            foregroundColor: AppTheme.forestDark,
            minimumSize: const Size.fromHeight(AppTheme.minTouchTargetSize),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.buttonRadius)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          onPressed: onPressed,
          child: content,
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.forestGreen,
        minimumSize: const Size.fromHeight(AppTheme.minTouchTargetSize),
        side: const BorderSide(color: AppTheme.forestGreen, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.buttonRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: onPressed,
      child: content,
    );
  }
}
