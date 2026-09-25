import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/awakening_screen.dart';
import '../screens/home_screen.dart';
import '../screens/module_screen.dart';
import '../widgets/system_nav_bar.dart';

/// Phase 0 routing. Auth-aware redirects (profile-first) arrive in phase 1.
final appRouter = GoRouter(
  initialLocation: '/awakening',
  routes: [
    GoRoute(
      path: '/awakening',
      builder: (context, state) => const AwakeningScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _TabsShell(navigationShell: navigationShell),
      branches: [
        _branch('/home', const HomeScreen()),
        _branch('/log', const ModuleScreen(
          title: 'LOG ACTIVITY',
          window: 'SYSTEM LOG',
          notice: 'Activity reporting and SYSTEM verdicts activate in phase 3.',
        )),
        _branch('/train', const ModuleScreen(
          title: 'PROTOCOL',
          window: 'PROTOCOL CHANNEL',
          notice: 'ARCHITECT channel activates in phase 5.',
        )),
        _branch('/diet', const ModuleScreen(
          title: 'DIET PROTOCOL',
          window: 'DAILY TARGETS',
          notice: 'Plan display activates once ARCHITECT issues a protocol.',
        )),
        _branch('/profile', const ModuleScreen(
          title: 'HUNTER PROFILE',
          window: 'HUNTER METRICS',
          notice: 'Registration data and ANALYZE metrics activate in phase 2.',
        )),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (context, state) => screen)],
    );

class _TabsShell extends StatelessWidget {
  const _TabsShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SystemNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
