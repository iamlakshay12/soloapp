# Architect → ANALYZE → HUNTER METRICS Design

**Date:** 2026-08-16  
**Status:** Draft for user review  
**Approach:** A — Architect-first backend scan; Profile displays persisted metrics until the hunter taps ANALYZE  
**Related:** [ARCHITECT_AGENT_SPEC.md](./ARCHITECT_AGENT_SPEC.md), [ANALYZE_SUBAGENT_SPEC.md](./ANALYZE_SUBAGENT_SPEC.md), [2026-08-01-system-architect-hierarchy-design.md](./2026-08-01-system-architect-hierarchy-design.md)

## Goal

After onboarding completes, ARCHITECT wakes with the hunter’s filled-in dossier, then ANALYZE computes metrics from that dossier. Profile shows those persisted values under **HUNTER METRICS**. Profile never auto-runs ANALYZE.

## Current gap

SYSTEM init currently computes metrics itself, then assigns Architect last. Profile calls ANALYZE on focus and paints in-memory results. Physical onboarding fields can appear while BMI/BMR/TDEE stay `—` even when `hunter_analysis` already has a row.

## Hierarchy

```
Frontend
  → SYSTEM (auth, persist, job transport)
      → ARCHITECT (seeded dossier + typed jobs)
          → ANALYZE (deterministic metrics algorithm)
```

## Lifecycle

1. Hunter finishes onboarding. SYSTEM sets `hunter_profiles.completed_at` and stores the dossier.
2. SYSTEM runs `hunter.initialize.v1`. It does not compute BMI/TDEE itself.
3. SYSTEM assigns one active ARCHITECT and seeds `architect_brief` from the full dossier.
4. ARCHITECT emits exactly one `hunter.analyze.v1` job with `source: initialization`.
5. SYSTEM executes ANALYZE. ANALYZE runs `computeHunterMetrics` / destiny from the Architect-supplied dossier.
6. SYSTEM persists `hunter_analysis`, `hunter_destiny`, `hunter_rules`, `hunter_progression`, and a snapshot. ARCHITECT brief Assessment / Last Event is updated from those results.
7. SYSTEM marks the hunter `initialized`.
8. Profile opens HUNTER METRICS by reading the persisted row. No ANALYZE call.
9. Recalculation: hunter edits physical fields on Profile, then taps ANALYZE. SYSTEM saves the profile, ARCHITECT emits `hunter.analyze.v1` with `source: profile_update`, ANALYZE overwrites `hunter_analysis`, Profile refreshes from that row.

## Ownership

| Layer | Owns | Must not |
|--------|------|----------|
| SYSTEM | Auth, onboarding persist, Architect assignment, ANALYZE execution, hunter-scoped reads/writes | Training strategy; inventing metrics |
| ARCHITECT | Seed brief from dossier; issue allowlisted ANALYZE jobs; ingest results into brief | Direct Supabase; client-side XP/rank; inventing BMI/TDEE |
| ANALYZE | Deterministic metrics and starting-rank destiny from dossier facts | Running on Profile focus; running on weekly check-in; UI routing |
| Profile | Display persisted HUNTER METRICS; edit physical fields; explicit ANALYZE button | Auto-scan; calling ANALYZE without a field change |

## Profile UI

Profile stays one screen.

1. **HUNTER STATUS** — rank, level, objective. Read-only. Rank/level come from `hunter_progression`, not from ANALYZE on later visits.
2. **PHYSICAL DATA** — gender, age, height, weight, target weight, training days. Editable after the first persisted scan. Unsaved edits do not change HUNTER METRICS.
3. **HUNTER METRICS** — rename of the current `SYSTEM METRICS` window. Same rows: BMI, BMI category, body fat estimate, lean mass, FFMI, BMR, TDEE, calorie target, protein target, target delta, estimated weeks, difficulty, progress. Values come only from persisted `hunter_analysis`. Show `—` until the first scan row exists.
4. **ANALYZE button** — enabled only when at least one physical field differs from the last saved scan inputs. Tap: validate → SYSTEM saves profile → ARCHITECT requests ANALYZE → Profile reloads persisted metrics. Disabled / idle otherwise.
5. **RETRY ANALYZE** — shown only when Architect is assigned and `hunter_analysis` is still missing (first-scan failure). Disappears after the first persisted row exists.
6. **Weekly check-in panel** — removed. Weight changes go through PHYSICAL DATA + ANALYZE.

