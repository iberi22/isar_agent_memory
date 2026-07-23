#Requires -Version 5.1
<#
.SYNOPSIS
  Per-feature implementation verification scanner for agents (read-only).

.DESCRIPTION
  Walks features.json, reports claimed %, resolves evidence paths, emits head/tail/range
  code excerpts, links SRS REQ-*, and optionally auto-suggests % (DiffClaimed).

  Agent contract sections:
    FEATURE_START / EVIDENCE_PATHS / EXCERPTS / KEYWORD_HITS /
    SRS_LINKS / DIFF_CLAIMED / AGENT_VERIFY_CHECKLIST / AGENT_OUTPUT_REQUIRED / FEATURE_END

.PARAMETER Id
  Feature id (exact, substring, or wildcard *)

.PARAMETER ReqId
  Only features linked to this SRS requirement (e.g. REQ-003 or REQ-*)

.PARAMETER List
  Table: id | claimed | suggested | delta | verdict | evid | name

.PARAMETER ListSrs
  List parsed SRS requirements and linked feature counts

.PARAMETER DiffClaimed
  Always compute suggested_pct + verdict heuristic (auto-on with -List)

.PARAMETER LinkSrs
  Attach related REQs (default on)

.PARAMETER All / MaxFeatures / Below / Status
  Selection filters

.PARAMETER Mode / Lines / Tail / Head / StartLine / EndLine
  Excerpt controls (cat/tail/range)

.PARAMETER Keywords / UseNameKeywords
  Grep inside evidence files

.PARAMETER AgentBrief / Json / WritePack / OutDir / NoWrite
  Output controls

.EXAMPLE
  pwsh .gitcore/scripts/feature-verify.ps1 -List -DiffClaimed
  pwsh .gitcore/scripts/feature-verify.ps1 -Id SRC-FUN-001 -Tail -AgentBrief -DiffClaimed
  pwsh .gitcore/scripts/feature-verify.ps1 -ReqId REQ-004 -UseNameKeywords -WritePack
  pwsh .gitcore/scripts/feature-verify.ps1 -ListSrs
  pwsh .gitcore/scripts/feature-verify.ps1 -Below 95 -MaxFeatures 5 -DiffClaimed -WritePack
#>
param(
    [string]$ProjectRoot = "",
    [string]$Id = "",
    [string]$ReqId = "",
    [switch]$List,
    [switch]$ListSrs,
    [switch]$DiffClaimed,
    [switch]$LinkSrs = $true,
    [switch]$All,
    [int]$MaxFeatures = 15,
    [double]$Below = 101,
    [string]$Status = "",
    [ValidateSet("head", "tail", "range", "full")]
    [string]$Mode = "head",
    [int]$Lines = 35,
    [switch]$Tail,
    [switch]$Head,
    [int]$StartLine = 1,
    [int]$EndLine = 0,
    [string[]]$Keywords = @(),
    [switch]$UseNameKeywords,
    [int]$MaxChars = 10000,
    [int]$MaxFilesPerFeature = 6,
    [switch]$Json,
    [switch]$WritePack,
    [string]$OutDir = "",
    [switch]$AgentBrief,
    [switch]$NoWrite
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "lib\GitCore.Common.ps1")

if ($Tail) { $Mode = "tail" }
if ($Head) { $Mode = "head" }
if ($List) { $DiffClaimed = $true }

$root = if ($ProjectRoot) { (Resolve-Path $ProjectRoot).Path } else { Get-ProjectRoot }
Set-Location $root

$pack = Get-ProjectFeatures $root
$srsPack = Get-SrsRequirements $root
$allReqs = @($srsPack.Requirements)

