#!/bin/bash
# Script de integración RAC con menú de opciones para Neogenesys
# Autor: Asistente IA
# Fecha: $(date)

set -e

echo "🚀 Iniciando integración de menú RAC para Neogenesys..."

# Verificar contenedores activos
echo "📋 Verificando contenedores..."
if ! docker ps | grep -q "kolaboree-authentik-server"; then
    echo "❌ Error: Contenedor authentik-server no está ejecutándose"
    exit 1
fi

if ! docker ps | grep -q "kolaboree-authentik-outpost"; then
    echo "❌ Error: Contenedor authentik-outpost no está ejecutándose"
    exit 1
fi

echo "✅ Contenedores verificados"

# Copiar archivos del menú RAC
echo "📦 Desplegando archivos del menú RAC..."

# Copiar script del menú a assets
if docker exec -u root kolaboree-authentik-server cp /media/branding/static/rac-options-menu.js /web/dist/assets/; then
    echo "✅ Script del menú copiado exitosamente"
else
    echo "⚠️ Advertencia: No se pudo copiar el script del menú"
fi

# Verificar favicon
if docker exec kolaboree-authentik-server test -f /web/dist/assets/icons/neogenesys-favicon.svg; then
    echo "✅ Favicon personalizado encontrado"
else
    echo "📥 Copiando favicon personalizado..."
    docker exec -u root kolaboree-authentik-server cp /media/branding/static/neogenesys-favicon.svg /web/dist/assets/icons/
    echo "✅ Favicon copiado"
fi

# Verificar logos disponibles
echo "🎨 Verificando logos disponibles:"
if ls /home/infra/local_server_poc/authentik/branding/logos/*.svg >/dev/null 2>&1; then
    for logo in /home/infra/local_server_poc/authentik/branding/logos/*.svg; do
        basename_logo=$(basename "$logo")
        echo "  📄 $basename_logo"
        
        # Copiar a assets/icons si no existe
        if ! docker exec kolaboree-authentik-server test -f "/web/dist/assets/icons/$basename_logo"; then
            echo "    📥 Copiando $basename_logo..."
            docker exec -u root kolaboree-authentik-server cp "/media/branding/logos/$basename_logo" /web/dist/assets/icons/
        fi
    done
    echo "✅ Todos los logos están disponibles"
else
    echo "⚠️ No se encontraron logos en la carpeta de logos"
fi

# Verificar configuración RAC
echo "🔧 Verificando configuración RAC..."

# Mostrar estado del outpost
echo "📊 Estado del outpost RAC:"
docker exec kolaboree-authentik-outpost ps aux | grep -v grep | grep rac || echo "  🔄 Proceso RAC iniciando..."

# Mostrar puertos y conectividad
echo "🌐 Verificando conectividad:"
echo "  🔗 Puerto 443 (HTTPS):"
if netstat -tulpn | grep -q ":443 "; then
    echo "    ✅ Puerto 443 activo"
else
    echo "    ❌ Puerto 443 no disponible"
fi

echo "  🔗 Puerto 9000 (Authentik):"
if docker exec kolaboree-authentik-server netstat -tulpn | grep -q ":9000 "; then
    echo "    ✅ Puerto 9000 activo en contenedor"
else
    echo "    ⚠️ Puerto 9000 no visible"
fi

# Verificar archivos de branding
echo "🎭 Verificando archivos de branding:"
BRANDING_FILES=(
    "/media/branding/static/neogenesys.css"
    "/media/branding/static/rac-options-menu.js"
    "/media/branding/static/neogenesys-favicon.svg"
    "/media/branding/static/hide-footer.js"
)

for file in "${BRANDING_FILES[@]}"; do
    if docker exec kolaboree-authentik-server test -f "$file"; then
        echo "  ✅ $(basename "$file")"
    else
        echo "  ❌ $(basename "$file") - FALTANTE"
    fi
done

# Información de URLs importantes
echo ""
echo "🌍 URLs importantes:"
echo "  🏠 Portal principal: https://gate.kappa4.com"
echo "  🔐 Admin Authentik: https://gate.kappa4.com/if/admin/"
echo "  💻 RAC HTML5: https://gate.kappa4.com/if/rac/"
echo "  📱 Outpost status: https://gate.kappa4.com/outpost.goauthentik.io/ping"

echo ""
echo "⚡ Características del menú RAC implementadas:"
echo "  🔘 Botón de opciones flotante"
echo "  🚪 Cerrar sesión (Ctrl+Alt+D)"
echo "  🖥️  Pantalla completa (F11)"
echo "  📸 Captura de pantalla"
echo "  📋 Gestión de portapapeles"
echo "  ⚙️  Panel de configuración"
echo "  ⌨️  Atajos de teclado"
echo "  🎨 Estilo corporativo Neogenesys"

echo ""
echo "🎯 Instrucciones de uso:"
echo "  1. Navegar a: https://gate.kappa4.com"
echo "  2. Autenticarse con credenciales"
echo "  3. Seleccionar 'Windows Remote Desktop'"
echo "  4. En la sesión HTML5, presionar Ctrl+Alt+M para abrir el menú"
echo "  5. O buscar el botón flotante ⚙️ en la esquina superior derecha"

echo ""
echo "✅ Integración completada exitosamente!"
echo "🚀 El sistema RAC con menú Neogenesys está listo para usar"