---
name: implement
description: "Orchestrates the full agent-pack pipeline for a task: git-engineer → [tech-lead] → engineer(s) → code-reviewer → [security-reviewer] → [performance-reviewer] → test-engineer → merge-reviewer → git-engineer (push/PR). Use when implementing a feature, fix, or change end-to-end. Trigger this when someone says: implement this, build this feature, make this change, add this functionality, code this up, I need this feature built, ship this. Do NOT use for targeted bug fixes with a known root cause — use /hotfix or /debug instead. Do NOT use for pure restructuring with no behavior change — use /refactor instead."
---

# Implement Task

Run the full agent pipeline for the task the user described:

1. **git-engineer** — always first. Confirm the working branch is correct before any code changes.

   **After git-engineer returns:** check the current branch with `git branch --show-current`. If the branch is still `main` or `master`, **stop immediately** and output:

   > **Cannot proceed:** Engineer agents use worktree isolation, and worktrees must not be created from `main` or `master`. Please switch to a feature branch first, then re-run `/implement`.

   Do not invoke any further agents until the user is on a non-main/master branch.

2. **tech-lead** — invoke if the task is ambiguous, spans multiple concerns, or touches more than three files. Skip for well-scoped, single-file tasks.

3. **devils-advocate** — invoke before implementation if the task introduces a new pattern, a new dependency, or an irreversible architectural change. Skip for small bug fixes and established patterns.

4. **api-designer** — invoke before engineer agents if the task creates or significantly modifies API endpoints. Skip for internal refactors that do not change the API surface.

5. **Engineer agents** — invoke based on the file types being changed, always with `isolation: "worktree"`:
   - C# / .NET changes: **csharp-engineer**
   - TypeScript / Vue 3 changes: **frontend-engineer**
   - MCP server changes: **mcp-engineer**
   - Schema, migrations, SQL: **database-engineer**
   - Run csharp-engineer and frontend-engineer in parallel if both are needed and there are no shared files between them.

   **Worktree base:** The `isolation: "worktree"` parameter creates each worktree from the current feature branch's HEAD — NOT from `main` or `master`. This ensures the engineer starts from the same commits the developer is working on. Never pass a base branch of `main` to engineer agents.

   When each agent completes, the worktree path and branch name are both returned. Collect both — pass the **branch names** to merge-reviewer in step 10 and retain the **worktree paths** for cleanup in step 10a.

   > **Test requirement:** Per CLAUDE.md, every engineer must verify existing tests pass and flag coverage gaps before handing off. Do not proceed to code-reviewer if an engineer reports failing tests.

5a. **ts-linter** — invoke immediately after **frontend-engineer** or **mcp-engineer** completes, before code-reviewer. Pass the list of modified `.ts` and `.vue` files. If ts-linter returns FAIL, route back to the originating engineer for fixes before continuing. Do not proceed to code-reviewer until ts-linter returns PASS or SKIP.

   If both frontend-engineer and mcp-engineer ran in parallel, invoke ts-linter **once** after both complete, passing all modified `.ts` and `.vue` files from both engineers combined.

6. **code-reviewer** — always after any engineer agent output.

7. **security-reviewer** — invoke if changes touch authentication, authorization, data access, PII, external endpoints, or secrets.

8. **performance-reviewer** — invoke if changes include database queries, API endpoints, loops over collections, or caching logic.

   If both security-reviewer and performance-reviewer are required, invoke them in parallel — they are independent and have no dependency on each other.

9. **test-engineer** — always last among reviewers, after code-reviewer completes. Never invoke before code-reviewer has finished.

10. **merge-reviewer** — always last. Pass a summary of: the task description, which pipeline stages ran, all findings from code-reviewer / security-reviewer / performance-reviewer, whether test-engineer produced tests, and **the list of worktree branch names** collected in step 5. merge-reviewer will verify all required stages passed and commit the changes to the feature branch.

    **If merge-reviewer returns PASS:** the changes are committed to the feature branch. Proceed to step 10a.

10a. **Worktree cleanup** — after merge-reviewer returns PASS, clean up all worktrees created in step 5.

    For each worktree path collected in step 5, verify it still exists and remove it:
    ```bash
    git worktree remove <worktree-path> --force
    ```

    Then delete each temporary worktree branch:
    ```bash
    git branch -d <worktree-branch>
    ```

    Finally, prune any stale worktree references:
    ```bash
    git worktree prune
    ```

    If a worktree path no longer exists (already cleaned up by the platform), skip the `git worktree remove` for that path and proceed to branch deletion.

    Do not skip cleanup. Stale worktrees and branches accumulate in the repository and confuse future pipelines.

11. **git-engineer (push/PR mode)** — invoke after merge-reviewer returns PASS. Ask the user whether to push the feature branch and optionally open a pull request. Pass the feature branch name and the commit SHA from merge-reviewer.

    **If merge-reviewer returns FAIL:** begin a retry cycle:
    - Route each failed item back to the agent responsible (e.g., Critical code finding → engineer agent, missing tests → test-engineer).
    - Engineer agents on retry also use `isolation: "worktree"` and must be created from the feature branch, not main.
    - Add any new worktree paths and branch names to the collected lists.
    - After fixes, re-run steps 6–10 (code-reviewer through merge-reviewer).
    - Allow up to **2 retry cycles** total. If merge-reviewer still returns FAIL after 2 retries, stop and surface the unresolved FAIL report to the user for manual resolution.
    - On final failure, still run step 10a cleanup — do not leave retry worktrees behind.

Do not skip steps without stating a reason. State which agents you are skipping and why before beginning.

## Gotchas

- **Starting on main/master:** The worktree check in step 1 is critical. Engineer agents create worktrees from the current branch — if that branch is main, the worktree is based on main and the merge-reviewer cannot safely commit without polluting the main history. Stop hard if the branch is main.
- **Worktrees left behind after failure:** If the pipeline fails or is abandoned mid-run, still execute step 10a cleanup. Stale worktrees are invisible to the user but accumulate in `.git/worktrees` and cause confusing failures on future runs.
- **Retry cycle confusion:** A retry cycle means routing a specific finding back to the responsible engineer, fixing it, and re-running from code-reviewer (step 6) through merge-reviewer (step 10). Do not re-run the full pipeline from step 1 — git-engineer, tech-lead, and api-designer do not need to re-run.
- **Parallel engineer agents writing to the same file:** If csharp-engineer and frontend-engineer both need to touch a shared file (e.g., a config file), run them sequentially, not in parallel. Parallel writes to the same file cause merge conflicts in the worktree branches.
- **Skipping ts-linter before code-reviewer:** Type errors caught by ts-linter are blocking — they invalidate the code-reviewer's analysis. Always run ts-linter immediately after any frontend-engineer or mcp-engineer output, before code-reviewer sees the code.
