#!/bin/bash

# Script de construcción y actualización para Cutepomo
# Automatiza el proceso completo de Sparkle

set -e

# Configuración
APP_NAME="cutepomo"
VERSION="1.0.0"
SCHEME="cutepomo"
CONFIGURATION="Release"
DERIVED_DATA_PATH=".build"
GITHUB_REPO="suprastudy/CutePomo"

echo "🚀 Iniciando proceso de construcción y actualización para $APP_NAME v$VERSION"

# 1. Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
rm -rf "$DERIVED_DATA_PATH"
rm -f "${APP_NAME}-${VERSION}.zip"

# 2. Construir la aplicación
echo "🔨 Construyendo la aplicación..."
xcodebuild -project "${APP_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    clean build

# 3. Verificar que la app se construyó correctamente
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: No se pudo encontrar la aplicación construida en $APP_PATH"
    exit 1
fi

echo "✅ Aplicación construida exitosamente"

# 4. Crear archivo ZIP
echo "📦 Creando archivo ZIP..."
cd "${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}"
zip -r "${APP_NAME}-${VERSION}.zip" "${APP_NAME}.app"
cd - > /dev/null

# Mover ZIP al directorio principal
mv "${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}-${VERSION}.zip" .

# 5. Firmar la actualización
echo "🔐 Firmando la actualización..."
SIGNATURE_OUTPUT=$(/usr/local/Caskroom/sparkle/2.7.0/bin/sign_update "${APP_NAME}-${VERSION}.zip")

# Extraer la firma y el tamaño
SIGNATURE=$(echo "$SIGNATURE_OUTPUT" | grep 'sparkle:edSignature=' | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')
LENGTH=$(echo "$SIGNATURE_OUTPUT" | grep 'length=' | sed 's/.*length="\([^"]*\)".*/\1/')

echo "📝 Firma generada: $SIGNATURE"
echo "📏 Tamaño del archivo: $LENGTH bytes"

# 6. Actualizar appcast.xml
echo "📄 Actualizando appcast.xml..."
CURRENT_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

cat > appcast.xml << EOF
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>Cutepomo Updates</title>
        <description>Actualizaciones para la aplicación Cutepomo</description>
        <language>es</language>
        <item>
            <title>Version $VERSION</title>
            <pubDate>$CURRENT_DATE</pubDate>
            <sparkle:version>$VERSION</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <description>
                <![CDATA[
                    <h2>Cutepomo v$VERSION 🍅</h2>
                    <ul>
                        <li>Aplicación de timer Pomodoro con interfaz minimalista</li>
                        <li>Sistema de actualizaciones automáticas integrado</li>
                        <li>Configuración de tiempos personalizable</li>
                        <li>Interfaz siempre visible y flotante</li>
                        <li>Compatibilidad con macOS 15.0+</li>
                    </ul>
                ]]>
            </description>
            <link>https://github.com/$GITHUB_REPO/releases/tag/v$VERSION</link>
            <enclosure
                url="https://github.com/$GITHUB_REPO/releases/download/v$VERSION/${APP_NAME}-${VERSION}.zip"
                sparkle:version="$VERSION"
                sparkle:shortVersionString="$VERSION"
                length="$LENGTH"
                type="application/octet-stream"
                sparkle:edSignature="$SIGNATURE" />
        </item>
    </channel>
</rss>
EOF

echo "✅ appcast.xml actualizado"

# 7. Mostrar resumen
echo ""
echo "🎉 ¡Proceso completado exitosamente!"
echo "📦 Archivo ZIP: ${APP_NAME}-${VERSION}.zip"
echo "📄 Archivo appcast: appcast.xml"
echo ""
echo "📋 Próximos pasos:"
echo "1. Sube el archivo ${APP_NAME}-${VERSION}.zip a GitHub Releases"
echo "2. Sube el archivo appcast.xml a tu repositorio"
echo "3. Asegúrate de que la URL del appcast sea accesible"
echo ""
echo "🔗 URLs que necesitas configurar:"
echo "   - Release: https://github.com/$GITHUB_REPO/releases/tag/v$VERSION"
echo "   - ZIP: https://github.com/$GITHUB_REPO/releases/download/v$VERSION/${APP_NAME}-${VERSION}.zip"
echo "   - Appcast: https://raw.githubusercontent.com/$GITHUB_REPO/main/appcast.xml" 