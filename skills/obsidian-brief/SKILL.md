---
name: obsidian-brief
description: >
  Synthesize a context brief from recent Obsidian session logs and captures for
  the current project. Use before starting work to load project context without
  a specific search query. Trigger when someone says "brief me", "what have we
  been working on", "load project context", "catch me up", "obsidian brief",
  "what's the recent context", "summarize recent sessions". Does NOT require a
  search term — it proactively summarizes what's relevant. Read-only.
---

# Obsidian Brief

Synthesize recent Obsidian notes for the current project into a concise context
brief — what was built, decisions made, and open threads — without requiring a
search query. Designed to be run at the start of a session or before `/implement`.

## Step 1 — Check configuration

Read `OBSIDIAN_VAULT_PATH` from the environment:
- Bash: `bash -c 'echo $OBSIDIAN_VAULT_PATH'`
- PowerShell: `$env:OBSIDIAN_VAULT_PATH`

If empty, stop gracefully:

> "OBSIDIAN_VAULT_PATH is not set — skipping context brief. Configure it via
> `install.sh` or add it to `~/.claude/settings.json` under the `env` key."

Also read:
- `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
- `CLAUDE_PROJECT_DIR` (or fall back to current working directory)

## Step 2 — Determine scope and date range

**Project slug:** basename of `CLAUDE_PROJECT_DIR` (or cwd), lowercase,
non-alphanumeric chars replaced with hyphens, max 30 characters.

**Effective folder:**
```
effective_folder = OBSIDIAN_PROJECTS_FOLDER || "Claude/Projects"
project_base     = <OBSIDIAN_VAULT_PATH>/<effective_folder>/<project_slug>
```

**Date range:** default 14 days. If the user passed an argument (e.g., `30d`,
`7d`, `60d`), parse the number. Compute `cutoff_date = today − N days` in
`YYYY-MM-DD` format.

## Step 3 — Find recent notes

Use Glob to collect all `.md` files under `<project_base>/`. Then filter to
files modified on or after `cutoff_date`. On macOS/Linux, create a reference
file and use `find -newer`:

```bash
touch -t "$(date -d '<cutoff_date>' '+%Y%m%d0000' 2>/dev/null || date -j -f '%Y-%m-%d' '<cutoff_date>' '+%Y%m%d0000')" /tmp/brief_cutoff 2>/dev/null
find "<project_base>" -name "*.md" -newer /tmp/brief_cutoff 2>/dev/null
```

Cap at the 10 most recently modified files.

If the project folder does not exist or zero files are found within the date
range, check whether any notes exist at all in the project folder:

- **No folder at all:** "No notes found for `<project_slug>`. Try `/obsidian-log`
  after your next session to start building context."
- **Folder exists but all files are older:** "Most recent note is from
  `<date>`. Try `/obsidian-brief <N>d` with a wider range."

Do not fall through to a global vault search — the brief is project-scoped.

## Step 4 — Read and extract

For each file (most recently modified first), read it and extract:

- **What was built / done** — content under "What was done" headings
- **Decisions** — content under "Decisions made" headings
- **Next steps / open threads** — content under "Next steps" headings, plus any
  lines starting with `- [ ]` or containing `TODO`

Process session logs and capture notes the same way — extract whichever of
the three sections are present.

## Step 5 — Synthesize

Produce a brief in this format (under 250 words total):

```
## Recent context for <project_slug> (last N days, M notes)

### What's been built
<3-5 bullets — collapse redundant items across notes into one bullet each>

### Decisions made
<bullet list — omit this section entirely if no decisions appear in the notes>

### Open threads
<bullet list — most recent first>
```

Collapse: if multiple sessions all mention the same work item, render one
bullet, not one per session. Prioritize the most recent phrasing.

## Step 6 — Offer drill-down

After presenting the brief, list the source notes and offer to open one:

> "Sources (most recent first):
> - `[[<wikilink-1>]]` (YYYY-MM-DD)
> - `[[<wikilink-2>]]` (YYYY-MM-DD)
>
> Want me to load a specific note in full, or open one in Obsidian?"

Wikilinks are relative to the vault root: strip `OBSIDIAN_VAULT_PATH`, convert
backslashes to forward slashes, remove `.md` extension.

If the user asks to open a note and `OBSIDIAN_REST_API_KEY` is set:

```bash
curl -sk "https://127.0.0.1:${OBSIDIAN_REST_API_PORT:-27124}/open/<url-encoded-vault-relative-path>" \
  -H "Authorization: Bearer $OBSIDIAN_REST_API_KEY"
```

## Gotchas

- Read-only. Never modify any vault files.
- Do not widen to global search on empty results — tell the user and stop.
- Synthesis must collapse redundant items. Three sessions mentioning the same
  feature → one bullet, not three.
- Wikilinks must strip the full `OBSIDIAN_VAULT_PATH` prefix and `.md` suffix.
- If the user says `/obsidian-brief 30d`, the `30d` is the date range argument —
  parse it as days and override the 14-day default.
