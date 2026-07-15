---
name: refactor
description: "Refactor existing code with impact analysis first. Routes to tech-lead for blast-radius assessment, then engineers, with heavy emphasis on test coverage. Use when restructuring code with no intended behavior change. Trigger this when someone says: refactor this, clean up this code, extract this pattern, restructure this, this code is messy, improve the code structure, rename this across the codebase, remove duplication. Do NOT use when the change modifies behavior — use /implement instead. Do NOT use for single-file cleanup — just edit the file directly."
---

# Refactor

Restructure existing code without changing observable behavior. The defining constraint: **no behavior delta** — all existing tests must still pass after the refactor.

## 1. Define the refactor

Confirm with the user:
- **What** is being refactored (files, modules, or patterns)
- **Why** (readability, performance, removing duplication, preparing for a future change)
- **What must not change** (public API surface, database behavior, external contracts)

Read `docs/CONVENTIONS.md` if it exists. Check `memory/**/*.md` for any decisions about the code being changed. If `memory/architecture/repo-map.md` exists, use it to scope the blast radius quickly — it maps which directories own what. Verify its `Verified-at-commit` against HEAD; if the structure has drifted, recommend `/repo-map refresh` before the impact analysis in step 3.

## 2. git-engineer — branch setup

Always first. Confirm the working branch. If on `main` or `master`, ask the user to name the refactor branch before proceeding.

## 3. tech-lead — impact analysis

Always invoke tech-lead before any engineer for a refactor. Pass:
- The refactor scope and goal
- The "must not change" constraints from step 1

The tech-lead will:
- Identify all files and call sites affected by the change
- Flag whether any public API surface, interface, or contract is at risk
- Determine whether the change is safe to parallelize or must be sequential
- Produce a sequenced plan

Present the plan to the user. If the tech-lead flags the refactor as high-blast-radius or pattern-changing, or if the plan introduces a new pattern (even one extracted from existing code), recommend running devils-advocate on the plan before proceeding.

## 4. devils-advocate (conditional)

Invoke if tech-lead flags the refactor as:
- Touching more than 5 files across layers
- Changing a shared abstraction used in many places
- Introducing a new pattern that did not exist before

Skip for straightforward extractions, renames, or formatting changes.

## 5. Engineer agents

Dispatch based on file types, following the plan from tech-lead. Use `isolation: "worktree"` for each engineer. Worktrees only branch from the current refactor branch's HEAD if `worktree.baseRef` is `"head"` in settings.json — if unset or `"fresh"`, the harness silently bases new worktrees on local/origin `main` instead. Collect both the worktree path and branch name returned by each agent for cleanup after merge-reviewer.

Immediately after each engineer returns, verify the worktree actually branched from the refactor branch:

```bash
git merge-base --is-ancestor <refactor-branch> <worktree-branch>
```

If this fails (non-zero exit), the worktree is stale — it started from `main`, not the refactor branch, and its diff may be missing refactor-branch-only changes. Repair before continuing:

```bash
git -C <worktree-path> diff "$(git -C <worktree-path> merge-base main HEAD)" > /tmp/<worktree-branch>.patch
git -C <worktree-path> reset --hard <refactor-branch>
git -C <worktree-path> apply --3way /tmp/<worktree-branch>.patch
```

If the patch does not apply cleanly, stop and route back to the engineer with the conflicting file list rather than resolving it yourself.

Pass each engineer:
- The refactor goal and constraints
- The specific files they own
- A reminder: **no behavior delta** — existing tests must pass

Run **ts-linter** immediately after frontend-engineer or mcp-engineer. Block on FAIL.

## 6. code-reviewer

Invoke with the explicit note that this is a refactor — reviewer should flag any unintended behavior changes, not just style issues.

Run security-reviewer and performance-reviewer only if the refactor touches auth, data access, or hot-path code. State your reasoning.

## 7. test-engineer

After code-reviewer. Focus on:
- Any new abstractions or extracted functions that lack direct test coverage
- Ensuring the refactor did not reduce meaningful coverage

## 8. merge-reviewer

Final gate. Pass the worktree branch names and a summary of all stages. merge-reviewer will merge worktree branches into the refactor branch, clean up worktrees and temporary branches, then run the gate checklist.

If PASS: push and optionally open a PR. Note in the PR description that this is a pure refactor with no behavior change.
If FAIL: retry up to 2 cycles. New worktrees on retry are also created from the refactor branch. Collect new paths/branches and pass them to the next merge-reviewer invocation.

## Gotchas

- **Refactor that discovers a bug:** If an engineer finds a bug while refactoring, do not fix it in the same PR. Note it, complete the refactor with no behavior change, and create a separate /debug or /implement task for the bug. Mixing bug fixes into a refactor obscures the change history and breaks the "no behavior delta" guarantee.
- **Pre-existing failing tests:** Run the test suite before the refactor begins (step 1 or before step 5). If tests were already failing before your changes, document that baseline. Do not accept responsibility for pre-existing failures, but do not hide them either.
- **The devils-advocate threshold is a guideline:** The "5+ files" and "shared abstraction" conditions are signals, not rules. Use judgment. A 2-file refactor that changes a foundational interface used everywhere warrants devils-advocate. A 10-file rename of a private module probably does not.
- **Behavior change masquerading as refactor:** If the user's request includes any change to output format, API response shape, error messages, or business logic — even a "minor cleanup" — it is not a pure refactor. Use /implement instead and make the behavior change explicit.
- **Test coverage decrease is a blocker:** If test-engineer finds that the refactor reduced meaningful coverage (not just line count), route back to the engineer before merge-reviewer. A refactor that deletes test coverage is not complete.
