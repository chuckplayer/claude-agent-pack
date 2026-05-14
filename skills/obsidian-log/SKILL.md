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
- `OBSIDIAN_CLI_MODE` (default `"filesystem"` if unset)
- `OBSIDIAN_REST_API_PORT` (default `27123` if unset)
- `OBSIDIAN_REST_API_HTTPS` (default `"false"` if unset)
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

## Step 4 — Dispatch obsidian-writer

Invoke the **obsidian-writer** agent with:

- `write_mode`: `session`
- `vault_path`: value of `OBSIDIAN_VAULT_PATH`
- `cli_mode`: value of `OBSIDIAN_CLI_MODE` (default `"filesystem"` if unset)
- `rest_api_port`: value of `OBSIDIAN_REST_API_PORT` (default `27123` if unset)
- `rest_api_https`: value of `OBSIDIAN_REST_API_HTTPS` (default `"false"` if unset)
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

## Step 5 — Confirm

Report the session file path returned by obsidian-writer. Example:

> "Session logged to `Projects/agent-pack/sessions/2026-05-14-1430-agent-pack.md`"

## Gotchas

- If not in a git repo, the step 2 git commands will fail — catch gracefully
  and pass `"not a git repo"` as the branch field.
- Do not summarize or edit the user's bullets — record them verbatim.
- Do not write the file yourself — always dispatch obsidian-writer.
