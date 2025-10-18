#!/bin/bash
# Guía para configurar el branding en Authentik

echo "🎨 GUÍA DE CONFIGURACIÓN DE BRANDING EN AUTHENTIK"
echo "================================================="

echo ""
echo "✅ IMÁGENES SUBIDAS CORRECTAMENTE:"
echo "├── brand.svg (Logo principal)"
echo "├── icon.svg (Icono principal)" 
echo "└── icon_left_brand.svg (Logo lateral)"

echo ""
echo "🔧 CONFIGURACIÓN EN AUTHENTIK UI:"
echo "================================="

echo ""
echo "PASO 1: Acceder a la configuración de Tenants"
echo "─────────────────────────────────────────────"
echo "1. Ir a: https://34.68.124.46:9443/if/admin/"
echo "2. Login como akadmin"
echo "3. En el menú lateral: System > Tenants"
echo "4. Hacer clic en 'authentik-default' para editarlo"

echo ""
echo "PASO 2: Configurar Branding Settings"
echo "───────────────────────────────────"
echo "En la sección 'Branding settings':"
echo ""
echo "📋 CONFIGURACIÓN EXACTA:"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│ Logo: /static/dist/assets/icons/brand.svg               │"
echo "│ Favicon: /static/dist/assets/icons/icon.svg             │"
echo "│ Title: Kolaboree                                        │"
echo "│ Branding title: Neo Genesys                             │"
echo "│ Branding logo: /static/dist/assets/icons/brand.svg      │"
echo "└─────────────────────────────────────────────────────────┘"

echo ""
echo "PASO 3: Configurar tema personalizado (OPCIONAL)"
echo "──────────────────────────────────────────────"
echo "En la sección 'Attributes':"
echo "1. Hacer clic en 'Add entry'"
echo "2. Key: settings"
echo "3. Value (copiar exactamente):"
echo '{'
echo '  "theme": {'
echo '    "base": "authentik",'
echo '    "application": "neogenesys"'
echo '  }'
echo '}'

echo ""
echo "PASO 4: Guardar cambios"
echo "──────────────────────"
echo "1. Hacer clic en 'Update' al final del formulario"
echo "2. Esperar confirmación de guardado"

echo ""
echo "PASO 5: Verificar el branding"
echo "────────────────────────────"
echo "1. Abrir nueva pestaña en modo incógnito"
echo "2. Ir a: https://34.68.124.46:9443/"
echo "3. Verificar que aparezca el logo de Neo Genesys"
echo "4. Verificar el favicon en la pestaña del navegador"

echo ""
echo "🔍 RUTAS DE IMÁGENES DISPONIBLES:"
echo "================================"
echo "Para usar en Authentik:"
echo "├── Logo principal: /static/dist/assets/icons/brand.svg"
echo "├── Icono: /static/dist/assets/icons/icon.svg"
echo "├── Logo lateral: /static/dist/assets/icons/icon_left_brand.svg"
echo "└── Logo superior: /static/dist/assets/icons/icon_top_brand.svg"

echo ""
echo "💡 CONSEJOS:"
echo "============"
echo "• Si no ves cambios inmediatamente, limpia cache del navegador (Ctrl+F5)"
echo "• Los archivos SVG son mejores para logos (escalables)"
echo "• El branding afecta todas las páginas de Authentik"
echo "• Puedes usar diferentes logos para diferentes posiciones"

echo ""
echo "🚨 SOLUCIÓN DE PROBLEMAS:"
echo "========================="
echo "Si el logo no aparece:"
echo "1. Verificar que la ruta sea exacta: /static/dist/assets/icons/brand.svg"
echo "2. Limpiar cache del navegador"
echo "3. Verificar que el archivo esté en el contenedor:"
echo "   docker exec kolaboree-authentik-server ls -la /web/dist/assets/icons/brand.svg"

echo ""
echo "✅ VERIFICACIÓN FINAL:"
echo "====================="
echo "• Logo aparece en página de login ✓"
echo "• Favicon aparece en pestaña ✓"
echo "• Título personalizado aparece ✓"

echo ""
echo "🎯 SIGUIENTE PASO:"
echo "=================="
echo "Una vez configurado el branding, probar el flujo completo:"
echo "1. Logout de Authentik"
echo "2. Ir a: https://34.68.124.46:9443/application/o/guacamole/"
echo "3. Login con: soporte@kolaboree.local / Neo123!!!"
echo "4. Verificar acceso a Guacamole con branding de Neo Genesys"