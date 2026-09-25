# SYSTEM + ARCHITECT Hierarchy Design

**Date:** 2026-08-01  
**Status:** Draft for user review (Approach 1 — split control plane; §1 hierarchy approved)  
**Related:** [ARCHITECT_AGENT_SPEC.md](./ARCHITECT_AGENT_SPEC.md), [SYSTEM_AGENTS_REGISTRY.md](./SYSTEM_AGENTS_REGISTRY.md)

## Goals

1. Introduce **SYSTEM** as the sole FE↔BE bridge and data plane.
2. Rename **ORCHESTRATOR → ARCHITECT**; assign one Architect per hunter after init.
3. Architect owns a living user file (`architect_brief` + structured dossier) and devises typed instructions for specialists.
4. Specialists (ANALYZE, etc.) never touch Supabase directly; all data access goes through SYSTEM with strict `hunter_id` isolation.

## Hierarchy

```
Frontend
   → SYSTEM (gateway + onboarding + Supabase isolation)
      → ARCHITECT (per-hunter control brain + brief)
         → ANALYZE / LOG / TRAIN / DIET / … (specialists)
```

## Ownership

| Layer | Owns | Must not |
|--------|------|----------|
| SYSTEM | Auth binding, onboarding persistence, all DB I/O, job transport, typed responses | Training strategy; rewriting Architect brief |
| ARCHITECT | Post-init plan, brief updates, specialist instruction issuance, interpreting results via SYSTEM | Direct Supabase; cross-hunter data; client-side XP/rank |
| Specialists | Domain computation | Direct DB; calling peers without Architect/SYSTEM |

## Lifecycle

1. Signup / onboarding data → **SYSTEM**
2. Registration complete (`completed_at`) → SYSTEM init path → **assign ARCHITECT**
3. Ongoing → Architect updates brief + issues jobs; SYSTEM executes data + specialist calls

## User file (v1)

- **Source of truth:** Postgres dossier scoped by `hunter_id` (profile, analysis, progression, system state).
- **Architect user file:** `architect_brief` (markdown/text) per hunter, rewritten after major events.
- **Not in v1:** multi-file notebooks, vector memory, disk `.md` trees.

## Instruction style (v1)

- Rules create **typed jobs** (no freeform LLM tool calls yet).
- After major events, rules (later: optional LLM) rewrite `architect_brief`.

## Data isolation (SYSTEM hard rules)

- Every mutation/query resolves `clerk_user_id` → `hunters.id` from the verified JWT.
- Never accept a client-supplied `hunter_id` as authoritative.
- Service-role access only inside SYSTEM-owned edge paths; specialists receive already-scoped payloads or call SYSTEM helpers.
- One Architect assignment row per hunter; no shared briefs.

## Mapping from today

| Today | Target |
|--------|--------|
| `agent-runner` | Becomes / folds into **SYSTEM** entry |
| `system-initialize` + ORCHESTRATOR naming | **ARCHITECT** init + coordination |
| `analyze-hunter` | Specialist under Architect (via SYSTEM) |
| ORCHESTRATOR/SYSTEM conflation in registry | Split: SYSTEM root + ARCHITECT control |

## Non-goals (this design)

- Implementing LLM Architect reasoning
- Workforce OS tenants
- Full LOG/EVALUATE/MISSION agents (contracts only as needed for Architect rules)
