#Requires -Version 5.1
<#
.SYNOPSIS
  Fast GitCore protocol health check for a project.
#>
param(
    [string]$ProjectRoot = "",
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$here = $PSScriptRoot
. (Join-Path $here "lib\GitCore.Common.ps1")

$root = if ($ProjectRoot) { (Resolve-Path $ProjectRoot).Path } else { Get-ProjectRoot }
$fail = 0
$checks = @()

function Add-Check($name, $ok, $detail = "") {
    $script:checks += [pscustomobject]@{ Name = $name; Ok = [bool]$ok; Detail = $detail }
    if (-not $ok) { $script:fail++ }
}

$ver = if (Test-Path (Join-Path $root ".git-core-protocol-version")) {
    (Get-Content (Join-Path $root ".git-core-protocol-version") -Raw).Trim()
} else { "0.0.0" }

Add-Check "protocol_version_3.8+" ((Compare-SemVer $ver "3.8.0") -ge 0) $ver
Add-Check "AGENTS.md" (Test-Path (Join-Path $root "AGENTS.md"))
Add-Check "SRC.md" (Test-Path (Join-Path $root "SRC.md"))
Add-Check "docs/SRS/index.md" (Test-Path (Join-Path $root "docs\SRS\index.md"))
Add-Check "docs/SRS/REQUIREMENTS.md" (Test-Path (Join-Path $root "docs\SRS\REQUIREMENTS.md"))
Add-Check "docs/SRS/ARCHITECTURE.md" (Test-Path (Join-Path $root "docs\SRS\ARCHITECTURE.md"))
Add-Check ".gitcore/ARCHITECTURE.md" (Test-Path (Join-Path $root ".gitcore\ARCHITECTURE.md"))
Add-Check ".gitcore/planning/PLANNING.md" (Test-Path (Join-Path $root ".gitcore\planning\PLANNING.md"))
Add-Check ".gitcore/planning/TASK.md" (Test-Path (Join-Path $root ".gitcore\planning\TASK.md"))
Add-Check ".gitcore/scripts/gitcore-update.ps1" (Test-Path (Join-Path $root ".gitcore\scripts\gitcore-update.ps1"))
Add-Check ".gitcore/scripts/implementation-score.ps1" (Test-Path (Join-Path $root ".gitcore\scripts\implementation-score.ps1"))

$yml = 0
if (Test-Path (Join-Path $root ".github\workflows")) {
    $yml = @(Get-ChildItem (Join-Path $root ".github\workflows") -Filter "*.yml" -EA SilentlyContinue).Count
}
Add-Check "no_active_workflow_yml" ($yml -eq 0) "active yml=$yml"

if (-not $Quiet) {
    Write-Host "Protocol health: $(Split-Path $root -Leaf) (v$ver)" -ForegroundColor Cyan
    foreach ($c in $checks) {
        $mark = if ($c.Ok) { "OK" } else { "FAIL" }
        $color = if ($c.Ok) { "Green" } else { "Red" }
        Write-Host ("  [{0}] {1} {2}" -f $mark, $c.Name, $c.Detail) -ForegroundColor $color
    }
    Write-Host ("Result: {0} failed / {1} checks" -f $fail, $checks.Count) -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
}

exit $fail
