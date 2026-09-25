# PROJECT HUNTER — SYSTEM AGENTS REGISTRY

**Quick reference:** Use these names when asking to build or update an agent.

> Example: *"Update the **ANALYZE** agent to add waist circumference"*  
> Example: *"Build the **LOG** agent next"*

---

## Platform Entry / SYSTEM Gateway

| You say | Agent ID | Endpoint | Responsibility | Spec |
|---------|----------|----------|----------------|------|
| **SYSTEM** | `system` | `agent-runner` *(target: SYSTEM gateway)* | FE↔BE bridge: auth, onboarding data, Supabase isolation, job transport, typed results | [2026-08-01-system-architect-hierarchy-design.md](./2026-08-01-system-architect-hierarchy-design.md) |

Initial workflows (via SYSTEM):

- `hunter.initialize.v1` → SYSTEM init path + **ARCHITECT** assignment / `system-initialize`
- `hunter.analyze.v1` → ANALYZE / `analyze-hunter` (invoked through SYSTEM; Architect may request)
- `hunter.architect.*.v1` → ARCHITECT protocol / weekly / get / vault sync / vault status / admin-pull

The mobile app calls **SYSTEM** only. Specialists do not own cross-hunter data access.

**Also uses:** `sync-hunter`, `save-hunter-profile`

---

## Control Brain (per hunter)

| You say | Agent ID | Display name | Edge / module | Spec file |
|---------|----------|--------------|---------------|-----------|
| **ARCHITECT** | `architect` | ARCHITECT Agent | Assigned after init; brief + job intents *(legacy name: ORCHESTRATOR / `system-initialize` coordination)* | [ARCHITECT_AGENT_SPEC.md](./ARCHITECT_AGENT_SPEC.md) |

**Role:** Per-hunter control brain. Maintains `architect_brief` + dossier context, devises typed instructions for specialists, interprets results **only through SYSTEM**. Never touches Supabase directly. PROTOCOL chat/plan memory is **phone-first** ([design](./2026-08-01-phone-first-architect-design.md)); weekly / admin-pull snapshots land in `hunter_vault_snapshots`.

**Legacy:** [PROJECT_HUNTER_SYSTEM_AGENT_SPEC.md](./PROJECT_HUNTER_SYSTEM_AGENT_SPEC.md) (orchestrator-era Bible mapping; split into SYSTEM + ARCHITECT going forward).

> Do not say “ORCHESTRATOR” for new work — say **ARCHITECT**.

---

## Child Agents — Hunter-Facing (Tabs / UI)

These map to app tabs and `SystemAgentId` in code.

| You say | Agent ID | Display name | Tab | Pillar | Status | Edge function | Spec file |
|---------|----------|--------------|-----|--------|--------|---------------|-----------|
| **ANALYZE** | `analyze` | ANALYZE Agent | Profile (metrics) | Evolution | **Live** | `analyze-hunter` | [ANALYZE_SUBAGENT_SPEC.md](./ANALYZE_SUBAGENT_SPEC.md) |
| **LOG** | `log` | LOG Agent | Log | Discipline | Planned | `evaluate-log` *(planned)* | *(not yet)* |
| **TRAIN** / **PROTOCOL** | `train` | PROTOCOL Agent (TRAIN·DIET) | Train — combined chatbot | Capability + Discipline | **Always unlocked** — feeds ARCHITECT hunter brief | *(planned)* | *(not yet)* |
| **DIET** | `diet` | DIET Plan View | Diet — plan display (not a second chat) | Discipline | **Always unlocked** viewer; reads `ProtocolPlanContext` | *(planned)* | *(not yet)* |
| **ADVICE** *(deprecated)* | `advice` | — | **Removed** from nav/tabs | Knowledge | Deprecated | — | — |

### PROTOCOL chat strategy (UI)

- **Train tab** = always-on TRAIN·DIET PROTOCOL chatbot. Conversation feeds **ARCHITECT** (hunter brief / “hunter md”).
- **Diet tab** = display of the diet/meal plan written by that chat into session `ProtocolPlanContext`.
- Do **not** rebuild Advice as a third chat surface.

