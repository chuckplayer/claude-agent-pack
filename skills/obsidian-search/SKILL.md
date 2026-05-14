---
name: obsidian-search
description: >
  Search past Claude session logs and captures in the Obsidian vault. Use when
  someone says "find my notes about X", "search obsidian", "what did I log
  about X", "find that capture", "look up session from last week", "search my
  Claude notes". Returns matching entries with excerpts and wikilink references.
  Read-only.
---

# Obsidian Search

Search everything Claude has logged in your vault. Matches against
`Claude/**/*.md` — sessions, captures, and daily notes — and returns results
as Obsidian wikilinks with excerpts so you can jump straight to the right note.

## Step 1 — Check configuration

Run `bash -c 'echo $OBSIDIAN_VAULT_PATH'` (or `$env:OBSIDIAN_VAULT_PATH` on
Windows). If the result is empty, stop and tell the user:

> "OBSIDIAN_VAULT_PATH is not set. Re-run `install.sh` and provide your vault
> path when prompted, or add it manually to `~/.claude/settings.json` under
> the `env` key."

## Step 1.5 — Check for Claude notes directory

Verify `<OBSIDIAN_VAULT_PATH>/Claude/` exists before searching. If it does not exist, stop and tell the user:
"No Claude notes found in your vault yet. Use `/obsidian-capture` to save a note or `/obsidian-log` to record a session, then search again."

## Step 2 — Get search term

If the user has not already provided a search term, ask:

> "What are you looking for?"

## Step 3 — Search

Use the Grep tool on `<OBSIDIAN_VAULT_PATH>/Claude/**/*.md` for the search
term (case-insensitive). For each matching file, read 3–5 lines of context
around the match.

If there are more than 10 matching files, sort by most recently modified and
show only the top 10.

## Step 4 — Present results

For each match, show:

- **Wikilink** — relative to the vault root, no `.md` extension:
  `[[Claude/sessions/2026-05-13-1430-my-project]]`
- **Excerpt** — one line of match context
- **Type** — `session`, `capture`, or `daily`

If no matches are found, say:

> "No results found for '<term>' in your Claude notes. Try a broader term or
> check that notes have been written with `/obsidian-log` or
> `/obsidian-capture`."

## Step 5 — Open best match (optional)

If `OBSIDIAN_CLI_MODE` is `"rest-api"` and there are results, offer to open
the best match in Obsidian:

> "Would you like me to open the top result in Obsidian?"

If yes, call:

```bash
curl -sk "https://127.0.0.1:${OBSIDIAN_REST_API_PORT:-27123}/open/<url-encoded-relative-path>"
```

## Gotchas

- Read-only. Never modify any vault files.
- Wikilinks must be relative to the vault root — strip the `OBSIDIAN_VAULT_PATH`
  prefix and remove the `.md` extension.
- If there are many matches (more than 10), show the 10 most recently modified
  files first.
