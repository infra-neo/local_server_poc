#!/bin/bash
# Script para subir imágenes de branding a Authentik

echo "🎨 SUBIENDO IMÁGENES DE BRANDING A AUTHENTIK"
echo "============================================"

# Directorio de origen (local)
LOCAL_BRANDING_DIR="/home/infra/local_server_poc/authentik/branding"
LOCAL_LOGOS_DIR="$LOCAL_BRANDING_DIR/logos"
LOCAL_STATIC_DIR="$LOCAL_BRANDING_DIR/static"

# Directorio de destino en el contenedor
CONTAINER_ICONS_DIR="/web/dist/assets/icons/"
CONTAINER_STATIC_DIR="/web/dist/static/"

echo "1. 📋 Verificando archivos disponibles..."
echo ""
echo "Logos disponibles:"
ls -la "$LOCAL_LOGOS_DIR" 2>/dev/null || echo "❌ No se encontró directorio de logos"

echo ""
echo "Archivos estáticos disponibles:"
ls -la "$LOCAL_STATIC_DIR" 2>/dev/null || echo "❌ No se encontró directorio estático"

echo ""
echo "2. 📁 Verificando directorio de destino en contenedor..."
docker exec kolaboree-authentik-server ls -la "$CONTAINER_ICONS_DIR"

echo ""
echo "3. 🚀 Subiendo imágenes de logos al contenedor..."

# Subir logos como iconos de marca
if [ -f "$LOCAL_LOGOS_DIR/neogenesys-logo.svg" ]; then
    echo "📤 Subiendo neogenesys-logo.svg como brand.svg..."
    docker cp "$LOCAL_LOGOS_DIR/neogenesys-logo.svg" kolaboree-authentik-server:"$CONTAINER_ICONS_DIR/brand.svg"
    echo "✅ brand.svg actualizado"
fi

if [ -f "$LOCAL_LOGOS_DIR/neo-genesys-logo.svg" ]; then
    echo "📤 Subiendo neo-genesys-logo.svg como icon_left_brand.svg..."
    docker cp "$LOCAL_LOGOS_DIR/neo-genesys-logo.svg" kolaboree-authentik-server:"$CONTAINER_ICONS_DIR/icon_left_brand.svg"
    echo "✅ icon_left_brand.svg actualizado"
fi

# Subir como icono principal también
if [ -f "$LOCAL_LOGOS_DIR/neogenesys-logo.svg" ]; then
    echo "📤 Subiendo neogenesys-logo.svg como icon.svg..."
    docker cp "$LOCAL_LOGOS_DIR/neogenesys-logo.svg" kolaboree-authentik-server:"$CONTAINER_ICONS_DIR/icon.svg"
    echo "✅ icon.svg actualizado"
fi

echo ""
echo "4. 🎨 Subiendo archivos CSS personalizados..."

# Subir CSS personalizado
if [ -f "$LOCAL_STATIC_DIR/custom.css" ]; then
    echo "📤 Subiendo custom.css..."
    docker cp "$LOCAL_STATIC_DIR/custom.css" kolaboree-authentik-server:"$CONTAINER_STATIC_DIR/custom.css"
    echo "✅ custom.css subido"
fi

if [ -f "$LOCAL_STATIC_DIR/neogenesys.css" ]; then
    echo "📤 Subiendo neogenesys.css..."
    docker cp "$LOCAL_STATIC_DIR/neogenesys.css" kolaboree-authentik-server:"$CONTAINER_STATIC_DIR/neogenesys.css"
    echo "✅ neogenesys.css subido"
fi

# Subir favicon si existe
if [ -f "$LOCAL_STATIC_DIR/favicon.ico" ]; then
    echo "📤 Subiendo favicon.ico..."
    docker cp "$LOCAL_STATIC_DIR/favicon.ico" kolaboree-authentik-server:"$CONTAINER_STATIC_DIR/favicon.ico"
    echo "✅ favicon.ico subido"
fi

echo ""
echo "5. 🔧 Ajustando permisos en el contenedor..."
docker exec kolaboree-authentik-server chown -R root:root "$CONTAINER_ICONS_DIR"
docker exec kolaboree-authentik-server chmod -R 644 "$CONTAINER_ICONS_DIR"*

echo ""
echo "6. 📋 Verificando archivos subidos..."
echo "Iconos en el contenedor:"
docker exec kolaboree-authentik-server ls -la "$CONTAINER_ICONS_DIR" | grep -E "(brand|icon|neogenesys)"

echo ""
echo "Archivos estáticos en el contenedor:"
docker exec kolaboree-authentik-server ls -la "$CONTAINER_STATIC_DIR" | grep -E "(custom|neogenesys|favicon)" 2>/dev/null || echo "No se encontraron archivos CSS personalizados"

echo ""
echo "7. 🔄 Reiniciando Authentik para aplicar cambios..."
docker-compose restart authentik-server

echo ""
echo "✅ PROCESO COMPLETADO"
echo "===================="
echo ""
echo "🎯 PRÓXIMOS PASOS:"
echo "1. Esperar a que Authentik reinicie (1-2 minutos)"
echo "2. Ir a: https://34.68.124.46:9443/if/admin/"
echo "3. Ir a: System > Tenants"
echo "4. Editar el tenant 'authentik-default'"
echo "5. En 'Branding settings':"
echo "   • Logo: /static/dist/assets/icons/brand.svg"
echo "   • Favicon: /static/dist/static/favicon.ico"
echo "6. Guardar cambios"
echo ""
echo "🌟 Para CSS personalizado:"
echo "1. Ir a: System > Tenants"
echo "2. En 'Web Certificate': seleccionar certificado"
echo "3. En 'Attributes', agregar:"
echo "   • Key: settings"
echo "   • Value: {"
echo "     \"theme\": {"
echo "       \"base\": \"authentik\","
echo "       \"application\": \"neogenesys\""
echo "     }"
echo "   }"