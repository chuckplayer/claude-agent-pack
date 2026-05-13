---
name: obsidian-capture
description: >
  Save a note, decision, or thought to the Obsidian vault right now. Use when
  someone says "capture this", "save this to Obsidian", "note this down", "log
  this decision", "obsidian note", "save this for later", "capture that idea".
  Requires OBSIDIAN_VAULT_PATH to be set.
---

# Obsidian Capture

Save an ad-hoc note, decision, or thought to the vault immediately. Captures
land in `Claude/captures/` and are linked into the daily note automatically.

## Step 1 — Check configuration

Run `bash -c 'echo $OBSIDIAN_VAULT_PATH'` (or `$env:OBSIDIAN_VAULT_PATH` on
Windows). If the result is empty, stop and tell the user:

> "OBSIDIAN_VAULT_PATH is not set. Re-run `install.sh` and provide your vault
> path when prompted, or add it manually to `~/.claude/settings.json` under
> the `env` key."

## Step 2 — Collect content

Ask the user: "What do you want to capture?"

Accept a title and body, or just body text (title will default to the first
line of the body if not provided separately).

## Step 3 — Dispatch obsidian-writer

Invoke the **obsidian-writer** agent with:

- `write_mode`: `capture`
- `vault_path`: value of `OBSIDIAN_VAULT_PATH`
- `cli_mode`: value of `OBSIDIAN_CLI_MODE` (default `"filesystem"` if unset)
- `rest_api_port`: value of `OBSIDIAN_REST_API_PORT` (default `27123` if unset)
- `title`: user's title
- `body`: user's body text
- `project`: basename of current working directory
- `timestamp`: current datetime in `YYYY-MM-DDThh:mm` format

## Step 4 — Confirm

Report the file path the agent wrote to. Example:

> "Captured to `Claude/captures/2026-05-13-1430.md`"

## Gotchas

- If `OBSIDIAN_VAULT_PATH` contains spaces, it still works — the agent handles
  quoting.
- Do not attempt to write the file yourself — always dispatch obsidian-writer.
- If obsidian-writer reports the vault directory doesn't exist, tell the user
  to verify the path in `~/.claude/settings.json`.
