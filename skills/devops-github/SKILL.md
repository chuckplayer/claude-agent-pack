---
name: devops-github
description: "Read and create GitHub PRs and issues via the gh CLI for repos configured in GITHUB_ORG/GITHUB_REPOS. Use for one-off GitHub Boards/Repos operations outside the code pipeline: viewing PRs or issues, commenting, changing state, linking commits. Trigger this when someone says: check my PRs, list open issues, create a GitHub issue, comment on PR #N, close this issue, link this commit to an issue, connect to github, smoke test the gh cli. Do NOT use for Azure DevOps boards/work items -- that's skills/devops-azure. Do NOT use for a full code review or implementation pipeline -- use /review-pr or /implement instead."
---

# GitHub (gh CLI)

Read and write GitHub PRs and issues by shelling out to the `gh` CLI — no MCP server required. Handles first-time setup, strict repo targeting, and safe write operations for repos configured via environment variables.

## 1. Verify setup

Check, in order:

1. **`gh` CLI installed?** Run `gh --version`. If missing, stop and direct the user to install it (https://cli.github.com).
2. **Authenticated?** Run `gh auth status`. If not logged in, walk the user through `gh auth login` interactively — do not attempt to script credentials or store a PAT in plaintext. Let `gh` handle the browser/token flow natively.
3. **Env vars set?** Check `GITHUB_ORG` and `GITHUB_REPOS` (comma-delimited list, e.g. `GITHUB_REPOS=repo-a,repo-b`). If unset, ask the user for the org and repo(s) they want to work with for this session — do not hardcode any org/repo name into this file.

Report each check's result clearly before proceeding.

## 2. Resolve the target repo — never guess

Repo targeting must be unambiguous every time, even when it seems obvious:

1. **Resolve both sources.** Parse `GITHUB_REPOS` into a list, and if the current working directory is inside a git repo, also read its remote (`git remote get-url origin`).
2. **If the user names a repo explicitly,** it must match one of the configured `GITHUB_REPOS` entries (case-insensitive). A name that doesn't match any configured entry is an error — ask the user to correct it or add it to `GITHUB_REPOS`. Never silently substitute a different configured repo.
3. **If no repo is named and only one is configured,** use it — but state which repo out loud before running anything (e.g. "Using `org/repo-a`, configured via GITHUB_REPOS") rather than proceeding silently.
4. **If no repo is named and multiple are configured,** ask the user to disambiguate before running any `gh` command.
5. **If the local git remote disagrees with the resolved target** (configured repo or user-named repo points somewhere other than what's checked out locally), stop and flag the mismatch explicitly — ask the user to confirm which one they actually mean before proceeding.

## 3. Identify the operation

Ask or infer whether the user wants to **read** or **write**:

- **Read:** list/view PRs, issues, checks, comments — no confirmation needed, safe to run directly.
- **Write:** create a PR/issue, comment, change state (close/reopen/merge), link a commit to an issue — always preview first (see step 5).

## 4. Read operations

Common commands (run with `--repo <org>/<repo>` resolved from step 2):

```bash
gh pr list --repo <org>/<repo>
gh pr view <number> --repo <org>/<repo>
gh issue list --repo <org>/<repo>
gh issue view <number> --repo <org>/<repo>
```

Summarize results for the user rather than dumping raw CLI output.

## 5. Write operations — always preview and confirm

For any create/comment/state-change/link operation:

1. Build the exact `gh` command and, for multi-line bodies, the exact text that will be posted.
2. Show the user the full command and payload verbatim, including the resolved `--repo <org>/<repo>` target.
3. Ask for explicit confirmation before running it.
4. Only after confirmation, execute it.

Examples:

```bash
gh issue create --repo <org>/<repo> --title "<title>" --body "<body>"
gh pr create --repo <org>/<repo> --title "<title>" --body "<body>" --base main
gh issue comment <number> --repo <org>/<repo> --body "<comment>"
gh issue close <number> --repo <org>/<repo>
```

Linking a commit to an issue is done via a `Fixes #<number>` / `Closes #<number>` reference in a commit message or PR/issue body — preview the exact reference text before including it.

## Gotchas

- **`gh auth status` fails or shows no host:** Walk through `gh auth login` interactively (choose GitHub.com, browser or token flow). Never ask the user to paste a PAT into chat — let `gh` prompt for it directly in the terminal.
- **`GITHUB_REPOS` unset:** Treat as first-run. Ask the user which org/repo(s) to use for this session rather than guessing or defaulting to the current git remote silently — confirm it matches intent first.
- **Only one repo configured is not the same as "safe to assume":** Still state the resolved repo out loud before running anything, and still cross-check it against the local git remote if one exists. A single configured repo can still be the wrong repo if the env var is stale or set globally across projects.
- **Ambiguous repo target:** If more than one repo is configured and the request doesn't name one, always ask — never guess which repo a bare issue/PR number belongs to.
- **Configured repo vs. local git remote mismatch:** If `GITHUB_REPOS` (or a user-named repo) doesn't match the git remote of the current working directory, stop and ask — don't assume the env var or the local checkout is "more correct."
- **Write operations:** Never skip the preview-and-confirm step in step 5, even for a one-line comment. This is the one hard rule from the design brief.
