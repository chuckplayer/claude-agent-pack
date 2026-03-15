$PackDir = Split-Path $PSScriptRoot -Parent

$upToDate    = 0
$outdated    = 0
$notInstalled = 0

Write-Host "Claude Agent Pack -- Update Check"
Write-Host ""

Write-Host "-- Agents"
$agentFiles = Get-ChildItem "$PackDir\agents\*.md"
foreach ($f in $agentFiles) {
    $installed = "$HOME\.claude\agents\$($f.Name)"
    $label = $f.BaseName

    if (-not (Test-Path $installed)) {
        Write-Host "  [--] $label  (not installed)"
        $notInstalled++
    } else {
        $srcHash = (Get-FileHash $f.FullName -Algorithm MD5).Hash
        $dstHash = (Get-FileHash $installed  -Algorithm MD5).Hash
        if ($srcHash -eq $dstHash) {
            Write-Host "  [ok] $label"
            $upToDate++
        } else {
            Write-Host "  [!!] $label  (outdated)"
            $outdated++
        }
    }
}

Write-Host ""
Write-Host "-- Skills"
$skillDirs = Get-ChildItem "$PackDir\skills" -Directory
foreach ($d in $skillDirs) {
    $src       = "$PackDir\skills\$($d.Name)\SKILL.md"
    $installed = "$HOME\.claude\skills\$($d.Name)\SKILL.md"

    if (-not (Test-Path $installed)) {
        Write-Host "  [--] $($d.Name)  (not installed)"
        $notInstalled++
    } else {
        $srcHash = (Get-FileHash $src       -Algorithm MD5).Hash
        $dstHash = (Get-FileHash $installed -Algorithm MD5).Hash
        if ($srcHash -eq $dstHash) {
            Write-Host "  [ok] $($d.Name)"
            $upToDate++
        } else {
            Write-Host "  [!!] $($d.Name)  (outdated)"
            $outdated++
        }
    }
}

Write-Host ""
Write-Host "----"
Write-Host "  $upToDate up to date, $outdated outdated, $notInstalled not installed"
Write-Host ""

if ($outdated -gt 0 -or $notInstalled -gt 0) {
    Write-Host "Run .\install.ps1 to update."
    exit 1
}
