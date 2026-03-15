param(
    [Parameter(Mandatory = $true)]
    [string]$Pattern,

    [string]$MemoryDir = (Join-Path (Get-Location).Path "memory")
)

if (-not (Test-Path $MemoryDir)) {
    Write-Host "ERROR: Memory directory not found: $MemoryDir"
    Write-Host "Run scripts\setup-project.ps1 to scaffold the memory\ structure."
    exit 1
}

$found = 0
$files = Get-ChildItem -Path $MemoryDir -Recurse -Filter "*.md" | Sort-Object FullName

foreach ($file in $files) {
    $content = Get-Content $file.FullName -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Skip superseded/archived files
    $statusLine = $content | Select-String -Pattern '^\*\*Status:\*\*' | Select-Object -First 1
    if ($statusLine) {
        $status = ($statusLine.Line -replace '^\*\*Status:\*\*\s*', '').Trim().ToLower()
        if ($status -eq 'superseded' -or $status -eq 'archived') {
            continue
        }
    }

    # Search for pattern (case-insensitive)
    $matches = $content | Select-String -Pattern $Pattern -CaseSensitive:$false
    if ($matches) {
        Write-Host "=== $($file.FullName)"
        foreach ($m in ($matches | Select-Object -First 10)) {
            Write-Host "$($m.LineNumber): $($m.Line)"
        }
        Write-Host ""
        $found++
    }
}

if ($found -eq 0) {
    Write-Host "No results for: $Pattern"
    exit 1
}

Write-Host "$found file(s) matched."
