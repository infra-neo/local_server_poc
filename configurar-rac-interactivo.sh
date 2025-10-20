#!/bin/bash

# Script de Configuración RAC - Guía Interactiva
# Este script te ayudará a configurar RAC paso a paso

echo "🚀 CONFIGURACIÓN RAG HTML5 - ASISTENTE INTERACTIVO"
echo "=================================================="
echo ""
echo "📋 INFORMACIÓN NECESARIA:"
echo "--------------------------------"
echo "🌐 Authentik Admin URL: https://gate.kappa4.com/if/admin/"
echo "👤 Usuario Admin: akadmin"
echo "🔑 Password: [tu password de akadmin]"
echo "🖥️  VM Windows IP: 100.95.223.18"
echo "🔐 Credenciales VM: soporte / Neo123!!!"
echo "🆔 Outpost ID: c431906a-976b-4d42-bb79-bc134af3c844"
echo ""

# Función para monitorear logs en background
monitor_logs() {
    echo "🔍 Iniciando monitoreo de logs..."
    docker logs -f kolaboree-authentik-outpost &
    LOG_PID=$!
    echo "✅ Logs monitoreándose (PID: $LOG_PID)"
}

# Función para detener logs
stop_logs() {
    if [ ! -z "$LOG_PID" ]; then
        kill $LOG_PID 2>/dev/null
        echo "⏹️  Monitoreo de logs detenido"
    fi
}

echo "¿Quieres que inicie el monitoreo de logs? (y/n): "
read -r start_logs

if [[ $start_logs =~ ^[Yy]$ ]]; then
    monitor_logs
fi

echo ""
echo "📝 PASOS A SEGUIR:"
echo "=================="
echo ""
echo "1️⃣  ACCEDER A AUTHENTIK ADMIN"
echo "   → Abrir: https://gate.kappa4.com/if/admin/"
echo "   → Login con: akadmin"
echo ""
read -p "✅ ¿Ya accediste a Authentik Admin? (Enter para continuar)"

echo ""
echo "2️⃣  CREAR RAC PROVIDER"
echo "   → Menu: Applications → Providers"
echo "   → Botón: Create → RAC Provider"
echo "   → Name: Windows-Remote-Desktop"
echo "   → Settings: {} (vacío)"
echo "   → Save"
echo ""
read -p "✅ ¿Ya creaste el RAC Provider? (Enter para continuar)"

echo ""
echo "3️⃣  CREAR ENDPOINT RAC"
echo "   → Seleccionar el provider recién creado"
echo "   → Tab: RAC Endpoints → Create"
echo "   → Name: Windows-VM-Principal"
echo "   → Protocol: RDP"
echo "   → Host: 100.95.223.18"
echo "   → Port: 3389"
echo "   → Auth mode: Static"
echo "   → Username: soporte"
echo "   → Password: Neo123!!!"
echo "   → Save"
echo ""
read -p "✅ ¿Ya creaste el Endpoint? (Enter para continuar)"

echo ""
echo "4️⃣  CREAR APLICACIÓN"
echo "   → Menu: Applications → Applications"
echo "   → Create"
echo "   → Name: Remote Desktop"
echo "   → Slug: remote-desktop"
echo "   → Provider: Windows-Remote-Desktop"
echo "   → Icon: fa://desktop"
echo "   → Save"
echo ""
read -p "✅ ¿Ya creaste la Aplicación? (Enter para continuar)"

echo ""
echo "5️⃣  ASIGNAR OUTPOST"
echo "   → Menu: Applications → Outposts"
echo "   → Seleccionar tu outpost existente"
echo "   → Tab: Providers"
echo "   → Agregar: Windows-Remote-Desktop"
echo "   → Save"
echo ""
read -p "✅ ¿Ya asignaste el Outpost? (Enter para continuar)"

echo ""
echo "🎯 PRUEBA FINAL"
echo "==============="
echo "🌐 URL de prueba: https://gate.kappa4.com/application/o/remote-desktop/"
echo ""
read -p "¿Quieres que detenga el monitoreo de logs? (Enter para detener)"

stop_logs

echo ""
echo "🎉 ¡CONFIGURACIÓN COMPLETADA!"
echo "============================"
echo ""
echo "✅ Sistema RAC HTML5 configurado"
echo "🌐 Acceso: https://gate.kappa4.com/application/o/remote-desktop/"
echo "🔑 Credenciales VM: soporte / Neo123!!!"
echo ""
echo "📊 Si hay problemas, revisar:"
echo "   → docker logs kolaboree-authentik-outpost --tail 20"
echo "   → Verificar que el Outpost esté asignado al Provider"
echo ""