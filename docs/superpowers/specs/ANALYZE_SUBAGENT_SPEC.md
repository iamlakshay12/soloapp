# ANALYZE Subagent Specification

> **Registry:** [SYSTEM_AGENTS_REGISTRY.md](./SYSTEM_AGENTS_REGISTRY.md) — all agent names in one place.

---

## Agent Identity

| Field | Value |
|-------|-------|
| **You say** | **ANALYZE** |
| **Agent ID** | `analyze` |
| **Display name** | ANALYZE Agent |
| **Type** | Child agent (under ARCHITECT; via SYSTEM) |
| **Pillar** | Evolution |
| **Status** | **Live** |
| **Edge function** | `analyze-hunter` |
| **Endpoint** | `POST /functions/v1/analyze-hunter` |
| **Spec file** | `ANALYZE_SUBAGENT_SPEC.md` |
| **Code** | `supabase/functions/analyze-hunter/` |
| **Mobile lib** | `apps/mobile/lib/run-hunter-analysis.ts` |
| **Mobile hook** | `apps/mobile/hooks/useProfileAnalysis.ts` |

---

## Related Agents (Do Not Overlap)

| Agent | Relationship to ANALYZE |
|-------|------------------------|
| **SYSTEM** | Invokes ANALYZE; enforces hunter-scoped data access |
| **ARCHITECT** | May request ANALYZE via SYSTEM; consumes results into brief |
| **ORCHESTRATOR** *(legacy)* | Renamed to ARCHITECT |
| **EVALUATE** | Will use ANALYZE metrics as context for verdicts *(planned)* |
| **RANK** | Owns rank promotion after init; ANALYZE assigns **starting rank** only |
| **MISSION** | Will use calorie/protein targets from ANALYZE rules *(planned)* |
| **LOG** | Submits actions; does not recalculate metrics |
| **TRAIN** / **DIET** | Consume targets set by ANALYZE via `hunter_rules` |

---

## Purpose

First live child agent under **ARCHITECT** (invoked through **SYSTEM**). Processes hunter biometric
data, defines each Hunter's **personal S-Rank** and **starting rank**, and
recalculates guidance metrics.

From the Bible (Evolution pillar): body composition, performance trends,
recovery signals, goal milestones.

---

## Responsibilities

- Compute BMI, BMR, TDEE, body fat estimate, lean mass, FFMI
- Derive calorie and protein targets from objective / Ascension Path
- **Define personal S-Rank** from Hunter's stated goal + biometrics
- **Assign starting rank (E/D/C)** at initialization from baseline + goal quality
- Track progress toward target weight
- Recalibrate `hunter_rules` when stats change
- Store historical snapshots for trend analysis
- Return SYSTEM verdict on profile scan (mechanical tone)

---

## Does NOT

- Change rank / XP / level after initialization (**RANK** / **EVALUATE** agents own ongoing promotion)
- Generate daily quests (**MISSION** agent)
- Coach or motivate the user (SYSTEM personality §14)

---

## Trigger Points

| Source | When |
|--------|------|
| `initialization` | **ORCHESTRATOR** runs at end of onboarding |
| `weekly_update` | Hunter submits new weight on Profile screen |
| `profile_update` | Profile fields change post-init; Profile tab auto-scan |

---

## Tables

| Table | Purpose |
|-------|---------|
| `hunter_analysis` | Current metrics (single row per hunter, upserted) |
| `hunter_destiny` | Personal S-Rank definition, starting rank, journey summary |
| `hunter_profiles.personal_goal` | Hunter-declared goal (required before init) |
| `hunter_weekly_stats` | Weekly weight entries |
| `hunter_analysis_snapshots` | Historical JSON snapshots |
| `hunter_rules` | Patches `daily_calorie_target`, `daily_protein_minimum_g` |

---

## Personal S-Rank & Starting Rank

At initialization, ANALYZE reads `hunter_profiles.personal_goal` (min 15 chars)
and computes a unique destiny via `compute-hunter-destiny.ts`:

| Output | Description |
|--------|-------------|
| `s_rank_definition` | Text criteria for this Hunter's S-Rank attainment |
| `s_rank_criteria` | JSON: target weight, body fat %, evolution weeks, etc. |
| `starting_rank` | E, D, or C — baseline from biometrics + goal quality |
| `starting_rank_reason` | SYSTEM explanation of rank assignment |
| `ascension_path` | Reclamation / Titan / Endurance / Vanguard |
| `journey_summary` | One-paragraph journey baseline |

Shared logic: `supabase/functions/_shared/compute-hunter-destiny.ts`

Onboarding collects personal goal in the **hunter-goal** step after objective.

---

## Metrics Computed

| Metric | Method |
|--------|--------|
| BMI | weight / height² |
| Body fat % | Deurenberg formula (BMI + age + sex) |
| BMR | Mifflin-St Jeor |
| TDEE | BMR × training multiplier |
| Calorie target | TDEE ± adjustment by objective |
| Protein target | weight × 2.2g |
| Lean mass | weight × (1 − body fat) |
| FFMI | lean mass / height² |
| Progress % | delta closed since last weigh-in |

Shared logic: `supabase/functions/_shared/compute-hunter-metrics.ts`

---

## Ascension Path Inputs

Registration objective → path (see orchestrator spec):

| Objective | Path |
|-----------|------|
| `fat_loss` | Reclamation |
| `muscle_gain` | Titan |
| `general_fitness` | Endurance |
| `athletic` | Vanguard |
| `recomposition` | Reclamation + Titan |

Calorie adjustment differs by path/objective inside `computeCalorieTarget()`.

---

## SYSTEM Voice Examples

- "Deep biometric analysis complete on submitted hunter data."
- "Weekly biometric scan complete. Weight −0.8 kg."
- "BMI 24.2 (normal). Body fat estimate 16.3%."
- "Progress toward target: 12%. Calorie target recalibrated to 2100 kcal."

Never: "Great progress!" / "Keep it up!"

---

## When You Ask to Update This Agent

Say any of:

- *"Update **ANALYZE**"*
- *"Update the **analyze** agent"*
- *"Update `analyze-hunter` edge function"*
- *"Update ANALYZE subagent spec"*

All refer to this agent.
