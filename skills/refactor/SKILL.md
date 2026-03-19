---
name: refactor
description: Refactor existing code with impact analysis first. Routes to tech-lead for blast-radius assessment, then engineers, with heavy emphasis on test coverage. Use when restructuring code with no intended behavior change.
---

# Refactor

Restructure existing code without changing observable behavior. The defining constraint: **no behavior delta** — all existing tests must still pass after the refactor.

## 1. Define the refactor

Confirm with the user:
- **What** is being refactored (files, modules, or patterns)
- **Why** (readability, performance, removing duplication, preparing for a future change)
- **What must not change** (public API surface, database behavior, external contracts)

Read `docs/CONVENTIONS.md` if it exists. Check `memory/**/*.md` for any decisions about the code being changed.

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

Dispatch based on file types, following the plan from tech-lead. Use `isolation: "worktree"` for each engineer.

Pass each engineer:
- The refactor goal and constraints
- The specific files they own
- A reminder: **no behavior delta** — existing tests must pass

Run **ts-linter** immediately after frontend-engineer or mcp-engineer. Block on FAIL.

> **Test requirement (same as all pipelines):** Every engineer must confirm all pre-existing tests still pass and that test coverage has not decreased before handing off. If any pre-existing test fails after the refactor, the engineer must fix it before proceeding to code-reviewer. This is not unique to refactor — it is the standard requirement for all engineer agents per CLAUDE.md.

## 6. code-reviewer

Invoke with the explicit note that this is a refactor — reviewer should flag any unintended behavior changes, not just style issues.

Run security-reviewer and performance-reviewer only if the refactor touches auth, data access, or hot-path code. State your reasoning.

## 7. test-engineer

After code-reviewer. Focus on:
- Any new abstractions or extracted functions that lack direct test coverage
- Ensuring the refactor did not reduce meaningful coverage

## 8. merge-reviewer

Final gate. Pass the worktree branch names and a summary of all stages.

If PASS: push and optionally open a PR. Note in the PR description that this is a pure refactor with no behavior change.
If FAIL: retry up to 2 cycles.
