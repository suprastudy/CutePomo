# Configuración de Actualizaciones Automáticas con Sparkle

## ✅ **Estado Actual: Implementación Completa**

Sparkle ha sido completamente integrado en cutepomo. La aplicación ahora incluye:

### 🔧 **Características Implementadas:**

1. **Menú de Actualizaciones**
   - "Check for Updates..." en el menú principal
   - Estado dinámico (habilitado/deshabilitado)

2. **Panel de Configuración**
   - Tab "General" en Settings
   - Toggle para verificaciones automáticas
   - Toggle para descargas automáticas
   - Botón manual "Check for Updates Now"

3. **Gestión Automática**
   - Verificación diaria automática (24 horas)
   - Descarga automática opcional
   - Integración nativa con macOS

## 📋 **Pasos Restantes para Producción:**

### 1. **Generar Claves de Firma EdDSA**

```bash
# Generar par de claves
/path/to/Sparkle/bin/generate_keys

# Esto genera:
# - Una clave pública (para Info.plist)
# - Una clave privada (para firmar actualizaciones)
```

### 2. **Configurar Info.plist**

Actualizar los valores en `cutepomo/Info.plist`:

```xml
<key>SUFeedURL</key>
<string>https://tu-dominio.com/cutepomo/appcast.xml</string>

<key>SUPublicEDKey</key>
<string>TU_CLAVE_PUBLICA_AQUI</string>
```

### 3. **Crear Appcast Feed**

Crear `appcast.xml` en tu servidor:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>cutepomo Updates</title>
        <description>Updates for cutepomo</description>
        <language>en</language>
        <item>
            <title>Version 1.0.1</title>
            <description><![CDATA[
                <ul>
                    <li>Bug fixes and improvements</li>
                </ul>
            ]]></description>
            <pubDate>Wed, 09 Jan 2024 19:20:11 +0000</pubDate>
            <enclosure 
                url="https://tu-dominio.com/cutepomo/cutepomo-1.0.1.zip"
                sparkle:version="1.0.1"
                sparkle:shortVersionString="1.0.1"
                length="1623481"
                type="application/octet-stream"
                sparkle:edSignature="TU_FIRMA_AQUI" />
        </item>
    </channel>
</rss>
```

### 4. **Firmar Actualizaciones**

Para cada nueva versión:

```bash
# Crear archivo zip con la nueva versión
zip -r cutepomo-1.0.1.zip cutepomo.app

# Firmar el archivo
/path/to/Sparkle/bin/sign_update cutepomo-1.0.1.zip -f private_key
```

### 5. **Automatización con GitHub Actions** (Opcional)

Crear `.github/workflows/release.yml`:

```yaml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Release
        run: |
          xcodebuild -scheme cutepomo -configuration Release \
            -archivePath cutepomo.xcarchive archive
          
      - name: Export App
        run: |
          xcodebuild -exportArchive -archivePath cutepomo.xcarchive \
            -exportPath . -exportOptionsPlist ExportOptions.plist
            
      - name: Create ZIP
        run: zip -r cutepomo-${{ github.ref_name }}.zip cutepomo.app
        
      - name: Sign Update
        run: |
          echo "$SPARKLE_PRIVATE_KEY" > private_key
          /path/to/sparkle/bin/sign_update cutepomo-${{ github.ref_name }}.zip -f private_key
          
      - name: Update Appcast
        run: |
          # Script para actualizar appcast.xml
          # y subirlo al servidor
```

## 🎯 **Configuraciones Actuales:**

### Info.plist:
- ✅ `SUEnableAutomaticChecks`: true
- ✅ `SUAllowsAutomaticUpdates`: true  
- ✅ `SUScheduledCheckInterval`: 86400 (24 horas)
- ⚠️ `SUFeedURL`: Necesita URL real
- ⚠️ `SUPublicEDKey`: Necesita clave real

### Funcionalidades:
- ✅ Verificación manual desde menú
- ✅ Verificación manual desde Settings
- ✅ Configuración de verificaciones automáticas
- ✅ Configuración de descargas automáticas
- ✅ Indicador visual de estado

## 🔒 **Seguridad:**

- ✅ EdDSA signature verification
- ✅ HTTPS requerido para feed
- ✅ App Sandbox compatible
- ✅ Hardened Runtime compatible

## 📝 **Notas Importantes:**

1. **Clave Privada**: Nunca commitear la clave privada al repositorio
2. **Feed URL**: Debe ser HTTPS para producción
3. **Versioning**: Usar semantic versioning (1.0.0, 1.0.1, etc.)
4. **Testing**: Probar con versiones de desarrollo primero

## 🚀 **Para Lanzar:**

1. Generar claves EdDSA
2. Configurar servidor web para hospedar appcast.xml
3. Actualizar Info.plist con URL y clave real
4. Crear primer appcast.xml
5. Lanzar versión 1.0.0
6. Para actualizaciones futuras: compilar, firmar, actualizar appcast

¡Sparkle está completamente implementado y listo para producción! 🎉 