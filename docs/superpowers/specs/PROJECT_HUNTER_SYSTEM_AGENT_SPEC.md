# PROJECT HUNTER — SYSTEM ORCHESTRATOR AGENT SPECIFICATION

**Version:** 0.2  
**Constitution:** [PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md](./PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md)

> The orchestrator is the root agent of Project Hunter. It implements the
> SYSTEM's governing logic. All child agents report to it. The frontend
> never calculates XP, rank, or verdicts.

---

## 1. Genesis (Purpose)

From the Bible:

> To transform unrealised human potential into measurable evolution.

The orchestrator does **not** motivate, entertain, or coach. It **evaluates,
adapts, guides, assigns, and enforces**.

A human becomes a Hunter when they submit to the SYSTEM (Awakening +
Registration). The orchestrator activates at **SYSTEM Initialization**.

---

## 2. Immutable Laws (Orchestrator Must Enforce)

| Law | Orchestrator obligation |
|-----|-------------------------|
| I — Every Hunter has unrealised potential | Baseline metrics at init; never cap growth prematurely |
| II — Potential is unlocked, not granted | Rank/XP only via verified actions, never manual grants |
| III — Discipline outweighs talent | Streaks, consistency rules, daily log requirements |
| IV — The SYSTEM never lies | All metrics server-computed; no client-side fiction |
| V — Every action has consequences | Evaluation → XP/reward/penalty pipeline |
| VI — Consistency beats intensity | Weekly reviews weigh adherence over single peaks |
| VII — Progress is personal | No leaderboard-as-judgment; comparison is informational |

---

## 3. Orchestrator Role

The orchestrator is the **control plane**. It:

1. Validates identity (Clerk JWT)
2. Loads or creates Hunter records
3. Delegates specialized work to child agents
4. Merges outputs into Hunter state
5. Generates SYSTEM responses (verdicts, notices)
6. Manages subsystem unlock policy
7. Never performs UI logic

Child agents are **specialists**. The orchestrator **coordinates** them.

---

## 4. Lifecycle (Bible → Implementation)

| Bible phase | App lifecycle | Orchestrator action |
|-------------|---------------|---------------------|
| Awakening | Sign-in + `/awakening` | Sync hunter identity |
| Registration | Onboarding wizard | Save `hunter_profiles` |
| Initial evaluation | `/analysis` → `system-initialize` | Run init workflow |
| Rule generation | Post-init | Write `hunter_rules` |
| First missions | Dashboard (future) | Assign daily missions |
| Action submission | Log / Train / Diet tabs | Route to child agents |
| Evaluation | Edge evaluation fn (future) | Receive verdict |
| XP update | `hunter_progression` | Apply verified XP only |
| Rank update | `rank_history` | Promote on demonstrated growth |
| Weekly review | Scheduled / manual (future) | Re-run analyze + review |

### Workflow order (never change)

1. Validate payload
2. Load hunter
3. Create hunter if absent
4. Validate profile completeness
5. Calculate metrics *(delegate to `analyze` subagent)*
6. Apply rules
7. Update Supabase
8. Generate SYSTEM response
9. Return verdict

---

## 5. Hunter Identity (What the Orchestrator Owns)

| Bible field | Storage / source |
|-------------|------------------|
| Hunter ID | `hunters.id` + `clerk_user_id` |
| Hunter Name | `hunters.display_name` |
| Awakening Date | `hunters.created_at` |
| Current Rank | `hunter_progression.rank` |
| Current Title | Future: `hunter_titles` |
| Personal Ascension Path | Derived from `hunter_profiles.objective` |
| Potential | Future: computed from attributes + trends |
| Discipline Score | Future: from logs + streaks |
| Reputation | Future: SYSTEM trust metric |
| Evolution Stage | `hunter_system_state.lifecycle_stage` |

Frontend **displays** identity. Orchestrator **authorizes** changes.

---

## 6. Personal Ascension Paths

Objective at registration maps to a Bible path:

