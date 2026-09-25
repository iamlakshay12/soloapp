# ARCHITECT Agent — Rules & Responsibilities

**Version:** 1.0  
**Status:** Design approved (Approach 1)  
**Agent ID:** `architect`  
**Display name:** ARCHITECT Agent  
**Supersedes naming:** ORCHESTRATOR / “SYSTEM Orchestrator” as the per-hunter control brain  
**Constitution:** [PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md](./PROJECT_HUNTER_SYSTEM_BIBLE_Volume_I.md)  
**Hierarchy design:** [2026-08-01-system-architect-hierarchy-design.md](./2026-08-01-system-architect-hierarchy-design.md)  
**Phone-first memory:** [2026-08-01-phone-first-architect-design.md](./2026-08-01-phone-first-architect-design.md)  
**Registry:** [SYSTEM_AGENTS_REGISTRY.md](./SYSTEM_AGENTS_REGISTRY.md)

> The frontend never calculates XP, rank, or verdicts.  
> ARCHITECT never touches Supabase directly. All data I/O goes through **SYSTEM**.  
> **Phone-first:** PROTOCOL chat + plan live in the on-device vault; cloud LLM still runs via SYSTEM; vault syncs weekly (or on admin pull).

---

## 1. Genesis (Purpose)

ARCHITECT is the per-hunter **control brain** assigned after SYSTEM Initialization.

It exists to:

1. Hold a living understanding of *this* Hunter (dossier + `architect_brief`)
2. Devise **typed instructions** for specialist agents (ANALYZE, LOG, …)
3. Interpret specialist results (delivered via SYSTEM) and update the brief
4. Enforce Bible laws in planning — without becoming a chatbot or motivator

It does **not** entertain, hype, or invent unverified progress.

A human becomes a Hunter under **SYSTEM** (Awakening + Registration).  
ARCHITECT activates when SYSTEM completes initialization and **assigns** this agent to the hunter.

---

## 2. Position in the Stack

```
Frontend → SYSTEM → ARCHITECT → specialists (ANALYZE, LOG, …)
```

| Peer | Relationship |
|------|----------------|
| **SYSTEM** | Only channel for auth-scoped data, job transport, and specialist invocation |
| **ANALYZE** | Specialist; Architect requests analysis / re-analysis via SYSTEM |
| **LOG / EVALUATE / MISSION / RANK / …** | Future specialists; same rule — instructions out, results in, via SYSTEM |

Legacy note: code and docs may still say “orchestrator” / `system-initialize` until the rename slice lands. Behavior target is this spec.

---

## 3. Immutable Laws (Architect Must Respect)

Architect planning and instructions must never violate:

| Law | Architect obligation |
|-----|----------------------|
| I — Unrealised potential | Never declare a Hunter “finished”; brief stays open-ended |
| II — Potential unlocked, not granted | Never instruct fake XP/rank grants |
| III — Discipline outweighs talent | Prefer consistency-oriented instructions when specialists exist |
| IV — SYSTEM never lies | Only use metrics/results returned through SYSTEM |
| V — Every action has consequences | Route failures toward evaluation/penalty paths when those agents exist |
| VI — Consistency beats intensity | Avoid boom-bust mission plans |
| VII — Progress is personal | Brief and instructions are hunter-scoped only |

---

## 4. Responsibilities

### 4.1 Must do

1. **Accept assignment** after SYSTEM init for exactly one `hunter_id`
2. **Maintain the user file:** structured dossier (via SYSTEM reads) + `architect_brief`
3. **Issue typed jobs** to specialists through SYSTEM (v1: rule/template based)
4. **Update the brief** after major events (init, analysis, future log/eval cycles)
5. **Coordinate unlock intent** (which subsystems should unlock) — SYSTEM persists `hunter_system_state`
6. **Merge specialist outputs into planning context** without writing DB itself
7. **Stay hunter-isolated** — never load or reference another hunter’s brief or dossier

### 4.2 Must not

