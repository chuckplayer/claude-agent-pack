---
name: hotfix
description: Fast-track fix pipeline for production incidents. Skips worktree isolation and planning ceremony. Still requires code-reviewer and merge-reviewer as a safety gate. Use when speed matters and the fix is already understood.
---

# Hotfix

Apply a targeted fix with minimal ceremony. This pipeline is intentionally abbreviated — use it only when the problem is already diagnosed and the change is small and well-understood.

> **When to use `/debug` instead:** If you don't yet know the root cause, use `/debug` to diagnose first, then return here to apply the fix.

## 1. Confirm the fix is understood

Before starting, confirm:
- The **root cause** is known
- The **change** is small and scoped (a few lines; no new dependencies; no schema changes)
- The fix does not introduce a new architectural pattern

If any of these are false, use `/implement` instead and state why.

## 2. Branch setup

Run `git branch --show-current`.

- If on `main` or `master`: create a `hotfix/<brief-slug>` branch immediately. Do not proceed on main.
- If already on a non-main branch: confirm it is the correct branch for this fix.

No worktree isolation. The engineer works directly on the hotfix branch.

## 3. Engineer — direct fix

Route to the appropriate engineer based on file type:

| File type | Engineer |
|-----------|----------|
| `.cs` / .NET | **csharp-engineer** |
| `.ts` / `.vue` | **frontend-engineer** |
| `.ts` in an MCP server | **mcp-engineer** |
| SQL / migration | **database-engineer** |

Pass:
- Exact files to change
- Root cause and the intended fix
- How to verify (test command or manual repro)

**No `isolation: "worktree"`** — engineer works directly on the hotfix branch.

## 4. ts-linter (if applicable)

If frontend-engineer or mcp-engineer made changes, run **ts-linter** immediately. Block on FAIL before proceeding.

## 5. code-reviewer

Always. Pass the changed files and the root cause context. This is a non-negotiable safety gate even in a hotfix.

- Skip **security-reviewer** and **performance-reviewer** unless the fix touches auth, data access, secrets, or a critical hot path. State your reasoning.

## 6. merge-reviewer

Pass:
- Summary of the fix (root cause, what changed, why)
- Which pipeline stages ran and which were skipped (with reasons)
- code-reviewer findings

If PASS: proceed to step 7.
If FAIL: fix the blocking issue and re-run steps 5–6. Allow **1 retry only** — if it still fails, escalate to the user rather than looping further.

## 7. Push

After merge-reviewer returns PASS, push the hotfix branch immediately. Ask the user whether to open a pull request targeting `main` and whether to request an expedited review.

Do not run test-engineer by default. If the user wants test coverage added, note it as a follow-up task rather than blocking the hotfix.
