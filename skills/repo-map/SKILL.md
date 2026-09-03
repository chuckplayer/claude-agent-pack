---
name: repo-map
description: "Generate or refresh a durable, directory-level map of the codebase — what each directory is for and its key entry-point files — stored as memory/architecture/repo-map.md and stamped with the git commit it was verified against. Use to create the map, refresh it after the tree drifts, or check whether it is stale. Trigger this when someone says: map the repo, build a repo map, what does each directory do, refresh the repo map, is the repo map stale, generate the file manifest, update the codebase map. Do NOT use to produce a full onboarding orientation — use /onboard instead (it reads this map). Do NOT use to search memory — use /memory-query instead."
---

# Repo Map

Maintain a durable, cross-session map of the codebase at **directory/module granularity** — one entry per meaningful directory, with only its 1–3 entry-point files called out by name. The map lives at `memory/architecture/repo-map.md`, so it is read by every agent via the memory rule and auto-synced to Obsidian by the memory-snapshot hook.

The map is stamped with the git commit it was last verified against (`verified-at-commit`). That stamp is what makes it resilient: staleness is a `git diff` question, not a guess, and refreshes re-describe only the directories that actually changed.

If `memory/` does not exist in this project, report that and suggest `/setup-project` — do not create it here.

## Modes

Pick the mode from context. Default to **refresh** when the file already exists, **generate** when it does not.

### generate — no map exists yet

1. `git rev-parse --short HEAD` to capture the current commit.
2. Glob the tree (respecting `.gitignore`) to enumerate meaningful directories. Skip vendored/build/output dirs (`node_modules`, `bin`, `obj`, `dist`, `.git`, `target`, `venv`).
3. For each directory, determine its purpose from the files it contains and name the 1–3 files a newcomer would open first (entry points, orchestrators, config roots).
4. Write `memory/architecture/repo-map.md` using the format below, stamping `verified-at-commit` with the HEAD from step 1.

### refresh — map exists (default)

1. Read the map's `verified-at-commit` value.
2. `git diff --name-only <verified-at-commit>..HEAD -- . ':(exclude)memory/architecture/repo-map.md'` to find changed paths. Always exclude the map's own file — a prior stamp bump is not codebase drift. If the stamped commit is unreachable (rebased/squashed), fall back to a full regenerate and note it.
3. Re-describe **only** the directories that contain changed, added, or deleted files. Leave untouched directories exactly as they are — do not rewrite the whole file.
4. Add new directories, remove entries for directories that no longer exist.
5. Re-stamp `verified-at-commit` with the current HEAD and update `last-updated`.

### verify — report staleness only, no writes

1. Read `verified-at-commit`.
2. `git diff --name-only <verified-at-commit>..HEAD -- . ':(exclude)memory/architecture/repo-map.md'` and list which mapped directories have drifted. Excluding the map's own file keeps a prior stamp bump from reading as drift.
3. Report: up to date, or "N directories drifted since `<sha>` — run `/repo-map refresh`." Make no edits.

## File format

Follow `docs/MEMORY-WRITING.md`. Fenced lowercase YAML — the seven required keys plus two extra fields, `last-updated` and `verified-at-commit`:

```yaml
---
date: YYYY-MM-DD
type: pattern
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: n/a
last-updated: YYYY-MM-DD
verified-at-commit: <short-sha>
---
```

Body: one `## <dir>/` heading per meaningful directory, a one-line purpose, then a short bullet list of only the entry-point files that matter. Directory-level is the rule; do not write one line per source file.

## Gotchas

- **Per-file creep:** The value is low upkeep. If you find yourself listing every file in a directory, stop — name only the entry points. A per-file manifest rots the moment a file moves and defeats the purpose.
- **Full rewrite on refresh:** refresh must be surgical. Re-describing untouched directories wastes tokens and risks drift in stable entries. Only touch directories that appear in the `git diff`.
- **Unreachable stamp:** If `verified-at-commit` is not an ancestor of HEAD (history was rewritten), you cannot compute a meaningful diff — regenerate fully and note why in your report.
- **This is not onboarding:** The map is a structural index, not a narrative. Purpose, architecture explanation, and first-tasks belong in `/onboard`, which consumes this map. Keep the map terse.
- **Obsidian sync is automatic:** Do not write to the vault directly. `memory/architecture/repo-map.md` is copied to the vault by the memory-snapshot hook on SessionEnd — no extra step needed.
