# Configuración de GitHub Secrets para Releases Automáticos

## 🔑 **Secrets Requeridos**

Para que el workflow de GitHub Actions funcione correctamente, necesitas configurar estos secrets en tu repositorio:

### 1. **SPARKLE_PRIVATE_KEY**
```bash
# La clave privada EdDSA generada por Sparkle
# Ubicación: ~/sparkle_private_key (después de ejecutar generate_keys)
```

### 2. **P12_CERTIFICATE** (Opcional - para distribución fuera del App Store)
```bash
# Certificado Developer ID Application exportado desde Keychain Access
# Exportar como .p12 y convertir a base64
```

### 3. **P12_PASSWORD** (Opcional)
```bash
# Contraseña del certificado P12
```

## 📋 **Pasos para Configurar**

### 1. **Obtener la Clave Privada de Sparkle**

La clave privada ya fue generada cuando ejecutamos `generate_keys`. Para encontrarla:

```bash
# Buscar la clave privada
find ~ -name "*sparkle*" -name "*private*" 2>/dev/null

# O verificar en el directorio home
ls -la ~/sparkle_private_key
```

### 2. **Configurar Secrets en GitHub**

1. Ve a tu repositorio: https://github.com/suprastudy/CutePomo
2. Click en **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

#### **Secret: SPARKLE_PRIVATE_KEY**
```bash
# Copiar el contenido de la clave privada
cat ~/sparkle_private_key

# Ejemplo del contenido:
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEINxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-----END PRIVATE KEY-----
```

### 3. **Configurar Certificados de Code Signing (Opcional)**

Si quieres distribución fuera del App Store:

#### **Exportar Certificado Developer ID**
1. Abrir **Keychain Access**
2. Buscar "Developer ID Application"
3. Right-click → **Export**
4. Guardar como `.p12`
5. Convertir a base64:

```bash
base64 -i MyCertificate.p12 | pbcopy
```

#### **Secret: P12_CERTIFICATE**
Pegar el output base64 del comando anterior.

#### **Secret: P12_PASSWORD**
La contraseña que usaste al exportar el .p12.

## 🚀 **Verificar Configuración**

### 1. **Test Local** (Opcional)
```bash
# Verificar que puedes firmar localmente
cd /Users/matiassandoval/Library/Developer/Xcode/DerivedData/cutepomo-baemtrflsijnogbnsualkgkgwfyu/SourcePackages/artifacts/sparkle/Sparkle/bin

# Crear un archivo de prueba
echo "test" > test.txt
zip test.zip test.txt

# Firmar con tu clave privada
./sign_update test.zip -f ~/sparkle_private_key

# Limpiar
rm test.txt test.zip
```

### 2. **Test GitHub Actions**
Una vez configurados los secrets, puedes probar creando un tag:

```bash
# En tu repositorio local
git tag v1.0.2
git push origin v1.0.2
```

Esto debería disparar el workflow automáticamente.

## 📝 **Estructura Final del Repositorio**

```
CutePomo/
├── .github/
│   └── workflows/
│       └── release.yml
├── cutepomo/
│   ├── (archivos de la app)
│   └── Info.plist (con clave pública)
├── appcast.xml
└── README.md
```

## ⚠️ **Notas Importantes**

1. **Nunca commitear la clave privada** al repositorio
2. **Usar HTTPS** para el feed URL en Info.plist
3. **Semantic versioning** para los tags (v1.0.0, v1.0.1, etc.)
4. Los **secrets están encriptados** y solo son accesibles durante el workflow

## 🔍 **Verificar que Todo Funciona**

1. ✅ Secrets configurados en GitHub
2. ✅ Info.plist tiene la clave pública correcta
3. ✅ appcast.xml está en el repositorio
4. ✅ Workflow ejecuta sin errores
5. ✅ Release se crea automáticamente
6. ✅ appcast.xml se actualiza automáticamente

¡Una vez configurado, cada nuevo tag `v*.*.*` disparará automáticamente un release completo con actualizaciones firmadas! 🎉 