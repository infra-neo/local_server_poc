#!/bin/bash

# Script para configurar RAC Provider y Endpoints en Authentik
# Ejecutar después de que Authentik esté funcionando

set -e

AUTHENTIK_URL="https://gate.kappa4.com"
AUTHENTIK_TOKEN="" # Necesitará generar un token API

echo "🚀 Configurando RAC Provider y Endpoints..."

# Función para hacer requests a Authentik API
authentik_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    curl -s -X "$method" \
        -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
        -H "Content-Type: application/json" \
        "$AUTHENTIK_URL/api/v3/$endpoint" \
        ${data:+-d "$data"}
}

# 1. Obtener Outpost ID
echo "📡 Obteniendo Outpost ID..."
OUTPOST_ID=$(authentik_api GET "outposts/instances/" | jq -r '.results[0].pk // empty')

if [ -z "$OUTPOST_ID" ]; then
    echo "❌ Error: No se encontró Outpost"
    exit 1
fi

echo "✅ Outpost ID: $OUTPOST_ID"

# 2. Crear RAC Provider
echo "🔧 Creando RAC Provider..."
RAC_PROVIDER=$(cat <<EOF
{
    "name": "Windows-VMs-RAC",
    "settings": {}
}
EOF
)

PROVIDER_RESPONSE=$(authentik_api POST "providers/rac/" "$RAC_PROVIDER")
PROVIDER_ID=$(echo "$PROVIDER_RESPONSE" | jq -r '.pk // empty')

if [ -z "$PROVIDER_ID" ]; then
    echo "❌ Error creando RAC Provider"
    exit 1
fi

echo "✅ RAC Provider creado: $PROVIDER_ID"

# 3. Crear Endpoint RAC para VM Windows
echo "🖥️ Creando Endpoint RAC..."
RAC_ENDPOINT=$(cat <<EOF
{
    "name": "Windows-VM-Principal",
    "provider": $PROVIDER_ID,
    "protocol": "rdp",
    "host": "100.95.223.18",
    "port": 3389,
    "auth_mode": "static",
    "settings": {
        "username": "soporte",
        "password": "Neo123!!!"
    }
}
EOF
)

ENDPOINT_RESPONSE=$(authentik_api POST "providers/rac/endpoints/" "$RAC_ENDPOINT")
ENDPOINT_ID=$(echo "$ENDPOINT_RESPONSE" | jq -r '.pk // empty')

if [ -z "$ENDPOINT_ID" ]; then
    echo "❌ Error creando Endpoint RAC"
    exit 1
fi

echo "✅ Endpoint RAC creado: $ENDPOINT_ID"

# 4. Crear Aplicación
echo "📱 Creando Aplicación RAC..."
RAC_APPLICATION=$(cat <<EOF
{
    "name": "Remote Desktop",
    "slug": "remote-desktop",
    "provider": $PROVIDER_ID,
    "meta_description": "Acceso remoto a escritorios Windows",
    "meta_icon": "fa://desktop",
    "policy_engine_mode": "any",
    "group": ""
}
EOF
)

APP_RESPONSE=$(authentik_api POST "core/applications/" "$RAC_APPLICATION")
APP_ID=$(echo "$APP_RESPONSE" | jq -r '.pk // empty')

if [ -z "$APP_ID" ]; then
    echo "❌ Error creando Aplicación"
    exit 1
fi

echo "✅ Aplicación RAC creada: $APP_ID"

# 5. Asignar Outpost al Provider
echo "🔗 Asignando Outpost al Provider..."
ASSIGN_OUTPOST=$(cat <<EOF
{
    "providers": [$PROVIDER_ID]
}
EOF
)

authentik_api PATCH "outposts/instances/$OUTPOST_ID/" "$ASSIGN_OUTPOST"

echo ""
echo "🎉 ¡Configuración RAC completada!"
echo ""
echo "📋 Resumen:"
echo "- RAC Provider ID: $PROVIDER_ID"
echo "- Endpoint ID: $ENDPOINT_ID"
echo "- Aplicación ID: $APP_ID"
echo "- Outpost ID: $OUTPOST_ID"
echo ""
echo "🌐 URL de acceso:"
echo "https://gate.kappa4.com/application/o/remote-desktop/"
echo ""
echo "🔑 Credenciales Windows:"
echo "Usuario: soporte"
echo "Password: Neo123!!!"