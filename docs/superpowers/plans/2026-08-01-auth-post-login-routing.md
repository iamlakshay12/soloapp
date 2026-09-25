# Auth Post-Login Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route signed-in hunters by registration progress — incomplete → Awakening/onboarding resume; complete → home with hydrated data.

**Architecture:** Extend `sync-hunter` to return profile + `registrationComplete`. Pure client resolvers decide destination. One navigation helper replaces always-`/awakening` redirects in index, auth, and Clerk fallbacks. Soft guards keep completed/incomplete users on the correct side of the funnel.

**Tech Stack:** Expo Router, Clerk (`@clerk/clerk-expo`), Supabase Edge Function `sync-hunter`, Deno tests for pure resolvers.

**Spec:** `docs/superpowers/specs/2026-08-01-auth-post-login-routing-design.md`

## Global Constraints

- Profile-first routing (Sign Up / Sign In copy only; destination from `completed_at` / fields)
- Completion gate = `hunter_profiles.completed_at`
- Zero progress → `/awakening`; partial → `/onboarding` at first missing step; complete → `/(tabs)`
- No new `onboarding_step` column
- Clerk JWT verified inside edge function (`verify_jwt: false` at gateway)

## File map

| File | Role |
|------|------|
| `supabase/functions/sync-hunter/index.ts` | Return hunter + profile + `registrationComplete` |
| `apps/mobile/lib/auth-routing.ts` | Pure `resolveOnboardingStep` + `resolveAuthDestination` |
| `supabase/tests/auth-routing/auth-routing.test.ts` | Deno unit tests |
| `apps/mobile/lib/sync-hunter.ts` | Surface profile fields from sync response |
| `apps/mobile/lib/profile-to-registration.ts` | Map DB profile → `RegistrationData` |
| `apps/mobile/hooks/useResolveAuthRoute.ts` | Sync + resolve + `router.replace` |
| `apps/mobile/components/auth/ClerkProvider.tsx` | Neutral fallback URLs (`/`) |
| `apps/mobile/app/index.tsx` | Signed-in → resolve (not always awakening) |
| `apps/mobile/app/auth.tsx` | Post-auth + signed-in → resolve |
| `apps/mobile/app/awakening.tsx` | Guard: complete → home |
| `apps/mobile/app/onboarding.tsx` / wizard | Resume step + hydrate; guard complete → home |
| `apps/mobile/app/(tabs)/_layout.tsx` or index | Guard: incomplete → resume |

---

### Task 1: Extend sync-hunter

**Files:**
- Modify: `supabase/functions/sync-hunter/index.ts`
- Modify: `apps/mobile/lib/sync-hunter.ts`

- [x] After hunter upsert, select `hunter_profiles` for `hunter_id`
- [x] Return `{ ok, hunter, profile, registrationComplete }`
- [x] Update mobile `syncHunterToSupabase` return type
- [x] Deploy edge function with `verify_jwt: false`

### Task 2: Pure resolvers + tests

**Files:**
- Create: `apps/mobile/lib/auth-routing.ts`
- Create: `supabase/tests/auth-routing/auth-routing.test.ts`

- [x] Write failing Deno tests (empty / partial / complete)
- [x] Implement `resolveOnboardingStep` + `resolveAuthDestination`
- [x] Run tests until green

### Task 3: Client resolution hook + wire screens

**Files:**
- Create: `apps/mobile/hooks/useResolveAuthRoute.ts` (or `lib/resolve-and-navigate.ts`)
- Create: `apps/mobile/lib/profile-to-registration.ts`
- Modify: ClerkProvider, index, auth, awakening, onboarding, tabs

- [x] Hook: sync → resolve → replace; expose status for loading UI
- [x] Replace always-awakening redirects
- [x] Onboarding accepts initial step + hydrate from profile
- [x] Soft guards both directions

### Task 4: Smoke verify

- [x] Completed hunter (`completed_at` set) → home after reload/sign-in
- [ ] Incomplete / new → awakening or resume step
- [x] Confirm no always-awakening loop
