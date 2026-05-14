---
name: obsidian-log
description: >
  Write a session log entry to the Obsidian vault for the current Claude Code
  session. Use when someone says "log this session", "save session to Obsidian",
  "obsidian log", "write a session note", "log what we did", "record what we
  built". Gathers git context and asks for a brief summary before writing.
  Requires OBSIDIAN_VAULT_PATH to be set.
---

# Obsidian Log

Write a lightweight session log capturing what was built, any decisions made,
and what comes next. Session logs land in the project's vault folder
(`<projects_folder>/<repo>/sessions/` or `Claude/<repo>/sessions/` if no
projects folder is configured) and are linked into the daily note automatically.

## Step 1 — Check configuration

Read `OBSIDIAN_VAULT_PATH` from the environment:
- Bash: `bash -c 'echo $OBSIDIAN_VAULT_PATH'`
- PowerShell: `$env:OBSIDIAN_VAULT_PATH`

If empty, stop and tell the user:

> "OBSIDIAN_VAULT_PATH is not set. Re-run `install.sh` and provide your vault
> path when prompted, or add it manually to `~/.claude/settings.json` under
> the `env` key."

Also read:
- `OBSIDIAN_REST_API_KEY` (empty string if unset — key presence gates REST API use)
- `OBSIDIAN_REST_API_PORT` (default `27124` if unset)
- `OBSIDIAN_REST_API_HTTPS` (default `"true"` if unset)
- `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)

## Step 2 — Gather git context

Run these commands via the Bash tool:

- `git branch --show-current` — current branch name
- `git log --oneline -5` — five most recent commits
- `git diff --stat HEAD~1 2>/dev/null || echo "(no prior commit)"` — files
  changed in the last commit
- Current datetime (record at the moment of invocation)

## Step 3 — Ask for summary

Ask the user:

> "What were the key things done, any decisions made, and what's next? A few
> bullets is all that's needed — this is lightweight."

Accept the user's response as-is. Do not expand, rewrite, or paraphrase it.

## Step 4 — Write session file (REST API if key present, filesystem fallback)

### 4a. REST API attempt (skip if `OBSIDIAN_REST_API_KEY` is empty)

If the key is set, attempt to write the session file via the Obsidian Local REST
API using PowerShell. This runs in the main session where PowerShell is available.

**Compute the vault-relative session path:**
```
effective_folder = OBSIDIAN_PROJECTS_FOLDER || "Claude/Projects"
project_slug     = project_name, lowercased, non-alphanumeric → hyphens, max 30 chars
timestamp        = YYYY-MM-DD-HHmm (from step 2 datetime)
vault_rel_path   = <effective_folder>/<project_slug>/sessions/<timestamp>-<project_slug>.md
                   (use forward slashes)
```

**Build the session markdown** (same format obsidian-writer would produce):
```markdown
---
type: claude/session
project: <project>
project_dir: <project_dir>
date: <YYYY-MM-DD>
ended_at: <YYYY-MM-DDThh:mm>
branch: <branch>
tags: [claude, session-log]
---

## What was done
<what_was_done bullets>

## Decisions made
<decisions bullets>

## Next steps
<next_steps bullets>
```

**Attempt the PUT via PowerShell:**
```powershell
$key    = $env:OBSIDIAN_REST_API_KEY
$port   = if ($env:OBSIDIAN_REST_API_PORT) { $env:OBSIDIAN_REST_API_PORT } else { "27124" }
$scheme = if ($env:OBSIDIAN_REST_API_HTTPS -eq 'false') { 'http' } else { 'https' }
$vaultRel = "<vault_rel_path computed above>"
$url    = "${scheme}://127.0.0.1:${port}/vault/${vaultRel}"
$body   = @"<session markdown content>"@
try {
    Invoke-RestMethod -Method Put -Uri $url `
        -Headers @{ "Authorization" = "Bearer $key"; "Content-Type" = "text/markdown" } `
        -Body $body -ContentType 'text/markdown' `
        -SkipCertificateCheck -TimeoutSec 5
    $apiWritten = $true
} catch {
    $apiWritten = $false
}
```

- If `$apiWritten` is `$true`: proceed to step 4b with `session_api_written: true`
- If `$apiWritten` is `$false` (any error): proceed to step 4b with `session_api_written: false`

### 4b. Dispatch obsidian-writer

Invoke the **obsidian-writer** agent with:

- `write_mode`: `session`
- `vault_path`: value of `OBSIDIAN_VAULT_PATH`
- `projects_folder`: value of `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
- `project`: basename of `CLAUDE_PROJECT_DIR` or current working directory
- `project_dir`: `CLAUDE_PROJECT_DIR` or current working directory
- `branch`: from step 2
- `recent_commits`: from step 2
- `changed_files`: from step 2
- `what_was_done`: from the user's answer
- `decisions`: from the user's answer
- `next_steps`: from the user's answer
- `timestamp`: current datetime in `YYYY-MM-DDThh:mm` format
- `session_api_written`: `true` if 4a succeeded, `false` otherwise

## Step 5 — Confirm

Report the session file path and whether it was written via REST API or filesystem.
Example:

> "Session logged to `Amwins/agent-pack/sessions/2026-05-14-1430-agent-pack.md` (via REST API)"

or:

> "Session logged to `Amwins/agent-pack/sessions/2026-05-14-1430-agent-pack.md` (filesystem)"

## Gotchas

- If not in a git repo, the step 2 git commands will fail — catch gracefully
  and pass `"not a git repo"` as the branch field.
- Do not summarize or edit the user's bullets — record them verbatim.
- If OBSIDIAN_REST_API_KEY is missing: skip step 4a entirely and dispatch
  obsidian-writer with `session_api_written: false`.
- The daily note append is always handled by obsidian-writer (filesystem), even
  when step 4a succeeds — do not attempt REST API for the daily note in this skill.
