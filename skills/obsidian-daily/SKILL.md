---
name: obsidian-daily
description: >
  Show or open today's Claude activity note in the Obsidian vault. Use when
  someone says "show today's Obsidian note", "open daily note", "what did I do
  today", "obsidian daily", "today's activity", "what did Claude do today".
  Read-only — does not modify any files.
---

# Obsidian Daily

View today's Claude activity note. This skill is read-only — it never dispatches
obsidian-writer.

## Step 1 — Check configuration

Read `OBSIDIAN_VAULT_PATH` from the environment:
- Bash: `bash -c 'echo $OBSIDIAN_VAULT_PATH'`
- PowerShell: `$env:OBSIDIAN_VAULT_PATH`

If empty, stop and tell the user:

> "OBSIDIAN_VAULT_PATH is not set. Re-run `install.sh` and provide your vault
> path when prompted, or add it manually to `~/.claude/settings.json` under
> the `env` key."

Also read:
- `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
- `CLAUDE_PROJECT_DIR` (or fall back to current working directory) — used to compute the repo slug

## Step 2 — Compute the daily note path

Today's local date in `YYYY-MM-DD` format.

1. Compute `project_slug`: basename of `CLAUDE_PROJECT_DIR` (or cwd), lowercase,
   non-alphanumeric characters replaced with hyphens, max 30 characters.
2. Use `OBSIDIAN_PROJECTS_FOLDER` if set, otherwise default to `Claude/Projects`.
3. `effective_folder` may be multi-segment (e.g. `Claude/Projects`) — treat each
   `/`-delimited segment as a path component.
4. Daily note path: `<OBSIDIAN_VAULT_PATH>/<effective_folder>/<project_slug>/daily/<YYYY-MM-DD>.md`

## Step 3 — Read today's daily note

Use the Read tool to read the file at the computed path.

## Step 4 — Display

Show the file contents inline in the conversation.

If the file does not exist, say:

> "No activity logged today yet for this project. Session notes appear here
> automatically when Claude Code stops; use `/obsidian-capture` to save a note
> or `/obsidian-recap` to synthesize a daily recap."

## Step 5 — Open in Obsidian (optional)

If `OBSIDIAN_CLI_MODE` is `"rest-api"`, attempt to open the note in Obsidian's
editor. Compute the vault-relative path (strip the vault root prefix, use forward
slashes, URL-encode the result), then call:

```bash
curl -sk "https://127.0.0.1:${OBSIDIAN_REST_API_PORT:-27124}/open/<url-encoded-vault-relative-path>"
```

If this fails, or if CLI mode is `"filesystem"`, skip silently — the note was
already displayed inline in step 4.

## Gotchas

- This skill is strictly read-only. Do not dispatch obsidian-writer under any
  circumstance.
- The date must be today's local date, not UTC.
- If the vault path contains spaces, URL-encode it properly in the curl command.
- Project slug computation: `basename(cwd).toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 30)`
