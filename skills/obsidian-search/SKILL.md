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

Search everything Claude has logged in your vault. Results are scoped to the
current project by default — pass `--global` (or ask "search all projects") to
search the entire vault.

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
- `CLAUDE_PROJECT_DIR` (or fall back to current working directory)

## Step 2 — Determine search scope

**If the user passed `--global` or asked to search "all projects" / "everywhere":**
- Search scope: `<OBSIDIAN_VAULT_PATH>/Claude/**/*.md`
- If `OBSIDIAN_PROJECTS_FOLDER` is set, also include:
  `<OBSIDIAN_VAULT_PATH>/<OBSIDIAN_PROJECTS_FOLDER>/**/*.md`

**Default (project-first):**
- Compute `project_slug`: basename of `CLAUDE_PROJECT_DIR` (or cwd), lowercase,
  non-alphanumeric chars replaced with hyphens, max 30 characters.
- If `OBSIDIAN_PROJECTS_FOLDER` is set:
  Search `<OBSIDIAN_VAULT_PATH>/<OBSIDIAN_PROJECTS_FOLDER>/<project_slug>/**/*.md`
- If not set:
  Search `<OBSIDIAN_VAULT_PATH>/Claude/<project_slug>/**/*.md`

If the project folder does not exist or returns no results, automatically fall
through to the global scope and note that you expanded the search.

## Step 3 — Get search term

If the user has not already provided a search term, ask:

> "What are you looking for?"

## Step 4 — Search

Use the Grep tool on the determined scope for the search term (case-insensitive).
For each matching file, read 3–5 lines of context around the match.

If there are more than 10 matching files, sort by most recently modified and
show only the top 10.

## Step 5 — Present results

For each match, show:

- **Wikilink** — relative to the vault root, no `.md` extension, forward slashes:
  `[[Projects/agent-pack/sessions/2026-05-14-1430-agent-pack]]`
- **Excerpt** — one line of match context
- **Type** — `session`, `capture`, `daily`, or `memory-snapshot`

If no matches are found in the project scope, try the global scope automatically.

If no matches found globally, say:

> "No results found for '<term>' in your Claude notes. Try a broader term or
> check that notes have been written with `/obsidian-log` or `/obsidian-capture`."

## Step 6 — Open best match (optional)

If `OBSIDIAN_CLI_MODE` is `"rest-api"` and there are results, offer to open
the best match in Obsidian:

> "Would you like me to open the top result in Obsidian?"

If yes, compute the vault-relative path (forward slashes, URL-encoded), then call:

```bash
curl -sk "https://127.0.0.1:${OBSIDIAN_REST_API_PORT:-27123}/open/<url-encoded-vault-relative-path>"
```

## Gotchas

- Read-only. Never modify any vault files.
- Wikilinks must be relative to the vault root — strip the `OBSIDIAN_VAULT_PATH`
  prefix, convert backslashes to forward slashes, and remove the `.md` extension.
- If there are many matches (more than 10), show the 10 most recently modified
  files first.
- Memory snapshot files (`memory-snapshot.md`) can also contain useful context —
  include them in search results.
