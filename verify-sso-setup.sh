#!/bin/bash

echo "=== DIAGNÓSTICO Y VERIFICACIÓN DEL SISTEMA SSO ==="
echo ""

echo "🔍 1. VERIFICANDO ESTADO DE CONTENEDORES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose ps | grep -E "(authentik|guacamole|postgres|ldap)"
echo ""

echo "🔍 2. VERIFICANDO CONFIGURACIÓN DE GUACAMOLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Extension Priority configurada:"
docker-compose exec guacamole printenv EXTENSION_PRIORITY
echo ""
echo "Header Authentication configurada:"
docker-compose exec guacamole printenv HTTP_AUTH_HEADER
echo ""

echo "🔍 3. VERIFICANDO CONECTIVIDAD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Probando conectividad a Guacamole:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://34.68.124.46:8080/guacamole/
echo ""
echo "Probando conectividad a Authentik:"
curl -s -o /dev/null -w "Status: %{http_code}\n" https://34.68.124.46:9443/ -k
echo ""

echo "🔍 4. VERIFICANDO LOGS RECIENTES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Últimos logs de Authentik:"
docker logs kolaboree-authentik-server --tail=5 2>/dev/null || echo "No hay logs recientes de Authentik"
echo ""
echo "Últimos logs de Guacamole:"
docker logs kolaboree-guacamole --tail=5 2>/dev/null || echo "No hay logs recientes de Guacamole"
echo ""

echo "🔍 5. VERIFICANDO USUARIO LDAP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verificando que el usuario 'soporte' existe en LDAP:"
docker exec kolaboree-ldap ldapsearch -x -H ldap://localhost -D "cn=admin,dc=kolaboree,dc=local" -w "Neogenesys123!!!" -b "dc=kolaboree,dc=local" "(uid=soporte)" | grep -E "(dn:|uid:|mail:)" || echo "Usuario no encontrado"
echo ""

echo "🔍 6. PRUEBA DE HEADERS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Probando si Guacamole acepta headers de autenticación:"
curl -s -H "X-AUTHENTIK-USERNAME: soporte" -H "X-AUTHENTIK-EMAIL: soporte@kolaboree.local" http://34.68.124.46:8080/guacamole/ | grep -q "guacamole" && echo "✅ Guacamole responde a headers" || echo "❌ Problema con headers"
echo ""

echo "📋 PRÓXIMOS PASOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Si todos los servicios están UP, continúa con la configuración de Authentik"
echo "2. Ve a: https://34.68.124.46:9443"
echo "3. Sigue la guía en forward-auth-setup-step-by-step.sh"
echo "4. Si hay problemas, revisa los logs específicos con:"
echo "   docker logs kolaboree-authentik-server -f"
echo "   docker logs kolaboree-guacamole -f"
echo ""

echo "🌐 URLs IMPORTANTES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Authentik Admin: https://34.68.124.46:9443"
echo "🖥️  Guacamole: http://34.68.124.46:8080/guacamole/"
echo "👤 LDAP User: soporte@kolaboree.local / Neo123!!!"
echo "👨‍💼 Admin: akadmin / Neogenesys123!!!"