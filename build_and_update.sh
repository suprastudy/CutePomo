#!/bin/bash

# Script de construcción y actualización para Cutepomo
# Automatiza el proceso completo de Sparkle

set -e

# Configuración
APP_NAME="cutepomo"
VERSION="1.0.1"
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
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/${APP_NAME}.app"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: No se encontró la aplicación en $APP_PATH"
    exit 1
fi

echo "✅ Aplicación construida exitosamente"

# 4. Crear el archivo ZIP
echo "📦 Creando archivo ZIP..."
cd "$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION"
zip -r "${APP_NAME}-${VERSION}.zip" "${APP_NAME}.app"
cd - > /dev/null

# 5. Mover el ZIP al directorio principal
mv "$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/${APP_NAME}-${VERSION}.zip" .

# 6. Firmar la actualización
echo "🔐 Firmando la actualización..."
SIGNATURE_OUTPUT=$(/usr/local/Caskroom/sparkle/2.7.0/bin/sign_update "${APP_NAME}-${VERSION}.zip")
echo "$SIGNATURE_OUTPUT"

# Extraer información de la firma
SIGNATURE=$(echo "$SIGNATURE_OUTPUT" | grep "sparkle:edSignature" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')
FILE_SIZE=$(stat -f%z "${APP_NAME}-${VERSION}.zip")

echo ""
echo "📋 Información para actualizar appcast.xml:"
echo "Versión: $VERSION"
echo "Archivo: ${APP_NAME}-${VERSION}.zip"
echo "Tamaño: $FILE_SIZE bytes"
echo "Firma: $SIGNATURE"
echo "URL de descarga: https://github.com/$GITHUB_REPO/releases/download/v$VERSION/${APP_NAME}-${VERSION}.zip"
echo ""
echo "🎉 ¡Proceso completado! Ahora:"
echo "1. Sube el archivo ${APP_NAME}-${VERSION}.zip como release v$VERSION en GitHub"
echo "2. Actualiza appcast.xml con la información mostrada arriba"
echo "3. Haz commit y push de appcast.xml" 