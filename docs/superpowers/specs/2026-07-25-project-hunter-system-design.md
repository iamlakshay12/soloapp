# Project Hunter SYSTEM — Design Spec (v1 MVP)

**Date:** 2026-07-25  
**Status:** Draft — pending user review  
**Scope:** Core loop only (Phase 1)

---

## 1. Summary

Project Hunter SYSTEM is a Solo Leveling–inspired AI fitness operating system. The user is a **Hunter**; the application is the **SYSTEM**. The SYSTEM evaluates actions, assigns XP, issues verdicts, and governs rank progression.

**v1 ships the core loop:**

> Awakening → Hunter Registration → SYSTEM Initialization → Dashboard → Action Reporting → SYSTEM Evaluation → XP

**Out of scope for v1:** Diet consultation, training protocol, advice chat, weekly reviews, boss battles, penalty automation, rank auto-promotion.

---

## 2. Architecture

```
┌──────────────────────────────────────┐
│     Expo App (apps/mobile/)          │
│  • UI only — zero business logic     │
│  • Clerk Google sign-in              │
│  • React Native Reusables + theme    │
└──────────────┬───────────────────────┘
               │ HTTPS + Clerk JWT (Bearer)
               ▼
┌──────────────────────────────────────┐
│   SYSTEM API on Vercel (apps/api/)   │
│  • Hono router on Vercel Functions   │
│  • All game rules + AI evaluation    │
│  • Clerk JWT verification            │
└──────────────┬───────────────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
  Supabase          LLM Provider
  (Postgres)        (Groq v1, swappable)
```

### Monorepo layout

```
/
├── apps/
│   ├── mobile/          # Expo (React Native) — the Hunter app
│   └── api/             # Hono API — deployed to Vercel
├── packages/
│   └── shared/          # Shared TypeScript types + Zod schemas
├── docs/
│   └── superpowers/
├── supabase/
│   └── migrations/      # SQL migrations
└── package.json         # npm/pnpm workspaces root
```

The existing `solo-app/` Next.js scaffold was removed — not used for v1.

### Key principles

1. **Frontend never contains business logic** — no XP math, rank changes, or verdict generation on the client.
2. **All writes go through the SYSTEM API** — mobile app calls API; API writes to Supabase with service role.
3. **Mobile reads display data via API** — not direct Supabase client on mobile (keeps RLS simple, secrets off device).
4. **LLM is swappable** — `ILLMProvider` interface; v1 uses Groq (fast/cheap); migrate to self-hosted in Phase 3.

---

## 3. Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile app | Expo SDK 52+, Expo Router, TypeScript |
| Mobile UI | React Native Reusables, NativeWind v4, Lovable cyberpunk theme |
| Auth | Clerk (`@clerk/clerk-expo`) — Google sign-in |
| API | Hono on Vercel Serverless Functions |
| Database | Supabase (Postgres) |
| LLM (v1) | Groq API (`llama-3.3-70b-versatile` or equivalent) |
| Validation | Zod (shared schemas in `packages/shared`) |
| Deploy — API | Vercel (`vercel deploy`) |
| Deploy — Mobile | Expo EAS Build (`eas build`) |

---

## 4. Auth Flow (Clerk + Supabase)

```
1. User taps "Accept Awakening" → Clerk Google OAuth
2. Clerk session established on mobile
3. Mobile obtains Clerk JWT via getToken()
4. Mobile sends JWT as Authorization: Bearer <token> on every API call
5. API verifies JWT with Clerk backend SDK (@clerk/backend)
6. API maps clerk_user_id → hunters row
7. Clerk webhook (user.created) → POST /api/webhooks/clerk → creates hunters row
```

**Clerk webhook handler** (`apps/api/src/routes/webhooks/clerk.ts`):
- Event: `user.created`
- Action: Insert `hunters` row with `clerk_user_id`, default rank `F`, xp `0`, `initialized: false`

**No Supabase Auth** — Clerk is the sole identity provider. Supabase is database-only, accessed by API with service role key (never exposed to mobile).

---

## 5. Mobile Screens & User Flow (v1)

### 5.1 Screen map

| Screen | Route | Purpose |
|--------|-------|---------|
| Awakening | `/` | Hero + "Accept Awakening" CTA |
| Sign In | `/sign-in` | Clerk Google OAuth (redirect if unauthenticated) |
| Onboarding | `/onboarding` | Multi-step SYSTEM registration |
| Initialization | `/initialization` | SYSTEM processing + analysis reveal |
| Dashboard | `/dashboard` | Hunter status, stats, quick actions |
| Log Action | `/log` | Report workout/nutrition/sleep |
| Verdict | `/verdict/[logId]` | SYSTEM evaluation result |

### 5.2 Onboarding steps (match Lovable theme, SYSTEM voice)

