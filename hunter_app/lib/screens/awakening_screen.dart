import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/system_theme.dart';
import '../widgets/system_background.dart';
import '../widgets/system_button.dart';
import '../widgets/system_window.dart';

class AwakeningScreen extends StatelessWidget {
  const AwakeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SystemBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SystemSpacing.lg),
            child: Column(
              children: [
                const Text('SYSTEM', style: SystemText.display)
                    .animate()
                    .fadeIn(duration: 900.ms)
                    .shimmer(delay: 900.ms, duration: 1400.ms, color: SystemColors.primary),
                const SizedBox(height: SystemSpacing.sm),
                const Text('HUNTER PROGRESSION PROTOCOL', style: SystemText.eyebrow)
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 700.ms),
                const SizedBox(height: SystemSpacing.xl),
                SystemWindow(
                  title: 'SYSTEM INITIALIZATION',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SystemMessage(lines: [
                        'A dormant potential has been detected.',
                        'Do you accept the Awakening?',
                      ]),
                      const SizedBox(height: SystemSpacing.lg),
                      SystemButton(
                        label: 'Accept Awakening',
                        onPressed: () => context.go('/home'),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: SystemSpacing.xl),
                Text(
                  'YOUR LEVEL 100 AWAITS',
                  style: SystemText.label.copyWith(color: SystemColors.textFaint),
                ).animate().fadeIn(delay: 1400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
