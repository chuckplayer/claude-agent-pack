---
name: obsidian-daily
description: >
  Show or open today's Claude activity note in the Obsidian vault. Use when
  someone says "show today's Obsidian note", "open daily note", "what did I do
  today", "obsidian daily", "today's activity", "what did Claude do today".
  Read-only — does not modify any files.
---

# Obsidian Daily

View today's Claude activity note. The daily note at
`Claude/daily/<YYYY-MM-DD>.md` accumulates links to every session log and
capture written today. This skill is read-only — it never dispatches
obsidian-writer.

## Step 1 — Check configuration

Run `bash -c 'echo $OBSIDIAN_VAULT_PATH'` (or `$env:OBSIDIAN_VAULT_PATH` on
Windows). If the result is empty, stop and tell the user:

> "OBSIDIAN_VAULT_PATH is not set. Re-run `install.sh` and provide your vault
> path when prompted, or add it manually to `~/.claude/settings.json` under
> the `env` key."

## Step 2 — Read today's daily note

Construct the path using today's local date:

```
<OBSIDIAN_VAULT_PATH>/Claude/daily/<YYYY-MM-DD>.md
```

Use the Read tool to read the file.

## Step 3 — Display

Show the file contents inline in the conversation.

If the file does not exist, say:

> "No activity logged today yet. Use `/obsidian-capture` to save a note or
> `/obsidian-log` to record a session."

## Step 4 — Open in Obsidian (optional)

If `OBSIDIAN_CLI_MODE` is `"rest-api"`, attempt to open the note in Obsidian's
editor:

```bash
curl -sk "https://127.0.0.1:${OBSIDIAN_REST_API_PORT:-27123}/open/Claude%2Fdaily%2F<YYYY-MM-DD>.md"
```

If this fails, or if CLI mode is `"filesystem"`, skip silently — the note was
already displayed inline in step 3.

## Gotchas

- This skill is strictly read-only. Do not dispatch obsidian-writer under any
  circumstance.
- If the vault path contains spaces, URL-encode it properly in the curl command.
- The date must be today's local date, not UTC.
