#!/bin/bash
# Script para actualizar con el logo oficial de Neogenesys

echo "🎨 ACTUALIZANDO CON LOGO OFICIAL DE NEOGENESYS"
echo "=============================================="

# Directorio de origen
LOCAL_LOGOS_DIR="/home/infra/local_server_poc/authentik/branding/logos"
CONTAINER_ICONS_DIR="/web/dist/assets/icons/"

echo "1. 📤 Subiendo logo oficial de Neogenesys..."

# Subir el logo oficial como brand.svg
if [ -f "$LOCAL_LOGOS_DIR/neogenesys-oficial.svg" ]; then
    echo "📤 Subiendo neogenesys-oficial.svg como brand.svg..."
    docker cp "$LOCAL_LOGOS_DIR/neogenesys-oficial.svg" kolaboree-authentik-server:"$CONTAINER_ICONS_DIR/brand.svg"
    echo "✅ brand.svg actualizado con logo oficial"
fi

# También como icon.svg
if [ -f "$LOCAL_LOGOS_DIR/neogenesys-oficial.svg" ]; then
    echo "📤 Subiendo neogenesys-oficial.svg como icon.svg..."
    docker cp "$LOCAL_LOGOS_DIR/neogenesys-oficial.svg" kolaboree-authentik-server:"$CONTAINER_ICONS_DIR/icon.svg"
    echo "✅ icon.svg actualizado con logo oficial"
fi

# Y como icon_left_brand.svg
if [ -f "$LOCAL_LOGOS_DIR/neogenesys-oficial.svg" ]; then
    echo "📤 Subiendo neogenesys-oficial.svg como icon_left_brand.svg..."
    docker cp "$LOCAL_LOGOS_DIR/neogenesys-oficial.svg" kolaboree-authentik-server:"$CONTAINER_ICONS_DIR/icon_left_brand.svg"
    echo "✅ icon_left_brand.svg actualizado con logo oficial"
fi

echo ""
echo "2. 📋 Verificando archivos actualizados..."
docker exec kolaboree-authentik-server ls -la "$CONTAINER_ICONS_DIR" | grep -E "(brand|icon)\.svg"

echo ""
echo "3. 🔄 Reiniciando Authentik para aplicar cambios..."
docker-compose restart authentik-server

echo ""
echo "✅ LOGO OFICIAL ACTUALIZADO"
echo "=========================="

echo ""
echo "🎯 CONFIGURACIÓN CORREGIDA PARA AUTHENTIK:"
echo "========================================="
echo ""
echo "📋 EN SYSTEM > TENANTS > authentik-default:"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│ Logo: /static/dist/assets/icons/brand.svg               │"
echo "│ Favicon: /static/dist/assets/icons/icon.svg             │"
echo "│ Title: Kolaboree                                        │"
echo "│ Branding title: Neogenesys                              │"
echo "│ Branding logo: /static/dist/assets/icons/brand.svg      │"
echo "└─────────────────────────────────────────────────────────┘"

echo ""
echo "⚠️ IMPORTANTE: El nombre correcto es 'Neogenesys' (todo junto)"
echo "❌ NO usar: 'Neo Genesys' (separado)"
echo "✅ USAR: 'Neogenesys' (junto)"

echo ""
echo "🔧 PASOS PARA APLICAR EN AUTHENTIK:"
echo "1. Ir a: https://34.68.124.46:9443/if/admin/"
echo "2. System > Tenants > authentik-default"
echo "3. En 'Branding title' cambiar a: Neogenesys"
echo "4. Verificar que Logo apunte a: /static/dist/assets/icons/brand.svg"
echo "5. Guardar cambios"

echo ""
echo "✅ Logo oficial de Neogenesys listo para usar"