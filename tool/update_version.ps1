#!/usr/bin/env pwsh
# Script to update version across all files
# Usage: .\tool\update_version.ps1 <new-version>

param(
    [Parameter(Mandatory=$true)]
    [string]$NewVersion
)

$ErrorActionPreference = "Stop"

Write-Host "`n🔄 Updating version to $NewVersion across all files...`n" -ForegroundColor Cyan

# Files to update with their patterns
$updates = @(
    @{
        File = "pubspec.yaml"
        Pattern = "version:\s*[\d\.\-a-zA-Z]+"
        Replacement = "version: $NewVersion"
        Description = "pubspec.yaml version"
    },
    @{
        File = "README.md"
        Pattern = "isar_agent_memory:\s*\^[\d\.\-a-zA-Z]+"
        Replacement = "isar_agent_memory: ^$NewVersion"
        Description = "README.md dependency"
    },
    @{
        File = "README.md"
        Pattern = "\[!\[pub package\]\(https://img\.shields\.io/pub/v/isar_agent_memory\.svg\)\]"
        Replacement = "[![pub package](https://img.shields.io/pub/v/isar_agent_memory.svg)]"
        Description = "README.md badge (refresh)"
    }
)

$updatedFiles = @()
$errors = @()

foreach ($update in $updates) {
    $filePath = Join-Path $PSScriptRoot ".." $update.File

    if (!(Test-Path $filePath)) {
        Write-Host "⚠️  File not found: $($update.File)" -ForegroundColor Yellow
        continue
    }

    try {
        $content = Get-Content $filePath -Raw
        $newContent = $content -replace $update.Pattern, $update.Replacement

        if ($content -ne $newContent) {
            Set-Content $filePath -Value $newContent -NoNewline
            Write-Host "✅ Updated: $($update.Description)" -ForegroundColor Green
            $updatedFiles += $update.File
        } else {
            Write-Host "ℹ️  No change needed: $($update.Description)" -ForegroundColor Gray
        }
    } catch {
        $errors += "Failed to update $($update.File): $_"
        Write-Host "❌ Error updating $($update.File): $_" -ForegroundColor Red
    }
}

Write-Host "`n📝 Summary:" -ForegroundColor Cyan
Write-Host "Updated files: $($updatedFiles.Count)" -ForegroundColor White
Write-Host "Errors: $($errors.Count)" -ForegroundColor White

if ($updatedFiles.Count -gt 0) {
    Write-Host "`n📋 Files modified:" -ForegroundColor Yellow
    $updatedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }

    Write-Host "`n💡 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Review changes: git diff" -ForegroundColor White
    Write-Host "2. Update CHANGELOG.md manually" -ForegroundColor White
    Write-Host "3. Commit: git add -A && git commit -m `"chore: bump version to $NewVersion`"" -ForegroundColor White
    Write-Host "4. Push: git push origin main" -ForegroundColor White
    Write-Host "5. The release workflow will trigger automatically`n" -ForegroundColor White
}

if ($errors.Count -gt 0) {
    Write-Host "`n❌ Errors encountered:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
