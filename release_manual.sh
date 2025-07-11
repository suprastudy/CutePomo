#!/bin/bash

# 🚀 Script para crear release manual de cutepomo
# Uso: ./release_manual.sh 1.0.1

if [ -z "$1" ]; then
    echo "❌ Error: Debes especificar la nueva versión"
    echo "Uso: ./release_manual.sh 1.0.1"
    exit 1
fi

NEW_VERSION="$1"
APP_NAME="cutepomo"
EXPORT_DIR="$HOME/Desktop/Vacio"

echo "🚀 Creando release $NEW_VERSION de $APP_NAME"
echo "📁 Exportando a: $EXPORT_DIR"

# Crear directorio de export si no existe
mkdir -p "$EXPORT_DIR"

echo ""
echo "📝 Paso 1: Actualizando versión a $NEW_VERSION..."
sed -i '' "s/MARKETING_VERSION = [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*;/MARKETING_VERSION = $NEW_VERSION;/g" cutepomo.xcodeproj/project.pbxproj

echo "✅ Versión actualizada a $NEW_VERSION"

echo ""
echo "🔨 Paso 2: Compilando $APP_NAME $NEW_VERSION..."

# Limpiar builds anteriores
rm -rf build/

# Compilar la app
xcodebuild archive \
  -project $APP_NAME.xcodeproj \
  -scheme $APP_NAME \
  -configuration Release \
  -archivePath build/$APP_NAME.xcarchive \
  -destination "generic/platform=macOS" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

if [ $? -ne 0 ]; then
    echo "❌ Error compilando la app"
    exit 1
fi

echo "✅ Compilación exitosa"

echo ""
echo "📦 Paso 3: Exportando app a $EXPORT_DIR..."

# Copiar la app compilada
cp -R build/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app "$EXPORT_DIR/"

echo "✅ App exportada a $EXPORT_DIR/$APP_NAME.app"

echo ""
echo "🗜️ Paso 4: Creando archivo ZIP..."

cd "$EXPORT_DIR"
zip -r "$APP_NAME-v$NEW_VERSION.zip" "$APP_NAME.app" -q

if [ $? -ne 0 ]; then
    echo "❌ Error creando ZIP"
    exit 1
fi

cd - > /dev/null

FILE_SIZE=$(stat -f%z "$EXPORT_DIR/$APP_NAME-v$NEW_VERSION.zip")
echo "✅ ZIP creado: $APP_NAME-v$NEW_VERSION.zip ($FILE_SIZE bytes)"

echo ""
echo "🔐 Paso 5: Firmando con Sparkle..."

# Firmar el archivo
if [[ -f "keys/sparkle_keys" ]]; then
    SIGNATURE=$(openssl dgst -sha256 -sign keys/sparkle_keys "$EXPORT_DIR/$APP_NAME-v$NEW_VERSION.zip" | openssl base64 -A)
    echo "✅ Archivo firmado"
else
    SIGNATURE="PLACEHOLDER_SIGNATURE"
    echo "⚠️ No se encontró llave privada, usando placeholder"
fi

echo ""
echo "📝 Paso 6: Actualizando appcast.xml..."

# Obtener fecha actual
CURRENT_DATE=$(date -R)

# Crear nueva entrada para appcast
NEW_ENTRY="        <item>
            <title>Version $NEW_VERSION</title>
            <description><![CDATA[
                <h2>Qué hay de nuevo en v$NEW_VERSION:</h2>
                <ul>
                    <li>Nuevas características y mejoras</li>
                    <li>Corrección de errores</li>
                    <li>Optimizaciones de rendimiento</li>
                </ul>
            ]]></description>
            <pubDate>$CURRENT_DATE</pubDate>
            <sparkle:version>$NEW_VERSION</sparkle:version>
            <sparkle:shortVersionString>$NEW_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
            <enclosure 
                url=\"https://github.com/suprastudy/CutePomo/releases/download/v$NEW_VERSION/$APP_NAME-v$NEW_VERSION.zip\" 
                length=\"$FILE_SIZE\" 
                type=\"application/octet-stream\" 
                sparkle:edSignature=\"$SIGNATURE\" />
        </item>

        <!-- Versión anterior: -->"

# Insertar nueva entrada al principio del appcast
sed -i '' '/<!-- Versión base actual -->/,/<!-- Versión anterior: -->/c\
<!-- Nueva versión -->\
'"$NEW_ENTRY"'
' appcast.xml

echo "✅ Appcast actualizado"

echo ""
echo "🎉 ¡COMPLETADO!"
echo ""
echo "📋 RESUMEN:"
echo "   • App compilada: $EXPORT_DIR/$APP_NAME.app"
echo "   • ZIP creado: $EXPORT_DIR/$APP_NAME-v$NEW_VERSION.zip"
echo "   • Tamaño: $FILE_SIZE bytes"
echo "   • Appcast actualizado"
echo ""
echo "📤 SIGUIENTE PASO:"
echo "   1. Sube $APP_NAME-v$NEW_VERSION.zip a GitHub Releases"
echo "   2. Haz commit y push del appcast.xml actualizado"
echo ""
echo "🔗 GitHub Releases: https://github.com/suprastudy/CutePomo/releases" 