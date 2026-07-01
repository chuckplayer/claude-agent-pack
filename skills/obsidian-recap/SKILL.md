---
name: obsidian-recap
description: >
  Synthesize a daily recap of Claude activity for the current project and write
  it to the Obsidian vault. Reads the day's auto-logged session notes, git
  history, and current-state note, then produces a narrative "what happened
  today" rollup that the link-only daily note lacks. Use when someone says
  "recap today", "daily recap", "write a recap", "summarize today's work",
  "obsidian recap", "wrap up the day", "end-of-day summary". Defaults to today;
  accepts a date argument (YYYY-MM-DD). Requires OBSIDIAN_VAULT_PATH to be set.
---

# Obsidian Recap

Produce a synthesized, narrative **daily recap** for the current project and
persist it to the vault. The Stop hook already writes one session note per
session and a link-only daily note; those are raw artifacts. This skill reads
those artifacts and turns them into prose a human can skim weeks later.

**This is synthesis, not transcription.** The recap explains what was
accomplished and why, collapsing many sessions into a coherent story. It is the
LLM's job precisely because a hook cannot summarize.

Recaps land in `<projects_folder>/<repo>/recaps/<YYYY-MM-DD>.md` (or
`Claude/Projects/<repo>/recaps/` if no projects folder is configured) and are
linked into that day's daily note automatically.

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
- `CLAUDE_PROJECT_DIR` (or fall back to current working directory)

## Step 2 — Determine date and scope

**Target date:** default to today (`YYYY-MM-DD`). If the user passed a date
argument (e.g., `/obsidian-recap 2026-06-30`), use that instead. Reject anything
that is not a valid `YYYY-MM-DD` string and ask for the correct format.

**Project slug:** basename of `CLAUDE_PROJECT_DIR` (or cwd), lowercased,
non-alphanumeric characters replaced with hyphens, max 30 characters.

**Effective folder:**
```
effective_folder = OBSIDIAN_PROJECTS_FOLDER || "Claude/Projects"
project_base     = <OBSIDIAN_VAULT_PATH>/<effective_folder>/<project_slug>
```

## Step 3 — Gather the day's raw material

Collect, in this order (skip any source that is missing — do not fail):

1. **Session notes for the date.** Use Glob on
   `<project_base>/sessions/<YYYY-MM-DD>-*.md` and read each. These carry the
   frontmatter, recent commits, changed files, prompts, agents invoked, and
   (on SessionEnd) captured decisions.
2. **The daily note** `<project_base>/daily/<YYYY-MM-DD>.md` — the link/GUID
   list of sessions that ran that day (useful to confirm session count).
3. **Current-state note** `<project_base>/_current.md` — the rolling "Where we
   left off" and "Open threads" (context for framing next steps).
4. **Git history for the date**, via the Bash tool from `CLAUDE_PROJECT_DIR`:
   ```bash
   git log --since="<YYYY-MM-DD> 00:00" --until="<YYYY-MM-DD> 23:59" \
     --pretty=format:'%h %s' --no-merges
   ```
   If not a git repo, skip silently.

If **no** session notes and **no** commits exist for the date, stop gracefully:

> "No Claude activity found for `<project_slug>` on `<date>`. Nothing to recap."

Do not invent content or widen the date range on your own.

## Step 4 — Synthesize the recap

Write a narrative recap in this format. Keep it tight (under ~300 words of prose,
excluding lists). Collapse repetition: if five sessions all advanced one feature,
that is one story beat, not five.

```markdown
---
type: claude/recap
project: <project>
date: <YYYY-MM-DD>
sessions: <count of session notes read>
tags: [claude, recap, daily, project/<project_slug>]
---

# Recap — <project> — <YYYY-MM-DD>

## Summary
<2-4 sentence narrative of what the day was about and what moved forward.>

## What shipped
- <bullet per meaningful change, grounded in commits / changed files>

## Decisions
- <bullet per decision captured in the session notes; omit the section if none>

## Open threads / next
- <bullet per unfinished item, drawn from _current.md open threads and session next-steps>

## Sessions
- [[<vault-relative-session-link-1>]] (<HH:MM>)
- [[<vault-relative-session-link-2>]] (<HH:MM>)
```

Grounding rules:
- Every "What shipped" bullet must trace to a real commit or changed file — do
  not claim work that has no artifact.
- Pull "Decisions" only from the `## Decisions` sections of session notes. Do
  not manufacture decisions from prompts.
