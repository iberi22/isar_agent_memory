#Requires -Version 5.1
<#
.SYNOPSIS
  Ensure SRS/SRC structure exists (delegates to monorepo GitCore script when available).
#>
param(
    [string]$ProjectRoot = "",
    [switch]$ForceTemplates
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "lib\GitCore.Common.ps1")

$root = if ($ProjectRoot) { (Resolve-Path $ProjectRoot).Path } else { Get-ProjectRoot }
$gcSource = Get-GitCoreSource

if ($gcSource) {
    $script = Join-Path $gcSource "scripts\swal-ensure-srs-src.ps1"
    if (Test-Path $script) {
        & $script -Root (Split-Path $gcSource -Parent) -ForceTemplates:$ForceTemplates
        # Also ensure this project specifically if full root scan skipped it
    }
}

# Local minimal ensure
$Date = Get-Date -Format "yyyy-MM-dd"
$ver = Get-ProtocolVersionFrom (if ($gcSource) { $gcSource } else { $root })
$name = Split-Path $root -Leaf

function Ensure-Min([string]$path, [string]$content) {
    if (Test-Path $path) { return }
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content $path $content -Encoding UTF8
    Write-GcLog "created $path" "OK"
}

Ensure-Min (Join-Path $root "SRC.md") "# SRC — $name`n`n**Protocol:** $ver · **Updated:** $Date`n`n## Overview`n$name`n`n## Directory structure`n`n## Build / test`n`n## Cross-references`n- docs/SRS/`n- AGENTS.md`n"
Ensure-Min (Join-Path $root "docs\SRS\index.md") "# SRS — $name`n`nSee REQUIREMENTS.md and ARCHITECTURE.md.`n"
Ensure-Min (Join-Path $root "docs\SRS\REQUIREMENTS.md") "# REQUIREMENTS — $name`n`n## REQ-001: GitCore compliance`n- Files: AGENTS.md, SRC.md, docs/SRS/`n"
Ensure-Min (Join-Path $root "docs\SRS\ARCHITECTURE.md") "# Architecture map — $name`n`nSee monorepo docs/SWAL/README.md for ecosystem layers.`n"

Write-GcLog "ensure-srs-src done for $name" "OK"
