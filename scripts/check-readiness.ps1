param(
    [string]$ProjectDir = (Get-Location).Path
)

$PackDir = Split-Path $PSScriptRoot -Parent
$pass = 0
$fail = 0

function Check {
    param([string]$Label, [bool]$Ok, [string]$Detail = "")
    if ($Ok) {
        Write-Host "  [ok] $Label"
        $script:pass++
    } else {
        $msg = "  [!!] $Label"
        if ($Detail) { $msg += "  -- $Detail" }
        Write-Host $msg
        $script:fail++
    }
}

Write-Host "Claude Agent Pack -- Readiness Check"
Write-Host ""

# Claude Code
Write-Host "-- Claude Code"
Check "~/.claude directory exists" (Test-Path "$HOME\.claude") `
    "Install Claude Code first: https://claude.ai/download"

# Agents
Write-Host ""
Write-Host "-- Agents"
$agentFiles = Get-ChildItem "$PackDir\agents\*.md"
$missingAgents = @()
foreach ($f in $agentFiles) {
    if (-not (Test-Path "$HOME\.claude\agents\$($f.Name)")) {
        $missingAgents += $f.BaseName
    }
}
if ($missingAgents.Count -eq 0) {
    Check "All $($agentFiles.Count) agents installed" $true
} else {
    $installed = $agentFiles.Count - $missingAgents.Count
    Check "Agents installed ($installed/$($agentFiles.Count))" $false `
        "Missing: $($missingAgents -join ', ')  -- run .\install.ps1"
}

# Skills
Write-Host ""
Write-Host "-- Skills"
$skillDirs = Get-ChildItem "$PackDir\skills" -Directory
$missingSkills = @()
foreach ($d in $skillDirs) {
    if (-not (Test-Path "$HOME\.claude\skills\$($d.Name)\SKILL.md")) {
        $missingSkills += $d.Name
    }
}
if ($missingSkills.Count -eq 0) {
    Check "All $($skillDirs.Count) skills installed" $true
} else {
    $installed = $skillDirs.Count - $missingSkills.Count
    Check "Skills installed ($installed/$($skillDirs.Count))" $false `
        "Missing: $($missingSkills -join ', ')  -- run .\install.ps1"
}

# Project scaffolding
Write-Host ""
Write-Host "-- Project ($ProjectDir)"
Check "CLAUDE.md"               (Test-Path "$ProjectDir\CLAUDE.md")              "run scripts\setup-project.ps1"
Check "docs/CONVENTIONS.md"     (Test-Path "$ProjectDir\docs\CONVENTIONS.md")    "run scripts\setup-project.ps1"
Check "docs/MEMORY-WRITING.md"  (Test-Path "$ProjectDir\docs\MEMORY-WRITING.md") "run scripts\setup-project.ps1"
foreach ($subdir in @("decisions", "architecture", "context", "known-issues")) {
    Check "memory/$subdir/" (Test-Path "$ProjectDir\memory\$subdir") "run scripts\setup-project.ps1"
}

Write-Host ""
Write-Host "----"
Write-Host "  $pass passed, $fail failed"
Write-Host ""

if ($fail -gt 0) { exit 1 }
