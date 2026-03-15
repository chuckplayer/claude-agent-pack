$PackDir = Split-Path $PSScriptRoot -Parent

$pass = 0
$fail = 0

function HasField {
    param([string[]]$Content, [string]$Field)
    return ($Content | Where-Object { $_ -match "^${Field}\s*:" }).Count -gt 0
}

Write-Host "Claude Agent Pack -- Agent & Skill Linter"
Write-Host ""

Write-Host "-- Agents"
$agentFiles = Get-ChildItem "$PackDir\agents\*.md"
foreach ($f in $agentFiles) {
    $name    = $f.BaseName
    $content = Get-Content $f.FullName
    $errors  = 0
    Write-Host "  $name"

    # Frontmatter must open with ---
    if ($content[0] -ne '---') {
        Write-Host "    MISSING: frontmatter opening ---"
        $errors++
    }

    foreach ($field in @("name", "description", "tools", "model")) {
        if (-not (HasField $content $field)) {
            Write-Host "    MISSING field: $field"
            $errors++
        }
    }

    # Must have body content after the closing ---
    $fmCount   = 0
    $bodyLines = 0
    foreach ($line in $content) {
        if ($line -eq '---') { $fmCount++; continue }
        if ($fmCount -ge 2 -and $line.Trim() -ne '') { $bodyLines++ }
    }
    if ($bodyLines -eq 0) {
        Write-Host "    MISSING: agent instructions body (no content after frontmatter)"
        $errors++
    }

    if ($errors -eq 0) {
        Write-Host "    [ok]"
        $pass++
    } else {
        $fail++
    }
}

Write-Host ""
Write-Host "-- Skills"
$skillDirs = Get-ChildItem "$PackDir\skills" -Directory
foreach ($d in $skillDirs) {
    $name      = $d.Name
    $skillFile = "$PackDir\skills\$name\SKILL.md"
    $errors    = 0
    Write-Host "  $name"

    if (-not (Test-Path $skillFile)) {
        Write-Host "    MISSING: SKILL.md"
        $fail++
        continue
    }

    $lines = Get-Content $skillFile
    if ($lines.Count -lt 5) {
        Write-Host "    WARNING: SKILL.md is very short ($($lines.Count) lines)"
        $errors++
    }

    if ($errors -eq 0) {
        Write-Host "    [ok]"
        $pass++
    } else {
        $fail++
    }
}

Write-Host ""
Write-Host "----"
Write-Host "  $pass passed, $fail failed"
Write-Host ""

if ($fail -gt 0) { exit 1 }