### Unlock at initialization

- Unlocked: `analyze`, `log`, `train`, `diet`
- Locked: *(none for tab agents; train/diet never rank-gated)*
- `advice` is no longer granted at init (legacy arrays may still contain it)

Stored in: `hunter_system_state.unlocked_agents` / `locked_agents`

---

## Child Agents — Backend Only (No Tab)

These run under **ARCHITECT** (via SYSTEM); Hunters never “open” them directly.

| You say | Agent ID | Display name | Pillar | Status | Edge function | Spec file |
|---------|----------|--------------|--------|--------|---------------|-----------|
| **MISSION** | `mission` | MISSION Agent | Discipline | Planned | `assign-missions` *(planned)* | *(not yet)* |
| **EVALUATE** | `evaluate` | EVALUATE Agent | All three | Planned | `evaluate-log` *(planned)* | *(not yet)* |
| **RANK** | `rank` | RANK Agent | Evolution | Planned | `update-rank` *(planned)* | *(not yet)* |
| **PENALTY** | `penalty` | PENALTY Agent | Discipline | Planned | `apply-penalty` *(planned)* | *(not yet)* |

---

## Naming Convention

| Layer | Format | Example |
|-------|--------|---------|
| **How you refer to it** | UPPERCASE word | "Update **ANALYZE**" |
| **Agent ID** (code / DB) | lowercase slug | `analyze` |
| **Display name** (UI copy) | UPPERCASE + "Agent" | `ANALYZE Agent` |
| **Edge function** | kebab-case | `analyze-hunter` |
| **Spec file** | `{NAME}_SUBAGENT_SPEC.md` | `ANALYZE_SUBAGENT_SPEC.md` |

---

## Agent → Bible Mapping

| Agent | Bible section |
|-------|---------------|
| SYSTEM | Awakening data, identity, isolation, gateway |
| ARCHITECT | Genesis/Laws enforcement in planning, Lifecycle post-init |
| ORCHESTRATOR *(legacy name)* | See ARCHITECT |
| ANALYZE | Evolution pillar, Potential, Hunter Attributes; **assigns starting rank + personal S-Rank at init** |
| LOG | Discipline pillar, Action Submission |
| TRAIN / PROTOCOL | Capability + Discipline — combined Train·Diet chatbot (UI on Train tab) |
| DIET | Discipline pillar, Nutrition — plan viewer fed by PROTOCOL chat |
| ADVICE *(deprecated)* | Knowledge attribute — **removed** from product surfaces |
| MISSION | Mission Engine (§10) |
| EVALUATE | Evaluation Engine (§11), XP Philosophy (§9) |
| RANK | Rank Philosophy (§7), Rewards (§12) |
| PENALTY | Punishment Philosophy (§13) |

Constitution: [PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md](./PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md)

---

## Code References

| Location | What it defines |
|----------|-----------------|
| `apps/mobile/types/system.ts` | `SystemAgentId` union type |
| `supabase/functions/_shared/generate-rules.ts` | `subsystem_unlock_policy` |
| `hunter_system_state` table | `unlocked_agents[]`, `locked_agents[]` |

---

## Build Order (Suggested)

1. ✅ **SYSTEM** gateway + init path — `agent-runner` / `system-initialize` *(rename/split in progress)*
2. ⬜ **ARCHITECT** — assignment + `architect_brief` + job intents ([spec](./ARCHITECT_AGENT_SPEC.md))
3. ✅ **ANALYZE** — `analyze-hunter`
4. ⬜ **LOG** + **EVALUATE** — daily action → verdict → XP
5. ⬜ **MISSION** — daily / weekly quest assignment
6. ⬜ **TRAIN** + **DIET** PROTOCOL — combined chat (Train) + plan view (Diet); unlock at rank D; wire LLM/edge
7. ⬜ **RANK** — promotion logic
8. ⬜ **PENALTY** — failed daily missions
9. ❌ **ADVICE** — deprecated / removed from tabs (fold knowledge into PROTOCOL or SYSTEM notices later)
