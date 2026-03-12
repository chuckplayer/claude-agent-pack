---
name: implement
description: Orchestrates the full agent-pack pipeline for a task: branch-manager → [tech-lead] → engineer(s) → code-reviewer → [security-reviewer] → [performance-reviewer] → test-engineer → merge-reviewer. Use when implementing a feature, fix, or change end-to-end.
---

# Implement Task

Run the full agent pipeline for the task the user described:

1. **branch-manager** — always first. Confirm the working branch is correct before any code changes.

   **After branch-manager returns:** check the current branch with `git branch --show-current`. If the branch is still `main` or `master`, **stop immediately** and output:

   > **Cannot proceed:** Engineer agents use worktree isolation, and worktrees must not be created from `main` or `master`. Please switch to a feature branch first, then re-run `/implement`.

   Do not invoke any further agents until the user is on a non-main/master branch.

2. **tech-lead** — invoke if the task is ambiguous, spans multiple concerns, or touches more than three files. Skip for well-scoped, single-file tasks.

3. **devils-advocate** — invoke before implementation if the task introduces a new pattern, a new dependency, or an irreversible architectural change. Skip for small bug fixes and established patterns.

4. **api-designer** — invoke before engineer agents if the task creates or significantly modifies API endpoints. Skip for internal refactors that do not change the API surface.

5. **Engineer agents** — invoke with `isolation: "worktree"` so each agent works in an isolated copy of the repository. Invoke based on the file types being changed:
   - C# / .NET changes: **csharp-engineer**
   - TypeScript / Vue 3 changes: **typescript-engineer**
   - Schema, migrations, SQL: **database-engineer**
   - Run csharp-engineer and typescript-engineer in parallel if both are needed and there are no shared files between them.

   Each engineer agent runs in its own worktree. When the agent completes, the worktree path and branch are returned. Collect all worktree branches before proceeding.

5a. **ts-linter** — invoke immediately after **typescript-engineer** completes, before code-reviewer. Pass the list of modified `.ts` and `.vue` files. If ts-linter returns FAIL, route back to typescript-engineer for fixes before continuing. Do not proceed to code-reviewer until ts-linter returns PASS or SKIP.

6. **code-reviewer** — always after any engineer agent output.

7. **security-reviewer** — invoke if changes touch authentication, authorization, data access, PII, external endpoints, or secrets.

8. **performance-reviewer** — invoke if changes include database queries, API endpoints, loops over collections, or caching logic.

9. **test-engineer** — always last among reviewers, after code-reviewer completes. Never invoke before code-reviewer has finished.

10. **merge-reviewer** — always last. Pass a summary of: the task description, which pipeline stages ran, all findings from code-reviewer / security-reviewer / performance-reviewer, and whether test-engineer produced tests.

    **If merge-reviewer returns PASS:** the changes are committed to the feature branch. Report the commit SHA to the user and stop.

    **If merge-reviewer returns FAIL:** begin a retry cycle:
    - Route each failed item back to the agent responsible (e.g., Critical code finding → engineer agent, missing tests → test-engineer).
    - Engineer agents on retry also use `isolation: "worktree"`.
    - After fixes, re-run steps 6–10 (code-reviewer through merge-reviewer).
    - Allow up to **2 retry cycles** total. If merge-reviewer still returns FAIL after 2 retries, stop and surface the unresolved FAIL report to the user for manual resolution.

Do not skip steps without stating a reason. State which agents you are skipping and why before beginning.
