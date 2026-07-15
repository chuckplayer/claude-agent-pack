---
name: scaffold
description: "Scaffold a new feature end-to-end: API contract → database schema → backend service/controller → frontend. Use when building something new from scratch across multiple layers. More opinionated than /implement — always runs the full vertical slice in the correct dependency order. Trigger this when someone says: build this feature from scratch, scaffold a new endpoint, I need a full-stack feature, new feature end-to-end, build the whole thing. Do NOT use when the task is already partially built or only one layer needs changes — use /implement instead."
---

# Scaffold New Feature

Build a new feature end-to-end across all layers in the correct dependency order.

## 1. Confirm scope

Before starting, confirm with the user:
- **What** is being built (feature name and one-sentence description)
- **Which layers** are needed (API, DB, backend, frontend — not every feature needs all four)
- **Any constraints** (naming conventions, existing patterns to follow, related entities)

Read `docs/CONVENTIONS.md` if it exists. Check `memory/**/*.md` for any architecture or design decisions relevant to this feature. If `memory/architecture/repo-map.md` exists, consult it to decide where new files for each layer belong (which directory owns API, data, service, and frontend code) so the scaffold follows the existing structure. After the feature lands and adds new directories, recommend `/repo-map refresh` so the map stays current.

## 2. git-engineer — branch setup

Always first. Confirm the working branch. If on `main` or `master`, ask the user to name the feature branch before proceeding. Do not start any implementation until the branch is confirmed.

## 3. api-designer — REST contract

Always invoke for new features that expose any endpoint. Pass:
- The feature description and scope confirmed in step 1
- Any existing API patterns to follow (from CONVENTIONS.md or memory)

The api-designer will produce routes, HTTP methods, request/response shapes, status codes, and auth requirements. Present the contract to the user and ask for approval before proceeding to implementation.

## 4. database-engineer — schema and migrations

Invoke if the feature requires new or modified tables, columns, indexes, or stored procedures. Pass the approved API contract as context so entity names and field names stay consistent.

Use `isolation: "worktree"` for database-engineer. Collect the worktree path and branch name it returns.

## 5. Backend engineer — services and controllers

Invoke **csharp-engineer** (or the appropriate backend engineer for this project). Pass:
- The approved API contract
- The migration output or schema changes from database-engineer
- Existing patterns for services, repositories, and controllers

Use `isolation: "worktree"` for the engineer agent. Collect the worktree path and branch name it returns.

Run **ts-linter** immediately after if any `.ts` files were touched. Block on FAIL before continuing.

## 6. frontend-engineer — UI and API client

Invoke if the feature has a frontend component. Pass:
- The approved API contract (as the source of truth for endpoint URLs, request/response shapes)
- Any relevant component patterns from CONVENTIONS.md

Use `isolation: "worktree"` for frontend-engineer. Collect the worktree path and branch name it returns.

Run **ts-linter** immediately after. Block on FAIL before continuing.

> **Sequencing note:** frontend-engineer must run after csharp-engineer because the frontend depends on the API surface being defined. Do not run them in parallel.

## 6a. Verify worktree base

`isolation: "worktree"` (steps 4–6) only branches from the feature branch's HEAD if `worktree.baseRef` is `"head"` in settings.json. If unset or `"fresh"` (the harness default), it silently bases new worktrees on local/origin `main` instead — regardless of what branch you're on. Before the review pass, verify each worktree branch collected in steps 4–6:

```bash
git merge-base --is-ancestor <feature-branch> <worktree-branch>
```

Non-zero exit means the worktree is stale and missing feature-branch-only commits. Repair before continuing:

```bash
git -C <worktree-path> diff "$(git -C <worktree-path> merge-base main HEAD)" > /tmp/<worktree-branch>.patch
git -C <worktree-path> reset --hard <feature-branch>
git -C <worktree-path> apply --3way /tmp/<worktree-branch>.patch
```

If the patch conflicts, stop and route back to the responsible engineer with the conflicting file list.

## 7. Review pass

Run in parallel:
- **code-reviewer** — on all layers
- **security-reviewer** — always for new API endpoints and data access
- **performance-reviewer** — always for new database queries and API endpoints

## 8. test-engineer

After code-reviewer completes. Cover all new public methods, API endpoints, and frontend components.

## 9. merge-reviewer

Final gate. Pass the worktree branch names from steps 4–6 and a summary of all pipeline stages.

If PASS: proceed to step 9a.
If FAIL: retry up to 2 cycles, routing findings back to the responsible engineer. Re-run the verification in step 6a against any new worktrees before continuing. Collect new paths/branches and pass them to the next merge-reviewer invocation.

## 9a. Worktree cleanup verification

merge-reviewer owns worktree cleanup on the PASS path (its Step 0a removes each worktree, deletes its branch, and prunes). After a PASS, just verify nothing was left behind:
```bash
git worktree list
git worktree prune
```

**Only if the pipeline failed or was abandoned before merge-reviewer ran** (or merge-reviewer stopped early on a merge conflict), clean up manually using the worktree paths and branch names collected in steps 4–6:
```bash
git worktree remove <worktree-path> --force
git branch -D <worktree-branch>
git worktree prune
```

If a worktree path no longer exists, skip the `git worktree remove` for that path and proceed to branch deletion. Do not skip cleanup on failure — stale worktrees accumulate and confuse future pipelines.

## 10. git-engineer — push and PR

After step 9a completes. Ask the user whether to push and open a pull request. Include the API contract summary in the PR description.

## Gotchas

- **Frontend running before backend is ready:** The frontend depends on the API contract being finalized. Never run frontend-engineer in parallel with csharp-engineer — the endpoint shapes must be locked first.
- **API contract not approved before engineers start:** If the user skips api-designer approval and an engineer implements against a wrong shape, you will need to redo both layers. Always get explicit approval on the contract before step 4.
- **Mid-pipeline failure:** If a layer fails (e.g., database-engineer errors out), stop and surface the failure to the user before continuing. Do not skip a broken layer and proceed to the next — downstream layers depend on it.
- **Worktree not cleaned up after FAIL:** If merge-reviewer returns FAIL and the user abandons the scaffold, still run the worktree cleanup commands from step 9a. Stale worktrees accumulate and confuse future pipelines.
- **Schema changes not committed before backend:** The csharp-engineer must have access to the migration output from database-engineer. Pass the schema diff explicitly — the engineer cannot read an uncommitted migration from a different worktree.
