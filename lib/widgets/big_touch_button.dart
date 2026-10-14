import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable large tap target button meeting the min 56px height requirement
/// designed for outdoor visibility, full stadium curvature, and Hindi text safety.
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
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 26),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppTheme.forestDark : AppTheme.forestGreen,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            shape: const StadiumBorder(),
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
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: onPressed,
      child: content,
    );
  }
}