1. Biological classification (Male / Female)
2. Age (number input)
3. Height (cm or ft/in text)
4. Current weight (kg or lb)
5. Training days per week (1-2 / 3-4 / 5-6 / Daily)
6. Target weight (kg or lb)
7. Primary objective (Fat Loss / Muscle Gain / Body Recomposition / Athletic Performance / General Fitness)

Each step shows a SYSTEM terminal modal with "SYSTEM processing…" transition between steps.

### 5.3 Initialization screen

After onboarding submit:
1. Call `POST /api/onboard` with all registration data
2. API calculates BMR, TDEE, protein target, body fat estimate, difficulty score
3. API assigns initial rank (F or E based on goal difficulty)
4. Show "SYSTEM ANALYSIS" screen with calculated metrics
5. Show rank assignment + "Initialize Dashboard" button
6. Navigate to Dashboard

### 5.4 Dashboard (home)

Display (all from `GET /api/dashboard`):
- Level (derived from XP thresholds)
- Rank badge (F–SS)
- EXP bar (current / next level threshold)
- Stats cards: Total EXP, Quests Done, Day Streak, Levels to 100
- SYSTEM status message
- Buttons: **Log Activity**, **View Profile**

### 5.5 Log Action flow

1. User selects log type: **Workout** | **Nutrition** | **Sleep**
2. User enters free-text description (e.g. "Push day: bench 4x8, OHP 3x10")
3. Submit → `POST /api/evaluate-log`
4. API calls LLM with SYSTEM persona + hunter context + log text
5. API returns: verdict text, XP awarded, updated hunter stats
6. Navigate to Verdict screen showing SYSTEM response

### 5.6 Navigation (bottom tab bar — v1 minimal)

| Tab | Screen |
|-----|--------|
| Home | Dashboard |
| Log | Log Action |
| Profile | Hunter profile (read-only stats from API) |

Train, Advice, Diet tabs are **placeholder/disabled** in v1 with "SYSTEM LOCKED — Rank insufficient" message.

### 5.7 Visual theme (from Lovable prototype)

- Background: `#0a0612` (near-black purple)
- Primary accent: `#a855f7` (purple-500)
- Glow borders on modals/cards
- Font: monospace for SYSTEM messages, sans-serif for UI labels
- CRT scanline overlay (subtle, optional)
- Modal windows styled as SYSTEM terminal dialogs with header bar ("SYSTEM" + three dots)

---

## 6. SYSTEM API Endpoints

Base URL: `https://<project>.vercel.app/api`

All authenticated routes require `Authorization: Bearer <clerk_jwt>`.

### 6.1 `POST /api/webhooks/clerk`

- **Auth:** Clerk webhook signature verification
- **Body:** Clerk webhook payload
- **Action:** Create hunter on `user.created`

### 6.2 `POST /api/onboard`

- **Auth:** Required
- **Body:**

```typescript
{
  gender: "male" | "female";
  age: number;
  heightCm: number;
  weightKg: number;
  trainingDaysPerWeek: "1-2" | "3-4" | "5-6" | "daily";
  targetWeightKg: number;
  objective: "fat_loss" | "muscle_gain" | "recomposition" | "athletic" | "general_fitness";
}
```

- **Action:**
  - Validate input (Zod)
  - Calculate metrics (BMR via Mifflin-St Jeor, TDEE, protein target, estimated body fat, difficulty score)
  - Assign initial rank (F default; E if favorable metrics)
  - Update `hunters` row: set body stats, metrics, `initialized: true`
  - Insert `rank_history` row
- **Response:**

```typescript
{
  analysis: {
    bodyFatPercent: number;
    bmr: number;
    tdee: number;
    targetCalories: number;
    proteinTargetG: number;
    estimatedWeeksToGoal: number;
    difficultyScore: number; // 0-100
  };
  rank: "F" | "E" | "D" | "C" | "B" | "A" | "S" | "SS";
  level: number;
}
```

### 6.3 `GET /api/dashboard`

- **Auth:** Required
- **Response:**

```typescript
{
  hunter: {
    id: string;
    rank: string;
    level: number;
    xp: number;
    xpToNextLevel: number;
    dayStreak: number;
    questsCompleted: number;
    levelsTo100: number;
    objective: string;
    initialized: boolean;
  };
  systemMessage: string; // e.g. "Hunter registration complete. Rank C assigned."
}
```

### 6.4 `POST /api/evaluate-log`

- **Auth:** Required
- **Body:**

```typescript
{
  logType: "workout" | "nutrition" | "sleep";
  description: string; // free-text from user
}
```

