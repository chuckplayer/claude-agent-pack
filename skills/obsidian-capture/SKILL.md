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
always land in `Claude/captures/` (global, not project-specific) and are linked
into the project's daily note automatically.

## Step 1 — Check configuration

Read `OBSIDIAN_VAULT_PATH` from the environment:
- Bash: `bash -c 'echo $OBSIDIAN_VAULT_PATH'`
- PowerShell: `$env:OBSIDIAN_VAULT_PATH`

If empty, stop and tell the user:

> "OBSIDIAN_VAULT_PATH is not set. Re-run `install.sh` and provide your vault
> path when prompted, or add it manually to `~/.claude/settings.json` under
> the `env` key."

Also read:
- `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset — used for daily note routing)

You do not need the REST API variables. `obsidian-writer` owns the transport chain
(CLI → REST API → filesystem) and reads `OBSIDIAN_REST_API_KEY`, `OBSIDIAN_REST_API_PORT`,
and `OBSIDIAN_REST_API_HTTPS` from the environment itself. Never pass the API key to an
agent — it would end up in the dispatch payload and the transcript.

## Step 2 — Collect content

Ask the user: "What do you want to capture?"

Accept a title and body, or just body text (title will default to the first
line of the body if not provided separately).

## Step 3 — Dispatch obsidian-writer

Invoke the **obsidian-writer** agent with:

- `write_mode`: `capture`
- `vault_path`: value of `OBSIDIAN_VAULT_PATH`
- `projects_folder`: value of `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
- `title`: user's title
- `body`: user's body text
- `project`: basename of current working directory
- `timestamp`: current datetime in `YYYY-MM-DDThh:mm` format

That is the whole step. Do not attempt the REST API here — obsidian-writer tries the Obsidian
CLI, then the REST API, then the filesystem, and reports which one succeeded. Building the
capture markdown, choosing a transport, and verifying the write are all its job.

## Step 4 — Confirm

Report the file path and the transport obsidian-writer reported. Example:

> "Captured to `Claude/captures/2026-05-14-1430.md` (via Obsidian CLI)"

or:

> "Captured to `Claude/captures/2026-05-14-1430.md` (filesystem — CLI and REST API unavailable)"

Pass the transport through rather than guessing it. If obsidian-writer reports it degraded to
the filesystem, say why in the same line — a silent permanent degradation is invisible otherwise.

## Gotchas

- Capture files always go to `Claude/captures/` — they are not project-scoped.
- **Do not attempt the REST API in this skill.** It used to, and that duplicated transport
  logic in every calling skill. obsidian-writer owns the whole chain now; a REST attempt here
  would run *before* the dispatch and so defeat the CLI-first ordering entirely.
- Never pass `OBSIDIAN_REST_API_KEY` to obsidian-writer. It reads the key from the environment
  precisely so the secret stays out of the dispatch payload and the transcript.
- If obsidian-writer reports the vault directory doesn't exist, tell the user
  to verify the path in `~/.claude/settings.json`.
