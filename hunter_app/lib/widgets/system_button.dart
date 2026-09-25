import 'package:flutter/material.dart';

import '../theme/system_theme.dart';

/// Full-width glowing SYSTEM button. [filled] = primary; otherwise outlined.
class SystemButton extends StatelessWidget {
  const SystemButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SystemRadius.md),
          boxShadow: enabled && filled
              ? const [BoxShadow(color: SystemColors.primaryGlow, blurRadius: 16)]
              : null,
        ),
        child: Material(
          color: filled ? SystemColors.primaryDim : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SystemRadius.md),
            side: const BorderSide(color: SystemColors.primary),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(SystemRadius.md),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SystemSpacing.md),
              child: Center(
                child: Text(label.toUpperCase(), style: SystemText.button),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
