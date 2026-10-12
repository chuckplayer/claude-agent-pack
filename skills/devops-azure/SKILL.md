---
name: devops-azure
description: "Read and create Azure DevOps work items and PRs via the az CLI (devops extension) for the org/projects in AZURE_DEVOPS_ORG/AZURE_DEVOPS_PROJECTS. Use for one-off Azure Boards/Repos operations outside the code pipeline: viewing or creating work items, viewing PRs, commenting, updating state, linking commits. Also provides batch write mode (step 8), turning a reviewed /backlog tree into work items in one pass -- whole-tree preview, one confirmation, per-item reporting, ids written back. Trigger this when someone says: check my work items, list open PRs in Azure DevOps, create a work item, comment on PR #N, close this work item, connect to azure devops, create the work items from this backlog, push this backlog tree into ADO. Do NOT use for GitHub PRs/issues -- that's skills/devops-github. Do NOT use for a full review or implementation pipeline -- use /review-pr or /implement. Do NOT use to decompose a spec into a backlog -- that is /backlog; batch mode consumes its tree and never produces one."
---

# Azure DevOps (az CLI)

Read and write Azure DevOps work items and PRs by shelling out to the `az` CLI with the `devops` extension — no MCP server required. Handles first-time setup, operation-aware targeting (an ID-scoped lookup needs only the org; a project-scoped query, list, or write needs a resolved project), runtime field-schema discovery, and safe write operations for the org/projects configured via environment variables.

## 1. Verify setup

Check, in order:

