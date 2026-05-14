---
name: smell
description: "Run smell-reviewer against a file, directory, or the current working-tree changes. Use when someone says: check for code smells, smell review, find structural issues, review for smells, smell check, look for god classes, find long methods, check for dead code, smell this file, smell-review PR #N. Also use after /implement or /review-pr when the user wants a dedicated structural pass. Do NOT use when the user wants a full review pipeline -- use /review-pr instead."
---

# Smell Review

Run a targeted structural smell analysis on a specific target or the current
working-tree changes.

## 1. Determine the target

- If the user supplied **file paths**, use those directly.
- If the user supplied a **directory**, analyze all source files within it
  (skip `bin/`, `obj/`, `node_modules/`, `dist/`, `migrations/`).
- If the user supplied a **PR number**, run `gh pr diff <number> --name-only`
  to get the changed files, then use those.
- If **no target was supplied**, run `git diff main...HEAD --name-only`
  (or `git diff HEAD --name-only` if on main) to discover changed files.
  Confirm the list with the user before proceeding.

Filter the file list to source code only:
- **Include:** `.cs`, `.ts`, `.vue`, `.tsx`, `.jsx`, `.py`, `.go`, `.java`, `.rb`, `.rs`
- **Exclude:** config files (`.json`, `.yaml`, `.toml`, `.xml`), migrations,
  SQL scripts, test fixtures, generated files

If the filtered list is empty, tell the user: "No source code files found in
the target — smell-reviewer analyzes application logic, not config or
documentation."

## 2. Run smell-reviewer

Dispatch the `smell-reviewer` agent with:
- The filtered list of file paths
- Any relevant context the user provided (e.g., "focus on the service layer",
  "we just refactored this module")
- The contents of `docs/CONVENTIONS.md` if it exists (so the agent can read
  suppressions without a separate file read)

## 3. Present findings

The smell-reviewer agent will produce a severity-labeled report and offer
CONVENTIONS.md suppression options directly. No synthesis step is needed —
its output is the result.

## Gotchas

- **No changed files on a fresh branch:** `git diff main...HEAD` returns nothing
  if no commits exist. Ask the user to supply a target file or directory instead.
- **Large directories:** If the target contains more than 20 source files, warn
  the user that the review may take longer and offer to scope it to a
  subdirectory or specific files.
- **Smell review vs full review:** This skill runs smell-reviewer only. For a
  full quality pass (code quality + security + performance + smells), use
  `/review-pr` instead.
- **Fixing findings:** This skill surfaces structural issues — it does not fix
  them. If the user asks to fix a Critical smell finding (e.g., "break apart
  this God class"), route to `/refactor` or invoke the appropriate engineer
  agent.
