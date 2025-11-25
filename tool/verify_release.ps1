#!/usr/bin/env pwsh
# Complete verification script for isar_agent_memory release

$owner = "iberi22"
$repo = "isar_agent_memory"
$version = "0.5.0-beta"
$tag = "v$version"

Write-Host ""
Write-Host "🔍 Verificación Completa de Release v$version" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

# 1. Git Tags
Write-Host "📌 Git Tags:" -ForegroundColor Yellow
git tag -l | Select-String $version
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Tag $tag existe localmente" -ForegroundColor Green
}
Write-Host ""

# 2. GitHub Release
Write-Host "🎉 GitHub Release:" -ForegroundColor Yellow
try {
    $release = gh release view $tag --repo "$owner/$repo" --json name,tagName,isPrerelease,publishedAt 2>$null | ConvertFrom-Json
    if ($release) {
        Write-Host "   ✅ Release creado: $($release.name)" -ForegroundColor Green
        Write-Host "   📅 Publicado: $($release.publishedAt)" -ForegroundColor Gray
        Write-Host "   🏷️  Prerelease: $($release.isPrerelease)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ⚠️  No se pudo verificar el release" -ForegroundColor Yellow
}
Write-Host ""

# 3. GitHub Actions
Write-Host "⚙️  GitHub Actions:" -ForegroundColor Yellow
$runs = gh run list --repo "$owner/$repo" --workflow=publish-to-pub-dev.yml --limit 1 --json status,conclusion,createdAt,displayTitle 2>$null | ConvertFrom-Json
if ($runs -and $runs.Count -gt 0) {
    $run = $runs[0]
    $statusIcon = switch ($run.status) {
        "completed" { "✅" }
        "in_progress" { "🔄" }
        "queued" { "⏳" }
        default { "❓" }
    }
    Write-Host "   $statusIcon Status: $($run.status)" -ForegroundColor Gray
    if ($run.conclusion) {
        $conclusionColor = if ($run.conclusion -eq "success") { "Green" } else { "Red" }
        Write-Host "   📊 Resultado: $($run.conclusion)" -ForegroundColor $conclusionColor
    }
}
Write-Host ""

# 4. pub.dev Status
Write-Host "📦 pub.dev Status:" -ForegroundColor Yellow
Write-Host "   🔗 Verificando en: https://pub.dev/packages/$repo" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "https://pub.dev/packages/$repo" -UseBasicParsing -TimeoutSec 10
    if ($response.Content -match $version) {
        Write-Host "   ✅ Versión $version encontrada en pub.dev!" -ForegroundColor Green
    } else {
        Write-Host "   ⏳ Esperando publicación (puede tomar 2-5 minutos)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  No se pudo verificar pub.dev" -ForegroundColor Yellow
}
Write-Host ""

# 5. Local Repository
Write-Host "💻 Repositorio Local:" -ForegroundColor Yellow
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "   ✅ Working tree limpio" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Hay cambios sin commitear" -ForegroundColor Yellow
}
$ahead = git rev-list --count origin/main..HEAD 2>$null
if ($ahead -eq 0) {
    Write-Host "   ✅ Sincronizado con origin/main" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  $ahead commits adelante de origin/main" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "🔗 Enlaces Útiles:" -ForegroundColor Cyan
Write-Host "   Release: https://github.com/$owner/$repo/releases/tag/$tag" -ForegroundColor Blue
Write-Host "   Actions: https://github.com/$owner/$repo/actions" -ForegroundColor Blue
Write-Host "   pub.dev: https://pub.dev/packages/$repo" -ForegroundColor Blue
Write-Host ""