1. Call Supabase / service role / raw SQL
2. Trust client-supplied `hunter_id` or forged specialist results
3. Bypass SYSTEM to call ANALYZE (or any specialist) “directly” in the target architecture
4. Compute authoritative XP, rank promotions, or calorie math itself (delegate to specialists)
5. Share one Architect instance or brief across hunters
6. Perform UI routing or Clerk session management (SYSTEM / app own that)

### 4.3 May do (v1)

1. Choose *which* specialist job to run next from an allowlisted catalog
2. Rewrite `architect_brief` sections from templates + latest SYSTEM facts
3. Attach short instruction payloads to jobs (goals, constraints, focus flags)

### 4.4 Deferred (not v1)

1. Freeform LLM tool-calling to invent new job types
2. Multi-file markdown memory trees / vector recall
3. Cross-hunter comparison as judgment

---

## 5. Lifecycle

| Phase | Owner | Architect action |
|-------|--------|------------------|
| Signup / Awakening | SYSTEM | None (not assigned yet) |
| Registration / onboarding fields | SYSTEM | None |
| SYSTEM Initialization | SYSTEM + specialists | **Assigned**; receive init context; seed brief |
| Post-init home | ARCHITECT | Plan next jobs (e.g. refresh ANALYZE when profile changes) |
| Ongoing progression | ARCHITECT + specialists | Update brief; issue jobs; interpret results via SYSTEM |
| Sign-out | App / SYSTEM | Architect state remains in DB; no cross-session leak |

### Assignment rule

- **When:** SYSTEM init succeeds (profile complete + initial analysis/rules path done).
- **What is stored:** `hunter_architect` (or equivalent) row: `hunter_id`, `assigned_at`, `status`, `architect_brief`, `brief_updated_at`, `last_job_id` (optional).
- **Cardinality:** exactly one active Architect assignment per hunter.

---

## 6. User File

### 6.1 Structured dossier (source of truth — read via SYSTEM)

Architect may request (through SYSTEM) facts from:

- `hunters`
- `hunter_profiles`
- `hunter_analysis` / destiny fields
- `hunter_progression`
- `hunter_system_state`
- `hunter_rules`
- Future: logs, missions, evaluations

### 6.2 `architect_brief` (living markdown/text)

Single text document per hunter. Suggested sections (v1 templates):

```markdown
# Hunter Brief
## Identity
## Goal & Ascension Path
## Current Assessment
## Standing Instructions
## Open Loops
## Last Event
```

**Update triggers (v1):**

| Event | Brief update |
|-------|----------------|
| Architect assigned (init) | Seed all sections from dossier |
| ANALYZE result received | Refresh Assessment + Standing Instructions |
| Profile fields changed (via SYSTEM) | Refresh Goal / Identity; may request re-ANALYZE |
| Future: EVALUATION / LOG cycle | Append Open Loops / Last Event |

**Rules:**

- Brief is never a substitute for DB facts; if brief and dossier disagree, **dossier wins** and brief is corrected on next update.
- Brief content is private to that hunter.

### 6.3 Phone-first vault (PROTOCOL memory)

Per [2026-08-01-phone-first-architect-design.md](./2026-08-01-phone-first-architect-design.md):

- **Authoritative for PROTOCOL chat + plan:** on-device vault (native Documents / web IndexedDB)
- **Cloud LLM / specialists:** still only via SYSTEM
- **Supabase snapshots** (`hunter_vault_snapshots`): weekly or admin-pull copies — never override a richer local vault
- Client writes **local first**, marks dirty, then syncs via `hunter.architect.vault.sync.v1`

---

## 7. Job & Instruction Contracts

### 7.1 How Architect talks to specialists

Architect does **not** HTTP-call specialists in the target design. It emits a **job intent** to SYSTEM:

