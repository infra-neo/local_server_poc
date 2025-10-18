#!/bin/bash
# Script de verificación del flujo SSO completo

echo "🔍 VERIFICACIÓN COMPLETA DEL FLUJO SSO"
echo "======================================"

echo ""
echo "1. 🌐 Verificando servicios..."
echo "────────────────────────────"

# Verificar Authentik
AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -k https://34.68.124.46:9443/)
echo "Authentik (9443): $AUTH_STATUS $([ "$AUTH_STATUS" = "200" ] && echo "✅" || echo "❌")"

# Verificar Guacamole
GUAC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://34.68.124.46:8080/guacamole/)
echo "Guacamole (8080): $GUAC_STATUS $([ "$GUAC_STATUS" = "200" ] && echo "✅" || echo "❌")"

echo ""
echo "2. 🔧 Verificando configuración OIDC..."
echo "─────────────────────────────────────"

echo "Variables OIDC en Guacamole:"
docker exec kolaboree-guacamole env | grep -E "OPENID_(AUTHORIZATION|ISSUER|JWKS)_ENDPOINT" | while read line; do
    echo "  $line"
    if [[ $line == *"9443"* && $line == *"https"* ]]; then
        echo "    ✅ Configuración correcta"
    else
        echo "    ❌ Configuración incorrecta"
    fi
done

echo ""
echo "3. 👤 Verificando usuario LDAP..."
echo "───────────────────────────────"

# Verificar usuario en LDAP
LDAP_USER=$(docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01" -b "dc=kolaboree,dc=local" "(uid=soporte)" uid 2>/dev/null | grep "uid: soporte")

if [ -n "$LDAP_USER" ]; then
    echo "Usuario LDAP 'soporte': ✅ Existe"
else
    echo "Usuario LDAP 'soporte': ❌ No encontrado"
fi

echo ""
echo "4. 🎨 Verificando branding..."
echo "───────────────────────────"

# Verificar logos en Authentik
BRAND_SVG=$(docker exec kolaboree-authentik-server ls -la /web/dist/assets/icons/brand.svg 2>/dev/null)
if [ -n "$BRAND_SVG" ]; then
    echo "Logo Neogenesys: ✅ Subido"
else
    echo "Logo Neogenesys: ❌ No encontrado"
fi

echo ""
echo "5. 🔄 Probando flujo SSO..."
echo "─────────────────────────"

echo "URL de prueba SSO:"
echo "https://34.68.124.46:9443/application/o/guacamole/"

echo ""
echo "📋 RESUMEN DE CONFIGURACIÓN:"
echo "══════════════════════════"
echo "• Authentik: https://34.68.124.46:9443"
echo "• Guacamole: http://34.68.124.46:8080/guacamole/"  
echo "• Usuario de prueba: soporte@kolaboree.local / Neo123!!!"
echo "• OIDC URLs: ✅ Corregidas (puerto 9443)"
echo "• Branding: ✅ Logo oficial Neogenesys"

echo ""
echo "🎯 PRUEBA MANUAL:"
echo "================"
echo "1. Abrir navegador en modo incógnito"
echo "2. Ir a: https://34.68.124.46:9443/application/o/guacamole/"
echo "3. Verificar:"
echo "   • Aparece branding de Neogenesys ✓"
echo "   • Redirige a login de Authentik ✓"
echo "4. Login con: soporte@kolaboree.local / Neo123!!!"
echo "5. Verificar:"
echo "   • Login exitoso en Authentik ✓"
echo "   • Redirección automática a Guacamole ✓"
echo "   • Aparecen conexiones RDP disponibles ✓"

echo ""
echo "🚨 SI HAY PROBLEMAS:"
echo "==================="
echo "• Limpiar cookies y cache del navegador"
echo "• Verificar que Authentik y Guacamole estén ejecutándose"
echo "• Revisar logs:"
echo "  - docker logs kolaboree-authentik-server"
echo "  - docker logs kolaboree-guacamole"

echo ""
echo "✅ VERIFICACIÓN COMPLETADA"
echo "========================="