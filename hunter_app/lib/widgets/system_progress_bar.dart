import 'package:flutter/material.dart';

import '../theme/system_theme.dart';

/// Thin glowing EXP-style bar.
class SystemProgressBar extends StatelessWidget {
  const SystemProgressBar({
    super.key,
    required this.value,
    required this.max,
    this.label,
  });

  final num value;
  final num max;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: SystemSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(label!.toUpperCase(), style: SystemText.label)),
                Text('$value / $max', style: SystemText.label),
              ],
            ),
          ),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: SystemColors.backgroundElevated,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: SystemColors.divider),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [SystemColors.primaryDim, SystemColors.primary],
                ),
                boxShadow: const [
                  BoxShadow(color: SystemColors.primaryGlow, blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
