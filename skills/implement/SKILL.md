---
name: implement
description: "Orchestrates the full agent-pack pipeline for a task: git-engineer → [tech-lead] → engineer(s) → code-reviewer → [security-reviewer] → [performance-reviewer] → smell-reviewer → test-engineer → merge-reviewer → git-engineer (push/PR). Use when implementing a feature, fix, or change end-to-end. Trigger this when someone says: implement this, build this feature, make this change, add this functionality, code this up, I need this feature built, ship this. Do NOT use for targeted bug fixes with a known root cause — use /hotfix or /debug instead. Do NOT use for pure restructuring with no behavior change — use /refactor instead."
---

# Implement Task

Run the full agent pipeline for the task the user described:

1. **git-engineer** — always first. Confirm the working branch is correct before any code changes.

   **After git-engineer returns:** check the current branch with `git branch --show-current`. If the branch is still `main` or `master`, **stop immediately** and output:

   > **Cannot proceed:** Engineer agents use worktree isolation, and worktrees must not be created from `main` or `master`. Please switch to a feature branch first, then re-run `/implement`.

   Do not invoke any further agents until the user is on a non-main/master branch.

2. **tech-lead** — invoke if the task is ambiguous, spans multiple concerns, or touches more than three files. Skip for well-scoped, single-file tasks.

3. **devils-advocate** — invoke before implementation if the task introduces a new pattern, a new dependency, or an irreversible architectural change. Skip for small bug fixes and established patterns.

3a. **Obsidian sync requests** — tech-lead (step 2) and devils-advocate (step 3) write memory files to `./memory/` but cannot reach the vault themselves; neither grants `Bash` or `Agent`. If either one's output ends with an `## Obsidian sync request` section, you own the dispatch:

   - Check `$env:OBSIDIAN_VAULT_PATH`. If empty, skip silently.
   - For each memory file listed, dispatch **obsidian-writer** with the same field set as step 10b (`write_mode: "capture"`, plus the vault and project values; obsidian-writer reads REST config from the environment itself), using the description on that file's line as `title` and the file's full content (frontmatter + body) as `body`.

   Do this before invoking any engineer — the point is that the decision is searchable at write time, not at session end. If obsidian-writer errors, continue; the `memory/` file is the authoritative record.

4. **api-designer** — invoke before engineer agents if the task creates or significantly modifies API endpoints. Skip for internal refactors that do not change the API surface.

5. **Engineer agents** — before invoking each engineer, check for model overrides from earlier planning stages:
   - If tech-lead (step 2) output includes a `## Model Overrides` section naming this agent, note the specified model.
   - If devils-advocate (step 3) output includes a `## Model Escalations` section naming this agent, use that model instead (it takes precedence over tech-lead).
   - Pass the `model` parameter to the Agent call only when an override or escalation is present. Otherwise, let the agent use its frontmatter default.

   Invoke based on file types, always with `isolation: "worktree"`:
   - C# / .NET changes: **csharp-engineer**
   - TypeScript / Vue 3 changes: **frontend-engineer**
   - MCP server changes: **mcp-engineer**
   - Schema, migrations, SQL: **database-engineer**
   - Run csharp-engineer and frontend-engineer in parallel if both are needed and there are no shared files between them.

   **Worktree base:** The `isolation: "worktree"` parameter only creates each worktree from the current feature branch's HEAD if `worktree.baseRef` is set to `"head"` in settings.json. If that setting is unset or `"fresh"`, the harness bases the worktree on local/origin `main` instead — silently, regardless of what branch you're actually on. Do not assume the setting is correct; verify with step 5b below.

   When each agent completes, the worktree path and branch name are both returned. Collect both — pass the **branch names** to merge-reviewer in step 10 and retain the **worktree paths** in case the pipeline fails or is abandoned before merge-reviewer runs (step 10a).

