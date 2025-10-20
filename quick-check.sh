#!/bin/bash
# Script de verificación rápida RAC Neogenesys
# Ejecutar: ./quick-check.sh

clear
echo "🔍 Neogenesys RAC - Verificación Rápida"
echo "======================================"
echo "Fecha: $(date)"
echo ""

# Función para mostrar estado
check_status() {
    if [ $1 -eq 0 ]; then
        echo "✅ $2"
    else
        echo "❌ $2"
    fi
}

# 1. Verificar contenedores
echo "📦 CONTENEDORES:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep kolaboree | while read line; do
    if echo "$line" | grep -q "Up"; then
        echo "✅ $line"
    else
        echo "❌ $line"
    fi
done

echo ""

# 2. Verificar conectividad básica
echo "🌐 CONECTIVIDAD:"

# Puerto 443
if netstat -tulpn 2>/dev/null | grep -q ":443 "; then
    echo "✅ Puerto 443 (HTTPS) activo"
else
    echo "❌ Puerto 443 (HTTPS) inactivo"
fi

# Ping al Windows VM
if ping -c 1 100.95.223.18 >/dev/null 2>&1; then
    echo "✅ Windows VM (100.95.223.18) alcanzable"
else
    echo "❌ Windows VM (100.95.223.18) no alcanzable"
fi

# Puerto RDP
if timeout 3 bash -c "echo >/dev/tcp/100.95.223.18/3389" 2>/dev/null; then
    echo "✅ Puerto RDP (3389) accesible"
else
    echo "❌ Puerto RDP (3389) no accesible"
fi

echo ""

# 3. Verificar archivos importantes
echo "📁 ARCHIVOS IMPORTANTES:"

FILES_TO_CHECK=(
    "/home/infra/local_server_poc/authentik/branding/static/neogenesys.css:CSS Corporativo"
    "/home/infra/local_server_poc/authentik/branding/static/rac-options-menu.js:Menú RAC"
    "/home/infra/local_server_poc/authentik/branding/static/neogenesys-favicon.svg:Favicon"
    "/home/infra/local_server_poc/authentik/branding/logos/neogenesys-negative.svg:Logo Negativo"
    "/home/infra/local_server_poc/RAC_NEOGENESYS_GUIDE.md:Documentación"
)

for file_info in "${FILES_TO_CHECK[@]}"; do
    file_path=$(echo "$file_info" | cut -d: -f1)
    file_desc=$(echo "$file_info" | cut -d: -f2)
    
    if [ -f "$file_path" ]; then
        echo "✅ $file_desc"
    else
        echo "❌ $file_desc - FALTANTE"
    fi
done

echo ""

# 4. Verificar URLs importantes
echo "🌍 VERIFICACIÓN DE URLS:"

URLS_TO_CHECK=(
    "https://gate.kappa4.com:Portal Principal"
    "https://gate.kappa4.com/if/admin/:Panel Admin"
    "https://gate.kappa4.com/outpost.goauthentik.io/ping:Health Check"
)

for url_info in "${URLS_TO_CHECK[@]}"; do
    url=$(echo "$url_info" | cut -d: -f1-2)
    desc=$(echo "$url_info" | cut -d: -f3)
    
    if curl -s -k --connect-timeout 5 "$url" >/dev/null 2>&1; then
        echo "✅ $desc ($url)"
    else
        echo "❌ $desc ($url) - No responde"
    fi
done

echo ""

# 5. Información del sistema
echo "📊 INFORMACIÓN DEL SISTEMA:"
echo "🖥️  Hostname: $(hostname)"
echo "🌐 IP Principal: $(hostname -I | awk '{print $1}')"
echo "💾 Disco disponible: $(df -h / | awk 'NR==2 {print $4}') libre"
echo "🧠 Memoria disponible: $(free -h | awk 'NR==2 {print $7}') libre"
echo "⏰ Uptime: $(uptime -p)"

echo ""

# 6. Comandos útiles
echo "🛠️  COMANDOS ÚTILES:"
echo "📋 Ver logs RAC: docker logs -f kolaboree-authentik-outpost"
echo "🔄 Reiniciar RAC: docker restart kolaboree-authentik-outpost"
echo "🌐 Verificar NGINX: docker logs kolaboree-nginx"
echo "⚙️  Redeploy menú: ./scripts/deploy-rac-menu.sh"
echo "📖 Ver documentación: cat RAC_NEOGENESYS_GUIDE.md"

echo ""

# 7. Verificar menú desplegado
echo "🎮 VERIFICACIÓN MENÚ RAC:"
if docker exec kolaboree-authentik-server test -f "/web/dist/assets/rac-options-menu.js"; then
    menu_size=$(docker exec kolaboree-authentik-server stat -c%s "/web/dist/assets/rac-options-menu.js")
    echo "✅ Menú RAC desplegado (${menu_size} bytes)"
else
    echo "❌ Menú RAC no desplegado"
fi

echo ""

# 8. Resumen final
echo "🎯 RESUMEN EJECUTIVO:"

# Verificar contenedores críticos
outpost_running=$(docker ps | grep "kolaboree-authentik-outpost.*Up" | wc -l)
server_running=$(docker ps | grep "kolaboree-authentik-server.*Up" | wc -l)

# Verificar menú desplegado (con manejo de errores)
menu_deployed=0
if docker exec kolaboree-authentik-server test -f "/web/dist/assets/rac-options-menu.js" 2>/dev/null; then
    menu_deployed=1
fi

if [ "$outpost_running" -eq 1 ] && [ "$server_running" -eq 1 ] && [ "$menu_deployed" -eq 1 ]; then
    echo "🟢 SISTEMA OPERATIVO - RAC Neogenesys funcionando correctamente"
    echo "🚀 URLs de acceso:"
    echo "   👉 Portal: https://gate.kappa4.com"
    echo "   👉 Admin: https://gate.kappa4.com/if/admin/"
    echo ""
    echo "💡 Instrucciones rápidas:"
    echo "   1. Ir a https://gate.kappa4.com"
    echo "   2. Autenticarse"
    echo "   3. Seleccionar 'Windows Remote Desktop'"
    echo "   4. Usar Ctrl+Alt+M para abrir menú de opciones"
    echo "   5. O buscar el botón ⚙️ en la esquina superior derecha"
    echo ""
    echo "🎮 FUNCIONALIDADES DEL MENÚ RAC:"
    echo "   ⚙️  Botón de opciones flotante"
    echo "   🚪 Cerrar sesión (Ctrl+Alt+D)"
    echo "   �️  Pantalla completa (F11)"
    echo "   📸 Captura de pantalla"
    echo "   📋 Gestión de portapapeles"
    echo "   ⌨️  Atajos de teclado"
else
    echo "�🟡 SISTEMA REQUIERE ATENCIÓN:"
    echo "   📦 Contenedor outpost: $([ "$outpost_running" -eq 1 ] && echo "✅ OK" || echo "❌ FALLO")"
    echo "   📦 Contenedor server: $([ "$server_running" -eq 1 ] && echo "✅ OK" || echo "❌ FALLO")"
    echo "   🎮 Menú desplegado: $([ "$menu_deployed" -eq 1 ] && echo "✅ OK" || echo "❌ FALLO")"
fi

echo ""
echo "✨ Neogenesys - 25 Años de innovación tecnológica ✨"