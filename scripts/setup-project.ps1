param(
    [string]$Target = (Get-Location).Path
)

$PackDir = Split-Path $PSScriptRoot -Parent

if (-not (Test-Path $Target)) {
    Write-Host "ERROR: Target directory not found: $Target"
    exit 1
}

Write-Host "Claude Agent Pack -- Project Setup"
Write-Host "Target: $Target"
Write-Host ""

# CLAUDE.md
Copy-Item "$PackDir\CLAUDE.md" "$Target\CLAUDE.md" -Force
Write-Host "  [ok] CLAUDE.md"

# docs/
$docsDir = Join-Path $Target "docs"
New-Item -ItemType Directory -Path $docsDir -Force | Out-Null

$conventionsPath = Join-Path $docsDir "CONVENTIONS.md"
if (-not (Test-Path $conventionsPath)) {
    Copy-Item "$PackDir\docs\CONVENTIONS.template.md" $conventionsPath -Force
    Write-Host "  [ok] docs/CONVENTIONS.md  (from template)"
} else {
    Write-Host "  [--] docs/CONVENTIONS.md already exists, skipped"
}

Copy-Item "$PackDir\docs\MEMORY-WRITING.md" "$docsDir\MEMORY-WRITING.md" -Force
Write-Host "  [ok] docs/MEMORY-WRITING.md"

# memory/
foreach ($subdir in @("decisions", "architecture", "context", "known-issues")) {
    $path = Join-Path $Target "memory\$subdir"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    New-Item -ItemType File -Path "$path\.gitkeep" -Force | Out-Null
    Write-Host "  [ok] memory/$subdir/"
}

Write-Host ""
Write-Host "Done. Suggested next steps:"
Write-Host "  1. Edit docs/CONVENTIONS.md to match your project's conventions."
Write-Host "  2. Commit: git add CLAUDE.md docs/ memory/ && git commit -m 'chore: add Claude Agent Pack scaffolding'"
Write-Host "  3. In Claude Code, run /onboard to get oriented."
