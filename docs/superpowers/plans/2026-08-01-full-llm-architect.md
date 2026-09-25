# Full LLM ARCHITECT Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Assign one persistent ARCHITECT to every initialized hunter and let it lead Train·Diet and weekly updates through SYSTEM using an LLM, a private hunter brief, and allowlisted specialist jobs.

**Architecture:** Mobile sends typed workflows only to `agent-runner` (SYSTEM). SYSTEM resolves the hunter from the Clerk JWT, invokes `architect-agent`, persists the hunter-scoped brief/chat/plan, and executes any allowlisted ANALYZE request as a traced child step. ARCHITECT never receives a service-role key on the client and never trusts a client-supplied hunter ID.

**Tech Stack:** Expo Router, Clerk, Supabase Edge Functions/Postgres, Deno tests, OpenAI-compatible chat-completions API.

## Global Constraints

- SYSTEM is the sole mobile workflow entry.
- One active ARCHITECT and one living markdown brief per hunter.
- Every DB access is scoped by the hunter resolved from the verified Clerk JWT.
- ARCHITECT can request only registered typed workflows; v1 child execution is limited to `hunter.analyze.v1`.
- Train·Diet chat is always unlocked; Diet displays the persisted protocol plan.
- Weekly biometric updates pass through ARCHITECT before ANALYZE.
- LLM output is parsed and normalized; it cannot grant XP/rank or invent workflow IDs.
- Missing/failed LLM credentials use explicit template mode and return `usedLlm: false`.

---

### Task 1: ARCHITECT schema and isolation

**Files:**
- Create: `supabase/migrations/*_architect_memory_protocol.sql`

**Produces:** `hunter_architect`, `architect_chat_messages`, and `protocol_plans`, all RLS-enabled and revoked from `anon`/`authenticated`.

- [ ] Create migration with one active assignment and plan per `hunter_id`.
- [ ] Apply migration to project `btbutlmtvvpxgahnrbej`.
- [ ] Query tables and constraints to verify schema and public access revocation.

### Task 2: Pure ARCHITECT contracts and LLM normalization

**Files:**
- Create: `supabase/functions/_shared/architect/types.ts`
- Create: `supabase/functions/_shared/architect/seed-brief.ts`
- Create: `supabase/functions/_shared/architect/llm.ts`
- Create: `supabase/functions/_shared/architect/architect.test.ts`

**Produces:** `seedArchitectBrief`, `runArchitectLlm`, normalized `ProtocolPlanPayload`, and filtered `SpecialistJobIntent[]`.

- [ ] Write failing tests for brief seeding, plan normalization, illegal job rejection, and template fallback.
- [ ] Run tests and confirm expected failures.
- [ ] Implement minimal pure contracts and LLM adapter.
- [ ] Run tests until green.

### Task 3: Persistence and assignment

**Files:**
- Create: `supabase/functions/_shared/architect/persist.ts`
- Modify: `supabase/functions/system-initialize/index.ts`

**Produces:** `ensureArchitectAssigned`, dossier/message/plan loaders, and turn persistence.

- [ ] Assign ARCHITECT after successful initialization and on cached initialization.
- [ ] Seed `architect_brief` from the authoritative dossier.
- [ ] Persist every chat turn and latest plan under the resolved hunter only.

### Task 4: SYSTEM workflows and traced specialist dispatch

**Files:**
- Create: `supabase/functions/architect-agent/index.ts`
- Modify: `supabase/functions/_shared/agent-platform/contracts.ts`
- Modify: `supabase/functions/_shared/agent-platform/routing.ts`
- Modify: `supabase/functions/agent-runner/index.ts`
- Modify tests under `supabase/functions/_shared/agent-platform/`

**Produces:** `hunter.architect.protocol.v1`, `hunter.architect.weekly.v1`, and `hunter.architect.get.v1`.

- [ ] Add workflow parsing/routing tests and confirm RED.
- [ ] Route ARCHITECT workflows through SYSTEM.
- [ ] Have SYSTEM execute only allowlisted `hunter.analyze.v1` child jobs without recursively calling itself.
- [ ] Trace ARCHITECT and ANALYZE as separate run steps.
- [ ] Return one typed envelope containing reply, brief metadata, plan, and optional analysis.

### Task 5: Mobile Train, Diet, and weekly integration

**Files:**
- Create: `apps/mobile/lib/run-architect.ts`
- Modify: `apps/mobile/types/agent-platform.ts`
- Modify: `apps/mobile/contexts/ProtocolPlanContext.tsx`
- Modify: `apps/mobile/app/(tabs)/train.tsx`
- Modify: `apps/mobile/app/(tabs)/diet.tsx`
- Modify: `apps/mobile/components/system/WeeklyCheckInPanel.tsx`

**Produces:** persistent multi-turn ARCHITECT chat, server-loaded Diet plan, and weekly ARCHITECT→ANALYZE flow.

- [ ] Replace local Train stub replies with typed ARCHITECT calls.
- [ ] Hydrate recent messages and latest plan from `hunter.architect.get.v1`.
- [ ] Generate/update protocol plans through ARCHITECT.
- [ ] Send weekly weight through `hunter.architect.weekly.v1` and map returned ANALYZE metrics.

### Task 6: Deploy and verify

**Files:**
- Update: `docs/PRODUCT_HUNTER_SYSTEM.md`
- Update: `docs/superpowers/specs/ARCHITECT_AGENT_SPEC.md`
- Update: `docs/superpowers/specs/SYSTEM_AGENTS_REGISTRY.md`

- [ ] Deploy `architect-agent`, `agent-runner`, and `system-initialize` with Clerk verification inside (`verify_jwt: false` at gateway).
- [ ] Confirm LLM secret presence by name only; never print secret values.
- [ ] Verify initialized hunter has exactly one ARCHITECT row.
- [ ] Verify Train turn creates only that hunter’s messages and plan.
- [ ] Verify weekly update traces ARCHITECT then ANALYZE and updates the brief.
- [ ] Run Deno tests, mobile TypeScript, lints, and browser smoke.
