#!/bin/bash

echo "🔍 VERIFICACIÓN EN TIEMPO REAL"
echo "=============================="
echo "Ejecuta este script mientras configuras RAC Provider"
echo ""

echo "📊 ESTADO ACTUAL DEL SISTEMA:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "🔧 Estado de contenedores:"
docker-compose ps | grep -E "(authentik|guacamole)" | head -4

echo ""
echo "🌐 Conectividad:"
echo -n "Authentik Admin: "
curl -s -o /dev/null -w "Status: %{http_code}\n" https://34.68.124.46:9443/if/admin/ -k

echo -n "Guacamole: "
curl -s -o /dev/null -w "Status: %{http_code}\n" http://34.68.124.46:8080/guacamole/

echo ""
echo "👤 Usuario LDAP verificado:"
docker exec kolaboree-ldap ldapsearch -x -H ldap://localhost -D "cn=admin,dc=kolaboree,dc=local" -w "Neogenesys123!!!" -b "dc=kolaboree,dc=local" "(uid=soporte)" dn 2>/dev/null | grep "dn:" || echo "Usuario no encontrado"

echo ""
echo "🚀 URLs IMPORTANTES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Authentik Admin: https://34.68.124.46:9443/if/admin/"
echo "👤 Authentik User: https://34.68.124.46:9443/if/user/"
echo "🖥️  Guacamole (actual): http://34.68.124.46:8080/guacamole/"
echo ""
echo "📋 CREDENCIALES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Admin: akadmin / Neogenesys123!!!"
echo "Usuario: soporte@kolaboree.local / Neo123!!!"
echo ""

echo "✅ SISTEMA LISTO PARA CONFIGURACIÓN RAC PROVIDER"
echo ""
echo "💡 PRÓXIMO PASO: Ve a Authentik Admin y sigue la guía paso a paso"