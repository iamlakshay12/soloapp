# Agent Platform First Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route Hunter initialization and analysis through one observable Supabase Agent Platform endpoint while preserving existing app behavior and applying uppercase onboarding copy.

**Architecture:** Add an `agent-runner` Edge Function that authenticates the Hunter, creates an observable run, routes a typed workflow to the existing ORCHESTRATOR or ANALYZE endpoint, records the step, and returns the existing result in a stable envelope. The mobile app uses one runner client while its existing initialization and analysis helpers remain compatibility adapters.

**Tech Stack:** Expo 57, React Native 0.86, TypeScript 6, Clerk, Supabase Edge Functions (Deno), Supabase Postgres.

## Global Constraints

- Supabase remains the sole backend and authoritative data store.
- Clerk JWT is required for every workflow.
- `SUPABASE_SERVICE_ROLE_KEY` remains server-only.
- The frontend performs no rank, XP, destiny, target or unlock calculations.
- ORCHESTRATOR and ANALYZE retain their existing deterministic logic.
- Existing `system-initialize` and `analyze-hunter` endpoints continue to work.
- Physical Hunter table names may change; mobile and workflow contracts must not expose them.
- All onboarding questions are uppercase; hints may remain sentence case.
- Do not add an LLM, vector store, Workforce UI, LOG or EVALUATE in this slice.
- Do not create Git commits unless the user explicitly requests them.

---

## File Structure

### Create

- `supabase/functions/_shared/agent-platform/contracts.ts` — workflow and response contracts.
- `supabase/functions/_shared/agent-platform/contracts.test.ts` — request parser tests.
- `supabase/functions/_shared/agent-platform/sanitize.ts` — trace-safe summaries.
- `supabase/functions/_shared/agent-platform/sanitize.test.ts` — deterministic sanitization tests.
- `supabase/functions/agent-runner/index.ts` — auth, idempotency, routing and tracing.
- `apps/mobile/types/agent-platform.ts` — mobile runner types.
- `apps/mobile/lib/run-agent.ts` — single Agent Platform HTTP client.

### Modify

- `apps/mobile/lib/run-system-initialization.ts` — call `runAgent`.
- `apps/mobile/lib/run-hunter-analysis.ts` — call `runAgent`.
- `apps/mobile/components/onboarding/OnboardingWizard.tsx` — uppercase prompts and action labels.
- `docs/superpowers/specs/SYSTEM_AGENTS_REGISTRY.md` — register `agent-runner` as the platform entry point.

### Generate during Task 2

- Run `npx supabase migration new agent_platform_runs`; the CLI prints and creates the exact file under `supabase/migrations/`. Record that path in the task log and do not hand-invent its timestamp.

---

### Task 1: Define the Agent Platform Contract

**Files:**
- Create: `supabase/functions/_shared/agent-platform/contracts.ts`
- Test: `supabase/functions/_shared/agent-platform/contracts.test.ts`
- Create: `supabase/functions/_shared/agent-platform/sanitize.ts`
- Test: `supabase/functions/_shared/agent-platform/sanitize.test.ts`

**Interfaces:**
- Produces:
  - `HunterWorkflowId`
  - `AgentRunRequest`
  - `AgentRunEnvelope<T>`
  - `parseAgentRunRequest(input: unknown)`
  - `sanitizeTraceValue(input: unknown)`
- Consumes: no application internals.

- [ ] **Step 1: Write sanitization tests**

```ts
import { assertEquals } from 'jsr:@std/assert';
import { sanitizeTraceValue } from './sanitize.ts';

Deno.test('redacts secret-shaped fields', () => {
  assertEquals(
    sanitizeTraceValue({ token: 'secret', personalGoal: 'Run a 5K' }),
    { token: '[REDACTED]', personalGoal: 'Run a 5K' },
  );
});

Deno.test('limits long strings', () => {
  assertEquals(
    sanitizeTraceValue({ notes: 'x'.repeat(600) }),
    { notes: `${'x'.repeat(497)}...` },
  );
});
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```powershell
deno test supabase/functions/_shared/agent-platform/sanitize.test.ts
```

Expected: FAIL because `sanitize.ts` does not exist.

- [ ] **Step 3: Implement trace sanitization**

```ts
const SECRET_KEYS = /token|authorization|secret|password|key/i;
const MAX_STRING_LENGTH = 500;

