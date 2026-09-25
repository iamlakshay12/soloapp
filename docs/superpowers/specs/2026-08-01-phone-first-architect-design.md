# Phone-First Architect Design

**Date:** 2026-08-01  
**Status:** Approved  
**Related:** [ARCHITECT_AGENT_SPEC.md](./ARCHITECT_AGENT_SPEC.md), [PRODUCT_HUNTER_SYSTEM.md](../../PRODUCT_HUNTER_SYSTEM.md), [SYSTEM_AGENTS_REGISTRY.md](./SYSTEM_AGENTS_REGISTRY.md)

## Locked decisions

| Topic | Choice |
|--------|--------|
| Approach | Local Architect vault + SYSTEM sync API |
| Memory source of truth | Phone-first vault (native Documents / web IndexedDB) |
| Thinking / LLM | Cloud via SYSTEM (not on-device) |
| Sync cadence | Weekly batch by default |
| Admin | On-demand pull → next app foreground uploads full snapshot |
| UI API | Same vault API on native + web |

## Architecture

```
Frontend (Train / Diet / Weekly)
  → Local Architect runtime
    → Device vault (source of truth for chat + plan + brief)
    → SYSTEM agent-runner (LLM + specialists)
    → vault.sync / vault.status / vault.admin-pull
```

## Vault layout

```
hunter/{hunterId}/
  architect_brief.md
  meta.json
  chat/protocol.jsonl   # persisted as JSON array of turns
  plans/protocol_plan.json
  events/{id}.json      # persisted as events array
```

Native: files under app document directory.  
Web: IndexedDB object store keyed by the same logical paths.

## Assignment

1. Signup → onboarding → `hunter.initialize.v1`
2. SYSTEM upserts `hunter_architect` (`status=active`, `last_sync_at=null`)
3. App `ensureVault(hunterId)` seeds brief + empty chat/plan/events
4. Train appends local-first; marks dirty for sync

## Rules

- Memory writes **local first**, then dirty for sync
- Weekly Supabase snapshot is never authoritative over the vault
- Admin pull v1: set `pull_requested_at`; app uploads on next foreground
- No cross-hunter vault paths

## Workflows

| Workflow | Purpose |
|----------|---------|
| `hunter.architect.protocol.v1` | Train PROTOCOL turn (cloud LLM) |
| `hunter.architect.weekly.v1` | Weekly biometric + ANALYZE intent |
| `hunter.architect.get.v1` | Cloud state hydrate (non-authoritative vs vault) |
| `hunter.architect.vault.sync.v1` | Upload vault snapshot |
| `hunter.architect.vault.status.v1` | `last_sync_at` / `pull_requested_at` / dirty |
| `hunter.architect.vault.admin-pull.v1` | Set admin pull flag |

## Tables

- `hunter_architect` — assignment + sync flags (`last_sync_at`, `pull_requested_at`, `vault_dirty`)
- `hunter_vault_snapshots` — weekly / admin_pull / manual snapshots

## Non-goals (v1)

- CRM UI
- On-device LLM
- Encryption-at-rest polish
- Conflict UI / prune policies