1. **`az` CLI installed?** Run `az --version`. If missing, stop and direct the user to install it (https://learn.microsoft.com/cli/azure/install-azure-cli).
2. **`devops` extension installed?** Run `az extension show --name azure-devops`. If missing, install it with `az extension add --name azure-devops` (ask before installing).
3. **Authenticated?** Run `az account show`. If not logged in, walk the user through `az login` interactively. Once org/project targeting is resolved (steps 2–3 below), optionally set defaults for convenience with `az devops configure --defaults organization=<org> project=<project>` — do not do this before targeting is confirmed.
4. **Env vars set?** Check `AZURE_DEVOPS_ORG` (single value) and `AZURE_DEVOPS_PROJECTS` (comma-delimited list, e.g. `AZURE_DEVOPS_PROJECTS=<project-a>,<project-b>`). If unset, ask the user for the org and project(s) they want to work with — do not hardcode any org/project name into this file.

Report each check's result clearly before proceeding.

## 1a. Persisting or changing AZURE_DEVOPS_ORG/AZURE_DEVOPS_PROJECTS

These values change more often than a one-time install (switching projects, adding one), so persistence is handled by a standalone script rather than the installer: `scripts/set-env.sh` writes into `~/.claude/settings.json`'s `env` object (the same file the Obsidian integration uses), which works identically across macOS, Linux, and Windows — unlike a shell profile, which differs by shell and OS.

- After confirming a value with the user (new session-only value, or a change to an existing one), ask whether to persist it. If yes: `bash scripts/set-env.sh AZURE_DEVOPS_ORG=<org> AZURE_DEVOPS_PROJECTS=<ProjectA,ProjectB>`.
- Never hand-edit `~/.claude/settings.json` directly or write shell-profile export lines (`.zshrc`, `.bash_profile`, PowerShell `$PROFILE`) to persist these — always go through `scripts/set-env.sh` so the write is consistent and safe across platforms.
- A session-only value (user declines persistence) just needs `export AZURE_DEVOPS_ORG=...`/`$env:AZURE_DEVOPS_ORG=...` for the current shell, or simply proceeding without setting the env var and passing `--org`/`--project` explicitly for this run.

## 2. Classify the operation before resolving a project

Azure DevOps work item IDs and PR IDs are unique **org-wide**, not per-project — an ID-scoped lookup needs only the org. Forcing a project disambiguation question on a bare-ID request is not just unnecessary, it can be actively wrong (the item may not belong to any configured project at all). Split every request into one of two paths:

- **ID-scoped reads** — the user gives a specific work item or PR number ("read item 602810", "show PR 41"). Resolve the org only (step 3) and skip project resolution entirely. Do not validate the item's project against `AZURE_DEVOPS_PROJECTS` — the ID is unambiguous by definition, even if it belongs to a project outside the configured list.
- **Project-scoped operations** — anything that requires a project to run at all: WIQL queries ("what bugs are in <project-a>"), `pr list`, creating a work item or PR, updating state, commenting, or linking. These require full project resolution (step 4) before running anything.

## 3. Resolve the org

`AZURE_DEVOPS_ORG` is a single value. If unset, ask the user for it — do not guess or hardcode a default. This is sufficient on its own for ID-scoped reads (step 2).

## 4. Resolve the target project — never guess

Required for project-scoped operations only (step 2):

1. Parse `AZURE_DEVOPS_PROJECTS` into a list.
2. **If the user names a project explicitly** (e.g. "in <project-a>"), it must match one of the configured entries (case-insensitive). A name that doesn't match any configured entry is an error — ask the user to correct it or add it to `AZURE_DEVOPS_PROJECTS`. Never silently substitute a different configured project.
3. **If no project is named and only one is configured,** use it — but state which org/project out loud before running anything (e.g. "Using `<org>/<project-a>`, configured via AZURE_DEVOPS_PROJECTS") rather than proceeding silently.
4. **If no project is named and multiple are configured,** ask the user to disambiguate before running any `az boards`/`az repos` command.

## 5. Discover the project's field schema at runtime

Azure DevOps work item types, area paths, and iteration paths vary per project — never assume fixed fields. Before creating or updating a work item for the first time in a project this session:

```bash
az boards work-item show --id <existing-id> --org https://dev.azure.com/<org> --output json   # sample an existing item, or:
az boards area project list --project <project> --org https://dev.azure.com/<org>
az boards iteration project list --project <project> --org https://dev.azure.com/<org>
```

Use these to confirm valid work item types and area/iteration path values before building any create/update payload. Do not guess a field value that hasn't been confirmed against the project.

## 6. Read operations

ID-scoped (org only, per step 2/3):

```bash
az boards work-item show --id <id> --org https://dev.azure.com/<org>
az repos pr show --id <id> --org https://dev.azure.com/<org>
```

Project-scoped (org + project, per step 4):

```bash
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType] FROM WorkItems WHERE [System.TeamProject] = '<project>' AND [System.WorkItemType] IN ('Bug', 'Defect') ORDER BY [System.ChangedDate] DESC" --org https://dev.azure.com/<org>
az repos pr list --project <project> --org https://dev.azure.com/<org>
```

Summarize results for the user rather than dumping raw CLI output. A broad WIQL query (e.g. "all work items in a project") can return a very large result set — if so, save the full output and summarize the top items rather than pasting everything.

## 7. Write operations — always preview and confirm

All write operations are project-scoped (step 4) plus, for creates/updates, schema-checked (step 5). For any create/comment/state-change/link operation:

1. Build the exact `az` command and the exact field values (using the schema confirmed in step 5).
2. Show the user the full command and payload verbatim, including the resolved org/project target.
3. Ask for explicit confirmation before running it.
4. Only after confirmation, execute it.

Examples:

```bash
az boards work-item create --type "<type>" --title "<title>" --org https://dev.azure.com/<org> --project <project>
az repos pr create --title "<title>" --description "<body>" --org https://dev.azure.com/<org> --project <project> --repository <repo> --target-branch main
az boards work-item update --id <id> --state "<state>" --org https://dev.azure.com/<org>
az repos pr work-item add --id <pr-id> --work-items <work-item-id> --org https://dev.azure.com/<org>
```

Preview the exact linking reference or comment text before posting, same as any other write.

> **One amendment, scoped to batch write mode alone.** Batch write mode (step 8), operating over an **audited backlog tree**, takes **one confirmation for the whole batch** instead of one per write. **Every other write in this file still takes its own confirmation** — including a single work item created outside batch mode. The four rules above are unchanged for all of them.
>
> The replacement control is **per-item result reporting** (step 8i), not a relaxation. A mid-run `az` failure leaves a **partially created backlog**, which is a worse outcome than either failure the per-write rule guards against, so the compensating control must tell the operator exactly what was and was not created, and what to do next.
>
> This amendment comes from `docs/ado-delivery-pipeline-brief.md`'s 2026-07-29 scope revision rather than from a fresh judgement here, and the rule is amended **once, deliberately, in the file that owns it.**

## 8. Batch write mode — creating work items from a backlog tree

Consumes a reviewed feature/story/task tree emitted by `/backlog` (`<spec_dir>/<feature>.backlog.md`) and creates that tree as Azure DevOps work items in one pass.

Three properties hold throughout, and each is load-bearing:

- **Creates only.** This mode never sets state, assigns, logs hours, comments, or closes. Advancing a work item is `/implement` work-item mode's job.
- **Sole writer of `external_refs:`.** No other skill, agent, or person writes that field, and this mode writes no other line of the tree.
- **No rollback, ever.** A partial or interrupted run is **resumed**, never undone. Nothing here deletes a work item it created.

Do not enter this mode to create a single work item — steps 1–7 cover that, with their per-write confirmation intact.

**Steps 8a–8i live in `${CLAUDE_SKILL_DIR}/batch.md`. Read that file in full before doing anything else in
this mode** — before the preview and before any `az` write. Steps 1–4 above (setup, org, project) apply
unchanged, and the batch steps assume they have already run. The labels 8a–8i are kept exactly, because
other skills cite them by number. The file is long: if a single read is truncated or refused for size, read it
in successive ranges (offset and limit) until you have all of it — a partial read is not a read of the gates.

**The one-confirmation licence in the amendment above applies only once `batch.md` has been read in full in
this run and its 8e preview has been shown.** Until then step 7's per-write confirmation applies to every
write. Before the preview, say which of 8a–8i you have read, ending with the final section, "Gotchas
specific to batch mode" — a model that cannot name them has not read the gates. If the path above still
shows the literal text `${CLAUDE_SKILL_DIR}`, it was not substituted: look for `batch.md` beside this
`SKILL.md`.

**If `batch.md` cannot be read, stop before the preview.** Nothing has been written at that point. Report
the path that failed and that the skill's supporting file is missing (re-run the pack's `install.sh`). Do not
rebuild the batch steps from memory: the gates, the write-back and the resume rules in them are what make a
partial run recoverable, and a run without them is the "partially created backlog" the amendment above
exists to prevent.

