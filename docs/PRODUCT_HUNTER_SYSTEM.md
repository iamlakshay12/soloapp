# Project Hunter SYSTEM — Living Product Document

**Canonical file:** `docs/PRODUCT_HUNTER_SYSTEM.md`  
**Status:** Living — update this file as product decisions land  
**Last updated:** 2026-08-01  
**Constitution:** [PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md](./superpowers/specs/PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md)  
**Agent naming:** [SYSTEM_AGENTS_REGISTRY.md](./superpowers/specs/SYSTEM_AGENTS_REGISTRY.md)

> **How to use this doc**  
> This is the single source of truth for *what we are building and why*.  
> Detailed agent contracts live in `docs/superpowers/specs/`.  
> When product intent changes, update this file first, then align specs/code.  
> Adapted from the vibecoding “6 documents before code” framework into **one** living brief.

---

## Table of contents

1. [Product vision / north star](#1-product-vision--north-star)
2. [Principles (vibecoding adapted)](#2-principles-vibecoding-adapted)
3. [Current architecture](#3-current-architecture)
4. [App surfaces](#4-app-surfaces)
5. [Agent map & chat strategy](#5-agent-map--chat-strategy)
6. [Data / auth / isolation](#6-data--auth--isolation)
7. [Build status / roadmap](#7-build-status--roadmap)
8. [Open decisions](#8-open-decisions)
9. [Changelog](#9-changelog)

---

## 1. Product vision / north star

| Field | Value |
|-------|--------|
| **App name** | Project Hunter SYSTEM |
| **Tagline** | A Solo Leveling–inspired fitness operating system that evaluates, adapts, and guides — it does not entertain. |
| **Problem** | Generic fitness apps motivate and track, but they do not *govern* progression with measurable consequences, personal destiny, or a coherent control brain. |
| **For whom** | Individuals who want disciplined, measurable self-evolution (Hunters), not casual calorie-logging alone. |
| **Core value** | The user is a **Hunter**; the product is the **SYSTEM**. Progress is verified, personal, and consequence-bearing. |
| **Persona** | A motivated adult who accepts Awakening, completes Registration, and wants mechanical feedback (verdicts, missions, rank) over cheerleading. |

### North star (Bible)

> Transform unrealised human potential into measurable evolution.

The objective is **not** to build “another fitness app.” It is to build a living SYSTEM where every Hunter experiences meaningful progression through discipline, measurable evolution, and consistent evaluation.

### Success metrics (working — refine over time)

| Metric | Intent |
|--------|--------|
| Registration completion rate | Awakening → completed profile (`completed_at`) |
| Returning-hunter correct routing | Completed → home; incomplete → resume onboarding |
| Core loop retention | Log → evaluate → XP (once LOG/EVALUATE ship) |
| Chat → Diet plan adoption | Train chat produces a plan Diet can display |
| Isolation integrity | Zero cross-hunter data leaks in tests / audits |

### Out of scope (near-term)

- Workforce OS tenant UI (platform may prepare contracts; Hunter ships first)
- Vector memory / multi-file Architect notebooks
- Freeform LLM Architect inventing new job types
- Boss battles, Telegram/WhatsApp channels
- Cheerleading / motivational coaching UX

---

## 2. Principles (vibecoding adapted)

The vibecoding guide requires six pre-code documents (PRD, TRD, App Flow, UI/UX, Backend Schema, Implementation Plan). **Hunter consolidates those into this living file**, with deep specs linked below.

### 2.1 How the six map here

| Vibecoding doc | Where it lives for Hunter |
|----------------|---------------------------|
| **01 PRD** | §1 Vision + §5 Agent/chat strategy + Bible |
| **02 TRD** | §3 Architecture + stack table below |
| **03 App Flow** | §4 App surfaces + auth routing |
| **04 UI/UX** | Bible §14 (SYSTEM personality) + mobile theme (cyberpunk / Lovable SYSTEM terminal) |
| **05 Backend Schema** | §6 Data / auth / isolation + Supabase migrations |
| **06 Implementation Plan** | §7 Build status / roadmap |

### 2.2 Product principles (non-negotiable)

1. **Ambiguity kills agents** — Prefer named agents, typed workflows, and this doc over tribal knowledge.
2. **Frontend is presentation** — No XP, rank, destiny, calorie targets, or unlock math on the client.
3. **SYSTEM is the only FE↔BE bridge** — Auth binding, DB I/O, job transport, typed results.
4. **ARCHITECT is per-hunter** — One control brain, one `architect_brief` + dossier; never shared across hunters. Protocol memory is **phone-first** (device vault) with weekly / admin-pull snapshots to SYSTEM (`hunter_vault_snapshots`).
5. **Specialists compute; they do not own the data plane** — ANALYZE etc. run via SYSTEM.
6. **SYSTEM never lies** — Only verified metrics/results; mechanical tone (Bible §14).
7. **Profile-first auth routing** — Destination from registration progress, not Sign Up vs Sign In button.
8. **Update the living doc when intent changes** — Specs and registry follow this file for product-level decisions.

### 2.3 Locked stack (TRD snapshot)

| Layer | Choice |
|-------|--------|
| Mobile | Expo (React Native) + Expo Router + TypeScript |
| Auth | Clerk (`@clerk/clerk-expo`) — sole identity provider |
| Data / edge | Supabase Postgres + Edge Functions (service-role inside SYSTEM paths) |
| Agent entry | `agent-runner` → folds into / becomes **SYSTEM** gateway |
| Validation | Zod / shared typed envelopes |
| Deploy mobile | Expo EAS (as needed) |
| Future platform tenant | Workforce OS (deferred) |

**Hard constraints**

- Never trust client-supplied `hunter_id`.
- Never expose service-role keys to the mobile client.
- Do not use Supabase Auth for Hunter identity (Clerk only).

---

## 3. Current architecture

### 3.1 Hierarchy (approved)

```
Frontend (Expo)
  → SYSTEM          # gateway + onboarding + Supabase isolation + job transport
     → ARCHITECT    # per-hunter control brain + architect_brief + dossier
        → specialists (ANALYZE, LOG, TRAIN/…, …)
```

| Layer | Owns | Must not |
|-------|------|----------|
| **Frontend** | Input, display, navigation, temporary cache | Authoritative XP/rank/verdicts |
| **SYSTEM** | Auth→hunter binding, onboarding persistence, all DB I/O, invoke specialists, typed envelopes | Training strategy; owning Architect brief content |
| **ARCHITECT** | Living user file, job intents, interpreting results via SYSTEM | Direct Supabase; cross-hunter reads; client routing |
| **Specialists** | Domain computation (metrics, future eval, etc.) | Direct DB; peer calls bypassing SYSTEM |

**Specs**

- [2026-08-01-system-architect-hierarchy-design.md](./superpowers/specs/2026-08-01-system-architect-hierarchy-design.md)
- [ARCHITECT_AGENT_SPEC.md](./superpowers/specs/ARCHITECT_AGENT_SPEC.md)
- [SYSTEM_AGENTS_REGISTRY.md](./superpowers/specs/SYSTEM_AGENTS_REGISTRY.md)

### 3.2 ARCHITECT user file

| Part | Role |
|------|------|
| **Structured dossier** | Source of truth via SYSTEM: `hunters`, `hunter_profiles`, `hunter_analysis`, `hunter_progression`, `hunter_system_state`, `hunter_rules`, … |
| **`architect_brief`** | Living markdown/text per hunter; sections: Identity, Goal & Ascension Path, Current Assessment, Standing Instructions, Open Loops, Last Event |

**Rule:** If brief and dossier disagree, **dossier wins**; brief is corrected on next update.

### 3.3 Initial workflows

| Workflow | Path |
|----------|------|
| `hunter.initialize.v1` | SYSTEM init + ARCHITECT assignment |
| `hunter.analyze.v1` | ANALYZE via SYSTEM (Architect may request) |

Also in use: `sync-hunter`, `save-hunter-profile`, `analyze-hunter` (specialist edge).

### 3.4 Naming

| Say | Agent ID | Notes |
|-----|----------|-------|
| **SYSTEM** | `system` | Gateway / data plane |
| **ARCHITECT** | `architect` | Replaces “ORCHESTRATOR” for new work |
| **ANALYZE** | `analyze` | Live specialist |

Legacy code/docs may still say orchestrator / `system-initialize` until rename slices land.

---

## 4. App surfaces

### 4.1 Auth & registration (current intent — approved)

Profile-first routing ([auth-post-login-routing-design](./superpowers/specs/2026-08-01-auth-post-login-routing-design.md)):

| State | Destination |
|-------|-------------|
| Not signed in | `/` or `/auth` |
| Signed in, no onboarding fields | `/awakening` |
| Signed in, profile partial (`completed_at` null) | `/onboarding` at first incomplete step |
| Signed in, `completed_at` set | `/(tabs)` + hydrate |

**Sign Up vs Sign In:** copy only; same resolver.

Onboarding step order (resume): `initiate` → `gender` → `age` → `height` → `weight` → `training-days` → `target-weight` → `objective` → `hunter-goal`.

### 4.2 Screens — current vs planned

| Surface | Route (approx.) | Status | Notes |
|---------|-----------------|--------|-------|
| Landing / index | `/` | Live | Auth gate → resolver |
| Auth | `/auth` | Live | Clerk; neutral continue |
| Awakening | `/awakening` | Live | Zero-progress hunters |
| Onboarding | `/onboarding` | Live | Wizard + step save |
| Analysis reveal | `/analysis` | Live | Post-init SYSTEM analysis |
| Home | `/(tabs)` | Live | Dashboard shell |
| Log | `/(tabs)/log` | UI / partial | LOG agent planned |
| Train | `/(tabs)/train` | **Always unlocked** | PROTOCOL chatbot → plan context + (soon) ARCHITECT hunter brief |
| Diet | `/(tabs)/diet` | Locked @ rank D | Plan viewer from `ProtocolPlanContext` (empty until Generate Protocol) |
| Profile | `/(tabs)/profile` | Live | Metrics / ANALYZE-related |

### 4.3 Navigation (current)

SYSTEM nav labels: **HOME · LOG · TRAIN · DIET · PROFILE**.

**ADVICE** removed. Train + Diet are separate *surfaces* with different jobs (chat vs plan display), not two competing chatbot agents.

### 4.4 Key journeys

1. **New Hunter:** Auth → Awakening → Onboarding → Init/Analysis → Home  
2. **Resume incomplete:** Auth → sync → first missing onboarding step  
3. **Returning complete:** Auth → Home + hydrate  
4. **Train → Diet (planned):** Chat on Train designs diet/training plan → Diet displays plan (optional short follow-up on Diet)

---

## 5. Agent map & chat strategy

### 5.1 Platform entry

| You say | Responsibility |
|---------|----------------|
| **SYSTEM** | Sole mobile entry for workflows, sync, profile save, isolation |

### 5.2 Control brain

| You say | Responsibility |
|---------|----------------|
| **ARCHITECT** | Per-hunter brief + dossier; typed job intents; interpret results via SYSTEM |

### 5.3 Specialists — registry vs current product intent

| Agent | Registry role | Product intent (2026-08) | Status |
|-------|---------------|--------------------------|--------|
| **ANALYZE** | Evolution metrics, starting rank, personal S-Rank | Unchanged | **Live** |
| **LOG** | Discipline — action submission | Unchanged | Planned |
| **ADVICE** | Knowledge tab / agent | **Remove ADVICE section** from product surfaces | UI only → **deprecate** |
| **TRAIN** | Capability — training | **Combine with Diet into ONE chatbot agent** (chat on Train) | Planned / redesign |
| **DIET** | Discipline — nutrition | **Diet page displays plan** designed via Train chat; optional short follow-up | Planned / redesign |
| **MISSION** | Quest assignment | Backend only | Planned |
| **EVALUATE** | Verdicts / XP path | Backend only | Planned |
| **RANK** | Promotion | Backend only | Planned |
| **PENALTY** | Failures | Backend only | Planned |

### 5.4 Chat strategy — working assumption (Option C)

Unless superseded in [§8 Open decisions](#8-open-decisions):

| Surface | Job |
|---------|-----|
| **Train tab** | **Primary combined chatbot** for training + diet design / coaching conversation (SYSTEM voice). Diet plan is *created* here. |
| **Diet tab** | **Plan viewer** — renders the diet (and related nutrition targets) produced from the Train/chat flow. Optional: short follow-up clarifications, not a second full agent UX. |
| **Advice tab** | **Removed** — no dedicated ADVICE agent surface. Knowledge needs fold into SYSTEM notices, Profile, or the combined chat as appropriate later. |

**Agent ID TBD:** Prefer one conversational specialist (name TBD: e.g. keep `train` as chat owner, or introduce a single id like `coach` / `protocol`) while Diet remains a *view* over persisted plan data — not a peer chatbot. Update registry when the id is chosen.

### 5.5 Unlock policy (current code / registry)

| At init | Locked until rank D |
|---------|---------------------|
| `analyze`, `log`, `train`, `diet` | *(none for tabs)* |

`advice` dropped from init unlock; Train/Diet unlock timing stays rank D until decided otherwise.

Stored in: `hunter_system_state.unlocked_agents` / `locked_agents`.

---

## 6. Data / auth / isolation

### 6.1 Auth model

1. Clerk session on device → `getToken()`  
2. Bearer JWT on SYSTEM / edge calls  
3. Edge verifies JWT → resolves `clerk_user_id` → `hunters.id`  
4. All mutations/queries scoped to that hunter  

Completion gate: `hunter_profiles.completed_at`.

### 6.2 Isolation hard rules (SYSTEM)

- Never accept client `hunter_id` as authoritative.  
- Service-role only inside SYSTEM-owned edge paths.  
- Specialists receive already-scoped payloads or call SYSTEM helpers.  
- One active Architect assignment per hunter; briefs never shared.  
- ARCHITECT never touches Supabase directly.

### 6.3 Core tables (product view — not a full migration)

| Area | Tables / artifacts |
|------|--------------------|
| Identity | `hunters` (`clerk_user_id`, …) |
| Registration | `hunter_profiles` |
| Evolution | `hunter_analysis`, destiny fields, `hunter_rules` |
| Progression | `hunter_progression`, `hunter_system_state` |
| Architect | `hunter_architect` (or equiv.) + `architect_brief` |
| Runs | `agent_runs` / steps (observability) |
| Future | logs, missions, evaluations, diet/training plan store |

### 6.4 Sensitive / authority boundaries

| Concern | Owner |
|---------|-------|
| Session / OAuth | Clerk |
| Row access | SYSTEM + JWT resolution |
| XP / rank / verdicts | Specialists + validators via SYSTEM — never FE |
| Calorie / protocol math | Specialists (ANALYZE targets; future TRAIN/DIET plan agent) |

---

## 7. Build status / roadmap

Checkboxes are product-level. Tick when shipped and verified; note date in [§9 Changelog](#9-changelog).

### Phase A — Foundation

- [x] Expo mobile shell + SYSTEM visual language  
- [x] Clerk auth  
- [x] Awakening + onboarding wizard + profile persistence  
- [x] ANALYZE live (`analyze-hunter`)  
- [x] Init / analysis reveal path  
- [ ] SYSTEM gateway rename/split complete (`agent-runner` → SYSTEM)  
- [ ] ARCHITECT assignment + `architect_brief` persisted end-to-end  
- [x] Auth profile-first routing design approved  
- [ ] Auth profile-first routing fully shipped & smoke-tested  

### Phase B — Core loop

- [ ] LOG agent + evaluate path  
- [ ] MISSION assignment  
- [ ] Home hydration of progression / verdicts  

### Phase C — Train / Diet (redesign)

- [x] Remove ADVICE tab / nav (id kept deprecated in types for legacy unlock arrays)  
- [x] Single combined Train+Diet chatbot on Train (UI shell + Generate Protocol stub)  
- [x] Persist diet (and training) plan from chat — session `ProtocolPlanContext`  
- [x] Diet tab as plan viewer (+ optional short follow-up later)  
- [x] Unlock policy updated (no `advice` at init)  
- [x] Registry + `types/system.ts` aligned  
- [ ] Real LLM / edge PROTOCOL workflow replacing stub plan  

### Phase D — Progression authority

- [ ] RANK agent  
- [ ] PENALTY agent  
- [ ] Rank-D unlock of Train/Diet verified against Bible pillars  

### Phase E — Polish & platform

- [ ] Empty / error / loading states for all core journeys  
- [ ] Agent run observability hardened  
- [ ] Workforce OS deferred until Hunter loop is solid  

### Done criteria (near-term “product coherent”)

1. Completed hunters always land on home; incomplete resume correctly.  
2. Mobile talks only to SYSTEM for authoritative actions.  
3. Architect brief exists post-init for each hunter.  
4. Advice gone from nav; Train chat designs diet; Diet shows plan.  

---

## 8. Open decisions

Record decisions here; move resolved items to Changelog.

| ID | Topic | Options / notes | Status |
|----|-------|-----------------|--------|
| OD-01 | Combined chat agent id | Keep `train` as chat owner vs new id (`protocol` / `coach`); Diet as view-only | **Open** |
| OD-02 | Chat placement | **Working assumption: Option C** — chat on Train; Diet = plan + optional short follow-up | **Assumed** |
| OD-03 | Advice knowledge | Drop entirely vs fold Knowledge into chat/Profile notices | **Open** (surface removal decided; knowledge home TBD) |
| OD-04 | Diet follow-up depth | View-only vs limited clarification thread on Diet | **Open** |
| OD-05 | Unlock timing for Train/Diet | Keep rank D vs unlock earlier for plan design | **Open** |
| OD-06 | Plan persistence shape | New table(s) vs `hunter_rules` / Architect brief sections | **Open** |
| OD-07 | Legacy ORCHESTRATOR strings | Rename slice timing in code vs docs-only | **In progress** |

---

## 9. Changelog

| Date | Change |
|------|--------|
| 2026-08-01 | Created living product document from vibecoding PDF + Hunter specs/registry + recent product direction (Advice removal; Train+Diet combined chat; Diet as plan viewer; profile-first auth; Architect brief + dossier). |

---

## Appendix A — Spec index

| Doc | Role |
|-----|------|
| [PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md](./superpowers/specs/PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md) | Constitution / laws / personality |
| [SYSTEM_AGENTS_REGISTRY.md](./superpowers/specs/SYSTEM_AGENTS_REGISTRY.md) | Agent names & build order |
| [ARCHITECT_AGENT_SPEC.md](./superpowers/specs/ARCHITECT_AGENT_SPEC.md) | Architect rules |
| [ANALYZE_SUBAGENT_SPEC.md](./superpowers/specs/ANALYZE_SUBAGENT_SPEC.md) | ANALYZE contract |
| [2026-08-01-system-architect-hierarchy-design.md](./superpowers/specs/2026-08-01-system-architect-hierarchy-design.md) | Hierarchy |
| [2026-08-01-auth-post-login-routing-design.md](./superpowers/specs/2026-08-01-auth-post-login-routing-design.md) | Auth routing |
| [2026-08-01-agent-platform-architecture-design.md](./superpowers/specs/2026-08-01-agent-platform-architecture-design.md) | Platform harness (may still say ORCHESTRATOR) |
| [2026-07-25-project-hunter-system-design.md](./superpowers/specs/2026-07-25-project-hunter-system-design.md) | Early MVP design — **partially superseded** (API host, screen map) |

## Appendix B — Vibecoding workflow reminder

When spinning a new agent session: paste or `@` this file and say:

> Here is the Project Hunter living product document. Use it as the source of truth for product intent. Prefer linked specs for agent contracts. Do not invent architecture that conflicts with SYSTEM → ARCHITECT → specialists.

---

*End of living document — append Changelog rows; do not fork into a second “master” product doc.*