- **Action:**
  1. Fetch hunter profile + recent logs (last 7 days)
  2. Build LLM prompt with SYSTEM persona, hunter context, log text
  3. LLM returns structured JSON: `{ verdict: string, xpAwarded: number, severity: "pass" | "partial" | "fail" }`
  4. Apply XP to hunter (cap daily XP at 500 for v1)
  5. Recalculate level from XP thresholds
  6. Insert `hunter_logs` row
  7. Update streak if applicable
- **Response:**

```typescript
{
  logId: string;
  verdict: string;
  xpAwarded: number;
  xpTotal: number;
  level: number;
  rank: string;
  systemNotice: string; // short header like "VERDICT" or "SYSTEM NOTICE"
}
```

### 6.5 `GET /api/profile`

- **Auth:** Required
- **Response:** Full hunter profile + physical data + objectives (read-only)

### 6.6 `GET /api/logs`

- **Auth:** Required
- **Query:** `?limit=20&offset=0`
- **Response:** Paginated list of hunter logs with verdicts

---

## 7. SYSTEM Persona & AI Evaluation

### 7.1 System prompt (fixed, never user-editable)

```
You are the SYSTEM — an authoritative, impersonal fitness evaluation engine
inspired by Solo Leveling. You govern Hunter progression.

RULES:
- Never say "Good job!", "Great work!", or encouragement
- Use phrases: SYSTEM NOTICE, MISSION ACCEPTED, VERDICT, PENALTY APPLIED,
  RANK ADVANCED, INSUFFICIENT DISCIPLINE DETECTED
- Be concise, clinical, authoritative
- Evaluate the Hunter's reported action against their objective and rank
- Award XP based on effort, specificity, and consistency (0-200 per log)
- Return ONLY valid JSON matching the schema

Hunter context will be provided. Evaluate the log accordingly.
```

### 7.2 LLM response schema (structured output)

```typescript
{
  verdict: string;      // 2-4 sentences, SYSTEM voice
  xpAwarded: number;    // 0-200
  severity: "pass" | "partial" | "fail";
  systemNotice: string; // one of: "VERDICT", "SYSTEM NOTICE", "PENALTY APPLIED"
}
```

### 7.3 XP & Level rules (v1 — deterministic, server-side)

| Action | XP Range |
|--------|----------|
| Detailed workout log | 50–150 |
| Vague workout log | 10–30 |
| Nutrition log with macros | 30–80 |
| Sleep log | 20–50 |
| Daily cap | 500 XP |

**Level thresholds:** Level N requires `N * 200` total XP (Level 1 = 0, Level 2 = 200, Level 3 = 600, …).

**Rank thresholds (v1 — display only, no auto-promotion):**

| Rank | Min Level |
|------|-----------|
| F | 1 |
| E | 5 |
| D | 10 |
| C | 20 |
| B | 35 |
| A | 50 |
| S | 75 |
| SS | 95 |

Rank displayed = highest rank where `level >= minLevel`. Auto-promotion ceremonies deferred to Phase 2.

### 7.4 LLM provider interface

```typescript
interface ILLMProvider {
  evaluate(context: EvaluationContext): Promise<EvaluationResult>;
}

interface EvaluationContext {
  hunter: HunterProfile;
  recentLogs: HunterLog[];
  logType: string;
  description: string;
}

interface EvaluationResult {
  verdict: string;
  xpAwarded: number;
  severity: "pass" | "partial" | "fail";
  systemNotice: string;
}
```

v1 implementation: `GroqLLMProvider`. Future: `OllamaLLMProvider`, `OpenAILLMProvider`.

---

## 8. Database Schema

### 8.1 `hunters`

```sql
CREATE TABLE hunters (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_user_id   TEXT UNIQUE NOT NULL,
  display_name    TEXT,
  gender          TEXT CHECK (gender IN ('male', 'female')),
  age             INTEGER,
  height_cm       NUMERIC(5,1),
  weight_kg       NUMERIC(5,1),
  target_weight_kg NUMERIC(5,1),
  training_days   TEXT,
  objective       TEXT,
  -- Calculated metrics
  body_fat_pct    NUMERIC(4,1),
  bmr             INTEGER,
  tdee            INTEGER,
  target_calories INTEGER,
  protein_target_g INTEGER,
  difficulty_score INTEGER DEFAULT 50,
  -- Progression
  rank            TEXT NOT NULL DEFAULT 'F'
                  CHECK (rank IN ('F','E','D','C','B','A','S','SS')),
  xp              INTEGER NOT NULL DEFAULT 0,
  level           INTEGER NOT NULL DEFAULT 1,
  day_streak      INTEGER NOT NULL DEFAULT 0,
  quests_completed INTEGER NOT NULL DEFAULT 0,
  last_log_date   DATE,
  initialized     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_hunters_clerk ON hunters(clerk_user_id);
```

### 8.2 `hunter_logs`

