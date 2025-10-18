#!/bin/bash
# Script para configurar OIDC en Guacamole

echo "🔧 CONFIGURANDO OIDC EN GUACAMOLE"
echo "================================="

echo "1. 📋 Verificando estado actual..."

# Verificar si el directorio GUACAMOLE_HOME existe
docker exec kolaboree-guacamole mkdir -p /etc/guacamole/extensions

echo "2. 🔗 Habilitando extensión OIDC..."

# Copiar la extensión OIDC al directorio correcto
docker exec kolaboree-guacamole cp /opt/guacamole/extensions/guacamole-auth-sso/openid/guacamole-auth-sso-openid.jar /etc/guacamole/extensions/

echo "3. 📝 Creando archivo guacamole.properties..."

# Crear archivo de configuración con OIDC
docker exec kolaboree-guacamole bash -c 'cat > /etc/guacamole/guacamole.properties << EOF
# PostgreSQL properties (existente)
postgresql-hostname: postgresql
postgresql-port: 5432
postgresql-database: kolaboree
postgresql-username: kolaboree
postgresql-password: KolaboreeDB2024

# OIDC Configuration
openid-authorization-endpoint: https://34.68.124.46:9443/application/o/authorize/
openid-jwks-endpoint: https://34.68.124.46:9443/application/o/guacamole/jwks/
openid-issuer: https://34.68.124.46:9443/application/o/guacamole/
openid-client-id: ${OIDC_CLIENT_ID}
openid-client-secret: ${OIDC_CLIENT_SECRET}
openid-redirect-uri: http://34.68.124.46:8080/guacamole/
openid-username-claim-type: preferred_username
openid-scope: openid profile email
openid-allowed-clock-skew: 30
openid-max-token-validity: 300
EOF'

echo "4. 🔄 Verificando configuración creada..."
docker exec kolaboree-guacamole cat /etc/guacamole/guacamole.properties

echo ""
echo "5. 📋 INFORMACIÓN IMPORTANTE:"
echo "============================"
echo "⚠️ NECESITAS OBTENER DE AUTHENTIK:"
echo "   - Client ID del RAC Provider"
echo "   - Client Secret del RAC Provider"
echo ""
echo "📍 CÓMO OBTENERLOS:"
echo "1. Ir a: https://34.68.124.46:9443/if/admin/"
echo "2. Applications > Providers > [Tu RAC Provider]"
echo "3. Copiar Client ID y Client Secret"
echo ""
echo "📝 LUEGO ACTUALIZAR DOCKER-COMPOSE:"
echo "Agregar estas variables de entorno a Guacamole:"
echo "environment:"
echo "  - OIDC_CLIENT_ID=tu_client_id_aqui"
echo "  - OIDC_CLIENT_SECRET=tu_client_secret_aqui"

echo ""
echo "6. 🎯 CONFIGURACIÓN RAC PROVIDER REQUERIDA:"
echo "=========================================="
echo "En Authentik, el RAC Provider debe tener:"
echo "- Redirect URI: http://34.68.124.46:8080/guacamole/"
echo "- Client Type: Confidential"
echo "- Scopes: openid,profile,email"

echo ""
echo "✅ Extensión OIDC configurada en Guacamole"
echo "⚠️ Falta configurar Client ID y Secret"