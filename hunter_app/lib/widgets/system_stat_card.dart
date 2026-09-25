import 'package:flutter/material.dart';

import '../theme/system_theme.dart';

class SystemStatCard extends StatelessWidget {
  const SystemStatCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SystemSpacing.md),
      decoration: BoxDecoration(
        color: SystemColors.surface,
        borderRadius: BorderRadius.circular(SystemRadius.md),
        border: Border.all(color: SystemColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: SystemText.eyebrow),
          const SizedBox(height: SystemSpacing.sm),
          Text(value, style: SystemText.value),
        ],
      ),
    );
  }
}