```sql
CREATE TABLE hunter_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hunter_id       UUID NOT NULL REFERENCES hunters(id) ON DELETE CASCADE,
  log_type        TEXT NOT NULL CHECK (log_type IN ('workout','nutrition','sleep')),
  description     TEXT NOT NULL,
  verdict         TEXT NOT NULL,
  xp_awarded      INTEGER NOT NULL DEFAULT 0,
  severity        TEXT NOT NULL CHECK (severity IN ('pass','partial','fail')),
  system_notice   TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_logs_hunter ON hunter_logs(hunter_id, created_at DESC);
```

### 8.3 `rank_history`

```sql
CREATE TABLE rank_history (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hunter_id       UUID NOT NULL REFERENCES hunters(id) ON DELETE CASCADE,
  rank            TEXT NOT NULL,
  reason          TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_rank_history_hunter ON rank_history(hunter_id);
```

### 8.4 RLS policy

All tables: **RLS enabled, no public policies.** Only the API service role accesses the database. Mobile never connects to Supabase directly.

### 8.5 Deferred tables (Phase 2+)

- `hunter_rules` — SYSTEM-generated rules per hunter
- `missions` — daily/weekly/special quests
- `diet_profiles` — diet consultation results
- `training_protocols` — weekly training schedules

---

## 9. Error Handling

| Scenario | API Response | Mobile Behavior |
|----------|-------------|-----------------|
| Invalid/missing JWT | 401 Unauthorized | Redirect to sign-in |
| Hunter not found | 404 + auto-create attempt | Retry or show error |
| Hunter not initialized | 403 + `{ code: "NOT_INITIALIZED" }` | Redirect to onboarding |
| LLM failure | 503 + fallback verdict | Show generic SYSTEM notice, award minimum XP (10) |
| Validation error | 400 + Zod errors | Show field-level errors in onboarding |
| Rate limit (10 logs/day) | 429 | Show "SYSTEM OVERLOAD — retry tomorrow" |

---

## 10. Deployment

### 10.1 Vercel (SYSTEM API)

- Project: `hunter-system-api`
- Root: `apps/api`
- Framework: Other (Hono)
- Env vars: `CLERK_SECRET_KEY`, `CLERK_WEBHOOK_SECRET`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `GROQ_API_KEY`
- Deploy: `vercel deploy --prod` from `apps/api`

### 10.2 Supabase

- Create project via Supabase dashboard
- Run migrations from `supabase/migrations/`
- Configure Clerk webhook URL pointing to Vercel API

### 10.3 Expo EAS (Mobile)

- Project: `hunter-system-mobile`
- Root: `apps/mobile`
- Env vars (in `app.config.ts`): `EXPO_PUBLIC_CLERK_PUBLISHABLE_KEY`, `EXPO_PUBLIC_API_URL`
- Build: `eas build --platform all`
- Submit: `eas submit` (Phase 1.5 — after internal testing)

### 10.4 Environment summary

| Variable | Where | Secret? |
|----------|-------|---------|
| `CLERK_PUBLISHABLE_KEY` | Mobile | No |
| `CLERK_SECRET_KEY` | API | Yes |
| `CLERK_WEBHOOK_SECRET` | API | Yes |
| `SUPABASE_URL` | API | No |
| `SUPABASE_SERVICE_ROLE_KEY` | API | Yes |
| `GROQ_API_KEY` | API | Yes |
| `EXPO_PUBLIC_API_URL` | Mobile | No |

---

## 11. Testing Strategy (v1)

| Layer | Approach |
|-------|----------|
| API unit tests | Vitest — XP calculation, level/rank derivation, metric formulas |
| API integration | Vitest + test Supabase — onboard flow, evaluate-log flow |
| LLM evaluation | Mock `ILLMProvider` in tests; manual QA with real Groq |
| Mobile | Manual QA on Expo Go (iOS + Android) |
| E2E (Phase 1.5) | Maestro or Detox for critical flows |

---

## 12. Phase Roadmap

| Phase | Features |
|-------|----------|
| **v1 (this spec)** | Core loop: Awakening, onboarding, dashboard, log, AI verdict, XP |
| **v1.5** | EAS builds, App Store / Play Store submission |
| **Phase 2** | Diet consultation, training protocol, advice chat, rank promotion ceremonies |
| **Phase 3** | Weekly reviews, boss battles, penalty engine, self-hosted LLM option |
| **Phase 4** | `hunter_rules` adaptive SYSTEM, multiplayer guilds (future) |

---

## 13. Global Constraints

- TypeScript strict mode everywhere
- Zod validation on all API inputs/outputs
- No business logic in mobile app
- No Supabase client on mobile (API-only data access)
- SYSTEM persona enforced in all AI output
- All secrets server-side only
- RLS enabled on all Supabase tables
- Mobile must feel native on iOS and Android
- UI theme matches Lovable prototype (purple cyberpunk SYSTEM aesthetic)
