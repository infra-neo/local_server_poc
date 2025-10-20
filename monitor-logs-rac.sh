#!/bin/bash

# Monitor de Logs RAC - Ejecutar en terminal separada
echo "🔍 MONITOR DE LOGS RAC OUTPOST"
echo "=============================="
echo ""
echo "📊 Estados a observar:"
echo "✅ 'Successfully connected websocket' - Outpost conectado"
echo "🔧 'Creating new connection' - Nueva sesión RAC iniciando"
echo "🖥️  'RDP connection established' - Conexión RDP exitosa"
echo "❌ 'Connection failed' - Error de conexión"
echo "⚠️  'TLS handshake error' - Intentos externos (ignorar)"
echo ""
echo "🚀 Iniciando monitoreo en tiempo real..."
echo "========================================"
echo ""

# Filtrar logs relevantes para RAC
docker logs -f kolaboree-authentik-outpost 2>&1 | while read line; do
    # Timestamp
    timestamp=$(date '+%H:%M:%S')
    
    # Colorear según tipo de evento
    if echo "$line" | grep -q "Successfully connected"; then
        echo -e "[$timestamp] 🟢 $line"
    elif echo "$line" | grep -q "websocket"; then
        echo -e "[$timestamp] 🔗 $line"
    elif echo "$line" | grep -q "RDP\|rdp"; then
        echo -e "[$timestamp] 🖥️  $line"
    elif echo "$line" | grep -q "Connection\|connection"; then
        echo -e "[$timestamp] 🔧 $line"
    elif echo "$line" | grep -q "error\|Error\|ERROR"; then
        echo -e "[$timestamp] ❌ $line"
    elif echo "$line" | grep -q "warning\|Warning\|WARN"; then
        echo -e "[$timestamp] ⚠️  $line"
    elif echo "$line" | grep -q "TLS handshake"; then
        echo -e "[$timestamp] 🔒 $line (externo - ignorar)"
    else
        echo -e "[$timestamp] ℹ️  $line"
    fi
done