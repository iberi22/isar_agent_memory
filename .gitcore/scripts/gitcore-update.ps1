#Requires -Version 5.1
<#
.SYNOPSIS
  Update this project with latest GitCore consumer package (.gitcore managed files + scripts).

.DESCRIPTION
  Source of truth order:
    1. -Source path
    2. $env:GITCORE_HOME
    3. Walk parents for monorepo/GitCore
    4. Known local paths

  Never overwrites: ARCHITECTURE.md, planning/*, features.json (only patches protocol field),
  srs/, harness/, features.details/

.PARAMETER ProjectRoot
  Target project (default: detect)

.PARAMETER Source
  GitCore directory

.PARAMETER Force
  Re-copy managed files even if version matches

.PARAMETER SkipScore
  Do not run implementation-score after update
#>
param(
    [string]$ProjectRoot = "",
    [string]$Source = "",
    [switch]$Force,
    [switch]$SkipScore
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
# When run from package before copy, lib may be beside us
$lib = Join-Path $here "lib\GitCore.Common.ps1"
if (-not (Test-Path $lib)) {
    # bootstrap from Source
    if ($Source) {
        $lib = Join-Path $Source "package\consumer\scripts\lib\GitCore.Common.ps1"
    }
}
if (Test-Path $lib) { . $lib } else {
    function Write-GcLog($m, $l = "INFO") { Write-Host "[$l] $m" }
    function Get-GitCoreSource($Override = "") { if ($Override) { return $Override }; return $env:GITCORE_HOME }
    function Get-ProjectRoot { (Get-Location).Path }
    function Get-ProtocolVersionFrom($Path) {
        $p = Join-Path $Path "VERSION"; if (Test-Path $p) { return (Get-Content $p -Raw).Trim() }; "0.0.0"
    }
    function Compare-SemVer($A, $B) { return 0 }
}

$root = if ($ProjectRoot) { (Resolve-Path $ProjectRoot).Path } else { Get-ProjectRoot }
$gcSource = Get-GitCoreSource -Override $Source
if (-not $gcSource) {
    Write-GcLog "GitCore source not found. Set GITCORE_HOME to E:\proyectosSWAL\GitCore" "ERR"
    exit 2
}

$consumer = Join-Path $gcSource "package\consumer"
if (-not (Test-Path $consumer)) {
    Write-GcLog "Consumer package missing at $consumer — create package/consumer in GitCore" "ERR"
    exit 2
}

$latest = Get-ProtocolVersionFrom $gcSource
$current = "0.0.0"
$vf = Join-Path $root ".git-core-protocol-version"
if (Test-Path $vf) { $current = (Get-Content $vf -Raw).Trim() }

Write-GcLog "Update $(Split-Path $root -Leaf): $current -> $latest (source=$gcSource)"

if ((Compare-SemVer $current $latest) -ge 0 -and -not $Force) {
    Write-GcLog "Already on $current — use -Force to re-sync managed files" "OK"
    if (-not $SkipScore -and (Test-Path (Join-Path $here "implementation-score.ps1"))) {
        & (Join-Path $here "implementation-score.ps1") -ProjectRoot $root | Out-Null
    }
    exit 0
}

# Ensure dirs
$gitcoreDir = Join-Path $root ".gitcore"
$scriptsDir = Join-Path $gitcoreDir "scripts"
$docsDir = Join-Path $gitcoreDir "docs"
New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null
New-Item -ItemType Directory -Force -Path $docsDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $scriptsDir "lib") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $gitcoreDir "planning") | Out-Null

# Copy MANIFEST + protocol docs
Copy-Item (Join-Path $consumer "MANIFEST.json") (Join-Path $gitcoreDir "MANIFEST.json") -Force

$protoRef = Join-Path $gcSource "PROTOCOL_REFERENCE.md"
if (Test-Path $protoRef) {
    Copy-Item $protoRef (Join-Path $gitcoreDir "PROTOCOL_REFERENCE.md") -Force
}
$era = Join-Path $gcSource "docs\SWAL_PRIVATE_ERA.md"
if (Test-Path $era) {
    Copy-Item $era (Join-Path $docsDir "SWAL_PRIVATE_ERA.md") -Force
}
# Prefer package consumer SWAL_GOAL (unified goal for all projects)
$goalPkg = Join-Path $consumer "docs\SWAL_GOAL.md"
$goalSrc = Join-Path $gcSource "docs\SWAL_PRIVATE_ERA.md"
if (Test-Path $goalPkg) {
    Copy-Item $goalPkg (Join-Path $docsDir "SWAL_GOAL.md") -Force
} elseif (Test-Path (Join-Path $gcSource "..\docs\SWAL\GOAL.md")) {
    Copy-Item (Join-Path $gcSource "..\docs\SWAL\GOAL.md") (Join-Path $docsDir "SWAL_GOAL.md") -Force
}
# Also copy monorepo GOAL if available (richer)
$monoGoal = Join-Path (Split-Path $gcSource -Parent) "docs\SWAL\GOAL.md"
if (Test-Path $monoGoal) {
    # Keep short consumer goal as SWAL_GOAL; full canonical also as SWAL_GOAL_FULL when monorepo
    Copy-Item $monoGoal (Join-Path $docsDir "SWAL_GOAL_CANONICAL.md") -Force
}

# Copy all consumer scripts
$srcScripts = Join-Path $consumer "scripts"
Get-ChildItem $srcScripts -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($srcScripts.Length).TrimStart('\', '/')
    $dest = Join-Path $scriptsDir $rel
    $destParent = Split-Path $dest -Parent
    if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Force -Path $destParent | Out-Null }
    Copy-Item $_.FullName $dest -Force
}

# Version stamp
Set-Content -Path $vf -Value $latest -Encoding UTF8 -NoNewline
Set-Content -Path $vf -Value $latest -Encoding UTF8

# Patch features.json protocol version if present (text-only; avoid strict-mode JSON edge cases)
$fj = Join-Path $gitcoreDir "features.json"
if (Test-Path $fj) {
    try {
        $raw = Get-Content $fj -Raw -ErrorAction Stop
        if ($raw -match '"protocol"\s*:') {
            $raw2 = $raw -replace '"protocol"\s*:\s*"[^"]*"', "`"protocol`": `"$latest`""
            Set-Content $fj $raw2 -Encoding UTF8
        }
        elseif ($raw -match '"protocol_version"\s*:') {
            $raw2 = $raw -replace '"protocol_version"\s*:\s*"[^"]*"', "`"protocol_version`": `"$latest`""
            Set-Content $fj $raw2 -Encoding UTF8
        }
        else {
            $raw2 = $raw -replace '^\s*\{', "{`n  `"protocol`": `"$latest`","
            Set-Content $fj $raw2 -Encoding UTF8
        }
    } catch {
        Write-GcLog "features.json patch skipped: $_" "WARN"
    }
}

# Bootstrap missing critical files only
if (-not (Test-Path (Join-Path $gitcoreDir "ARCHITECTURE.md"))) {
    Set-Content (Join-Path $gitcoreDir "ARCHITECTURE.md") @"
# Architecture

**GitCore:** $latest

## Non-negotiables
1. Protocol compliance (SRC + SRS)
2. Private repo; GH Actions disabled by default
3. Pro = SWAL node (not Stripe)
4. Xavier HTTP/MCP for agentic memory
"@ -Encoding UTF8
}
if (-not (Test-Path (Join-Path $gitcoreDir "planning\PLANNING.md"))) {
    Set-Content (Join-Path $gitcoreDir "planning\PLANNING.md") "# PLANNING`n`n**Protocol:** $latest`n" -Encoding UTF8
}
if (-not (Test-Path (Join-Path $gitcoreDir "planning\TASK.md"))) {
    Set-Content (Join-Path $gitcoreDir "planning\TASK.md") "# TASK`n`n- [ ] Run implementation-score.ps1`n- [ ] Fill domain SRS`n" -Encoding UTF8
}
if (-not (Test-Path (Join-Path $gitcoreDir "features.json"))) {
    Set-Content (Join-Path $gitcoreDir "features.json") "{`"protocol`":`"$latest`",`"features`":[]}" -Encoding UTF8
}
if (-not (Test-Path (Join-Path $gitcoreDir "AGENT_INDEX.md"))) {
    Set-Content (Join-Path $gitcoreDir "AGENT_INDEX.md") "# Agent index`n`nFollow AGENTS.md.`n" -Encoding UTF8
}

Write-GcLog "Managed files synced to .gitcore/ for $(Split-Path $root -Leaf)" "OK"

if (-not $SkipScore) {
    $scoreScript = Join-Path $scriptsDir "implementation-score.ps1"
    if (Test-Path $scoreScript) {
        try {
            & $scoreScript -ProjectRoot $root
        } catch {
            Write-GcLog "implementation-score failed (non-fatal): $_" "WARN"
        }
    }
}

exit 0