| Registration objective | Ascension path | Primary focus |
|------------------------|----------------|---------------|
| `fat_loss` | **Reclamation** | Weight transformation |
| `muscle_gain` | **Titan** | Muscle growth |
| `general_fitness` | **Endurance** | Stamina baseline |
| `athletic` | **Vanguard** | Athletic performance |
| `recomposition` | **Reclamation + Titan** | Dual-track rules |

Each path affects:

- Calorie/protein rules (via `analyze`)
- Mission types (future mission agent)
- Promotion criteria (future rank agent)
- S-Rank requirements (future)

---

## 7. Rank Philosophy

Ranks are stages of **evolution**, not participation trophies.

| Rank | Title | Meaning |
|------|-------|---------|
| F | Unawakened | Pre-system (should not persist post-init) |
| E | Initiated Hunter | Default post-initialization |
| D | Disciplined Hunter | Unlocks Train + Diet subsystems |
| C | Capable Hunter | — |
| B | Elite Hunter | — |
| A | Ascended Hunter | — |
| S | Exceptional Hunter | — |
| SS | Legendary Hunter | — |

**Rules:**

- Initial rank assigned at SYSTEM Initialization (difficulty heuristic)
- Promotion requires **demonstrated growth**, not XP alone
- Rank changes write to `rank_history` with reason
- Orchestrator assigns initial rank; **evaluation agent** promotes

---

## 8. Hunter Attributes & Three Pillars

Attributes evolve independently. Grouped by pillar:

### Capability (what the Hunter can do)

- Strength, Endurance, Mobility, Skill  
- *Future agents:* `train`, performance logs

### Discipline (what the Hunter consistently does)

- Workout adherence, Nutrition, Sleep, Streak maintenance  
- *Future agents:* `log`, `diet`, daily mission compliance

### Evolution (how the Hunter changes over time)

- Body composition, Performance trends, Recovery, Goal milestones  
- *Current agent:* **`analyze`** (BMI, body fat, progress %, snapshots)

**Promotion requires balanced growth across all three pillars** (future rank agent logic).

---

## 9. XP Philosophy

XP = verified progress. Influenced by:

- Completion, Quality, Difficulty, Consistency, Recovery, Long-term improvement

XP is **not** effort alone. The evaluation agent computes XP; orchestrator persists it to `hunter_progression.xp`.

Frontend never calculates XP.

---

## 10. Mission Engine (Orchestrator Coordination)

Mission hierarchy (Bible):

| Type | Frequency | Orchestrator role |
|------|-----------|-------------------|
| Daily Missions | Daily | Assign after init; enforce via rules |
| Weekly Missions | Weekly | Weekly review trigger |
| Monthly Missions | Monthly | Future |
| Boss Missions | Milestone | Future |
| Emergency Missions | Event-driven | Future |
| Punishment Missions | On failure | Penalty zone logic |
| Evolution Missions | Rank gates | Future |
| Legendary Missions | Endgame | Future |

Each mission must define: objective, difficulty, success criteria, failure conditions, reward, penalty.

*Not yet implemented — orchestrator stores unlock policy and rules only.*

---

## 11. Evaluation Engine

Every submission produces **one verdict**:

| Verdict | Meaning |
|---------|---------|
| FAILED | Criteria not met; penalty may apply |
| ACCEPTABLE | Minimum threshold met |
| SUCCESS | Target met |
| EXCEPTIONAL | Above target |
| PERFECT | Maximum standard |

The SYSTEM evaluates. It does **not** congratulate.

Evaluation is a **future child agent** (`evaluate-log`). Orchestrator routes submissions and persists verdicts.

---

## 12. Reward & Punishment Philosophy

### Rewards (orchestrator may trigger via child agents)

- XP, Rank progression, Titles, Badges, Privileges, New mission types, Increased SYSTEM trust

### Punishments (corrective, not emotional)

- XP reduction, Reduced rewards, Mandatory recovery, Additional missions, Delayed promotion, Restricted progression, Special penalty quests

Punishment copy uses: `PENALTY APPLIED`, never guilt language.

---

## 13. Child Agent Registry

**Full naming cheat sheet:** [SYSTEM_AGENTS_REGISTRY.md](./SYSTEM_AGENTS_REGISTRY.md)

