#!/usr/bin/env pwsh
# Script to update the v0.5.0-beta release notes on GitHub

$owner = "iberi22"
$repo = "isar_agent_memory"
$tag = "v0.5.0-beta"
$releaseNotesFile = ".github/RELEASE_NOTES_v0.5.0-beta.md"

Write-Host "🔄 Updating GitHub Release for $tag..." -ForegroundColor Cyan

# Check if gh CLI is installed
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI (gh) is not installed." -ForegroundColor Red
    Write-Host "Please install it from: https://cli.github.com/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or update the release manually at:" -ForegroundColor Yellow
    Write-Host "https://github.com/$owner/$repo/releases/tag/$tag" -ForegroundColor Blue
    exit 1
}

# Check if release notes file exists
if (!(Test-Path $releaseNotesFile)) {
    Write-Host "❌ Release notes file not found: $releaseNotesFile" -ForegroundColor Red
    exit 1
}

Write-Host "📝 Reading release notes from: $releaseNotesFile" -ForegroundColor Gray

try {
    # Update the release
    gh release edit $tag `
        --repo "$owner/$repo" `
        --notes-file $releaseNotesFile `
        --prerelease `
        --title "v0.5.0-beta - Advanced RAG Capabilities"

    Write-Host "✅ Release updated successfully!" -ForegroundColor Green
    Write-Host "🔗 View at: https://github.com/$owner/$repo/releases/tag/$tag" -ForegroundColor Blue
} catch {
    Write-Host "❌ Failed to update release: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can update manually at:" -ForegroundColor Yellow
    Write-Host "https://github.com/$owner/$repo/releases/tag/$tag" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Copy the content from: $releaseNotesFile" -ForegroundColor Yellow
    exit 1
}