if ($ListSrs) {
    Write-Host ""
    Write-Host "SRS REQUIREMENTS  path=$($srsPack.Path)  count=$($allReqs.Count)" -ForegroundColor Cyan
    if ($srsPack.Error) { Write-Host "  WARN: $($srsPack.Error)" -ForegroundColor Yellow }
    Write-Host ("{0,-12} {1,5} {2,-12} {3}" -f "REQ", "FILES", "ESTADO", "TITLE")
    Write-Host ("-" * 88)
    $featPack = $pack
    foreach ($req in $allReqs) {
        $linkCount = 0
        if ($featPack.Features) {
            foreach ($f in $featPack.Features) {
                $fid = if ($f.id) { $f.id } else { $f.name }
                $links = Get-FeatureLinkedReqs -Feature $f -FeatureId $fid -Requirements @($req)
                if ($links.Count -gt 0) { $linkCount++ }
            }
        }
        Write-Host ("{0,-12} {1,5} {2,-12} {3}" -f $req.Id, $req.Files.Count, $req.Estado, $req.Title)
        if ($req.Files.Count -gt 0) {
            Write-Host ("             files: {0}" -f ($req.Files -join ", ")) -ForegroundColor DarkGray
        }
        Write-Host ("             linked_features≈{0}" -f $linkCount) -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "Tip: pwsh .gitcore/scripts/feature-verify.ps1 -ReqId REQ-003 -DiffClaimed -WritePack"
    exit 0
}

if ($pack.Error -and -not $pack.Path) {
    Write-GcLog "No features.json under $root" "ERR"
    exit 2
}
if ($pack.Error) {
    Write-GcLog "features parse error: $($pack.Error)" "ERR"
    exit 2
}

$features = @($pack.Features)
if ($features.Count -eq 0) {
    Write-GcLog "features.json empty ($($pack.Path))" "WARN"
    exit 0
}

function Get-FeatureId($f) {
    if ($f.id) { return [string]$f.id }
    if ($f.Id) { return [string]$f.Id }
    if ($f.name) { return [string]$f.name }
    return "unknown"
}

function Get-NameKeywords([string]$id, [string]$name) {
    $raw = "$id $name"
    $parts = $raw -split '[-_\s./]+' | Where-Object {
        $_ -and $_.Length -ge 3 -and $_ -notmatch '^(feat|src|fun|the|and|for|with|req)$'
    }
    return @($parts | Select-Object -Unique | Select-Object -First 8)
}

function Test-IsTestPath([string]$p) {
    return $p -match '(?i)(/|\\)(tests?|__tests__|spec|cypress|e2e)(/|\\)|\.(spec|test)\.(ts|tsx|js|jsx|rs|py)$'
}

# Precompute selection
$selected = @()
foreach ($f in $features) {
    $fid = Get-FeatureId $f
    if ($Id) {
        if ($Id -match '[\*\?]') {
            if ($fid -notlike $Id) { continue }
        } else {
            if ($fid -ne $Id -and $fid -notlike "*$Id*") { continue }
        }
    }
    if ($Status) {
        $st = [string]$f.status
        if ($st -notmatch [regex]::Escape($Status)) { continue }
    }
    $claim = Get-FeatureClaimedPct $f
    $pct = if ($null -eq $claim.Pct) { -1 } else { $claim.Pct }
    if ($pct -ge 0 -and $pct -ge $Below) { continue }

    $linked = @()
    if ($LinkSrs -or $ReqId) {
        $linked = @(Get-FeatureLinkedReqs -Feature $f -FeatureId $fid -Requirements $allReqs)
    }
    if ($ReqId) {
        $okReq = $false
        foreach ($L in $linked) {
            if ($ReqId -match '[\*\?]') {
                if ($L.ReqId -like $ReqId) { $okReq = $true; break }
            } else {
                if ($L.ReqId -eq $ReqId -or $L.ReqId -like "*$ReqId*") { $okReq = $true; break }
            }
        }
        # also allow direct match if feature mentions REQ in description
        if (-not $okReq -and ("$fid $($f.description)" -match [regex]::Escape($ReqId))) { $okReq = $true }
        if (-not $okReq) { continue }
    }

    $selected += [pscustomobject]@{
        Feature = $f
        Id      = $fid
        Claimed = $pct
        Source  = $claim.Source
        Status  = [string]$f.status
        Linked  = $linked
    }
}

if (-not $All -and -not $Id -and -not $ReqId -and -not $List) {
    $selected = $selected | Sort-Object { if ($_.Claimed -lt 0) { 999 } else { $_.Claimed } } | Select-Object -First $MaxFeatures
} elseif ($All -and -not $Id) {
    $selected = $selected | Sort-Object Id
} else {
    $selected = $selected | Sort-Object { if ($_.Claimed -lt 0) { 999 } else { $_.Claimed } }
}

if ($selected.Count -eq 0) {
    Write-GcLog "No features matched filters (Id/ReqId/Status/Below)" "WARN"
    exit 0
}

# ---- helper: analyze one feature (shared by List and deep) ----
function Invoke-FeatureAnalysis {
    param($Row)

    $f = $Row.Feature
    $fid = $Row.Id
    $evidenceRels = @(Get-FeatureEvidencePaths $f)
    $resolved = @()
    $missing = @()
    $excerpts = @()
    $hitBlocks = @()

    $kw = @($Keywords)
    if ($UseNameKeywords -or $DiffClaimed) {
        $kw += Get-NameKeywords $fid ([string]$f.name)
    }
    if ($f.acceptance_criteria) {
        $ac = $f.acceptance_criteria
        if ($ac -is [string]) { $kw += ($ac -split '\W+' | Where-Object { $_.Length -ge 5 } | Select-Object -First 5) }
        elseif ($ac -is [System.Array]) {
            foreach ($a in $ac) {
                $kw += ([string]$a -split '\W+' | Where-Object { $_.Length -ge 5 } | Select-Object -First 3)
            }
        }
    }
    $kw = @($kw | Where-Object { $_ } | Select-Object -Unique | Select-Object -First 12)

    $fileCount = 0
    $totalCodeLines = 0
    $testFileCount = 0

    foreach ($rel in $evidenceRels) {
        if ($fileCount -ge $MaxFilesPerFeature) { break }
        $abs = Resolve-ProjectPath $root $rel
        if (-not $abs) {
            $missing += $rel
            $resolved += [pscustomobject]@{ Rel = $rel; Abs = $null; Exists = $false; TotalLines = 0; IsTest = $false }
            continue
        }
        $fileCount++
        $meta = Get-Item $abs
        $isTest = Test-IsTestPath $abs
        if ($isTest) { $testFileCount++ }

        $ex = Get-FileExcerpt -Path $abs -Mode $Mode -Lines $Lines -StartLine $StartLine -EndLine $EndLine -MaxChars $MaxChars
        if (-not $isTest) { $totalCodeLines += [int]$ex.TotalLines }
        else { $totalCodeLines += [int]([math]::Min($ex.TotalLines, 100)) }

        $resolved += [pscustomobject]@{
            Rel        = $rel
            Abs        = $abs
            Exists     = $true
            TotalLines = $ex.TotalLines
            Bytes      = $meta.Length
            IsTest     = $isTest
            ExcerptOf  = "{0}-{1}" -f $ex.Start, $ex.End
        }
        $excerpts += [pscustomobject]@{
            Path       = $rel
            Abs        = $abs
            Mode       = $Mode
            Start      = $ex.Start
            End        = $ex.End
            TotalLines = $ex.TotalLines
            IsTest     = $isTest
            Text       = $ex.Text
        }
        if ($kw.Count -gt 0) {
            $hits = Search-FileKeywordHits -Path $abs -Keywords $kw -Context 2 -MaxHits 5
            foreach ($h in $hits) {
                $hitBlocks += [pscustomobject]@{
                    Path    = $rel
                    Keyword = $h.Keyword
                    Line    = $h.Line
                    Snippet = $h.Snippet
                }
            }
        }
    }

    $existsN = @($resolved | Where-Object Exists).Count
    $missN = $missing.Count
    $declared = $evidenceRels.Count
    $evidenceScore = if ($declared -eq 0) { 0 } else { [math]::Round(100.0 * $existsN / $declared, 1) }

    $hasGaps = $false
    if ($f.gaps) {
        if ($f.gaps -is [string]) { $hasGaps = $f.gaps.Trim().Length -gt 0 }
        else { $hasGaps = @($f.gaps).Count -gt 0 }
    }

    $suggest = Get-SuggestedImplementationPct `
        -ClaimedPct $Row.Claimed `
        -EvidenceScorePct $evidenceScore `
        -EvidenceExists $existsN `
        -EvidenceMissing $missN `
        -EvidenceDeclared $declared `
        -TotalCodeLines $totalCodeLines `
        -TestFileCount $testFileCount `
        -KeywordHitCount $hitBlocks.Count `
        -HasGaps $hasGaps `
        -Status $Row.Status

    return [pscustomobject]@{
        Id             = $fid
        Feature        = $f
        Claimed        = $Row.Claimed
        ClaimSource    = $Row.Source
        Status         = $Row.Status
        Linked         = $Row.Linked
        EvidenceRels   = $evidenceRels
        Resolved       = $resolved
        Missing        = $missing
        Excerpts       = $excerpts
        HitBlocks      = $hitBlocks
        Keywords       = $kw
        ExistsN        = $existsN
        MissN          = $missN
        Declared       = $declared
        EvidenceScore  = $evidenceScore
        TotalCodeLines = $totalCodeLines
        TestFileCount  = $testFileCount
        HasGaps        = $hasGaps
        SuggestedPct   = $suggest.SuggestedPct
        Delta          = $suggest.Delta
        Verdict        = $suggest.Verdict
        Breakdown      = $suggest.Breakdown
    }
}

# LIST mode with DiffClaimed columns
if ($List) {
    Write-Host ""
    Write-Host "FEATURES  source=$($pack.Path)  count=$($selected.Count)/$($features.Count)  srs=$($allReqs.Count) reqs" -ForegroundColor Cyan
    if ($ReqId) { Write-Host "filter ReqId=$ReqId" -ForegroundColor Yellow }
    Write-Host ("{0,-26} {1,6} {2,6} {3,7} {4,-11} {5,4} {6}" -f "ID", "CLAIM", "SUGG", "DELTA", "VERDICT", "EVID", "NAME")
    Write-Host ("-" * 100)
    $listRows = @()
    foreach ($row in $selected) {
        $a = Invoke-FeatureAnalysis $row
        $cp = if ($a.Claimed -lt 0) { "?" } else { "{0:N0}" -f $a.Claimed }
        $sp = "{0:N0}" -f $a.SuggestedPct
        $dp = if ($null -eq $a.Delta) { "?" } else { "{0:+0;-0;0}" -f $a.Delta }
        $nm = if ($a.Feature.name) { $a.Feature.name } else { "" }
        $ev = "{0}/{1}" -f $a.ExistsN, $a.Declared
        Write-Host ("{0,-26} {1,6} {2,6} {3,7} {4,-11} {5,4} {6}" -f $a.Id, $cp, $sp, $dp, $a.Verdict, $ev, $nm)
        if ($a.Linked -and $a.Linked.Count -gt 0) {
            $top = $a.Linked | Select-Object -First 2
            $linkTxt = ($top | ForEach-Object { $_.ReqId }) -join ", "
            Write-Host ("             srs: {0}" -f $linkTxt) -ForegroundColor DarkGray
        }
        $listRows += $a
    }
    Write-Host ""
    $over = @($listRows | Where-Object { $_.Verdict -eq 'overstated' }).Count
    $miss = @($listRows | Where-Object { $_.Verdict -eq 'missing' }).Count
    $conf = @($listRows | Where-Object { $_.Verdict -eq 'confirmed' }).Count
    Write-Host "Summary: confirmed=$conf overstated=$over missing=$miss partial_or_other=$($listRows.Count - $over - $miss - $conf)" -ForegroundColor Cyan
    Write-Host "Tip: pwsh .gitcore/scripts/feature-verify.ps1 -Id <id> -Tail -AgentBrief -DiffClaimed -WritePack"
    if ($WritePack -and -not $NoWrite) {
        $verifyRoot = if ($OutDir) { $OutDir } else { Join-Path $root ".gitcore\verify" }
        if (-not (Test-Path $verifyRoot)) { New-Item -ItemType Directory -Force -Path $verifyRoot | Out-Null }
        $csv = Join-Path $verifyRoot "diff-claimed.csv"
        $listRows | Select-Object Id, Claimed, SuggestedPct, Delta, Verdict, EvidenceScore, ExistsN, Declared, Status | Export-Csv $csv -NoTypeInformation -Encoding UTF8
        Write-Host "Wrote $csv"
    }
    exit 0
}

# Default WritePack when deep-diving
if (-not $NoWrite -and ($Id -or $ReqId -or $All -or $WritePack -or $AgentBrief -or $DiffClaimed)) {
    $WritePack = $true
}

$verifyRoot = if ($OutDir) { $OutDir } else { Join-Path $root ".gitcore\verify" }
if ($WritePack -and -not (Test-Path $verifyRoot)) {
    New-Item -ItemType Directory -Force -Path $verifyRoot | Out-Null
}

$indexItems = @()
$stdoutBlocks = New-Object System.Collections.Generic.List[string]

foreach ($row in $selected) {
    $a = Invoke-FeatureAnalysis $row
    $f = $a.Feature
    $fid = $a.Id

    $checks = @()
    $checks += "Confirm evidence files exist and match feature description."
    if ($a.MissN -gt 0) { $checks += "MISSING paths: fix features.json evidence or restore files." }
    if ($a.Claimed -ge 90 -and $a.ExistsN -eq 0) {
        $checks += "HIGH claimed % but zero evidence files — likely overstated."
    }
    if ($a.HasGaps) { $checks += "Review documented gaps field for residual work." }
    if ($f.steps) { $checks += "Walk steps[] and mark which are proven by excerpts." }
    if ($f.acceptance_criteria) { $checks += "Map acceptance_criteria to tests or code paths." }
    if ($a.Linked.Count -gt 0) {
        $checks += ("Cross-check SRS: {0}" -f (($a.Linked | Select-Object -First 3 | ForEach-Object { $_.ReqId }) -join ", "))
    }
    if ($DiffClaimed) {
        $checks += "Compare CLAIMED_PCT vs SUGGESTED_PCT (DiffClaimed heuristic); adjust features.json if overstated."
    }
    $checks += "Do NOT re-implement; only verify and report VERDICT."

    $reportObj = [ordered]@{
        schema             = "gitcore.feature-verify/v2"
        project            = Split-Path $root -Leaf
        project_root       = $root
        features_json      = $pack.Path
        srs_path           = $srsPack.Path
        generated_at       = (Get-Date).ToString("o")
        feature_id         = $fid
        name               = [string]$f.name
        status             = $a.Status
        claimed_pct        = $(if ($a.Claimed -lt 0) { $null } else { $a.Claimed })
        claimed_source     = $a.ClaimSource
        suggested_pct      = $a.SuggestedPct
        delta_pct          = $a.Delta
        auto_verdict       = $a.Verdict
        suggest_breakdown  = $a.Breakdown
        category           = [string]$f.category
        description        = [string]$f.description
        gaps               = $f.gaps
        steps              = $f.steps
        acceptance         = $f.acceptance_criteria
        srs_links          = $a.Linked
        evidence_paths     = $a.EvidenceRels
        evidence_resolved  = $a.Resolved
        evidence_score_pct = $a.EvidenceScore
        keywords           = $a.Keywords
        keyword_hits       = $a.HitBlocks
        excerpts           = $a.Excerpts
        agent_checks       = $checks
        mode               = $Mode
        lines              = $Lines
    }

    $indexItems += [pscustomobject]@{
        id               = $fid
        claimed_pct      = $reportObj.claimed_pct
        suggested_pct    = $a.SuggestedPct
        delta_pct        = $a.Delta
        auto_verdict     = $a.Verdict
        status           = $a.Status
        evidence_score   = $a.EvidenceScore
        evidence_exists  = $a.ExistsN
        evidence_missing = $a.MissN
        srs_links        = @($a.Linked | Select-Object -First 5 | ForEach-Object { $_.ReqId })
        pack             = "feature-$($fid -replace '[^\w\-]','_').md"
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("### FEATURE_START id=$fid")
    [void]$sb.AppendLine("schema: gitcore.feature-verify/v2")
    [void]$sb.AppendLine("project: $(Split-Path $root -Leaf)")
    [void]$sb.AppendLine("name: $([string]$f.name)")
    [void]$sb.AppendLine("status: $($a.Status)")
    [void]$sb.AppendLine("claimed_pct: $(if ($a.Claimed -lt 0) { 'null' } else { $a.Claimed }) ($($a.ClaimSource))")
    [void]$sb.AppendLine("suggested_pct: $($a.SuggestedPct)")
    if ($null -ne $a.Delta) {
        [void]$sb.AppendLine(("delta_pct: {0:+0.##;-0.##;0}" -f $a.Delta))
    }
    [void]$sb.AppendLine("auto_verdict: $($a.Verdict)")
    [void]$sb.AppendLine("evidence_score_pct: $($a.EvidenceScore) (exists=$($a.ExistsN) missing=$($a.MissN) declared=$($a.Declared))")
    [void]$sb.AppendLine("code_lines≈$($a.TotalCodeLines) test_files=$($a.TestFileCount)")
    if (-not $AgentBrief -and $f.description) {
        [void]$sb.AppendLine("description: $([string]$f.description)")
    }
    if ($a.HasGaps) {
        $gtxt = if ($f.gaps -is [string]) { $f.gaps } else { ($f.gaps | ConvertTo-Json -Compress) }
        [void]$sb.AppendLine("gaps: $gtxt")
    }

    if ($DiffClaimed -and $a.Breakdown) {
        [void]$sb.AppendLine("### DIFF_CLAIMED")
        foreach ($k in $a.Breakdown.Keys) {
            [void]$sb.AppendLine("- ${k}: $($a.Breakdown[$k])")
        }
        [void]$sb.AppendLine("heuristic: evidence*0.45 + tests + code_size + keywords + status - gaps")
    }

    if ($LinkSrs) {
        [void]$sb.AppendLine("### SRS_LINKS")
        if (-not $a.Linked -or $a.Linked.Count -eq 0) {
            [void]$sb.AppendLine("- (none auto-linked)")
        } else {
            foreach ($L in ($a.Linked | Select-Object -First 6)) {
                [void]$sb.AppendLine(("- {0} score={1} title={2} reasons={3}" -f $L.ReqId, $L.Score, $L.Title, ($L.Reasons -join "|")))
                if ($L.Files -and $L.Files.Count -gt 0) {
                    [void]$sb.AppendLine(("  files: {0}" -f ($L.Files -join ", ")))
                }
            }
        }
    }

    [void]$sb.AppendLine("### EVIDENCE_PATHS")
    if ($a.EvidenceRels.Count -eq 0) {
        [void]$sb.AppendLine("- (none declared in features.json)")
    }
    foreach ($r in $a.Resolved) {
        if ($r.Exists) {
            $tag = if ($r.IsTest) { "TEST" } else { "CODE" }
            [void]$sb.AppendLine("- OK  [$tag] $($r.Rel)  lines=$($r.TotalLines)  excerpt=$($r.ExcerptOf)")
            [void]$sb.AppendLine("      abs=$($r.Abs)")
        } else {
            [void]$sb.AppendLine("- MISS $($r.Rel)")
        }
    }

    [void]$sb.AppendLine("### EXCERPTS mode=$Mode")
    foreach ($ex in $a.Excerpts) {
        $tag = if ($ex.IsTest) { "TEST" } else { "CODE" }
        [void]$sb.AppendLine("#### FILE [$tag] $($ex.Path) lines $($ex.Start)-$($ex.End)/$($ex.TotalLines)")
        [void]$sb.AppendLine('```')
        [void]$sb.AppendLine($ex.Text)
        [void]$sb.AppendLine('```')
    }

    if ($a.HitBlocks.Count -gt 0) {
        [void]$sb.AppendLine("### KEYWORD_HITS")
        foreach ($h in $a.HitBlocks) {
            [void]$sb.AppendLine("#### HIT $($h.Path):$($h.Line) keyword=$($h.Keyword)")
            [void]$sb.AppendLine('```')
            [void]$sb.AppendLine($h.Snippet)
            [void]$sb.AppendLine('```')
        }
    }

    [void]$sb.AppendLine("### AGENT_VERIFY_CHECKLIST")
    $n = 1
    foreach ($c in $checks) {
        [void]$sb.AppendLine("$n. $c")
        $n++
    }
    [void]$sb.AppendLine("### AGENT_OUTPUT_REQUIRED")
    [void]$sb.AppendLine("Reply with (fill after reading excerpts only):")
    [void]$sb.AppendLine("  VERDICT: confirmed | partial | overstated | understated | missing")
    [void]$sb.AppendLine("  AUTO_VERDICT: $($a.Verdict)")
    [void]$sb.AppendLine("  CLAIMED_PCT: $(if ($a.Claimed -lt 0) { 'null' } else { $a.Claimed })")
    [void]$sb.AppendLine("  SUGGESTED_PCT: $($a.SuggestedPct)")
    [void]$sb.AppendLine("  YOUR_SUGGESTED_PCT: <number if you disagree with heuristic>")
    [void]$sb.AppendLine("  SRS_REQS: <comma REQ ids or none>")
    [void]$sb.AppendLine("  NOTES: <one paragraph>")
    [void]$sb.AppendLine("  MISSING_EVIDENCE: <paths or none>")
    [void]$sb.AppendLine("### FEATURE_END id=$fid")
    [void]$sb.AppendLine("")

    $block = $sb.ToString()
    [void]$stdoutBlocks.Add($block)

    if ($WritePack) {
        $safe = ($fid -replace '[^\w\-]', '_')
        Set-Content -Path (Join-Path $verifyRoot "feature-$safe.md") -Value $block -Encoding UTF8
        ($reportObj | ConvertTo-Json -Depth 8) | Set-Content -Path (Join-Path $verifyRoot "feature-$safe.json") -Encoding UTF8
    }
}

if ($WritePack) {
    $index = [ordered]@{
        schema        = "gitcore.feature-verify-index/v2"
        project       = Split-Path $root -Leaf
        generated_at  = (Get-Date).ToString("o")
        features_json = $pack.Path
        srs_path      = $srsPack.Path
        count         = $indexItems.Count
        mode          = $Mode
        diff_claimed  = [bool]$DiffClaimed
        items         = $indexItems
    }
    $indexPath = Join-Path $verifyRoot "index.json"
    ($index | ConvertTo-Json -Depth 6) | Set-Content -Path $indexPath -Encoding UTF8
    $csvPath = Join-Path $verifyRoot "diff-claimed.csv"
    $indexItems | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-GcLog "Wrote verify pack: $verifyRoot ($($indexItems.Count) features)" "OK"
}

if ($Json) {
    [ordered]@{
        schema  = "gitcore.feature-verify-batch/v2"
        project = Split-Path $root -Leaf
        count   = $indexItems.Count
        items   = $indexItems
        blocks  = @($stdoutBlocks)
    } | ConvertTo-Json -Depth 6
} else {
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " feature-verify v2  project=$(Split-Path $root -Leaf)  n=$($selected.Count)  mode=$Mode" -ForegroundColor Cyan
    Write-Host " features_json=$($pack.Path)" -ForegroundColor DarkGray
    if ($srsPack.Path) { Write-Host " srs=$($srsPack.Path) ($($allReqs.Count) REQs)" -ForegroundColor DarkGray }
    if ($ReqId) { Write-Host " filter ReqId=$ReqId" -ForegroundColor Yellow }
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    foreach ($b in $stdoutBlocks) { Write-Host $b }
    if ($WritePack) { Write-Host "Pack: $verifyRoot" -ForegroundColor DarkGray }
}

exit 0
