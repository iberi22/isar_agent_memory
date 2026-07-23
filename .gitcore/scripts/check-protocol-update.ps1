#Requires -Version 5.1
<#
.SYNOPSIS
  Check whether GitCore protocol needs updating (local source preferred).

.PARAMETER Update
  Apply update via gitcore-update.ps1

.PARAMETER Force
  Force re-copy even if versions match

.PARAMETER Source
  Override GitCore home
#>
param(
    [switch]$Update,
    [switch]$Force,
    [string]$Source = ""
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "lib\GitCore.Common.ps1")

$project = Get-ProjectRoot
$gcSource = Get-GitCoreSource -Override $Source

$current = "0.0.0"
$vf = Join-Path $project ".git-core-protocol-version"
if (Test-Path $vf) { $current = (Get-Content $vf -Raw).Trim() }

Write-GcLog "Project: $project"
Write-GcLog "Current protocol: $current"

if (-not $gcSource) {
    Write-GcLog "No local GitCore source found. Set GITCORE_HOME or use monorepo layout." "WARN"
    # Try remote version only
    try {
        $remote = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/iberi22/GitCore/main/.git-core-protocol-version" -UseBasicParsing -TimeoutSec 15).Content.Trim()
        Write-GcLog "Remote GitCore version: $remote"
        if ((Compare-SemVer $current $remote) -ge 0 -and -not $Force) {
            Write-GcLog "Up to date vs remote (no local source to apply)." "OK"
            exit 0
        }
        Write-GcLog "Update available vs remote: $current -> $remote" "WARN"
        if ($Update -or $Force) {
            Write-GcLog "Cannot apply from remote without local GitCore clone. Clone GitCore and set GITCORE_HOME." "ERR"
            exit 2
        }
        exit 1
    } catch {
        Write-GcLog "Could not reach remote: $_" "ERR"
        exit 2
    }
}

$latest = Get-ProtocolVersionFrom $gcSource
Write-GcLog "Source: $gcSource"
Write-GcLog "Latest (local): $latest"

if ((Compare-SemVer $current $latest) -ge 0 -and -not $Force) {
    Write-GcLog "GitCore protocol is up to date." "OK"
    exit 0
}

Write-GcLog "Update available: $current -> $latest" "WARN"

if (-not $Update -and -not $Force) {
    Write-Host "Run: pwsh .gitcore/scripts/check-protocol-update.ps1 -Update"
    Write-Host " Or: pwsh .gitcore/scripts/gitcore-update.ps1 -Force"
    exit 1
}

$updater = Join-Path $here "gitcore-update.ps1"
& $updater -ProjectRoot $project -Source $gcSource -Force:$Force
exit $LASTEXITCODE
