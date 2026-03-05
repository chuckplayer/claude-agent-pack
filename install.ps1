# Claude Code Agent Pack - Windows Installer
#
# If blocked by execution policy, run this once in PowerShell:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Then re-run this script.

$ErrorActionPreference = "Stop"

$claudeDir = "$env:USERPROFILE\.claude"
if (-not (Test-Path $claudeDir)) {
    Write-Host "ERROR: Claude Code directory not found at $claudeDir" -ForegroundColor Red
    Write-Host "Install Claude Code first: https://code.claude.com" -ForegroundColor Red
    exit 1
}

$agentsDir = "$claudeDir\agents"
New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null

$version = Get-Content "$PSScriptRoot\VERSION" -Raw | ForEach-Object { $_.Trim() }
Write-Host "Claude Agent Pack v$version" -ForegroundColor Cyan
Write-Host ""

$agentFiles = Get-ChildItem -Path "$PSScriptRoot\agents\" -Filter "*.md"
foreach ($file in $agentFiles) {
    Copy-Item -Path $file.FullName -Destination "$agentsDir\$($file.Name)" -Force
    Write-Host "  Installed: $($file.BaseName)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Copy CLAUDE.md to your project root:"
Write-Host '     Copy-Item "$PSScriptRoot\CLAUDE.md" ".\CLAUDE.md"'
Write-Host ""
Write-Host "  2. Copy CONVENTIONS template:"
Write-Host '     New-Item -ItemType Directory -Force -Path ".\docs" | Out-Null'
Write-Host '     Copy-Item "$PSScriptRoot\docs\CONVENTIONS.template.md" ".\docs\CONVENTIONS.md"'
Write-Host ""
Write-Host "  3. Copy memory scaffold:"
Write-Host '     Copy-Item -Recurse -Force "$PSScriptRoot\memory" "."'
Write-Host ""
Write-Host "  4. In Claude Code, try: Use the tech-lead agent to plan this feature"
Write-Host ""
Write-Host "To verify: open Claude Code and run /agents -- your new agents should appear in the list." -ForegroundColor Cyan
