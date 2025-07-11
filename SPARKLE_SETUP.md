# 🔄 Configuración de Sparkle para Actualizaciones Automáticas

Esta guía te ayudará a configurar completamente las actualizaciones automáticas de `cutepomo` usando Sparkle.

## 📋 Prerrequisitos

1. **Sparkle instalado en tu sistema:**
   ```bash
   brew install sparkle
   ```

2. **Proyecto subido a GitHub**

3. **Repositorio configurado para releases**

## 🚀 Configuración Inicial

### 1. Generar Llaves de Sparkle

```bash
# Ejecutar el script para generar las llaves
./scripts/generate_sparkle_keys.sh
```

Este script creará:
- `keys/sparkle_keys` (llave privada) - ⚠️ **MANTENER SEGURA**
- `keys/sparkle_keys.pub` (llave pública)

### 2. Actualizar Info.plist

1. Copia la llave pública generada
2. Reemplaza `PLACEHOLDER_PUBLIC_KEY` en `cutepomo/Info.plist` con la llave pública real
3. Actualiza la URL del appcast:
   ```xml
   <key>SUFeedURL</key>
   <string>https://raw.githubusercontent.com/suprastudy/CutePomo/main/appcast.xml</string>
   ```

### 3. Configurar GitHub Secrets

Ve a tu repositorio en GitHub → Settings → Secrets and variables → Actions

Agrega estos secrets:
- `SPARKLE_PRIVATE_KEY`: Pega el contenido completo de `keys/sparkle_keys`

### 4. Agregar Sparkle como Dependencia

En Xcode:
1. File → Add Package Dependencies
2. Agregar: `https://github.com/sparkle-project/Sparkle`
3. Seleccionar la versión más reciente
4. Asegúrate de que se agrega al target principal `cutepomo`

## 🔧 Proceso de Release

### Opción 1: Release Automático (Recomendado)

1. **Actualizar versión en Xcode:**
   - Selecciona el proyecto en Navigator
   - Ve a la sección "General" del target
   - Actualiza "Version" (ej: 1.0.4)

2. **Crear y push del tag:**
   ```bash
   git add .
   git commit -m "Preparar release v1.0.4"
   git push origin main
   
   # Crear tag
   git tag v1.0.4
   git push origin v1.0.4
   ```

3. **El GitHub Action se ejecutará automáticamente y:**
   - Compilará la app
   - Creará el ZIP
   - Firmará el archivo
   - Actualizará `appcast.xml`
   - Creará el GitHub Release

### Opción 2: Release Manual

1. **Ejecutar GitHub Action manualmente:**
   - Ve a GitHub → Actions → "Build and Release cutepomo"
   - Click "Run workflow"
   - Selecciona la branch y ejecuta

## 📱 Cómo Funciona para los Usuarios

1. **Primera instalación:** Los usuarios descargan e instalan manualmente
2. **Actualizaciones automáticas:** 
   - La app verifica actualizaciones al iniciar
   - También verifica cada 24 horas
   - Los usuarios pueden verificar manualmente: Menú → "Check for Updates..."

## 🛠️ Personalización

### Cambiar Frecuencia de Verificación

En `Info.plist`:
```xml
<key>SUScheduledCheckInterval</key>
<integer>3600</integer> <!-- 1 hora en segundos -->
```

### Deshabilitar Verificación Automática

En `Info.plist`:
```xml
<key>SUEnableAutomaticChecks</key>
<false/>
```

### Personalizar Descripción de Release

Edita `.github/workflows/release.yml` en la sección "Update appcast.xml":
```xml
<description><![CDATA[
    <h2>✨ Nueva versión disponible!</h2>
    <ul>
        <li>🎨 Nueva interfaz más intuitiva</li>
        <li>🐛 Corrección de errores importantes</li>
        <li>⚡ Mejoras de rendimiento</li>
    </ul>
]]></description>
```

## 🔧 Solución de Problemas

### La app no verifica actualizaciones

1. **Verificar URL del appcast:**
   - Asegúrate de que la URL en `Info.plist` es correcta
   - Verifica que `appcast.xml` sea accesible públicamente

2. **Verificar llave pública:**
   - Confirma que la llave pública en `Info.plist` coincide con la generada

3. **Logs de debug:**
   ```swift
   // Agregar en cutepomoApp.swift para debug
   updaterController = SPUStandardUpdaterController(
       startingUpdater: true, 
       updaterDelegate: nil, 
       userDriverDelegate: nil
   )
   ```

### Error de firma

1. **Verificar secret en GitHub:**
   - Asegúrate de que `SPARKLE_PRIVATE_KEY` está configurado correctamente

2. **Regenerar llaves si es necesario:**
   ```bash
   ./scripts/generate_sparkle_keys.sh
   ```

### Build falla en GitHub Actions

1. **Verificar que Sparkle esté agregado correctamente en Xcode**
2. **Revisar logs de GitHub Actions para errores específicos**

## 📚 Recursos Adicionales

- [Documentación oficial de Sparkle](https://sparkle-project.org/)
- [Guía de distribución de apps macOS](https://developer.apple.com/distribution/)
- [GitHub Actions para Xcode](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift)

## 🎯 Flujo Completo de Trabajo

1. **Desarrollo:** Hacer cambios en el código
2. **Version bump:** Actualizar versión en Xcode
3. **Commit y push:** Subir cambios a main
4. **Tag release:** Crear tag con versión (ej: v1.0.4)
5. **Automático:** GitHub Actions compila, firma y publica
6. **Usuarios:** Reciben notificación automática de actualización

¡Con esto tienes un sistema completo de actualizaciones automáticas! 🎉 