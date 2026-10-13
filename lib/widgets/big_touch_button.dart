import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable large tap target button meeting the min 56px height requirement
/// designed for outdoor visibility and low digital literacy.
class BigTouchButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const BigTouchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTheme.minTouchTargetSize),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 28),
              const SizedBox(width: 12),
            ],
            Text(label),
          ],
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppTheme.minTouchTargetSize),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 28),
            const SizedBox(width: 12),
          ],
          Text(label),
        ],
      ),
    );
  }
}
