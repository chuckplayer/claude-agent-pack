---
date: 2026-07-01
type: decision
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: repo-map.md
---

## Summary

Added a durable, cross-session **repo map** — a directory-level inventory of the
codebase (what each directory does + its entry-point files) stored at
`memory/architecture/repo-map.md` and maintained by a new `/repo-map` skill.
It rides the existing memory-snapshot hook to Obsidian for free and is consumed
by `/onboard`, tech-lead, `/plan`, `/refactor`, and `/scaffold`.

## Context

The project memory taxonomy captured decisions and constraints but had no
persistent map of *where things live* or *what each file is for*. `/onboard`
re-derived that structure from scratch every run and discarded it.

## Rationale

- Lives in `memory/architecture/`, so it is auto-read by all agents (memory rule)
  and auto-synced to the Obsidian vault by the SessionEnd memory-snapshot hook —
  no new plumbing for cross-session sharing or Obsidian logging.
- **Directory/module granularity, not per-file** — a per-file manifest rots the
  moment a file moves. Directory-level entries with named entry points survive drift.
- **Provenance via `Verified-at-commit`** — staleness becomes a `git diff` question,
  and refreshes re-describe only the directories that changed.
- **On-demand regeneration** (`/repo-map`), not a per-session hook — avoids LLM
  cost and noise on every SessionEnd for a slowly-changing artifact.

## Alternatives Rejected

- **Per-file manifest** — too much upkeep, stale immediately.
- **Auto-update on a SessionEnd hook** — token cost + noise every session.
- **Cache the raw `/onboard` output** — narrative, not a structural index; harder
  to invalidate surgically.

## Implications

- `repo-map.md` adds one optional frontmatter field beyond the standard spec:
  `Verified-at-commit`.
- Consumers read the map but must verify entries against current code before
  relying on them (memory records what was true when written).
- Refresh triggers are wired into merge-reviewer (advisory), git-engineer
  (post-commit suggestion), and `/memory-audit` (drift check that recommends
  refresh rather than archiving the map).