export function sanitizeTraceValue(input: unknown): unknown {
  if (Array.isArray(input)) return input.map(sanitizeTraceValue);
  if (input && typeof input === 'object') {
    return Object.fromEntries(
      Object.entries(input as Record<string, unknown>).map(([key, value]) => [
        key,
        SECRET_KEYS.test(key) ? '[REDACTED]' : sanitizeTraceValue(value),
      ]),
    );
  }
  if (typeof input === 'string' && input.length > MAX_STRING_LENGTH) {
    return `${input.slice(0, MAX_STRING_LENGTH - 3)}...`;
  }
  return input;
}
```

- [ ] **Step 4: Implement typed contracts and parser**

```ts
export type HunterWorkflowId = 'hunter.initialize.v1' | 'hunter.analyze.v1';

export type AgentRunRequest = {
  workflowId: HunterWorkflowId;
  idempotencyKey?: string;
  payload: Record<string, unknown>;
};

export type AgentRunEnvelope<T> = {
  ok: true;
  runId: string;
  workflowId: HunterWorkflowId;
  status: 'completed';
  result: T;
};

const WORKFLOWS = new Set<HunterWorkflowId>([
  'hunter.initialize.v1',
  'hunter.analyze.v1',
]);

export function parseAgentRunRequest(input: unknown): AgentRunRequest {
  if (!input || typeof input !== 'object') throw new Error('INVALID_REQUEST');
  const value = input as Record<string, unknown>;
  if (!WORKFLOWS.has(value.workflowId as HunterWorkflowId)) {
    throw new Error('UNKNOWN_WORKFLOW');
  }
  if (
    value.idempotencyKey !== undefined &&
    (typeof value.idempotencyKey !== 'string' ||
      value.idempotencyKey.length < 8 ||
      value.idempotencyKey.length > 128)
  ) {
    throw new Error('INVALID_IDEMPOTENCY_KEY');
  }
  return {
    workflowId: value.workflowId as HunterWorkflowId,
    idempotencyKey: value.idempotencyKey as string | undefined,
    payload:
      value.payload && typeof value.payload === 'object'
        ? (value.payload as Record<string, unknown>)
        : {},
  };
}
```

- [ ] **Step 5: Test the request parser**

```ts
import { assertEquals, assertThrows } from 'jsr:@std/assert';
import { parseAgentRunRequest } from './contracts.ts';

Deno.test('parses a supported workflow', () => {
  assertEquals(
    parseAgentRunRequest({
      workflowId: 'hunter.initialize.v1',
      payload: {},
    }),
    {
      workflowId: 'hunter.initialize.v1',
      idempotencyKey: undefined,
      payload: {},
    },
  );
});

