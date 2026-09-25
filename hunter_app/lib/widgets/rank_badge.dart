import 'package:flutter/material.dart';

import '../theme/system_theme.dart';

/// Rank badge F → SS. Higher ranks glow harder.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, this.size = 72});

  final String rank;
  final double size;

  static const _order = ['F', 'E', 'D', 'C', 'B', 'A', 'S', 'SS'];

  @override
  Widget build(BuildContext context) {
    final tier = _order.indexOf(rank.toUpperCase()).clamp(0, _order.length - 1);
    final glow = 8.0 + tier * 4;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SystemColors.surface,
        borderRadius: BorderRadius.circular(SystemRadius.lg),
        border: Border.all(color: SystemColors.primary, width: 1.5),
        boxShadow: [BoxShadow(color: SystemColors.primaryGlow, blurRadius: glow)],
      ),
      child: Text(
        rank.toUpperCase(),
        style: SystemText.display.copyWith(fontSize: size * 0.4, letterSpacing: 2),
      ),
    );
  }
}
