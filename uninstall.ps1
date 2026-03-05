# Claude Code Agent Pack - Windows Uninstaller
#
# If blocked by execution policy, run this once in PowerShell:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Then re-run this script.

$ErrorActionPreference = "Stop"

$claudeDir = "$env:USERPROFILE\.claude"
$agentsDir = "$claudeDir\agents"

if (-not (Test-Path $agentsDir)) {
    Write-Host "No agents directory found at $agentsDir -- nothing to remove." -ForegroundColor Yellow
    exit 0
}

$packAgentFiles = Get-ChildItem -Path "$PSScriptRoot\agents\" -Filter "*.md"

Write-Host "The following agents will be removed from $agentsDir :" -ForegroundColor Cyan
Write-Host ""

$toRemove = @()
foreach ($file in $packAgentFiles) {
    $target = "$agentsDir\$($file.Name)"
    if (Test-Path $target) {
        Write-Host "  $($file.Name)" -ForegroundColor Yellow
        $toRemove += $target
    }
}

if ($toRemove.Count -eq 0) {
    Write-Host "  (no matching agent files found)" -ForegroundColor Gray
    exit 0
}

Write-Host ""
$response = Read-Host "Remove these agents? (Y/N)"

if ($response -ne 'Y' -and $response -ne 'y') {
    Write-Host "Cancelled." -ForegroundColor Gray
    exit 0
}

Write-Host ""
foreach ($path in $toRemove) {
    Remove-Item -Path $path -Force
    Write-Host "  Removed: $(Split-Path $path -Leaf)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "$($toRemove.Count) agent(s) removed." -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: project-level memory/ directories are not removed --"
Write-Host "those live in your repositories and are managed like any other project file."
