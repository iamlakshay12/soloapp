import 'package:flutter/material.dart';

import '../theme/system_theme.dart';
import '../widgets/system_background.dart';
import '../widgets/system_window.dart';

/// Placeholder for tabs whose agents are not built yet.
class ModuleScreen extends StatelessWidget {
  const ModuleScreen({
    super.key,
    required this.title,
    required this.window,
    required this.notice,
  });

  final String title;
  final String window;
  final String notice;

  @override
  Widget build(BuildContext context) {
    return SystemBackground(
      child: ListView(
        padding: const EdgeInsets.all(SystemSpacing.lg),
        children: [
          Text(title, style: SystemText.title),
          const SizedBox(height: SystemSpacing.lg),
          SystemWindow(
            title: window,
            child: SystemMessage(tag: 'MODULE OFFLINE', lines: [notice]),
          ),
        ],
      ),
    );
  }
}
