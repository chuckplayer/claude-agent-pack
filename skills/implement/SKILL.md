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

   **Adoption rule — check this before invoking tech-lead.** If the caller passed a `plan_id` and path (typically from `/plan` step 5), **adopt that plan instead of re-planning**: read it, take its `## Acceptance bars` and any `## Model Overrides` from the file, and skip tech-lead entirely. Re-planning would write a second plan file for the same work and discard the bars devils-advocate already pressure-tested.

   Adoption is **opt-in and explicit**. Never glob the plan directory looking for a plan — a file in `docs/plans/` may govern a different branch's in-flight work, and adopting it would run this pipeline against the wrong acceptance criteria. Three cases:

   - **A `plan_id` was passed and the file exists** → adopt it. Confirm its `plan_id` and `branch` frontmatter match this run; if either disagrees, stop and ask the user rather than guessing which is right. Read its `## Model Overrides` section into the same notes step 5 would have taken from tech-lead's chat output — see the adoption note in step 5.
   - **A `plan_id` was passed but no file exists at that path** → stop and tell the user. The caller asserted a plan; its absence is a real problem, not a reason to quietly re-plan.
   - **No `plan_id` was passed** → no plan governs this run. Invoke or skip tech-lead on the normal criteria above, and merge-reviewer's gate 4a will report "not applicable". This is the common case.

   When you adopt a plan, carry its `plan_id` and path through to steps 9 and 10. (Creating a plan is `/plan`'s job — it owns the directory resolution and the write instruction. `/implement` adopts; it does not create.)

   **On adoption, validate the plan's structure before invoking anything else.** Blocking gate, same footing as 5c:

   ```bash
   bash scripts/lint-plans.sh <the path you were handed>
   ```

   Pass the path as a **discrete argument** — never interpolated into a longer shell string, for the command-substitution reason `agents/merge-reviewer.md` sets out in full. Pass only the plan handed to this run; the script never globs the directory. If `bash` is not on the shell's PATH, use the Bash tool rather than skipping.

   **A non-zero exit stops the run** — report the failure and ask the user to fix the plan. This is worth one command at the start: `/implement` adopts plans it did not write, and a plan handed in by a caller other than `/plan` may have been through neither tech-lead's writer nor devils-advocate's audit. Without this, a plan missing `## Deviations` or carrying an untyped `Evidence:` line fails at merge-reviewer's gate 4a instead — after every engineer, reviewer, and test stage has already run. `[--] ## Deviations still holds its sentinel` is **not** a failure here; step 10 is where that section gets filled in.

3. **devils-advocate** — invoke before implementation if the task introduces a new pattern, a new dependency, or an irreversible architectural change. Skip for small bug fixes and established patterns.

   **If a plan governs this run, pass it the plan path and ask it to pressure-test the plan file in place** — both the acceptance bars and the entries in `## Calls made for you`. It holds `Write`, and it is the only check on either. Ask it to flag any bar whose `Evidence:` line names something that cannot be produced, and any stated call that names no concrete artifact (a quality or a pattern name rather than a dependency, file, type, or value) — those have no lookup target, so merge-reviewer's Tier 3 skips them by construction and they enforce nothing. Sharpen them or mark them as documentation for the human. This is the same duty `/plan` step 3 carries; on the adoption path `/plan` already ran it, so skip it rather than repeating it.

   **If devils-advocate edited a plan file in this run, re-run `scripts/lint-plans.sh` on it** — same command and same blocking rule as the step 2 adoption run. It edits bars in place, so it can introduce a `Gated:` field with no `Cost:` line, a row-6 failure that did not exist when the plan was adopted. This applies only when devils-advocate actually edited a plan *here*; on the adoption path it did not run at all and `/plan` already covered both the challenge and the lint.

   **Expect a `## Challenge` section appended to the plan** — devils-advocate persists its narrative findings there before composing its reply, so a stall cannot take the judgement with it. That is expected output, not drift, and it is **not** a substitute for the report: a plan with a fresh `## Challenge` section and no report means the stage did not complete. Re-request once; if that is silent too, record "challenge findings written to the plan; narrative verdict never received" rather than treating the edits as a pass.

3a. **Obsidian sync requests** — tech-lead (step 2) and devils-advocate (step 3) write memory files to `./memory/` but cannot reach the vault themselves; neither grants `Bash` or `Agent`. If either one's output ends with an `## Obsidian sync request` section, you own the dispatch:

   - Check `$env:OBSIDIAN_VAULT_PATH`. If empty, skip silently.
   - For each memory file listed, dispatch **obsidian-writer** with the same field set as step 10b (`write_mode: "capture"`, plus the vault and project values; obsidian-writer reads REST config from the environment itself), using the description on that file's line as `title` and the file's full content (frontmatter + body) as `body`.

   Do this before invoking any engineer — the point is that the decision is searchable at write time, not at session end. If obsidian-writer errors, continue; the `memory/` file is the authoritative record.

4. **api-designer** — invoke before engineer agents if the task creates or significantly modifies API endpoints. Skip for internal refactors that do not change the API surface.

5. **Engineer agents** — before invoking each engineer, check for model overrides from earlier planning stages:
   - If tech-lead (step 2) output includes a `## Model Overrides` section naming this agent, note the specified model.
   - **If step 2 adopted a plan instead of invoking tech-lead**, read `## Model Overrides` from the adopted plan file — there is no tech-lead chat output to read on that path. Without this, an escalation devils-advocate pressure-tested during `/plan` silently fails to apply to engineer dispatch.

   **If a plan governs this run, carry its stated calls into each engineer's prompt.** Engineers run under `isolation: "worktree"` and **cannot see the plan** — it sits uncommitted in the primary working tree, so it does not exist in their checkout. Read `## Calls made for you`, select the entries that bear on that engineer's slice, and paste them **verbatim** into the dispatch prompt. Do not paraphrase: a summarised call is one the engineer cannot recognise itself departing from, which is where the signal dies.

   Then require the departure report in the handoff:

   > The plan for this work states the following calls. Follow them unless you have a concrete
   > reason not to. Either way, end your handoff with a line reading
   > `Departures from stated calls:` — list any call you did not follow and what you did instead,
   > or write `none`. An absent line is not a "no", so do not omit it.

   An explicit "none" matters: it distinguishes *the engineer followed the plan* from *the engineer was never asked*.
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
   git merge-base --is-ancestor <feature-branch> <worktree-branch>   # correct base?
   git log --oneline <feature-branch>..<worktree-branch>             # any commits at all?
   git -C <worktree-path> status --short                             # uncommitted work?
   ```

   **Both questions matter, and the second is the one that has actually bitten.** Ancestry being correct does not mean there is anything to merge: engineers are told not to commit (merge-reviewer owns commits), so a worktree branch routinely has **zero commits** while the work sits uncommitted in the worktree. `git merge-base --is-ancestor` is trivially satisfied in that state, so step 5b passes, and merge-reviewer's Step 0 then runs `git merge --no-ff` on a branch with nothing on it — merging nothing, reporting success, and **silently stranding the engineer's work**. That is the failure in `memory/known-issues/2026-07-15-worktree-isolation-bases-off-main.md` arriving through the *green* path.

   - **Exit 0 and the commit list is non-empty:** safe — the worktree contains every commit on `<feature-branch>` and has work of its own. Proceed.
   - **Exit 0 but the commit list is EMPTY while `status --short` shows modifications:** the work exists but is uncommitted, so a plain merge would transfer nothing. Do **not** rely on `git merge --no-ff`. Tell merge-reviewer this branch needs the transplant path, or resolve it here: diff the worktree, confirm parity, and apply the change in the primary tree.

     ```bash
     diff <(git diff -- <file>) <(git -C <worktree-path> diff -- <file>)   # prove parity FIRST
     ```

     Proving parity before discarding the worktree is what makes "re-apply it yourself" safe rather than a silent re-implementation that might differ.
   - **Exit 0, empty commit list, and a clean worktree:** the engineer changed nothing. Treat that as a finding and ask why before proceeding — a no-op handoff reported as success is its own bug.
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

5c. **lint-agents** — run whenever the changeset touches **`agents/`** or **`skills/`**, after the files are written and **before code-reviewer**. This is a **blocking gate**, on the same footing as ts-linter:

   ```bash
   bash scripts/lint-agents.sh
   ```

   Run the script directly rather than invoking the `/lint-agents` skill — that skill exists for manual, user-invoked runs, and this is orchestration. On a machine where `bash` is not on the shell's PATH, use the Bash tool rather than skipping the step.

   A **non-zero exit fails the pipeline.** Route the specific failure back to whoever wrote the file, fix it, and re-run until it exits 0. Do not proceed to code-reviewer on a FAIL: a malformed `description` is the routing contract itself, so an agent or skill that fails this check may be undispatchable or mis-routed no matter how good its body is, and a code-reviewer PASS on it means nothing.

   **Skip only when neither `agents/` nor `skills/` appears in the changeset**, and say so explicitly rather than silently.

   > **Why this is a step rather than a suggestion.** The batch-write cut shipped `skills/devops-azure/SKILL.md` with a description of 1346 characters against a 1024 limit, through code-reviewer, security-reviewer, test-engineer, and merge-reviewer's gate, into two pushed commits. The check that catches it existed the whole time and took one command; nothing in the pipeline ran it. A mechanical check catches a class of defect that careful prose review demonstrably does not.

5d. **Obsidian hook tests** — run whenever the changeset touches **`scripts/obsidian-stop-hook.js`** or **`scripts/obsidian-context-hook.js`**, after the files are written and **before code-reviewer**. **Blocking gate**, same footing as 5c:

   ```bash
   node scripts/obsidian-stop-hook.test.js
   ```

   No npm install, no dependencies — Node stdlib only, so there is no setup step to skip. A **non-zero exit fails the pipeline**; route the failure back to whoever changed the hook and re-run until it exits 0.

   **The trigger is those two files by name, not `scripts/` as a directory.** The suite imports `obsidian-stop-hook.js` and exercises `obsidian-context-hook.js` as a subprocess; it covers **neither** the three other `obsidian-*.js` hooks **nor** any `.sh` script in that directory. Running it after a change to `check-updates.sh` produces a PASS that checked nothing relevant, which is the same false assurance 5c warns about. Say the skip out loud rather than leaving it ambiguous.

   > **Why this is a step.** 131 tests, exit 0, and until 2026-08-03 **no pipeline invoked them** — found by auditing `scripts/` for other unrun checks after 5c was added. Several are named as regressions (`"regression: it never closed"`), meaning they encode bugs already fixed once; nothing was stopping a hook edit from reintroducing one silently. This is the same class as 5c, found by asking the question 5c raised.

5e. **Identifier lint** — run on **every** changeset, after the files are written and **before code-reviewer**. **Blocking gate**, same footing as 5c and 5d:

   ```bash
   bash scripts/lint-identifiers.sh
   ```

   **This repository is public.** The script fails when a real organisation, project, host, user path, or email address appears where the placeholder convention requires a placeholder. On a failure it prints `file:line` for each hit — fix the file, do not add a suppression marker unless the line is genuinely showing an example.

   **The trigger is every changeset, and that is deliberate — there is no path-based narrowing and therefore no legitimate skip.** 5c triggers on two directories and 5d on two filenames, because each check only covers those. An identifier can be introduced by *any* file in *any* commit, so a path trigger here would be a hole rather than a scope. If it did not run, say so plainly; never let its absence read as a pass.

   **Two exit codes, and they mean different things.** Exit **1** is a finding: an identifier is present, fix it. Exit **2** means the checker's own self-test failed — it could not prove its rules fire on violating fixtures — so its verdict on the repo is worthless and must not be reported as clean. Treat exit 2 as "fix the checker first", not as a finding.

   > **Why this is a step.** The rule pre-existed and nothing enforced it: `docs/azure-devops-github-skills-brief.md` forbade hardcoded org/project names **four lines above a list of them**. Enforcing it late cost a scrub of 115 references across 20 files plus a rewrite of all 172 commits — and a force push provably does **not** remove them from a public host, so the exposure could not be fully undone. Unlike 5c and 5d, this gate cannot be justified by "a check existed and nothing ran it"; it exists because prevention is the only control that works at all.

6. **code-reviewer** — always after any engineer agent output.

7. **security-reviewer** — invoke if changes touch authentication, authorization, data access, PII, external endpoints, or secrets.

8. **performance-reviewer** — invoke if changes include database queries, API endpoints, loops over collections, or caching logic.

8a. **smell-reviewer** — always invoke after code-reviewer for any code change that introduces or modifies classes, methods, or files. Skip only for documentation-only, config-only, or SQL-migration-only changes with no application logic.

   Run security-reviewer, performance-reviewer, and smell-reviewer in parallel — they are all independent and have no dependency on each other. Omit security-reviewer and performance-reviewer when their conditions are not met; smell-reviewer always runs on code changes.

9. **test-engineer** — always last among reviewers, after code-reviewer completes. Never invoke before code-reviewer has finished.

   **If a plan governs this run, pass test-engineer the plan path** and ask it to return the bars-to-evidence mapping described in its own instructions: for every `BAR-nnn` id in the plan, what evidence actually satisfies it (`tests`, `manual`, or `files`), or `NONE` where it found none. This is the only point where a bar is connected to something real, so a gate can fail against it. Carry the mapping into step 10 — merge-reviewer cross-checks it against the plan.

   `manual` and `files` are complete answers. Work with no test surface — prompt files, docs, shell scripts — is fully satisfied by a concrete file reference or a repeatable command, and test-engineer should not be pushed to invent tests that cannot exist.

10. **merge-reviewer** — always last. Pass a summary of: the task description, which pipeline stages ran, all findings from code-reviewer / security-reviewer / performance-reviewer / smell-reviewer, whether test-engineer produced tests, and **the list of worktree branch names** collected in step 5. merge-reviewer will verify all required stages passed and commit the changes to the feature branch.

    **If a plan governs this run, also pass the `plan_id`, the plan's path, and test-engineer's bars-to-evidence mapping.** merge-reviewer's gate 4a acts on a plan only when handed one — it never searches the plan directory. Omitting these makes the gate report "not applicable" and the plan's bars go unenforced, which looks like a pass. If no plan governs this run, pass nothing and say so explicitly, so the "not applicable" verdict is a stated fact rather than an accident.

    **Before dispatching, fill in the plan's `## Deviations` section.** tech-lead wrote it as a sentinel — an italic line beginning `Deviations not yet reviewed` — and gate 4a greps for exactly that string and fails while it is present. This is deliberate: an untouched section cannot be told apart from one nobody looked at. Replace **that line only**; leave the `## Deviations` heading in place.

    Replace the sentinel with one of two things:

    - **Nothing diverged:** `None.` followed by a one-clause affirmation of what you checked, e.g. `None. Every stated call was followed as written.`
    - **Something diverged:** one bullet per departure, each naming **the stated call**, **what shipped instead**, and **who decided** — an engineer or this session:

      ```markdown
      - **Test runner: Vitest** -> shipped plain `node` + `assert` with no devDependency.
        Decided by: coordinating session, to keep the scratch project dependency-free.
      ```

    Both sources count. Collect departures from every engineer's `Departures from stated calls:` line, **and record your own** — a call you overrode while coordinating is a deviation exactly as much as one an engineer made, and in practice it is the more common case. No ids and no numbering: nothing downstream maps onto a deviation, so an id would be ceremony.

    **If a deviation makes an acceptance bar unsatisfiable, you may amend that bar — under all four of these conditions, never otherwise:**

    1. The amendment is a **named consequence of a recorded deviation**, not an independent editorial call. Record the deviation first.
    2. The deviation entry **quotes the bar id and the original wording verbatim**, so the edit leaves a trace instead of erasing one.
    3. The change is **narrowly scoped to the clause the deviation invalidated**. Do not touch other bars, and do not loosen a substantive constraint while you are in there.
    4. **Only this session amends bar text.** Engineers never edit the plan; tech-lead wrote the bar and is no longer in the loop.

    A bar whose premise a recorded deviation has falsified is testing an abandoned design — leaving it unamended fails the run on a criterion nobody intends to meet. But the licence is narrow on purpose: **if any inconvenient bar could be edited back into satisfiability, acceptance bars lose their teeth entirely**, because "unsatisfiable" would always be cheaper to fix by rewriting the bar than by fixing the code or admitting a real miss. When in doubt, leave the bar alone and let it fail — an honest FAIL is recoverable, a quietly rewritten record is not.

    Then hand merge-reviewer each engineer's departure claims alongside the plan, so its Tier 2 check can confirm every claimed departure actually reached the section.

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
    - After fixes, re-run steps 6–10 (code-reviewer through merge-reviewer). **A retry rewrites `## Deviations`** — step 10 runs again, so a fix that changes what shipped updates the section for free. This is why the section is written at step 10 rather than step 9: written earlier, a retry would leave it stale and the gate would then enforce a stale record, which is worse than no record at all.
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
- **An agent that goes idle without reporting has NOT completed its stage.** This happens: on 2026-08-03 seven agents in one session finished their work correctly and went idle before sending a report. Because the work was right every time and only the report was lost, it looks indistinguishable from success — you watched the agent launch and finish, so believing it completed is the natural inference and it is wrong. **Treat a silent agent as a failed run of that stage and re-dispatch it.** Do not reconstruct its verdict, do not summarise what it "would have" found, and above all do not tell merge-reviewer the stage ran: that gate verifies stages from context, so an unreported stage passed off as complete produces a confident merge verdict about a review nobody read. Re-dispatching a read-only reviewer costs one call. Where the stage is mechanically reproducible — a test suite, `scripts/lint-agents.sh`, `node scripts/obsidian-stop-hook.test.js` — just run the command yourself instead. See `memory/known-issues/2026-08-03-subagent-goes-idle-before-reporting.md`; the stall is in the harness, so the only available defence is refusing to read silence as assent.