Deno.test('rejects an unknown workflow', () => {
  assertThrows(
    () => parseAgentRunRequest({ workflowId: 'arbitrary.function', payload: {} }),
    Error,
    'UNKNOWN_WORKFLOW',
  );
});
```

- [ ] **Step 6: Run tests**

Run:

```powershell
deno test supabase/functions/_shared/agent-platform/*.test.ts
```

Expected: 4 tests PASS.

- [ ] **Step 7: Review checkpoint**

Inspect the diff and confirm the contract has no Hunter table names and traces redact secret-shaped fields.

---

### Task 2: Add Observable Run Storage

**Files:**
- Generate with Supabase CLI: migration named `agent_platform_runs` under `supabase/migrations/`.

**Interfaces:**
- Produces:
  - `public.agent_runs`
  - `public.agent_run_steps`
- Consumes: `public.hunters(id)`.

- [ ] **Step 1: Discover and create the migration with the current CLI**

Run:

```powershell
npx supabase migration new --help
npx supabase migration new agent_platform_runs
```

Expected: Supabase prints the generated migration path.

- [ ] **Step 2: Add run and step tables to the generated migration**

```sql
CREATE TABLE public.agent_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hunter_id UUID NOT NULL REFERENCES public.hunters(id) ON DELETE CASCADE,
  workflow_id TEXT NOT NULL,
  workflow_version INTEGER NOT NULL DEFAULT 1 CHECK (workflow_version >= 1),
  status TEXT NOT NULL DEFAULT 'running'
    CHECK (status IN ('running', 'completed', 'failed')),
  idempotency_key TEXT,
  checkpoint TEXT,
  request_summary JSONB NOT NULL DEFAULT '{}',
  response_payload JSONB,
  response_summary JSONB,
  error_code TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX agent_runs_idempotency_unique
  ON public.agent_runs (hunter_id, workflow_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX agent_runs_hunter_started_idx
  ON public.agent_runs (hunter_id, started_at DESC);

CREATE TABLE public.agent_run_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID NOT NULL REFERENCES public.agent_runs(id) ON DELETE CASCADE,
  agent_id TEXT NOT NULL,
  sequence INTEGER NOT NULL CHECK (sequence >= 1),
  status TEXT NOT NULL DEFAULT 'running'
    CHECK (status IN ('running', 'completed', 'failed')),
  input_summary JSONB NOT NULL DEFAULT '{}',
  output_summary JSONB,
  validation_result JSONB,
  error_code TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  UNIQUE (run_id, sequence)
);

CREATE INDEX agent_run_steps_run_sequence_idx
  ON public.agent_run_steps (run_id, sequence);

ALTER TABLE public.agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_run_steps ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.agent_runs IS
  'Server-only Agent Platform workflow runs. Accessed with the service role.';
COMMENT ON TABLE public.agent_run_steps IS
  'Server-only observable steps within an Agent Platform run.';
```

No public RLS policy is added: mobile accesses these tables only through the authenticated Edge Function.

- [ ] **Step 3: Apply the migration to the linked project**

Use Supabase MCP `apply_migration` with project `btbutlmtvvpxgahnrbej`, migration name `agent_platform_runs`, and the reviewed SQL.

Expected: migration succeeds once.

- [ ] **Step 4: Verify schema and security**

Use Supabase MCP:

- `list_tables` to confirm both tables exist with RLS enabled;
- `get_advisors` to inspect security and performance warnings.

Expected: tables exist, RLS is enabled, and no critical security advisor issue was introduced.

- [ ] **Step 5: Review checkpoint**

Confirm the migration is present locally and remote schema matches it.

---

### Task 3: Implement the Observable Agent Runner

**Files:**
- Create: `supabase/functions/agent-runner/index.ts`

**Interfaces:**
- Consumes:
  - `parseAgentRunRequest(input)`
  - `sanitizeTraceValue(input)`
  - Clerk bearer token
  - existing `system-initialize` and `analyze-hunter` endpoints
- Produces:
  - `POST /functions/v1/agent-runner`
  - `AgentRunEnvelope<T>`

- [ ] **Step 1: Implement authentication and workflow routing**

Use this workflow map:

```ts
const WORKFLOW_TARGETS = {
  'hunter.initialize.v1': {
    agentId: 'orchestrator',
    functionName: 'system-initialize',
  },
  'hunter.analyze.v1': {
    agentId: 'analyze',
    functionName: 'analyze-hunter',
  },
} as const;
```

The handler must:

1. handle `OPTIONS`;
2. require `POST`;
3. verify the Clerk bearer token;
4. resolve `hunters.id` from `payload.sub`;
5. parse the workflow request;
6. derive `hunter-initialize-v1` as the default initialization idempotency key, while analysis remains non-idempotent unless the caller supplies a key;
7. reuse a completed run with the same effective idempotency key by returning its `response_payload`;
8. insert one `agent_runs` row and one running step;
9. forward the original bearer token, `SUPABASE_ANON_KEY`, and payload to the target Edge Function;
10. store the complete target response in server-only `response_payload`, while storing only sanitized content in `response_summary`;
11. mark the step/run completed or failed;
12. return:

```ts
{
  ok: true,
  runId,
  workflowId,
  status: 'completed',
  result: targetBody,
}
```

Use `sanitizeTraceValue` for every stored request/response summary. Do not store authorization headers.

- [ ] **Step 2: Prevent recursive routing**

Only the two exact workflow IDs in `WORKFLOW_TARGETS` are accepted. The target URL is constructed from `SUPABASE_URL` plus the hard-coded function name, never from user input:

```ts
const targetUrl =
  `${supabaseUrl}/functions/v1/${WORKFLOW_TARGETS[request.workflowId].functionName}`;
```

- [ ] **Step 3: Forward only required headers**

```ts
const targetResponse = await fetch(targetUrl, {
  method: 'POST',
  headers: {
    Authorization: authHeader,
    apikey: supabaseAnonKey,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(request.payload),
});
```

Require `SUPABASE_ANON_KEY` in addition to `SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY`, and `CLERK_SECRET_KEY`.

- [ ] **Step 4: Add deterministic error mapping**

Return:

- `401 UNAUTHORIZED` for missing/invalid Clerk token;
- `404 HUNTER_NOT_FOUND` when sync has not created the Hunter;
- `400 INVALID_REQUEST`, `UNKNOWN_WORKFLOW`, or `INVALID_IDEMPOTENCY_KEY`;
- the target function status and error code for workflow failures;
- `500 AGENT_PLATFORM_ERROR` only for unexpected failures.

Every failure marks the current run and step as `failed`.

- [ ] **Step 5: Deploy the function**

Use Supabase MCP `deploy_edge_function` with:

- project: `btbutlmtvvpxgahnrbej`;
- function: `agent-runner`;
- entrypoint: `index.ts`;
- files: runner plus both shared Agent Platform modules;
- JWT verification disabled at the platform gateway only because Clerk JWT is verified inside the function.

Expected: active deployment.

- [ ] **Step 6: Verify server behavior**

Call the deployed function without authorization.

Expected: HTTP 401 with `{ "code": "UNAUTHORIZED" }` and no run row.

Call with an authenticated Hunter session through the mobile app in Task 5.

- [ ] **Step 7: Review checkpoint**

Confirm the runner has no game calculations and cannot route arbitrary URLs or function names.

---

### Task 4: Add the Unified Mobile Agent Client

**Files:**
- Create: `apps/mobile/types/agent-platform.ts`
- Create: `apps/mobile/lib/run-agent.ts`
- Modify: `apps/mobile/lib/run-system-initialization.ts`
- Modify: `apps/mobile/lib/run-hunter-analysis.ts`

**Interfaces:**
- Produces:
  - `runAgent<T>(getToken, request)`
  - `AgentRunEnvelope<T>`
- Consumes:
  - `InitializationResult`
  - `AnalyzeHunterResult`
  - `getSupabaseUrl()`
  - `getSupabaseAnonKey()`

- [ ] **Step 1: Add mobile Agent Platform types**

```ts
export type HunterWorkflowId =
  | 'hunter.initialize.v1'
  | 'hunter.analyze.v1';

export type AgentRunEnvelope<T> = {
  ok: true;
  runId: string;
  workflowId: HunterWorkflowId;
  status: 'completed';
  result: T;
};

export type AgentRunRequest = {
  workflowId: HunterWorkflowId;
  payload?: Record<string, unknown>;
  idempotencyKey?: string;
};
```

- [ ] **Step 2: Implement one HTTP client**

```ts
export async function runAgent<T>(
  getToken: GetToken,
  request: AgentRunRequest,
) {
  const token = await getToken({ skipCache: true });
  if (!token) return { ok: false as const, reason: 'no_token' as const };

  try {
    const response = await fetch(
      `${getSupabaseUrl()}/functions/v1/agent-runner`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          apikey: getSupabaseAnonKey(),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...request,
          payload: request.payload ?? {},
        }),
      },
    );
    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      return {
        ok: false as const,
        reason: 'request_failed' as const,
        status: response.status,
        code: body.code as string | undefined,
        body,
      };
    }
    return {
      ok: true as const,
      data: body as AgentRunEnvelope<T>,
    };
  } catch (error) {
    return { ok: false as const, reason: 'network_error' as const, error };
  }
}
```

- [ ] **Step 3: Adapt initialization**

Replace its direct fetch with:

```ts
const result = await runAgent<InitializationResult>(getToken, {
  workflowId: 'hunter.initialize.v1',
  payload: {},
});
```

The runner derives the Hunter-scoped `hunter-initialize-v1` key. Do not generate
a random client key that defeats retries.

Return `result.data.result` so existing screens receive `InitializationResult` unchanged.

- [ ] **Step 4: Adapt analysis**

```ts
const result = await runAgent<AnalyzeHunterResult>(getToken, {
  workflowId: 'hunter.analyze.v1',
  payload: payload
    ? { ...payload, source: 'weekly_update' }
    : { source: 'profile_update' },
});
```

Return `result.data.result` so `mapAnalyzeResult` and all existing hooks remain unchanged.

- [ ] **Step 5: Type-check**

Run:

```powershell
npx tsc --noEmit
```

Expected: exit code 0.

- [ ] **Step 6: Review checkpoint**

Search `apps/mobile` for `/functions/v1/system-initialize` and `/functions/v1/analyze-hunter`.

Expected: no mobile calls remain; only the unified runner URL is called.

---

### Task 5: Apply Uppercase Onboarding Copy

**Files:**
- Modify: `apps/mobile/components/onboarding/OnboardingWizard.tsx`

**Interfaces:**
- Produces: uppercase visible onboarding questions and actions.
- Consumes: existing validation, save and navigation logic unchanged.

- [ ] **Step 1: Replace question copy**

Use these exact strings:

```ts
'INITIATE HUNTER REGISTRATION PROTOCOL.'
'STATE BIOLOGICAL CLASSIFICATION.'
'STATE CURRENT AGE IN YEARS.'
'STATE CURRENT HEIGHT.'
'STATE CURRENT WEIGHT.'
'STATE TRAINING FREQUENCY PER WEEK.'
'STATE TARGET WEIGHT.'
'STATE PRIMARY OBJECTIVE.'
"WHAT IS THE HUNTER'S GOAL?"
```

- [ ] **Step 2: Uppercase action and choice labels**

Use:

```ts
'INITIATE REGISTRATION'
'MALE'
'FEMALE'
'1–2 DAYS'
'3–4 DAYS'
'5–6 DAYS'
'DAILY'
'FAT LOSS'
'MUSCLE GAIN'
'BODY RECOMPOSITION'
'ATHLETIC PERFORMANCE'
'GENERAL FITNESS'
'CONFIRM'
'CONFIRM GOAL'
```

Hints, placeholders and validation errors remain sentence case.

- [ ] **Step 3: Type-check**

Run:

```powershell
npx tsc --noEmit
```

Expected: exit code 0.

- [ ] **Step 4: Review checkpoint**

Search the onboarding file for the previous sentence-case question strings.

Expected: no matches.

---

### Task 6: Document, Verify and Show the Build

**Files:**
- Modify: `docs/superpowers/specs/SYSTEM_AGENTS_REGISTRY.md`

**Interfaces:**
- Produces: accurate platform entry-point documentation.
- Consumes: deployed runner and mobile integration.

- [ ] **Step 1: Update the registry**

Add a Platform Entry section:

```md
## Platform Entry

| Component | Endpoint | Responsibility |
|-----------|----------|----------------|
| Agent Platform runner | `agent-runner` | Authenticates, routes, traces and returns typed workflow results |

Initial workflows:

- `hunter.initialize.v1` → ORCHESTRATOR / `system-initialize`
- `hunter.analyze.v1` → ANALYZE / `analyze-hunter`
```

- [ ] **Step 2: Start a clean local web build**

Before starting, inspect existing terminal sessions and do not duplicate a healthy Expo server.

Run from `apps/mobile` only if needed:

```powershell
npx expo start -c --web --port 8081
```

Expected: `Waiting on http://localhost:8081`.

- [ ] **Step 3: Run browser smoke test**

Open `http://localhost:8081` and verify:

1. SYSTEM Gate renders without an error overlay.
2. Authenticated navigation reaches onboarding.
3. Every onboarding question is uppercase.
4. Hunter Goal saves.
5. Analysis completes through `agent-runner`.
6. Destiny and starting rank render.
7. Dashboard opens.

If authentication requires manual user interaction, stop at SYSTEM Gate and ask the user to sign in; resume the same browser tab afterward.

- [ ] **Step 4: Verify Supabase persistence**

Use Supabase MCP to confirm the authenticated smoke test produced:

- one completed `agent_runs` row;
- one completed `agent_run_steps` row with the correct `agent_id`;
- the existing Hunter analysis/destiny/progression records;
- no secret-bearing fields in trace summaries.

- [ ] **Step 5: Run final checks**

Run:

```powershell
npx tsc --noEmit
```

Expected: exit code 0.

Inspect the Expo terminal after the route has bundled.

Expected: no compile error or unhandled runtime error.

- [ ] **Step 6: Final review checkpoint**

Confirm all success criteria from
`docs/superpowers/specs/2026-08-01-agent-platform-architecture-design.md`
that belong to the initial slice are satisfied. Report deferred items explicitly.
