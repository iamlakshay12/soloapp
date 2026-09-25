import 'package:flutter/material.dart';

/// SYSTEM design tokens — carried over from the original Expo theme.
class SystemColors {
  static const background = Color(0xFF07050F);
  static const backgroundElevated = Color(0xFF0F0A18);
  static const surface = Color(0xFF120D1F);
  static const surfaceBorder = Color(0xFF6B21A8);
  static const primary = Color(0xFFA855F7);
  static const primaryDim = Color(0xFF7C3AED);
  static const primaryGlow = Color(0x59A855F7); // 35%
  static const headerTint = Color(0x266B21A8); // 15%
  static const divider = Color(0x40A855F7); // 25%
  static const controlDot = Color(0x73A855F7); // 45%
  static const text = Color(0xFFE9D5FF);
  static const textMuted = Color(0xFF9CA3AF);
  static const textFaint = Color(0xFF4B5563);
  static const error = Color(0xFFF87171);
}

class SystemSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class SystemRadius {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
}

class SystemText {
  static const _mono = 'SpaceMono';

  static const display = TextStyle(
    fontFamily: _mono,
    fontSize: 44,
    letterSpacing: 10,
    color: SystemColors.text,
    shadows: [Shadow(color: SystemColors.primary, blurRadius: 24)],
  );
  static const title = TextStyle(
    fontFamily: _mono,
    fontSize: 22,
    letterSpacing: 3,
    color: SystemColors.text,
  );
  static const eyebrow = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    letterSpacing: 3,
    color: SystemColors.primary,
  );
  static const label = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    letterSpacing: 1.5,
    color: SystemColors.text,
  );
  static const systemTag = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    letterSpacing: 2,
    color: SystemColors.primary,
  );
  static const body = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: SystemColors.text,
  );
  static const muted = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: SystemColors.textMuted,
  );
  static const value = TextStyle(
    fontFamily: _mono,
    fontSize: 20,
    color: SystemColors.text,
  );
  static const button = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    letterSpacing: 2,
    color: SystemColors.text,
  );
}

class SystemTheme {
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SystemColors.background,
        colorScheme: const ColorScheme.dark(
          primary: SystemColors.primary,
          secondary: SystemColors.primaryDim,
          surface: SystemColors.surface,
          onSurface: SystemColors.text,
          error: SystemColors.error,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: SystemColors.primary,
        ),
      );
}
