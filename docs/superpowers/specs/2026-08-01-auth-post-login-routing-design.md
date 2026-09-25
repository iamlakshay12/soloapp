# Auth Post-Login Routing Design

**Date:** 2026-08-01  
**Status:** Approved  
**Product:** Project Hunter SYSTEM (Expo mobile + Clerk + Supabase)  
**Approach:** Client routing gate + extend sync (Approach 1)

## Problem

Today every authenticated session lands on `/awakening`, including returning hunters who already finished registration. Sign Up and Sign In both hard-redirect to awakening via `auth.tsx`, `index.tsx`, and Clerk fallback URLs.

## Goals

1. After authentication, route by **registration progress**, not by which button was pressed (profile-first).
2. New / incomplete hunters resume at the correct registration beat (Awakening or first incomplete onboarding step).
3. Completed hunters go to home `/(tabs)` and hydrate user/SYSTEM data from the authenticated session.
4. Sign Up vs Sign In differ in **copy only** on the auth screens.

## Non-goals

- Redesigning onboarding question content or analysis UX.
- Replacing Clerk or changing Supabase tenancy.
- Persisting Awakening “accepted” as its own DB flag (inferred from profile progress).
- Building Workforce OS / agent-platform work in this slice.

## Architecture (approved)

### Destination table

| State | Destination |
|--------|-------------|
| Not signed in | `/` or `/auth` |
| Signed in, no onboarding fields yet | `/awakening` |
| Signed in, profile partial (`completed_at` is null) | `/onboarding` at first incomplete step |
| Signed in, `completed_at` set | `/(tabs)` + hydrate data |

### Flow

```
Auth success OR app open while signed in
        → sync-hunter (Clerk → hunters row)
        → load hunter_profiles (via extended sync response)
        → resolveDestination(profile)
        → awakening | onboarding(+step) | home
```

### Single resolver

One pure function owns routing:

`resolveAuthDestination(profile | null) → { href, onboardingStep? }`

Used by:

- Post-auth navigation from `/auth` (after `setActive`)
- Signed-in hit on `/` (replace current always-`/awakening` redirect)
- Session restore / app cold start when Clerk reports signed in
- Soft guards: completed users on `/awakening` or `/onboarding` → home; incomplete users on `/(tabs)` → resume destination

Clerk `signInFallbackRedirectUrl` / `signUpFallbackRedirectUrl` / deprecated after-sign URLs should point at a neutral entry (e.g. `/` or a tiny `/auth/continue` that only runs the resolver), **not** hardcode `/awakening`.

## Components

| Unit | Responsibility |
|------|----------------|
| `resolveAuthDestination` | Pure: profile fields → destination + resume step |
| `resolveOnboardingStep` | Pure: first missing field in fixed step order |
| Extended `sync-hunter` | Upsert hunter **and** return linked `hunter_profiles` row (or null) + `registrationComplete` |
| `useAuthRouteResolution` (or equivalent) | Client hook: token → sync → resolve → `router.replace` |
| Auth / index / awakening / onboarding / tabs | Call or respect the resolver; remove always-awakening redirects |
| Home hydrate | On completed route to tabs: load analysis / system state needed for dashboard (existing analyze/init paths if already available; otherwise show home shell and fetch) |

### Onboarding step order (resume)

Match current wizard order (excluding transient `processing`):

1. `initiate` — shown only when opening onboarding with zero saved fields (fresh Accept Awakening). On resume, if any field is already saved, skip `initiate` and open the first missing data step.
2. `gender`
3. `age`
4. `height`
5. `weight`
6. `training-days`
7. `target-weight`
8. `objective`
9. `hunter-goal`

**Awakening vs onboarding:** If profile is null or all registration fields are empty → `/awakening`. After Accept Awakening → `/onboarding` at `initiate`. If any field is saved and `completed_at` is null → skip Awakening, open `/onboarding` at the first missing step, and hydrate prior answers into `RegistrationContext`.

Resume step is derived from which columns are non-null on `hunter_profiles` (already step-saved by the wizard). No new `onboarding_step` column required for v1.

## Data flow

1. Clerk session active → client gets JWT via `getToken`.
2. `POST sync-hunter` with Bearer token.
3. Response shape (extended):

```ts
{
  ok: true,
  hunter: { id, clerk_user_id, email, display_name, last_sign_in_at, initialized? },
  profile: null | {
    gender, age_years, height_cm, weight_kg, target_weight_kg,
    training_days, objective, personal_goal, completed_at, /* display fields */
  },
  registrationComplete: boolean // === Boolean(profile?.completed_at)
}
```

4. Client maps profile → destination.
5. If `registrationComplete`, navigate home and hydrate:
   - Prefer existing analysis fetch / system-initialize read paths already used by the app.
   - Do not re-run full ANALYZE unless product already does so on home; load stored analysis when present.
6. If incomplete, navigate to awakening or onboarding; onboarding wizard initializes `step` from `resolveOnboardingStep` and hydrates `RegistrationContext` from profile fields.

## Error handling

| Failure | Behavior |
|---------|----------|
| Clerk not loaded | Wait; show existing loading / gate |
| No token | Treat as signed out → `/` |
| `sync-hunter` network/4xx/5xx | Show recoverable error on a small “SYSTEM sync failed / Retry” surface; do not send completed users to awakening by default |
| Profile missing but hunter exists | Treat as no progress → `/awakening` |
| Resolver race (double navigate) | Idempotent `replace`; ignore if already on target href |

## Testing

- Unit: `resolveOnboardingStep` for empty, mid-chain, and complete profiles.
- Unit: `resolveAuthDestination` for null profile, partial, completed.
- Manual smoke:
  1. New Sign Up → Awakening → onboarding.
  2. Leave mid-onboarding, Sign In → resumes correct step with prior answers filled.
  3. Complete registration, Sign In → home with data.
  4. Cold start while signed in → same rules as (2)/(3).

## Relation to current architecture

- Keeps Awakening as first beat for zero-progress hunters (approved).
- Completion gate = `hunter_profiles.completed_at` (approved option A).
- Complements agent-platform work but does not depend on `agent-runner` for routing.
- Does not require git/worktree; ships as a focused auth-routing slice.

## Implementation sketch (not a plan)

1. Extend `sync-hunter` response with profile + `registrationComplete`.
2. Add pure resolvers + tests.
3. Add client resolution hook / helper.
4. Wire auth, index, Clerk redirects, awakening/onboarding/tabs guards.
5. Hydrate registration + home data on resume/complete.
6. Manual smoke on localhost web.
