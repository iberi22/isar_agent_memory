#Requires -Version 5.1
<#
.SYNOPSIS
  Shortcut: list all features with CLAIMED vs SUGGESTED % (verification queue).

.EXAMPLE
  pwsh .gitcore/scripts/feature-diff-claimed.ps1
  pwsh .gitcore/scripts/feature-diff-claimed.ps1 -Below 100 -WritePack
  pwsh .gitcore/scripts/feature-diff-claimed.ps1 -ReqId REQ-003
#>
param(
    [string]$ProjectRoot = "",
    [string]$ReqId = "",
    [double]$Below = 101,
    [string]$Status = "",
    [switch]$WritePack,
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$fv = Join-Path $here "feature-verify.ps1"
if (-not (Test-Path $fv)) {
    Write-Error "feature-verify.ps1 not found next to this script"
}

if ($Json) {
    $p = @{
        All         = $true
        DiffClaimed = $true
        Json        = $true
        NoWrite     = $true
    }
    if ($ProjectRoot) { $p.ProjectRoot = $ProjectRoot }
    if ($ReqId) { $p.ReqId = $ReqId }
    if ($Below -ne 101) { $p.Below = $Below }
    if ($Status) { $p.Status = $Status }
    & $fv @p
    exit $LASTEXITCODE
}

$p = @{
    List        = $true
    DiffClaimed = $true
}
if ($ProjectRoot) { $p.ProjectRoot = $ProjectRoot }
if ($ReqId) { $p.ReqId = $ReqId }
if ($Below -ne 101) { $p.Below = $Below }
if ($Status) { $p.Status = $Status }
if ($WritePack) { $p.WritePack = $true }

& $fv @p
exit $LASTEXITCODE