## Gotchas

- **`az account show` fails or shows no account:** Walk through `az login` interactively. Never ask the user to paste a PAT into chat.
- **`devops` extension missing:** `az boards`/`az repos` commands fail with an unrecognized-command error until `az extension add --name azure-devops` runs. Check for this before diagnosing anything else as an auth problem.
- **Don't ask "which project?" for a bare ID:** Work item and PR IDs are unique org-wide. A request like "read item 602810" needs only `AZURE_DEVOPS_ORG` — see step 2. Forcing project disambiguation here is a false ambiguity, not a safety win.
- **`AZURE_DEVOPS_PROJECTS` unset (project-scoped op):** Treat as first-run. Ask the user which project(s) to use for this session rather than guessing.
- **Only one project configured is not the same as "safe to assume":** Still state the resolved org/project out loud before running anything — a single configured project can still be the wrong one if the env var is stale or set globally across work.
- **Ambiguous project target:** If more than one project is configured and the request doesn't name one for a project-scoped operation, always ask.
- **Assuming a fixed field schema:** Work item type names, area paths, and iteration paths are project-specific in Azure DevOps. Never reuse field values discovered in one project for another without re-running step 5.
- **Write operations:** Never skip the preview-and-confirm step in step 7, even for a one-line comment. This is the one hard rule carried over from `devops-github`.
- **The per-batch confirmation is scoped to batch mode alone:** Step 7 still governs every other write in this file. One confirmation covering many writes is sanctioned in step 8 and nowhere else.
- **A blank `az` result is a tool failure on this machine, not a success:** Treat empty output as `UNKNOWN` and stop. See `memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`.
- **`$?` lies after a native command:** Use `$LASTEXITCODE`. A zero-looking `$?` following an `az` call is not evidence the call succeeded.
