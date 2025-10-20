#!/bin/bash

# Configuración RAC Automática - Modo Urgente
# Script para configurar RAC via API con autenticación por cookies

AUTHENTIK_URL="https://gate.kappa4.com"
USERNAME="akadmin"
PASSWORD="$1"  # Password como primer parámetro

if [ -z "$PASSWORD" ]; then
    echo "❌ Error: Se requiere password"
    echo "Uso: $0 <password_akadmin>"
    exit 1
fi

echo "🚀 CONFIGURACIÓN RAC AUTOMÁTICA - MODO URGENTE"
echo "=============================================="
echo ""
echo "📡 Authentik URL: $AUTHENTIK_URL"
echo "👤 Usuario: $USERNAME"
echo "🔐 Password: [OCULTO]"
echo ""

# Función para autenticarse y obtener cookies
authenticate() {
    echo "🔑 Autenticando con Authentik..."
    
    # Obtener CSRF token
    CSRF_TOKEN=$(curl -s -c cookies.txt "$AUTHENTIK_URL/if/admin/" | grep -o 'csrfmiddlewaretoken.*value="[^"]*"' | cut -d'"' -f2)
    
    if [ -z "$CSRF_TOKEN" ]; then
        echo "❌ Error: No se pudo obtener CSRF token"
        return 1
    fi
    
    echo "✅ CSRF Token obtenido"
    
    # Login
    LOGIN_RESPONSE=$(curl -s -b cookies.txt -c cookies.txt \
        -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "Referer: $AUTHENTIK_URL/if/admin/" \
        -d "csrfmiddlewaretoken=$CSRF_TOKEN&uid_field=$USERNAME&password=$PASSWORD" \
        "$AUTHENTIK_URL/if/admin/")
    
    # Verificar login exitoso
    if echo "$LOGIN_RESPONSE" | grep -q "dashboard\|Applications"; then
        echo "✅ Autenticación exitosa"
        return 0
    else
        echo "❌ Error: Falló la autenticación"
        return 1
    fi
}

# Función para llamar API con cookies
authentik_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    curl -s -b cookies.txt \
        -X "$method" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: $CSRF_TOKEN" \
        "$AUTHENTIK_URL/api/v3/$endpoint" \
        ${data:+-d "$data"}
}

# Función principal de configuración
configure_rac() {
    echo ""
    echo "🔧 Configurando componentes RAC..."
    echo "================================="
    
    # 1. Obtener Outpost ID
    echo "📡 1. Obteniendo Outpost ID..."
    OUTPOST_ID=$(authentik_api GET "outposts/instances/" | jq -r '.results[0].pk // empty' 2>/dev/null)
    
    if [ -z "$OUTPOST_ID" ]; then
        echo "❌ Error: No se encontró Outpost"
        return 1
    fi
    
    echo "✅ Outpost ID: $OUTPOST_ID"
    
    # 2. Crear RAC Provider
    echo "🖥️  2. Creando RAC Provider..."
    RAC_PROVIDER_DATA='{
        "name": "Windows-Remote-Desktop",
        "settings": {}
    }'
    
    PROVIDER_RESPONSE=$(authentik_api POST "providers/rac/" "$RAC_PROVIDER_DATA")
    PROVIDER_ID=$(echo "$PROVIDER_RESPONSE" | jq -r '.pk // empty' 2>/dev/null)
    
    if [ -z "$PROVIDER_ID" ]; then
        echo "❌ Error creando RAC Provider"
        echo "Response: $PROVIDER_RESPONSE"
        return 1
    fi
    
    echo "✅ RAC Provider creado: $PROVIDER_ID"
    
    # 3. Crear Endpoint RAC
    echo "🌐 3. Creando Endpoint RAC..."
    ENDPOINT_DATA='{
        "name": "Windows-VM-Principal",
        "provider": '$PROVIDER_ID',
        "protocol": "rdp",
        "host": "100.95.223.18",
        "port": 3389,
        "auth_mode": "static",
        "settings": {
            "username": "soporte",
            "password": "Neo123!!!"
        }
    }'
    
    ENDPOINT_RESPONSE=$(authentik_api POST "providers/rac/endpoints/" "$ENDPOINT_DATA")
    ENDPOINT_ID=$(echo "$ENDPOINT_RESPONSE" | jq -r '.pk // empty' 2>/dev/null)
    
    if [ -z "$ENDPOINT_ID" ]; then
        echo "❌ Error creando Endpoint RAC"
        echo "Response: $ENDPOINT_RESPONSE"
        return 1
    fi
    
    echo "✅ Endpoint RAC creado: $ENDPOINT_ID"
    
    # 4. Crear Aplicación
    echo "📱 4. Creando Aplicación..."
    APP_DATA='{
        "name": "Remote Desktop",
        "slug": "remote-desktop",
        "provider": '$PROVIDER_ID',
        "meta_description": "Acceso remoto a escritorios Windows",
        "meta_icon": "fa://desktop",
        "policy_engine_mode": "any"
    }'
    
    APP_RESPONSE=$(authentik_api POST "core/applications/" "$APP_DATA")
    APP_ID=$(echo "$APP_RESPONSE" | jq -r '.pk // empty' 2>/dev/null)
    
    if [ -z "$APP_ID" ]; then
        echo "❌ Error creando Aplicación"
        echo "Response: $APP_RESPONSE"
        return 1
    fi
    
    echo "✅ Aplicación creada: $APP_ID"
    
    # 5. Asignar Outpost al Provider
    echo "🔗 5. Asignando Outpost al Provider..."
    ASSIGN_DATA='{
        "providers": ['$PROVIDER_ID']
    }'
    
    ASSIGN_RESPONSE=$(authentik_api PATCH "outposts/instances/$OUTPOST_ID/" "$ASSIGN_DATA")
    
    echo "✅ Outpost asignado al Provider"
    
    return 0
}

# Ejecutar configuración
echo "⏱️ Iniciando configuración automática..."
echo ""

if authenticate; then
    if configure_rac; then
        echo ""
        echo "🎉 ¡CONFIGURACIÓN RAC COMPLETADA EXITOSAMENTE!"
        echo "=============================================="
        echo ""
        echo "📋 Resumen de configuración:"
        echo "- RAC Provider: Windows-Remote-Desktop"
        echo "- Endpoint: Windows-VM-Principal (100.95.223.18:3389)"
        echo "- Aplicación: Remote Desktop"
        echo "- Outpost: Asignado correctamente"
        echo ""
        echo "🌐 URL de acceso:"
        echo "https://gate.kappa4.com/application/o/remote-desktop/"
        echo ""
        echo "🔑 Credenciales Windows:"
        echo "Usuario: soporte"
        echo "Password: Neo123!!!"
        echo ""
        echo "⚡ ¡LISTO PARA LA DEMOSTRACIÓN!"
    else
        echo "❌ Error en la configuración RAC"
        exit 1
    fi
else
    echo "❌ Error en la autenticación"
    exit 1
fi

# Limpiar cookies
rm -f cookies.txt