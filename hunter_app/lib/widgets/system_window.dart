import 'package:flutter/material.dart';

import '../theme/system_theme.dart';

/// Terminal-style SYSTEM window: glowing border, header with dot + title + controls.
class SystemWindow extends StatelessWidget {
  const SystemWindow({
    super.key,
    this.title = 'SYSTEM',
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SystemColors.surface,
        borderRadius: BorderRadius.circular(SystemRadius.lg),
        border: Border.all(color: SystemColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(color: SystemColors.primaryGlow, blurRadius: 18),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SystemRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SystemSpacing.md,
                vertical: SystemSpacing.sm + 2,
              ),
              decoration: const BoxDecoration(
                color: SystemColors.headerTint,
                border: Border(bottom: BorderSide(color: SystemColors.divider)),
              ),
              child: Row(
                children: [
                  const _Dot(size: 8, color: SystemColors.primary, glow: true),
                  const SizedBox(width: SystemSpacing.sm),
                  Expanded(
                    child: Text(title.toUpperCase(), style: SystemText.label),
                  ),
                  for (var i = 0; i < 3; i++) ...[
                    const SizedBox(width: 6),
                    const _Dot(size: 6, color: SystemColors.controlDot),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SystemSpacing.md),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// The small "SYSTEM" / "SYSTEM NOTICE" line plus a message, used inside windows.
class SystemMessage extends StatelessWidget {
  const SystemMessage({super.key, this.tag = 'SYSTEM', required this.lines});

  final String tag;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tag, style: SystemText.systemTag),
        const SizedBox(height: SystemSpacing.sm),
        for (final line in lines) ...[
          Text(line, style: SystemText.body),
          const SizedBox(height: SystemSpacing.xs),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color, this.glow = false});

  final double size;
  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow ? [BoxShadow(color: color, blurRadius: 6)] : null,
      ),
    );
  }
}
