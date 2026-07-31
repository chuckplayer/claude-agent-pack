---
name: devops-azure
description: "Read and create Azure DevOps work items and PRs via the az CLI (devops extension) for the org/projects configured in AZURE_DEVOPS_ORG/AZURE_DEVOPS_PROJECTS. Use for one-off Azure Boards/Repos operations outside the code pipeline: viewing or creating work items, viewing PRs, commenting, updating state, linking work items to PRs/commits. Trigger this when someone says: check my work items, list open PRs in Azure DevOps, create a work item, comment on PR #N, close this work item, link this commit to a work item, connect to azure devops, smoke test the az cli. Do NOT use for GitHub PRs/issues -- that's skills/devops-github. Do NOT use for a full code review or implementation pipeline -- use /review-pr or /implement instead. Do NOT use to decompose a spec of record into a backlog -- that is /backlog, which produces a reviewed feature/story/task tree first."
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

## Gotchas

- **`az account show` fails or shows no account:** Walk through `az login` interactively. Never ask the user to paste a PAT into chat.
- **`devops` extension missing:** `az boards`/`az repos` commands fail with an unrecognized-command error until `az extension add --name azure-devops` runs. Check for this before diagnosing anything else as an auth problem.
- **Don't ask "which project?" for a bare ID:** Work item and PR IDs are unique org-wide. A request like "read item 602810" needs only `AZURE_DEVOPS_ORG` — see step 2. Forcing project disambiguation here is a false ambiguity, not a safety win.
- **`AZURE_DEVOPS_PROJECTS` unset (project-scoped op):** Treat as first-run. Ask the user which project(s) to use for this session rather than guessing.
- **Only one project configured is not the same as "safe to assume":** Still state the resolved org/project out loud before running anything — a single configured project can still be the wrong one if the env var is stale or set globally across work.
- **Ambiguous project target:** If more than one project is configured and the request doesn't name one for a project-scoped operation, always ask.
- **Assuming a fixed field schema:** Work item type names, area paths, and iteration paths are project-specific in Azure DevOps. Never reuse field values discovered in one project for another without re-running step 5.
- **Write operations:** Never skip the preview-and-confirm step in step 7, even for a one-line comment. This is the one hard rule carried over from `devops-github`.