## Data flow

| Event | Input | Output |
|-------|--------|--------|
| Init | Onboarding dossier via SYSTEM | Architect assigned + seeded; ANALYZE persists metrics; hunter initialized |
| Profile open | `hunter.architect.get.v1` | Persisted profile + HUNTER METRICS. No ANALYZE dispatch |
| Recalc | `hunter.architect.metrics.v1` with edited physical fields | Saved profile; ANALYZE `profile_update`; new `hunter_analysis`; envelope with metrics |
| LLM unavailable | Same dossier | Template brief + ANALYZE still runs. `usedLlm` may be false. Metrics still algorithmic |

Authoritative facts live in Postgres (`hunter_profiles`, `hunter_analysis`, `hunter_progression`). `architect_brief` is a living summary. If brief and dossier disagree, the dossier wins and the brief is corrected on the next Architect update.

Profile loads persisted HUNTER METRICS through SYSTEM by calling `hunter.architect.get.v1`, which returns the persisted analysis row and must not dispatch ANALYZE. The ANALYZE button calls `hunter.architect.metrics.v1` with the edited physical fields. SYSTEM saves the profile, Architect emits ANALYZE, SYSTEM executes it, and the envelope returns the new persisted metrics.

## ANALYZE algorithm

Keep the existing `computeHunterMetrics` / `computeHunterDestiny` algorithm. ARCHITECT does not invent numeric metrics. ANALYZE never grants XP or later rank promotions.

First scan `source` is `initialization`. Button recalculation `source` is `profile_update`.

## Idle rules

- Opening Home, Profile, Train, or Diet does not start ANALYZE.
- Weekly automatic ANALYZE is removed.
- ANALYZE runs only at init (Architect’s first job), on RETRY ANALYZE when no row exists, or on the Profile ANALYZE button after a physical-field change.

## Errors

| Failure | Behavior |
|---------|----------|
| Onboarding incomplete | Do not assign Architect. Do not run ANALYZE. Profile remains gated. |
| Architect assignment fails | Init fails. Do not mark `initialized`. Retry init. |
| First ANALYZE fails after Architect is assigned | Architect stays active. HUNTER METRICS shows `—` and a SYSTEM error. Show RETRY ANALYZE until a row exists. |
| Invalid edited numbers | Do not save. Do not dispatch ANALYZE. Show a field error. |
| Recalc ANALYZE fails | Keep last persisted HUNTER METRICS. Show the error. Do not blank the panel. |
| LLM unavailable | Seed brief from dossier and still dispatch ANALYZE. |

## Isolation

- Every read/write resolves `clerk_user_id` → `hunters.id` from the verified Clerk JWT.
- Client-supplied `hunter_id` is ignored.
- Hunter A cannot read or write hunter B’s brief, profile, or HUNTER METRICS.

## Non-goals

- Fine-tuning / training the Architect model
- ANALYZE running during each onboarding step
- Weekly automatic ANALYZE
- Architect LLM inventing BMI/TDEE
- New specialist agents (LOG, MISSION, RANK promotions)

## Tests

- Init order is Architect assign → ANALYZE job → persisted `hunter_analysis` → `initialized`
- Profile GET returns persisted BMI/BMR/TDEE without dispatching ANALYZE
- ANALYZE button is disabled until a physical field changes
- Recalc overwrites `hunter_analysis` and Profile refreshes from that row
- First-scan failure shows RETRY ANALYZE; success hides it
- Hunter A cannot read hunter B metrics
- LLM-off still produces metrics via the algorithm
- Weekly check-in panel is gone from Profile

## Mapping from today

| Today | Target |
|--------|--------|
| `system-initialize` computes metrics then assigns Architect | Assign Architect first; ANALYZE writes metrics |
| Profile `useProfileAnalysis` calls `hunter.analyze.v1` on focus | Profile reads persisted metrics only |
| Window title `SYSTEM METRICS` | `HUNTER METRICS` |
| Weekly weight check-in auto-ANALYZE | Removed; edit weight + ANALYZE button |
| Empty BMI despite `hunter_analysis` row | Profile paints persisted row on open |