- Wikilinks are vault-relative: strip the `OBSIDIAN_VAULT_PATH` prefix, convert
  backslashes to forward slashes, drop the `.md` extension.

## Step 5 — Write the recap (REST API if key present, filesystem fallback)

**Vault-relative recap path:** `<effective_folder>/<project_slug>/recaps/<YYYY-MM-DD>.md`
(use forward slashes).

### 5a. REST API attempt (skip if `OBSIDIAN_REST_API_KEY` is empty)

If the key is set, attempt the PUT — try PowerShell first, curl fallback — using
the same pattern as `/obsidian-capture` step 3a. Substitute `$vaultRel` with the
recap path above and `$body` with the recap markdown from step 4. The result
sets `apiWritten` to `true` or `false`.

*PowerShell (Windows PS5.1 or PS7, or macOS/Linux with `pwsh`):*
```powershell
$key    = $env:OBSIDIAN_REST_API_KEY
$port   = if ($env:OBSIDIAN_REST_API_PORT) { $env:OBSIDIAN_REST_API_PORT } else { "27124" }
$scheme = if ($env:OBSIDIAN_REST_API_HTTPS -eq 'false') { 'http' } else { 'https' }
$vaultRel = "<effective_folder>/<project_slug>/recaps/<YYYY-MM-DD>.md"
$url    = "${scheme}://127.0.0.1:${port}/vault/${vaultRel}"
$body   = @"<recap markdown content>"@
$irm = @{ Method='Put'; Uri=$url; Body=$body; ContentType='text/markdown'; TimeoutSec=5
          Headers=@{"Authorization"="Bearer $key";"Content-Type"="text/markdown"} }
try {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Invoke-RestMethod @irm -SkipCertificateCheck
    } else {
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-RestMethod @irm
    }
    $apiWritten = $true
} catch {
    $apiWritten = $false
}
```

*curl fallback (macOS/Linux without `pwsh`):*
```bash
KEY="$OBSIDIAN_REST_API_KEY"
PORT="${OBSIDIAN_REST_API_PORT:-27124}"
SCHEME=$([ "$OBSIDIAN_REST_API_HTTPS" = "false" ] && echo "http" || echo "https")
VAULT_REL="<effective_folder>/<project_slug>/recaps/<YYYY-MM-DD>.md"
BODY='<recap markdown content>'
STATUS=$(curl -sk -X PUT \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: text/markdown" \
  --data-binary "$BODY" \
  -w "%{http_code}" -o /dev/null \
  "${SCHEME}://127.0.0.1:${PORT}/vault/${VAULT_REL}")
[ "${STATUS:-0}" -ge 200 ] && [ "${STATUS:-0}" -lt 300 ] && apiWritten=true || apiWritten=false
```

- If `apiWritten` is `true`: dispatch obsidian-writer with `recap_api_written: true`
  (it will skip the recap file write and only append the daily note).
- If `apiWritten` is `false`: dispatch obsidian-writer normally.

### 5b. Dispatch obsidian-writer

Invoke the **obsidian-writer** agent with:

- `write_mode`: `recap`
- `vault_path`: value of `OBSIDIAN_VAULT_PATH`
- `projects_folder`: value of `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
- `project`: basename of `CLAUDE_PROJECT_DIR` or current working directory
- `date`: target date (`YYYY-MM-DD`)
- `recap_markdown`: the full markdown from step 4
- `session_count`: number of session notes read
- `recap_api_written`: `true` if 5a succeeded, `false` otherwise

## Step 6 — Confirm

Report the recap path and write method. Example:

> "Daily recap written to `Amwins/claude-agent-pack/recaps/2026-07-01.md` (via REST API)"

or:

> "Daily recap written to `Amwins/claude-agent-pack/recaps/2026-07-01.md` (filesystem)"

## Gotchas

- **Synthesis, not transcription.** If you find yourself copying prompt text
  verbatim, stop and summarize instead.
- **Ground every claim in an artifact.** No commit or changed file → no
  "What shipped" bullet.
- **Idempotent by design.** Re-running for the same date overwrites that date's
  recap (a single PUT / single Write). This is intentional — the recap reflects
  the latest reading of the day's notes.
- **Read-only against source notes.** Only the recap file and the daily note are
  written; never modify session notes, `_current.md`, or captures.
- **Do not widen the date range.** If the target date has no activity, say so
  and stop — do not silently recap a different day.
- If not in a git repo, skip the git step and build the recap from session notes
  alone.
