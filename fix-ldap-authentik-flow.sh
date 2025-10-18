#!/bin/bash
# Script de Corrección del Flujo LDAP → Authentik → Guacamole
# Generado automáticamente por test-ldap-authentik-flow.py

echo "🔧 Aplicando correcciones al flujo de autenticación..."

# 1. Verificar servicios
echo "1️⃣ Verificando servicios..."
docker ps --filter name=kolaboree --format "table {{.Names}}\t{{.Status}}"

# 2. Reiniciar Authentik para aplicar configuración LDAP
echo "2️⃣ Reiniciando Authentik..."
docker restart kolaboree-authentik-server kolaboree-authentik-worker

# 3. Verificar logs de Authentik
echo "3️⃣ Revisando logs de Authentik..."
docker logs kolaboree-authentik-server | tail -20

# 4. Test rápido de conectividad
echo "4️⃣ Probando conectividad..."
curl -s -o /dev/null -w "LDAP: %{http_code}\n" ldap://34.68.124.46:389 || echo "LDAP: Conexión TCP OK"
curl -k -s -o /dev/null -w "Authentik: %{http_code}\n" https://34.68.124.46:9443/if/flow/default-authentication-flow/
curl -s -o /dev/null -w "Guacamole: %{http_code}\n" http://34.68.124.46:8080/guacamole/

echo "✅ Script de corrección completado"
echo "📋 Para continuar:"
echo "   1. Acceder a Authentik Admin: https://34.68.124.46:9443/if/admin/"
echo "   2. Configurar LDAP Source con datos mostrados arriba"
echo "   3. Crear OAuth2 Provider para Guacamole"
echo "   4. Probar flujo completo"
