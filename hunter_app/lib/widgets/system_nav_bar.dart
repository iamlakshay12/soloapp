import 'package:flutter/material.dart';

import '../theme/system_theme.dart';

class SystemNavItem {
  const SystemNavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

const systemNavItems = [
  SystemNavItem('HOME', Icons.grid_view_rounded),
  SystemNavItem('LOG', Icons.edit_note_rounded),
  SystemNavItem('TRAIN', Icons.fitness_center_rounded),
  SystemNavItem('DIET', Icons.restaurant_rounded),
  SystemNavItem('PROFILE', Icons.person_outline_rounded),
];

/// Bottom SYSTEM menu: HOME · LOG · TRAIN · DIET · PROFILE.
class SystemNavBar extends StatelessWidget {
  const SystemNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SystemColors.backgroundElevated,
        border: Border(top: BorderSide(color: SystemColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SystemSpacing.sm),
          child: Row(
            children: [
              for (var i = 0; i < systemNavItems.length; i++)
                Expanded(child: _NavButton(
                  item: systemNavItems[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final SystemNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? SystemColors.primary : SystemColors.textFaint;
    return InkResponse(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            color: color,
            shadows: active
                ? const [Shadow(color: SystemColors.primary, blurRadius: 12)]
                : null,
          ),
          const SizedBox(height: SystemSpacing.xs),
          Text(item.label, style: SystemText.label.copyWith(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
