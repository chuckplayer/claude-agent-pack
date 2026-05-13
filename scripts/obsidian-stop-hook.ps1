# Obsidian auto-log Stop hook — PowerShell version for Windows
# Always exits 0 — never blocks or errors visibly.

$ErrorActionPreference = 'SilentlyContinue'

# Guard: require vault path and directory
$vault = $env:OBSIDIAN_VAULT_PATH
if (-not $vault -or -not (Test-Path $vault -PathType Container)) { exit 0 }

# Canonicalize vault path
try { $vault = [System.IO.Path]::GetFullPath($vault) } catch {}

# Determine project context
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$projectDir = $projectDir -replace '[\n\r]', ''
$projectName = Split-Path $projectDir -Leaf
$projectName = $projectName -replace '[\n\r:#{}|>`]', ''
$now = Get-Date -Format 'yyyy-MM-ddTHH:mm'
$date = Get-Date -Format 'yyyy-MM-dd'
$time = Get-Date -Format 'HH:mm'
$timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'

# Get current git HEAD
$headSha = ''
try {
    $headSha = & git -C "$projectDir" rev-parse HEAD 2>$null
} catch {}

# Guard: skip if nothing changed since last log
$lastShaFile = Join-Path $env:USERPROFILE '.claude\obsidian-last-logged-sha'
if (Test-Path $lastShaFile) {
    $lastSha = (Get-Content $lastShaFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($headSha -and $headSha -eq $lastSha) {
        $gitDirty = & git -C "$projectDir" status --short 2>$null
        if (-not $gitDirty) { exit 0 }
    }
}

# Gather git context
$branch = (& git -C "$projectDir" branch --show-current 2>$null) -join ''
if (-not $branch) { $branch = 'not a git repo' }
$branch = $branch -replace '[\n\r:#{}|>`]', ''
$recentCommits = & git -C "$projectDir" log --oneline -5 2>$null
if (-not $recentCommits) { $recentCommits = @('(none)') }
$changedFiles = @()
try {
    & git -C "$projectDir" rev-parse HEAD~1 2>$null | Out-Null
    if ($?) { $changedFiles = & git -C "$projectDir" diff --stat "HEAD~1" 2>$null }
} catch {}
$uncommitted = & git -C "$projectDir" status --short 2>$null

# Build project slug
$slug = $projectName.ToLower() -replace '[^a-z0-9]+', '-' -replace '^-|-$', ''
if ($slug.Length -gt 30) { $slug = $slug.Substring(0, 30) }

# Build file paths
$sessionFile = "Claude\sessions\${timestamp}-${slug}.md"
$dailyFile = "Claude\daily\${date}.md"
$fullSessionPath = Join-Path $vault $sessionFile
$fullDailyPath = Join-Path $vault $dailyFile

# Assert write targets are inside $vault\Claude\
$claudePrefix = Join-Path $vault 'Claude'
if (-not $fullSessionPath.StartsWith($claudePrefix) -or -not $fullDailyPath.StartsWith($claudePrefix)) { exit 0 }

# Create directories
New-Item -ItemType Directory -Force -Path (Split-Path $fullSessionPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $fullDailyPath) | Out-Null

# Build session content
$lines = @(
    '---',
    "type: claude/session",
    "project: $projectName",
    "project_dir: $projectDir",
    "date: $date",
    "ended_at: $now",
    "branch: $branch",
    "tags: [claude, session-log, auto]",
    '---',
    '',
    '## Recent commits'
)
foreach ($c in $recentCommits) { $lines += "- $c" }
$lines += ''
if ($changedFiles) {
    $lines += '## Files changed in last commit'
    $lines += $changedFiles
    $lines += ''
}
if ($uncommitted) {
    $lines += '## Uncommitted changes'
    foreach ($u in $uncommitted) { if ($u) { $lines += "- $u" } }
    $lines += ''
}
$lines += '<!-- auto-logged by Stop hook -->'

$lines | Out-File -FilePath $fullSessionPath -Encoding utf8

# Append to daily note
$slugNoExt = "${timestamp}-${slug}"
$dailyLine = "- $time **session** [[Claude/sessions/$slugNoExt]] — branch: $branch (auto)"

if (-not (Test-Path $fullDailyPath)) {
    "# $date`n`n$dailyLine" | Out-File -FilePath $fullDailyPath -Encoding utf8
} else {
    "`n$dailyLine" | Out-File -FilePath $fullDailyPath -Encoding utf8 -Append
}

# Save current SHA
if ($headSha) { $headSha | Out-File -FilePath $lastShaFile -Encoding utf8 -NoNewline }

exit 0
