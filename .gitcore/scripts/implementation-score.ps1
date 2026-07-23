#Requires -Version 5.1
<#
.SYNOPSIS
  Report implementation / protocol completion % for a SWAL project.

.DESCRIPTION
  Combines:
  - Protocol compliance (GitCore 3.8 files)
  - SRC + SRS completeness
  - features.json product progress
  - SWAL private-era checks (workflows disabled, version)

.PARAMETER ProjectRoot
  Project path (default: current or detected)

.PARAMETER Json
  Emit JSON only

.PARAMETER OutFile
  Write JSON report to path (default: .gitcore/implementation-score.json)
#>
param(
    [string]$ProjectRoot = "",
    [switch]$Json,
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "lib\GitCore.Common.ps1")

$root = if ($ProjectRoot) { (Resolve-Path $ProjectRoot).Path } else { Get-ProjectRoot }
Set-Location $root

$src = Test-SrcCompleteness $root
$srs = Test-SrsCompleteness $root
$feat = Get-FeaturesProgress $root

$protocolScore = 0
$protocolMax = 100
$protocolNotes = @()

$verFile = Join-Path $root ".git-core-protocol-version"
$ver = if (Test-Path $verFile) { (Get-Content $verFile -Raw).Trim() } else { "0.0.0" }
if ((Compare-SemVer $ver "3.8.0") -ge 0) { $protocolScore += 25 } else { $protocolNotes += "protocol version < 3.8.0 ($ver)" }

if (Test-Path (Join-Path $root "AGENTS.md")) { $protocolScore += 15 } else { $protocolNotes += "AGENTS.md missing" }
if (Test-Path (Join-Path $root ".gitcore\ARCHITECTURE.md")) { $protocolScore += 15 } else { $protocolNotes += "ARCHITECTURE.md missing" }
if (Test-Path (Join-Path $root ".gitcore\planning\PLANNING.md")) { $protocolScore += 10 } else { $protocolNotes += "PLANNING.md missing" }
if (Test-Path (Join-Path $root ".gitcore\planning\TASK.md")) { $protocolScore += 10 } else { $protocolNotes += "TASK.md missing" }
if (Test-Path (Join-Path $root ".gitcore\features.json")) { $protocolScore += 10 } else { $protocolNotes += "features.json missing" }
if (Test-Path (Join-Path $root ".gitcore\scripts\implementation-score.ps1")) { $protocolScore += 5 } else { $protocolNotes += "consumer scripts not installed" }
if (Test-Path (Join-Path $root ".gitcore\MANIFEST.json")) { $protocolScore += 5 } else { $protocolNotes += "MANIFEST.json missing" }
$hasEra = Test-Path (Join-Path $root ".gitcore\docs\SWAL_PRIVATE_ERA.md")
$hasPref = Test-Path (Join-Path $root ".gitcore\PROTOCOL_REFERENCE.md")
if ($hasEra -or $hasPref) {
    $protocolScore += 5
} else { $protocolNotes += "protocol docs missing" }

# Workflows: prefer disabled
$wfActive = Join-Path $root ".github\workflows"
$wfDisabled = Join-Path $root ".github\workflows.disabled"
$ymlActive = if (Test-Path $wfActive) { @(Get-ChildItem $wfActive -Filter "*.yml" -ErrorAction SilentlyContinue).Count } else { 0 }
$swalScore = 0
$swalNotes = @()
if ($ymlActive -eq 0) { $swalScore += 40 } else { $swalNotes += "$ymlActive active workflow yml files (should be disabled)" }
if (Test-Path $wfDisabled) { $swalScore += 30 } else { $swalNotes += "workflows.disabled not present (ok if never had CI)" ; $swalScore += 15 }
if ((Compare-SemVer $ver "3.8.0") -ge 0) { $swalScore += 30 } else { $swalNotes += "not on 3.8 private era" }

# Weighted overall
# Protocol 20%, SRC 15%, SRS 20%, Features 35%, SWAL 10%
$featScore = if ($null -eq $feat.Score) { 0 } else { [double]$feat.Score }
$featWeight = if ($null -eq $feat.Score -or $feat.Count -eq 0) { 0.15 } else { 0.35 }
$protocolWeight = 0.20
$srcWeight = 0.15
$srsWeight = 0.20
$swalWeight = 0.10
# redistribute feature weight if no features
$extra = 0.35 - $featWeight
$protocolWeight += $extra * 0.4
$srcWeight += $extra * 0.3
$srsWeight += $extra * 0.3

$overall = [math]::Round(
    ($protocolScore * $protocolWeight) +
    ($src.Score * $srcWeight) +
    ($srs.Score * $srsWeight) +
    ($featScore * $featWeight) +
    ($swalScore * $swalWeight)
, 1)

$report = [ordered]@{
    project           = Split-Path $root -Leaf
    path              = $root
    generated_at      = (Get-Date).ToString("o")
    protocol_version  = $ver
    overall_pct       = $overall
    breakdown         = [ordered]@{
        protocol_pct      = $protocolScore
        src_pct           = $src.Score
        srs_pct           = $srs.Score
        features_pct      = $featScore
        features_count    = $feat.Count
        features_source   = $feat.Source
        swal_compliance   = $swalScore
    }
    weights           = [ordered]@{
        protocol = $protocolWeight
        src      = $srcWeight
        srs      = $srsWeight
        features = $featWeight
        swal     = $swalWeight
    }
    gaps              = @($protocolNotes + $src.Missing + $srs.Missing + $swalNotes | Select-Object -Unique)
    grade             = if ($overall -ge 90) { "A" } elseif ($overall -ge 75) { "B" } elseif ($overall -ge 60) { "C" } elseif ($overall -ge 40) { "D" } else { "F" }
}

$jsonText = $report | ConvertTo-Json -Depth 6
$out = if ($OutFile) { $OutFile } else { Join-Path $root ".gitcore\implementation-score.json" }
$outDir = Split-Path $out -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
Set-Content -Path $out -Value $jsonText -Encoding UTF8

if ($Json) {
    Write-Output $jsonText
} else {
    Write-Host ""
    Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Implementation score: $($report.project)" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan
    $ovColor = "Red"
    if ($overall -ge 75) { $ovColor = "Green" }
    elseif ($overall -ge 50) { $ovColor = "Yellow" }
    Write-Host ("  Overall: {0}%  Grade {1}" -f $overall, $report.grade) -ForegroundColor $ovColor
    Write-Host ("  Protocol:   {0}%" -f $protocolScore)
    Write-Host ("  SRC:        {0}%" -f $src.Score)
    Write-Host ("  SRS:        {0}%" -f $srs.Score)
    Write-Host ("  Features:   {0}% ({1} items, {2})" -f $featScore, $feat.Count, $feat.Source)
    Write-Host ("  SWAL era:   {0}%" -f $swalScore)
    Write-Host ("  Protocol v: {0}" -f $ver)
    if ($report.gaps.Count -gt 0) {
        Write-Host "  Gaps:" -ForegroundColor Yellow
        $report.gaps | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
    }
    Write-Host "  Report: $out" -ForegroundColor DarkGray
    Write-Host ""
}

exit 0
