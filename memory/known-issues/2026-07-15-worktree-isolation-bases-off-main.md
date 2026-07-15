---
name: worktree-isolation-bases-off-main
description: isolation:"worktree" (used by every engineer agent dispatch in implement/refactor/scaffold) provisions from local/origin main by default, not the current branch, unless worktree.baseRef is set to "head"
metadata:
  type: known-issue
  status: active
  discovered: 2026-07-15
---

The Agent tool's `isolation: "worktree"` parameter — used for every csharp-engineer / frontend-engineer / mcp-engineer / database-engineer dispatch in the implement, refactor, and scaffold pipelines — does not base the new worktree on the current checked-out branch by default. It is governed by the harness's `worktree.baseRef` setting: `"fresh"` (the default when unset) branches from `origin/<default-branch>` (equivalently local `main`); `"head"` branches from the current local HEAD. Nothing in the pack sets this, so out of the box every worktree-isolated engineer silently starts from `main`, regardless of what feature branch the developer is actually on.

**Observed impact:** two engineer worktrees were provisioned from a stale `main` while the developer was working on a feature branch. Their diffs never shared the right ancestry with the feature branch, so the work that should have landed as commits on the feature branch instead ended up stranded as uncommitted changes — the merge/integration step had no clean way to reconcile histories that didn't share the expected base.

**Root cause of why this went undetected:** `agents/git-engineer.md`, `skills/implement/SKILL.md`, `skills/refactor/SKILL.md`, and `skills/scaffold/SKILL.md` all asserted, as fact, that `isolation: "worktree"` "creates each worktree from the current branch's HEAD — never from main." That assumption is false by default, and because it was stated as a guarantee, no verification step existed anywhere in the pipeline to catch the divergence before merge-reviewer tried to integrate the branches.

**Fix applied (2026-07-15):**
1. Set `worktree.baseRef: "head"` in `~/.claude/settings.json` (global) so worktrees actually branch from current HEAD going forward.
2. `install.sh` now sets this automatically on fresh installs (only if unset — won't clobber a deliberate `"fresh"` choice).
3. `scripts/check-readiness.sh` now fails the readiness check if `worktree.baseRef` isn't `"head"`, so drift is caught by `/system-check`.
4. Defense in depth: `skills/implement/SKILL.md` (step 5b), `skills/refactor/SKILL.md` (step 5), and `skills/scaffold/SKILL.md` (step 6a) now run `git merge-base --is-ancestor <feature-branch> <worktree-branch>` right after each engineer returns, and `agents/merge-reviewer.md` Step 0 runs the same check as a hard gate before merging. On failure, the repair is a diff transplant (`git diff <merge-base-with-main> | git apply --3way` onto the correct base) rather than a history merge, since the two branches don't share the expected ancestry.
5. All four docs that asserted the false guarantee were corrected to state the actual, config-dependent behavior.

**Why this stays `known-issue` and not `resolved`:** the underlying tool behavior (`isolation: "worktree"` defaulting to `"fresh"`) is unchanged — the pack works around it via settings + verification, but a machine where `~/.claude/settings.json` is reset, a project-level override reintroducing `"fresh"`, or a future harness change could reintroduce the same failure mode. The `git merge-base --is-ancestor` checks are the actual safety net; the setting is the first line of defense, not a substitute for it.

**How to apply:** Before trusting any `isolation: "worktree"` engineer output in this or any project using the pack, confirm `worktree.baseRef` is `"head"` (`/system-check` reports this) and do not skip the ancestor-check steps in implement/refactor/scaffold even if the setting looks correct — config can drift between when a check ran and when it matters.
