# 🔐 Configuración de Publicación Automática a pub.dev

## Problema Actual
El workflow está detenido esperando autorización manual porque falta el secret `PUB_CREDENTIALS_JSON`.

## Solución Inmediata (Para esta publicación)

1. **Copia el enlace de autorización** del log del workflow (línea 122)
2. **Ábrelo en tu navegador**
3. **Autoriza la publicación con tu cuenta de Google**
4. El workflow continuará automáticamente

## Configuración Permanente (Para futuras publicaciones)

### Paso 1: Obtener las credenciales

Después de autorizar la publicación manualmente por primera vez:

```bash
# En tu máquina local (Linux/Mac)
cat ~/.pub-cache/credentials.json

# En Windows PowerShell
Get-Content $env:APPDATA\pub-cache\credentials.json
```

### Paso 2: Configurar el Secret en GitHub

1. Ve a: https://github.com/iberi22/isar_agent_memory/settings/secrets/actions
2. Click en "New repository secret"
3. Name: `PUB_CREDENTIALS_JSON`
4. Value: Pega el contenido completo del archivo `credentials.json`
5. Click "Add secret"

### Paso 3: Verificar

El archivo `credentials.json` debería verse así:

```json
{
  "accessToken": "ya29.a0...",
  "refreshToken": "1//...",
  "tokenEndpoint": "https://oauth2.googleapis.com/token",
  "scopes": ["openid", "https://www.googleapis.com/auth/userinfo.email"],
  "expiration": 1234567890123
}
```

## Verificación Post-Configuración

Una vez configurado el secret:

1. Las futuras publicaciones serán **completamente automáticas**
2. No requerirá autorización manual
3. El workflow se ejecutará de principio a fin sin intervención

## Script de Ayuda

Ejecuta este script para extraer las credenciales:

```powershell
# En PowerShell (Windows)
$credPath = "$env:APPDATA\pub-cache\credentials.json"
if (Test-Path $credPath) {
    Write-Host "✅ Credenciales encontradas!" -ForegroundColor Green
    Write-Host "`nContenido a copiar al secret:" -ForegroundColor Yellow
    Get-Content $credPath
} else {
    Write-Host "❌ Archivo de credenciales no encontrado" -ForegroundColor Red
    Write-Host "Debes publicar manualmente primero: dart pub publish" -ForegroundColor Yellow
}
```

## Notas Importantes

- ⚠️ **NUNCA** compartas o hagas commit de `credentials.json`
- ⚠️ Las credenciales son **sensibles** - solo en GitHub Secrets
- ✅ El secret está cifrado en GitHub y solo accesible por workflows
- ✅ Puedes rotar las credenciales en cualquier momento

## Referencias

- [pub.dev Publishing Docs](https://dart.dev/tools/pub/publishing)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