Use UPPERCASE names when requesting changes (e.g. "update **ANALYZE**", "build **LOG**").

### Hunter-facing agents (tabs)

| You say | Agent ID | Display name | Status | Edge function |
|---------|----------|--------------|--------|---------------|
| **ANALYZE** | `analyze` | ANALYZE Agent | **Live** | `analyze-hunter` |
| **LOG** | `log` | LOG Agent | Planned | `evaluate-log` |
| **ADVICE** | `advice` | ADVICE Agent | UI only | — |
| **TRAIN** | `train` | TRAIN Agent | Locked @ D | — |
| **DIET** | `diet` | DIET Agent | Locked @ D | — |

### Backend agents (no tab)

| You say | Agent ID | Display name | Status |
|---------|----------|--------------|--------|
| **MISSION** | `mission` | MISSION Agent | Planned |
| **EVALUATE** | `evaluate` | EVALUATE Agent | Planned |
| **RANK** | `rank` | RANK Agent | Planned |
| **PENALTY** | `penalty` | PENALTY Agent | Planned |

### Root

| You say | Agent ID | Edge function |
|---------|----------|---------------|
| **ORCHESTRATOR** / **SYSTEM** | `orchestrator` | `system-initialize` |

Unlock policy in `hunter_rules.subsystem_unlock_policy`:

- **Unlocked at init:** `analyze`, `log`, `advice`
- **Locked until rank D:** `train`, `diet`

See [ANALYZE_SUBAGENT_SPEC.md](./ANALYZE_SUBAGENT_SPEC.md) for the first live child agent.

---

## 14. SYSTEM Personality (All Agents Inherit)

The SYSTEM is: **Mechanical, Calm, Precise, Consistent, Authoritative**

### Never say

- Good job / Proud of you / Keep going

### Preferred vocabulary

- `SYSTEM NOTICE`
- `VERDICT`
- `MISSION UPDATED`
- `PENALTY APPLIED`
- `RANK ADVANCEMENT DETECTED`

All orchestrator and child agent responses must use this voice.

---

## 15. Implementation Surface

### Frontend responsibilities

- Collect user input
- Display dashboard and SYSTEM windows
- Never calculate XP, rank, or metrics

### Supabase tables (orchestrator domain)

| Table | Purpose |
|-------|---------|
| `hunters` | Identity + `initialized` flag |
| `hunter_profiles` | Registration / biometric inputs |
| `hunter_analysis` | Current metrics (analyze agent) |
| `hunter_progression` | Rank, XP, level, streaks |
| `hunter_system_state` | Phase, lifecycle, agent unlocks |
| `hunter_rules` | SYSTEM-generated rules |
| `hunter_weekly_stats` | Weekly biometric entries |
| `hunter_analysis_snapshots` | Metric history |
| `hunter_logs` | Action submissions (future) |
| `rank_history` | Rank change audit trail |

### Edge functions

| Function | Role |
|----------|------|
| `sync-hunter` | Identity sync on sign-in |
| `save-hunter-profile` | Registration persistence |
| `system-initialize` | Orchestrator init workflow |
| `analyze-hunter` | Analyze subagent (metrics recalc) |

---

## 16. Long-term Vision

From the Bible closing principle:

> Build a living SYSTEM where every Hunter experiences meaningful progression through discipline, measurable evolution and consistent evaluation.

The orchestrator is the spine of that SYSTEM. Every new agent extends it — never bypasses it.

---

## Document Map

| Document | Scope |
|----------|-------|
| [PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md](./PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md) | Philosophy only — no tech |
| [SYSTEM_AGENTS_REGISTRY.md](./SYSTEM_AGENTS_REGISTRY.md) | **All agent names — use this to say what to update** |
| This spec | Orchestrator + agent architecture |
| [ANALYZE_SUBAGENT_SPEC.md](./ANALYZE_SUBAGENT_SPEC.md) | ANALYZE agent (live) |
| [2026-07-25-project-hunter-system-design.md](./2026-07-25-project-hunter-system-design.md) | MVP engineering design |
