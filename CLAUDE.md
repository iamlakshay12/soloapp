# Project Hunter SYSTEM — context for Claude

Solo Leveling–inspired fitness app. The user is a **Hunter**; the app is the **SYSTEM** — cold,
mechanical, evaluates real training with verdicts, XP, ranks F→SS. Never cheerleading
("SYSTEM NOTICE", "VERDICT", "PENALTY APPLIED" — never "Good job!").

## Source of truth
- Product intent: `docs/PRODUCT_HUNTER_SYSTEM.md` (§2.3 stack section is outdated — see below)
- Constitution / game rules: `docs/superpowers/specs/PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md`
- Agent names: `docs/superpowers/specs/SYSTEM_AGENTS_REGISTRY.md` (SYSTEM → ARCHITECT → specialists)
- `_archive/expo-clerk-setup-2026-08/` = old Expo + Clerk + Supabase build. Reference only; do not revive.
  Worth porting: `supabase/functions/_shared/compute-hunter-metrics.ts`,
  `compute-hunter-destiny.ts`, ARCHITECT prompt in `_shared/architect/llm.ts`.

## Stack (decided 2026-09-26 — rebuild from scratch)
- **Flutter** app in `hunter_app/` (Dart). Targets Android + iOS. No Expo.
- **Supabase only**: Supabase Auth (no Clerk), Postgres with RLS on `auth.uid()`, Edge Functions (Deno) for
  SYSTEM / ARCHITECT / specialists. LLM keys live only in Supabase secrets.
- Routing `go_router`; animation `flutter_animate`; state: Riverpod (from phase 1).
- iOS builds via Codemagic (user is on Windows, no Mac). Android builds locally.
- Rule: frontend is presentation only — no XP, rank, verdict or calorie math on the client.

## Design system (`hunter_app/lib/theme/system_theme.dart`)
Background #07050F, surface #120D1F, border #6B21A8, primary #A855F7, text #E9D5FF,
font SpaceMono (bundled) in UPPERCASE with wide tracking. Core widget: `SystemWindow`
(glowing panel, terminal-style header). Tabs: HOME · LOG · TRAIN · DIET · PROFILE.

## Build phases
0. Foundation — theme, widgets, Awakening screen, 5-tab shell ✅ written (verify `flutter run`)
1. Identity — Supabase Auth, `hunters` + `hunter_profiles` + RLS, profile-first routing
2. Awakening + ANALYZE — 9-step onboarding, port metrics, analysis reveal
3. Core loop — LOG + EVALUATE → verdict → XP
4. MISSION, RANK, PENALTY
5. ARCHITECT — per-hunter brief, Train·Diet chat, plan on Diet tab
6. Launch — Play closed test (12 testers × 14 days) + TestFlight → stores

## Open decisions
Sign-in methods at launch · final app name / bundle ID (placeholder `com.huntersystem`) ·
LLM provider · Train/Diet unlock timing.

## Environment notes
- Windows PC, project at `C:\dev\hunter-system` (moved out of OneDrive).
- Git: repo root = this folder, branch `main`, remote https://github.com/iamlakshay12/soloapp.
  `_archive/` is gitignored (has its own git history; kept locally for reference).
- Full plan doc: "Hunter SYSTEM — Flutter Rebuild & Deployment Plan" (Claude Docs).
