# Claude Code Agent Pack - Windows Uninstaller
#
# If blocked by execution policy, run this once in PowerShell:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Then re-run this script.

$ErrorActionPreference = "Stop"

$claudeDir = "$env:USERPROFILE\.claude"
$agentsDir = "$claudeDir\agents"
$skillsDir = "$claudeDir\skills"

$packAgentFiles = @()
if (Test-Path $agentsDir) {
    $packAgentFiles = Get-ChildItem -Path "$PSScriptRoot\agents\" -Filter "*.md"
}

$packSkillDirs = @()
if (Test-Path $skillsDir) {
    $packSkillDirs = Get-ChildItem -Path "$PSScriptRoot\skills\" -Directory
}

$toRemoveAgents = @()
$toRemoveSkills = @()

foreach ($file in $packAgentFiles) {
    $target = "$agentsDir\$($file.Name)"
    if (Test-Path $target) { $toRemoveAgents += $target }
}

foreach ($dir in $packSkillDirs) {
    $target = "$skillsDir\$($dir.Name)"
    if (Test-Path $target) { $toRemoveSkills += $target }
}

if ($toRemoveAgents.Count -eq 0 -and $toRemoveSkills.Count -eq 0) {
    Write-Host "Nothing to remove -- no matching agents or skills found." -ForegroundColor Yellow
    exit 0
}

Write-Host "The following will be removed:" -ForegroundColor Cyan
Write-Host ""
foreach ($path in $toRemoveAgents) { Write-Host "  agent: $(Split-Path $path -Leaf)" -ForegroundColor Yellow }
foreach ($path in $toRemoveSkills) { Write-Host "  skill: $(Split-Path $path -Leaf)" -ForegroundColor Yellow }

Write-Host ""
$response = Read-Host "Remove these? (Y/N)"

if ($response -ne 'Y' -and $response -ne 'y') {
    Write-Host "Cancelled." -ForegroundColor Gray
    exit 0
}

Write-Host ""
foreach ($path in $toRemoveAgents) {
    Remove-Item -Path $path -Force
    Write-Host "  Removed agent: $(Split-Path $path -Leaf)" -ForegroundColor Yellow
}
foreach ($path in $toRemoveSkills) {
    Remove-Item -Path $path -Recurse -Force
    Write-Host "  Removed skill: $(Split-Path $path -Leaf)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "$($toRemoveAgents.Count) agent(s) and $($toRemoveSkills.Count) skill(s) removed." -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: project-level memory/ directories are not removed --"
Write-Host "those live in your repositories and are managed like any other project file."
