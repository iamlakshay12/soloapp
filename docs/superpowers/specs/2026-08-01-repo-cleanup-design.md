# Repo Cleanup Design (Approach B — Aggressive)

**Date:** 2026-08-01  
**Status:** Executed (user chose B)  
**Scope:** Delete deploy junk, unify service connections, keep product code only

### Self-review
- No TBD placeholders
- Keep list matches remaining tree: `apps/`, `docs/`, `supabase/`, root `package.json` + `.gitignore`
- Hardcoded Supabase defaults removed; env via `.env.local` only
- `@clerk/expo` removed; `@clerk/clerk-expo` sole auth package

---

## Goal

Leave one clean product tree: Expo mobile + Supabase functions + docs. No deploy artifacts, no duplicate Clerk/Supabase wiring, no orphan modules.

## Keep (mandatory)

| Layer | What stays |
|-------|------------|
| Mobile | `apps/mobile/` (Expo app) |
| Backend | `supabase/functions/` (`sync-hunter`, `save-hunter-profile`, `system-initialize`, `analyze-hunter`, `clerk-webhook`, `_shared/`) |
| Migrations | `supabase/migrations/` |
| Docs | `docs/superpowers/specs/` |
| Root | `package.json` (workspace scripts only) |
| Env | `apps/mobile/.env.local` + `.env.example` (template) |

## Delete

- All root `deploy-*`, `mcp-*`, `sys-meta.json`, `deploy-sys-*.ts`
- Entire `scripts/` deploy helper folder
- Orphan `system-initialize/{compute-metrics,generate-rules,system-response}.ts` (index uses `_shared` only)
- Root `node_modules/` (unused)
- Duplicate `apps/mobile/.env` (keep `.env.local`)
- Unused npm dep `@clerk/expo` (code uses `@clerk/clerk-expo` only)

## Fix

- Add root `.gitignore` (node_modules, .env*, deploy junk patterns, .netlify)
- Merge root `app.json` EAS projectId into `apps/mobile/app.json`, then delete root `app.json`
- `supabase-config.ts`: remove hardcoded URL/anon key defaults; require env
- Single Clerk package: `@clerk/clerk-expo`

## Verify

- `npx expo start -c --web` from `apps/mobile` loads on localhost

## Out of scope

- Rewriting agent architecture / LOG agent
- Doc rewrite of Vercel mentions (follow-up)
- Deploying edge functions
