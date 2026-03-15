param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("decisions", "architecture", "context", "known-issues")]
    [string]$Subdir,

    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [string]$MemoryDir = (Join-Path (Get-Location).Path "memory")
)

$typeMap = @{
    "decisions"    = "decision"
    "architecture" = "finding"
    "context"      = "constraint"
    "known-issues" = "finding"
}

# Validate slug (kebab-case)
if ($Slug -notmatch '^[a-z0-9][a-z0-9-]*$') {
    Write-Host "ERROR: Slug must be lowercase kebab-case (letters, numbers, hyphens only)."
    Write-Host "  Got: $Slug"
    exit 1
}

$type     = $typeMap[$Subdir]
$date     = Get-Date -Format "yyyy-MM-dd"
$filename = "$date-$Slug.md"
$filepath = Join-Path $MemoryDir "$Subdir\$filename"

if (Test-Path $filepath) {
    Write-Host "ERROR: File already exists: $filepath"
    exit 1
}

New-Item -ItemType Directory -Path (Join-Path $MemoryDir $Subdir) -Force | Out-Null

$template = @"
**Date:** $date
**Type:** $type
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** n/a

## Summary

<!-- One paragraph describing this $type. -->

## Context

<!-- Why this situation arose or what drove this decision. -->

## Details

<!-- The specifics: what was decided, found, or constrained. -->

## Consequences

<!-- What this means for future work. What to watch out for. -->
"@

Set-Content -Path $filepath -Value $template -Encoding UTF8

Write-Host "Created: $filepath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Fill in the sections above."
Write-Host "  2. Add a pointer to memory\MEMORY.md:"
Write-Host "     | [$filename](memory/$Subdir/$filename) | <one-line description> |"
