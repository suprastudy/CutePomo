#!/bin/bash

# Script para generar llaves de Sparkle EdDSA
# Asegurate de tener Sparkle instalado: brew install sparkle

echo "🔑 Generando llaves de Sparkle EdDSA..."

# Crear directorio para las llaves si no existe
mkdir -p "$(dirname "$0")/../keys"

# Generar las llaves EdDSA
GENERATE_KEYS_PATH="/usr/local/Caskroom/sparkle/2.7.1/bin/generate_keys"

if [[ -f "$GENERATE_KEYS_PATH" ]]; then
    "$GENERATE_KEYS_PATH" "$(dirname "$0")/../keys/sparkle_keys"
    echo "✅ Llaves generadas en: keys/"
    echo ""
    echo "📋 IMPORTANTE: Copia la llave pública al Info.plist:"
    echo "   Reemplaza PLACEHOLDER_PUBLIC_KEY con:"
    cat "$(dirname "$0")/../keys/sparkle_keys.pub"
    echo ""
    echo "🔒 MANTÉN LA LLAVE PRIVADA SEGURA:"
    echo "   La llave privada está en: keys/sparkle_keys"
    echo "   Agrégala como SECRET en GitHub: SPARKLE_PRIVATE_KEY"
elif command -v generate_keys &> /dev/null; then
    generate_keys "$(dirname "$0")/../keys/sparkle_keys"
    echo "✅ Llaves generadas en: keys/"
    echo ""
    echo "📋 IMPORTANTE: Copia la llave pública al Info.plist:"
    echo "   Reemplaza PLACEHOLDER_PUBLIC_KEY con:"
    cat "$(dirname "$0")/../keys/sparkle_keys.pub"
    echo ""
    echo "🔒 MANTÉN LA LLAVE PRIVADA SEGURA:"
    echo "   La llave privada está en: keys/sparkle_keys"
    echo "   Agrégala como SECRET en GitHub: SPARKLE_PRIVATE_KEY"
else
    echo "❌ Error: generate_keys no encontrado"
    echo "💡 Instala Sparkle con: brew install sparkle"
    echo "💡 O visita: https://sparkle-project.org/"
fi 