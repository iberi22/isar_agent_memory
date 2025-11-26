#!/usr/bin/env pwsh
# Script para ayudar a configurar la publicación automática a pub.dev

Write-Host "`n🔐 Configuración de Publicación Automática a pub.dev`n" -ForegroundColor Cyan

# Verificar si existe el archivo de credenciales
$credPath = "$env:APPDATA\pub-cache\credentials.json"

if (Test-Path $credPath) {
    Write-Host "✅ Archivo de credenciales encontrado!" -ForegroundColor Green
    Write-Host "📍 Ubicación: $credPath`n" -ForegroundColor Gray

    Write-Host "📋 Contenido a copiar al GitHub Secret:`n" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Gray
    Get-Content $credPath | Write-Host -ForegroundColor White
    Write-Host "=" * 60 -ForegroundColor Gray

    Write-Host "`n📝 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Copia el contenido JSON de arriba" -ForegroundColor White
    Write-Host "2. Ve a: https://github.com/iberi22/isar_agent_memory/settings/secrets/actions" -ForegroundColor Blue
    Write-Host "3. Click 'New repository secret'" -ForegroundColor White
    Write-Host "4. Name: PUB_CREDENTIALS_JSON" -ForegroundColor White
    Write-Host "5. Value: Pega el JSON copiado" -ForegroundColor White
    Write-Host "6. Click 'Add secret'`n" -ForegroundColor White

    # Copiar al clipboard si es posible
    try {
        Get-Content $credPath | Set-Clipboard
        Write-Host "✅ Contenido copiado al clipboard!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  No se pudo copiar automáticamente al clipboard" -ForegroundColor Yellow
    }

} else {
    Write-Host "❌ Archivo de credenciales NO encontrado" -ForegroundColor Red
    Write-Host "📍 Ubicación esperada: $credPath`n" -ForegroundColor Gray

    Write-Host "💡 Necesitas publicar manualmente primero:" -ForegroundColor Yellow
    Write-Host "   1. cd $PWD" -ForegroundColor White
    Write-Host "   2. dart pub publish" -ForegroundColor White
    Write-Host "   3. Autoriza en el navegador" -ForegroundColor White
    Write-Host "   4. Vuelve a ejecutar este script`n" -ForegroundColor White

    Write-Host "🔗 O autoriza el workflow actual:" -ForegroundColor Yellow
    Write-Host "   https://github.com/iberi22/isar_agent_memory/actions`n" -ForegroundColor Blue
}

Write-Host "📚 Documentación completa en: .github/PUB_CREDENTIALS_SETUP.md`n" -ForegroundColor Gray
