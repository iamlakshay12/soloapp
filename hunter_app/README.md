# Hunter SYSTEM — Flutter app

Phase 0: SYSTEM theme, widgets, Awakening screen and the 5-tab shell.

## First-time setup (Windows, in this folder)

    flutter create --org com.huntersystem --platforms android,ios .
    flutter pub add go_router flutter_animate
    flutter test
    flutter run

`flutter create .` only adds missing files (android/, ios/, analysis_options.yaml, .gitignore);
it does not overwrite lib/, test/ or pubspec.yaml.