5b. **Verify worktree base** — immediately after each engineer agent returns from an `isolation: "worktree"` call, before ts-linter or code-reviewer sees the code, confirm the worktree actually branched from the feature branch:

   ```bash
   git merge-base --is-ancestor <feature-branch> <worktree-branch>
   ```

   - **Exit 0:** safe — the worktree contains every commit on `<feature-branch>`. Proceed.
   - **Non-zero exit:** stale base — the engineer edited files starting from `main`, not `<feature-branch>`, so its diff may be missing feature-branch-only changes to the same files. Stop before continuing the pipeline and repair in place:

     ```bash
     git -C <worktree-path> diff "$(git -C <worktree-path> merge-base main HEAD)" > /tmp/<worktree-branch>.patch
     git -C <worktree-path> reset --hard <feature-branch>
     git -C <worktree-path> apply --3way /tmp/<worktree-branch>.patch
     ```

     This captures the engineer's full delta (committed and uncommitted) relative to its true starting point, then replays it on the correct base — sidestepping the bad ancestry instead of trying to merge two unrelated histories. If `git apply` reports conflicts, stop and route back to the originating engineer with the conflicting file list; do not resolve conflicts yourself.

   This check exists because `isolation: "worktree"` defaults to basing new worktrees on `main` (see step 5's Worktree base note) — a harness behavior the pack cannot override, only detect and repair after the fact.

   > **Test requirement:** Per CLAUDE.md, every engineer must verify existing tests pass and flag coverage gaps before handing off. Do not proceed to code-reviewer if an engineer reports failing tests.

5a. **ts-linter** — invoke immediately after **frontend-engineer** or **mcp-engineer** completes, before code-reviewer. Pass the list of modified `.ts` and `.vue` files. If ts-linter returns FAIL, route back to the originating engineer for fixes before continuing. Do not proceed to code-reviewer until ts-linter returns PASS or SKIP.

   If both frontend-engineer and mcp-engineer ran in parallel, invoke ts-linter **once** after both complete, passing all modified `.ts` and `.vue` files from both engineers combined.

6. **code-reviewer** — always after any engineer agent output.

7. **security-reviewer** — invoke if changes touch authentication, authorization, data access, PII, external endpoints, or secrets.

8. **performance-reviewer** — invoke if changes include database queries, API endpoints, loops over collections, or caching logic.

8a. **smell-reviewer** — always invoke after code-reviewer for any code change that introduces or modifies classes, methods, or files. Skip only for documentation-only, config-only, or SQL-migration-only changes with no application logic.

   Run security-reviewer, performance-reviewer, and smell-reviewer in parallel — they are all independent and have no dependency on each other. Omit security-reviewer and performance-reviewer when their conditions are not met; smell-reviewer always runs on code changes.

9. **test-engineer** — always last among reviewers, after code-reviewer completes. Never invoke before code-reviewer has finished.

10. **merge-reviewer** — always last. Pass a summary of: the task description, which pipeline stages ran, all findings from code-reviewer / security-reviewer / performance-reviewer / smell-reviewer, whether test-engineer produced tests, and **the list of worktree branch names** collected in step 5. merge-reviewer will verify all required stages passed and commit the changes to the feature branch.

    **If merge-reviewer returns PASS:** the changes are committed to the feature branch. Proceed to step 10a.

10a. **Worktree cleanup verification** — merge-reviewer owns worktree cleanup on the PASS path (its Step 0a removes each worktree, deletes its branch, and prunes). After a PASS, just verify nothing was left behind:
    ```bash
    git worktree list
    git worktree prune
    ```

    **Only if the pipeline failed or was abandoned before merge-reviewer ran** (or merge-reviewer stopped early on a merge conflict), clean up manually using the worktree paths and branch names collected in step 5:
    ```bash
    git worktree remove <worktree-path> --force
    git branch -D <worktree-branch>
    git worktree prune
    ```

    If a worktree path no longer exists, skip the `git worktree remove` for that path and proceed to branch deletion. Do not skip this step on failure — stale worktrees and branches accumulate in the repository and confuse future pipelines.

10b. **Obsidian capture** — after worktrees are cleaned up, record what was shipped.
     Check if `OBSIDIAN_VAULT_PATH` is set (PowerShell: `$env:OBSIDIAN_VAULT_PATH`).
     If empty, skip this step silently.

     Dispatch the **obsidian-writer** agent with:
     - `write_mode`: `"capture"`
     - `vault_path`: value of `OBSIDIAN_VAULT_PATH`
     - `projects_folder`: value of `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
     - `project`: basename of the project directory
     - `title`: one-line description of what was shipped (e.g. "feat: add model tag to obsidian logs")
     - `body`: build from pipeline results collected during this run:
       ```
       **Shipped:** <commit SHA from merge-reviewer>
       **Branch:** <feature branch name>

       **What was built:**
       - <2–4 bullet points summarising the change>

       **Pipeline:** <comma-separated list of agents that ran, in order>
       **Key files:** <list of files changed, from merge-reviewer or engineers>
       ```

     Keep the body concise — this is a searchable index entry, not a design doc.

11. **git-engineer (push/PR mode)** — invoke after merge-reviewer returns PASS. Ask the user whether to push the feature branch and optionally open a pull request. Pass the feature branch name and the commit SHA from merge-reviewer.

    **If merge-reviewer's PASS report flagged mergeability conflicts against the base** (its step 3c advisory), surface them to the user *before* they open the PR — resolving conflicts locally now is cheaper than after GitHub/Azure's automatic review flags them. This is advisory: it does not block the push, but the user should decide whether to rebase/merge the base branch and resolve conflicts first.

    **If merge-reviewer returns FAIL:** begin a retry cycle:
    - Route each failed item back to the agent responsible (e.g., Critical code finding → engineer agent, missing tests → test-engineer).
    - Engineer agents on retry also use `isolation: "worktree"`. Re-run step 5b's ancestor check against each new worktree before trusting it — retries are exactly as susceptible to the stale-base problem as the first pass.
    - Add any new worktree paths and branch names to the collected lists.
    - After fixes, re-run steps 6–10 (code-reviewer through merge-reviewer).
    - Allow up to **2 retry cycles** total. If merge-reviewer still returns FAIL after 2 retries, stop and surface the unresolved FAIL report to the user for manual resolution.
    - On final failure, still run step 10a cleanup — do not leave retry worktrees behind.

Do not skip steps without stating a reason. State which agents you are skipping and why before beginning.

## Gotchas

- **Starting on main/master:** The worktree check in step 1 is critical. Engineer agents create worktrees from the current branch only when `worktree.baseRef` is `"head"` — if that branch is main, the worktree is based on main and the merge-reviewer cannot safely commit without polluting the main history. Stop hard if the branch is main.
- **`worktree.baseRef` unset or `"fresh"`:** This is the harness default and it silently bases every engineer worktree on local/origin `main` instead of the feature branch — even when step 1's check passed and the developer is correctly on a feature branch. This is exactly how engineer work has ended up stranded as uncommitted diffs after a "successful" run: the worktree never had the feature branch's commits to begin with. Step 5b's ancestor check exists specifically to catch this; do not skip it, and do not trust the "Worktree base" note in step 5 without it.
- **Worktrees left behind after failure:** If the pipeline fails or is abandoned mid-run, still execute step 10a cleanup. Stale worktrees are invisible to the user but accumulate in `.git/worktrees` and cause confusing failures on future runs.
- **Retry cycle confusion:** A retry cycle means routing a specific finding back to the responsible engineer, fixing it, and re-running from code-reviewer (step 6) through merge-reviewer (step 10). Do not re-run the full pipeline from step 1 — git-engineer, tech-lead, and api-designer do not need to re-run.
- **Parallel engineer agents writing to the same file:** If csharp-engineer and frontend-engineer both need to touch a shared file (e.g., a config file), run them sequentially, not in parallel. Parallel writes to the same file cause merge conflicts in the worktree branches.
- **Skipping ts-linter before code-reviewer:** Type errors caught by ts-linter are blocking — they invalidate the code-reviewer's analysis. Always run ts-linter immediately after any frontend-engineer or mcp-engineer output, before code-reviewer sees the code.
