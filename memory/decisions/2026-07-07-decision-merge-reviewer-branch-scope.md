---
date: 2026-07-07
type: decision
status: active
superseded-by: n/a
scope: agents/merge-reviewer.md
overrides-convention: no
related-to: merge-reviewer.md, review-pr, smell
---

## Summary

merge-reviewer now establishes an explicit **branch scope** (new Step 0c) instead of
inspecting only uncommitted working-tree changes. Scope is the diff from the base branch's
merge-base to the working tree (`git diff --name-only $(git merge-base <base> HEAD)`), which
covers both committed branch commits and any still-uncommitted work. The test-coverage gate
reads this scope; the commit message still describes only the staged delta; the PASS report
narrates the full branch via `git log <base>..HEAD`.

## Context

In a real session merge-reviewer reviewed a multi-commit branch pulled from another developer.
Its test-coverage gate used `git diff --name-only HEAD` (uncommitted working tree only). On a
pulled branch everything is already committed, so that diff was empty, the gate saw zero files,
and the model improvised a single-commit inspection (`git show HEAD`) — falsely reporting an
earlier-commit file as "not modified" and summarizing only the tip commit.

## Rationale

- **Merge-base → working tree, not `<base>...HEAD`.** A commit-range-only diff would miss
  uncommitted changes that merge-reviewer's own `git add -A` then commits (the context-missing /
  manual-invocation path). Diffing from the fork point to the working tree covers both, so the
  gate can never green-light a file the commit step is about to add un-reviewed.
- **Commit message stays on `git diff --cached`.** merge-reviewer creates a *new* commit from
  the staged delta; the message must describe that commit, not the branch history (which on a
  pulled branch is another developer's commits). The whole-branch summary belongs in the PASS
  report, not the commit message.
- **Base inferred from `origin/HEAD`, degrading to local `main`/`master`, then to
  `git diff HEAD`.** Keeps merge-reviewer branching-strategy agnostic where cheap without ever
  hard-failing on repos where it works today.
- **Over-scoping accepted, under-scoping rejected.** No `git fetch` is added, so a stale base
  can over-scope — the safe direction for a review gate. The original bug was under-scoping.
- **Scope computed after Step 0 merges.** Step 0 creates the commits under review; scoping
  before it would miss them.

## Alternatives Rejected

- **`git diff <base>...HEAD` (commit range only)** — drops uncommitted work that `git add -A`
  later commits, trading one blind spot for another.
- **Commit message from the branch diff** (`<base>...HEAD` / `git log`) — describes already-
  committed history, misattributes another dev's commits, regresses currently-correct behavior.
- **`dev`-first base detection** — `dev` is not a convention here; risks a wrong merge-base and
  wildly oversized scope.
- **Hard-FAIL when no base resolves** — makes merge-reviewer unusable on repos where the old
  `git diff HEAD` worked; degrade-with-warning instead.

## Implications

- Two cheap guards added: never commit on a detached HEAD; never create an empty commit when all
  work is already committed (emit a PASS report instead).
- PASS reports must state honestly what was gated — a branch pointed at outside the implement
  pipeline (no stage findings, nothing staged) says so rather than implying a full review.
- `review-pr` and `smell` still carry a hardcoded `main...HEAD` idiom with the same naming
  assumption. Propagating `origin/HEAD` inference to them is a deferred follow-up, not part of
  this change. `ts-linter` is unaffected (operates on a passed file list).
- merge-reviewer version bumped 1.0.0 → 1.1.0.
