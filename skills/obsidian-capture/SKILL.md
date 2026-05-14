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
- `OBSIDIAN_REST_API_KEY` (empty string if unset — key presence gates REST API use)
- `OBSIDIAN_REST_API_PORT` (default `27124` if unset)
- `OBSIDIAN_REST_API_HTTPS` (default `"true"` if unset)
- `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset — used for daily note routing)

## Step 2 — Collect content

Ask the user: "What do you want to capture?"

Accept a title and body, or just body text (title will default to the first
line of the body if not provided separately).

## Step 3 — Write capture file (REST API if key present, filesystem fallback)

### 3a. REST API attempt (skip if `OBSIDIAN_REST_API_KEY` is empty)

If the key is set, attempt to write the capture file via PowerShell.

**Vault-relative capture path** (always): `Claude/captures/<YYYY-MM-DD>-<HHmm>.md`

**Build the capture markdown** (same format obsidian-writer would produce):
```markdown
---
type: claude/capture
project: <project>
date: <YYYY-MM-DD>
captured_at: <YYYY-MM-DDThh:mm>
tags: [claude, capture]
---

## <title>

<body>
```

**Attempt the PUT — try PowerShell first, curl fallback:**

*PowerShell (Windows PS5.1 or PS7, or macOS/Linux with `pwsh` installed):*
```powershell
$key    = $env:OBSIDIAN_REST_API_KEY
$port   = if ($env:OBSIDIAN_REST_API_PORT) { $env:OBSIDIAN_REST_API_PORT } else { "27124" }
$scheme = if ($env:OBSIDIAN_REST_API_HTTPS -eq 'false') { 'http' } else { 'https' }
$vaultRel = "Claude/captures/<YYYY-MM-DD>-<HHmm>.md"
$url    = "${scheme}://127.0.0.1:${port}/vault/${vaultRel}"
$body   = @"<capture markdown content>"@
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

*If PowerShell tool is unavailable (macOS/Linux without `pwsh`), use curl via Bash:*
```bash
KEY="$OBSIDIAN_REST_API_KEY"
PORT="${OBSIDIAN_REST_API_PORT:-27124}"
SCHEME=$([ "$OBSIDIAN_REST_API_HTTPS" = "false" ] && echo "http" || echo "https")
VAULT_REL="Claude/captures/<YYYY-MM-DD>-<HHmm>.md"
BODY='<capture markdown content>'
STATUS=$(curl -sk -X PUT \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: text/markdown" \
  --data-binary "$BODY" \
  -w "%{http_code}" -o /dev/null \
  "${SCHEME}://127.0.0.1:${PORT}/vault/${VAULT_REL}")
[ "${STATUS:-0}" -ge 200 ] && [ "${STATUS:-0}" -lt 300 ] && apiWritten=true || apiWritten=false
```

- If `$apiWritten` is `$true`: dispatch obsidian-writer with `session_api_written: true`
  (obsidian-writer will skip capture file creation and only append the daily note)
- If `$apiWritten` is `$false`: dispatch obsidian-writer normally

### 3b. Dispatch obsidian-writer

Invoke the **obsidian-writer** agent with:

- `write_mode`: `capture`
- `vault_path`: value of `OBSIDIAN_VAULT_PATH`
- `projects_folder`: value of `OBSIDIAN_PROJECTS_FOLDER` (empty string if unset)
- `title`: user's title
- `body`: user's body text
- `project`: basename of current working directory
- `timestamp`: current datetime in `YYYY-MM-DDThh:mm` format
- `session_api_written`: `true` if 3a succeeded, `false` otherwise

## Step 4 — Confirm

Report the file path and write method. Example:

> "Captured to `Claude/captures/2026-05-14-1430.md` (via REST API)"

or:

> "Captured to `Claude/captures/2026-05-14-1430.md` (filesystem)"

## Gotchas

- Capture files always go to `Claude/captures/` — they are not project-scoped.
- If `OBSIDIAN_REST_API_KEY` is missing: skip step 3a entirely and dispatch
  obsidian-writer with `session_api_written: false`.
- The daily note append is always handled by obsidian-writer (filesystem).
- If obsidian-writer reports the vault directory doesn't exist, tell the user
  to verify the path in `~/.claude/settings.json`.
