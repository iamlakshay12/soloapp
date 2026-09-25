import 'package:flutter/material.dart';

import '../theme/system_theme.dart';
import '../widgets/rank_badge.dart';
import '../widgets/system_background.dart';
import '../widgets/system_progress_bar.dart';
import '../widgets/system_stat_card.dart';
import '../widgets/system_window.dart';

/// Phase 0: static starting state (Level 1, F-rank, 0 XP).
/// Real values come from Supabase once progression is built.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SystemBackground(
      child: ListView(
        padding: const EdgeInsets.all(SystemSpacing.lg),
        children: [
          const Text('SYSTEM STATUS', style: SystemText.eyebrow),
          const SizedBox(height: SystemSpacing.sm),
          Row(
            children: [
              const Expanded(
                child: Text('LEVEL 1 — F-CLASS HUNTER', style: SystemText.title),
              ),
              const SizedBox(width: SystemSpacing.md),
              const RankBadge(rank: 'F', size: 56),
            ],
          ),
          const SizedBox(height: SystemSpacing.lg),
          const SystemProgressBar(value: 0, max: 500, label: 'Experience'),
          const SizedBox(height: SystemSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: SystemSpacing.md,
            crossAxisSpacing: SystemSpacing.md,
            childAspectRatio: 1.6,
            children: const [
              SystemStatCard(label: 'Total EXP', value: '0'),
              SystemStatCard(label: 'Streak', value: '0 D'),
              SystemStatCard(label: 'Discipline', value: '—'),
              SystemStatCard(label: 'Levels to 100', value: '99'),
            ],
          ),
          const SizedBox(height: SystemSpacing.lg),
          const SystemWindow(
            title: 'Daily Missions',
            child: SystemMessage(
              tag: 'SYSTEM NOTICE',
              lines: ['Mission engine offline. Missions will be assigned after registration.'],
            ),
          ),
        ],
      ),
    );
  }
}
