import 'package:flutter/material.dart';

import 'app/router.dart';
import 'theme/system_theme.dart';

void main() {
  runApp(const HunterApp());
}

class HunterApp extends StatelessWidget {
  const HunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HUNTER SYSTEM',
      debugShowCheckedModeBanner: false,
      theme: SystemTheme.themeData,
      routerConfig: appRouter,
    );
  }
}
