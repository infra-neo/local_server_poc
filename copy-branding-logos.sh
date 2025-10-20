#!/bin/bash

# Script para copiar logos de branding Neogenesys a Authentik
# Uso: ./copy-branding-logos.sh

echo "🎨 COPIANDO LOGOS DE BRANDING NEOGENESYS"
echo "======================================="

# Verificar que el contenedor esté ejecutándose
if ! docker ps | grep -q "kolaboree-authentik-server"; then
    echo "❌ Error: El contenedor kolaboree-authentik-server no está ejecutándose"
    exit 1
fi

echo "📂 Copiando logos desde /media/branding/logos/ a /web/dist/assets/icons/..."

# Copiar archivos como root para evitar problemas de permisos
docker exec -u root kolaboree-authentik-server bash -c "
    # Copiar todos los logos de branding
    cp /media/branding/logos/* /web/dist/assets/icons/
    
    # Ajustar permisos para que authentik pueda acceder
    chown authentik:authentik /web/dist/assets/icons/neo*.svg
    
    echo '✅ Logos copiados exitosamente'
    echo '📋 Archivos de Neogenesys disponibles:'
    ls -la /web/dist/assets/icons/neo*.svg
"

echo ""
echo "🚀 ¡Logos de branding copiados exitosamente!"
echo "   Los logos de Neogenesys ya están disponibles en Authentik"
echo "   Ruta: /web/dist/assets/icons/"
echo ""
echo "📝 Archivos disponibles:"
echo "   - neo-genesys-logo.svg"
echo "   - neogenesys-logo.svg"  
echo "   - neogenesys-oficial.svg"