```ts
type ArchitectJobIntent = {
  hunterId: string;           // must match SYSTEM-resolved hunter; ignored if mismatched
  specialist: 'analyze' | 'log' | 'evaluate' | 'mission' | 'rank' | 'penalty' | 'train' | 'diet' | 'advice';
  workflowId: string;         // e.g. 'hunter.analyze.v1'
  instruction: {
    reason: string;           // short machine+human note for tracing
    focus?: string[];         // optional tags, e.g. ['recalibration']
    constraints?: Record<string, unknown>;
  };
  idempotencyKey?: string;
};
```

SYSTEM:

1. Re-resolves hunter from JWT (ignores forged ids)
2. Traces the run (`agent_runs` / steps)
3. Invokes the specialist
4. Returns a typed envelope to Architect (and/or FE)

### 7.2 v1 allowlisted jobs

| Job | workflowId | When Architect may issue |
|-----|------------|---------------------------|
| Initialize path | `hunter.initialize.v1` | Owned jointly with SYSTEM at assignment time (SYSTEM drives; Architect seeds brief after) |
| Analyze | `hunter.analyze.v1` | After init; on profile change; on explicit recalibration |

Future specialists join this table before Architect may call them.

### 7.3 Instruction quality rules

- Instructions must be **executable** (map to an allowlisted workflow).
- No instruction may request “grant rank S” or “add 500 XP”.
- Tone of any user-visible notice remains mechanical SYSTEM voice (Bible).

---

## 8. Error & Escalation

| Failure | Architect behavior |
|---------|-------------------|
| SYSTEM sync/auth failure | Do not invent data; surface retry via SYSTEM/FE |
| Specialist returns `PROFILE_INCOMPLETE` | Do not assign further evolution jobs; brief notes Open Loop: registration |
| Specialist timeout / 5xx | Record Last Event failure; allow one retry intent; then stop |
| Brief write failure | Keep dossier authoritative; retry brief update once |
| Unknown specialist id | Reject intent; never guess |

Architect never escalates by writing to another hunter’s rows.

---

## 9. Relation to Legacy Orchestrator Spec

[PROJECT_HUNTER_SYSTEM_AGENT_SPEC.md](./PROJECT_HUNTER_SYSTEM_AGENT_SPEC.md) remains the historical Bible-mapping for init workflow detail.

**Split going forward:**

| Concern | Owner |
|---------|--------|
| Identity sync, onboarding save, DB isolation, runner | **SYSTEM** |
| Per-hunter planning, brief, specialist instructions | **ARCHITECT** (this file) |
| Metrics / destiny / starting rank math | **ANALYZE** |

Init workflow order (unchanged intent):

1. Validate payload (SYSTEM)
2. Load/create hunter (SYSTEM)
3. Validate profile completeness (SYSTEM)
4. Calculate metrics (ANALYZE via SYSTEM)
5. Apply rules / unlock policy (SYSTEM persist; Architect records intent in brief)
6. Assign Architect + seed brief
7. Generate SYSTEM response
8. Return verdict to FE

---

## 10. Testing Expectations

- Unit: brief seed from dossier fixtures
- Unit: job intent allowlist rejects unknown specialists / illegal constraints
- Integration: JWT hunter A cannot read/write hunter B brief
- Integration: ANALYZE invoked only through SYSTEM path when Architect requests analyze
- Regression: completed hunters still route home; init still produces analysis + state

---

## 11. Implementation Sketch (not a substitute for a plan)

1. Registry rename ORCHESTRATOR → ARCHITECT; add SYSTEM as root gateway  
2. Migration: `hunter_architect` + `architect_brief`  
3. SYSTEM entry wraps/extends `agent-runner` + onboarding data paths  
4. Architect module: assign, seed brief, emit job intents  
5. Wire init completion → Architect assignment  
6. Update ANALYZE “Related Agents” to name ARCHITECT  

---

## 12. Naming Cheat Sheet

| You say | Agent ID | Role |
|---------|----------|------|
| **SYSTEM** | `system` | Gateway + data plane |
| **ARCHITECT** | `architect` | Per-hunter control brain |
| **ANALYZE** | `analyze` | Evolution specialist |
