#!/bin/bash
# Script para configurar autenticación transparente LDAP

echo "🔧 CONFIGURANDO AUTENTICACIÓN TRANSPARENTE"
echo "=========================================="

echo ""
echo "📋 FLUJO REQUERIDO:"
echo "• Usuario ingresa email en Authentik"
echo "• Authentik busca en LDAP (usuario+password)"
echo "• Login exitoso en Authentik"
echo "• Authentik envía credenciales LDAP a Guacamole"
echo "• Guacamole usa esas credenciales para login automático"

echo ""
echo "🔍 VERIFICANDO CONFIGURACIÓN ACTUAL..."

# Verificar configuración LDAP en Guacamole
echo "Variables LDAP actuales en Guacamole:"
docker exec kolaboree-guacamole env | grep -E "LDAP_" | while read line; do
    echo "  $line"
done

echo ""
echo "🎯 CONFIGURACIÓN NECESARIA:"
echo "=========================="

echo ""
echo "1. AUTHENTIK - Configurar LDAP Source para pass-through"
echo "───────────────────────────────────────────────────"
echo "En Authentik Admin:"
echo "• Directory > Federation & Social login > LDAP Sources"
echo "• Editar el LDAP Source existente"
echo "• IMPORTANTE: Activar 'Bind password source'"
echo "• Esto permite que Authentik mantenga las credenciales LDAP"

echo ""
echo "2. GUACAMOLE - Configurar para recibir credenciales"
echo "─────────────────────────────────────────────────"
echo "Necesitamos cambiar el enfoque de OIDC a Header Authentication"

echo ""
echo "🔧 MODIFICANDO DOCKER-COMPOSE..."

# Crear una nueva configuración para Guacamole
cat > /tmp/guacamole_new_config.txt << 'EOF'
# Configuración modificada para autenticación transparente
      # PostgreSQL Configuration (mantener)
      POSTGRESQL_HOSTNAME: postgres
      POSTGRESQL_PORT: 5432
      POSTGRESQL_DATABASE: ${POSTGRES_DB:-kolaboree}
      POSTGRESQL_USER: ${POSTGRES_USER:-kolaboree}
      POSTGRESQL_PASSWORD: ${POSTGRES_PASSWORD:-CHANGEME_SECURE_PASSWORD}
      POSTGRESQL_SSL_MODE: disable
      
      # LDAP Authentication (configuración principal)
      LDAP_HOSTNAME: "kolaboree-ldap"
      LDAP_PORT: "389"
      LDAP_ENCRYPTION_METHOD: "none"
      LDAP_USER_BASE_DN: "ou=users,dc=kolaboree,dc=local"
      LDAP_USERNAME_ATTRIBUTE: "uid"
      LDAP_MEMBER_ATTRIBUTE: "member"
      LDAP_USER_SEARCH_FILTER: "(objectClass=inetOrgPerson)"
      LDAP_GROUP_BASE_DN: "ou=groups,dc=kolaboree,dc=local"
      LDAP_GROUP_SEARCH_FILTER: "(objectClass=groupOfNames)"
      LDAP_BIND_DN: "cn=admin,dc=kolaboree,dc=local"
      LDAP_BIND_PASSWORD: "${LDAP_ADMIN_PASSWORD:-CHANGEME_LDAP_PASSWORD}"
      
      # Header Authentication para recibir de Authentik
      HTTP_AUTH_HEADER: "REMOTE_USER"
      HTTP_AUTH_NAME_ATTRIBUTE: "username"
      HTTP_AUTH_EMAIL_ATTRIBUTE: "email"
      
      # Extension priority (header primero, luego LDAP)
      EXTENSION_PRIORITY: "header,ldap,*"
EOF

echo "✅ Nueva configuración preparada"

echo ""
echo "3. AUTHENTIK - Configurar Forward Auth"
echo "─────────────────────────────────────"
echo "Authentik necesita configurarse como Forward Auth proxy"
echo "Esto permite que pase las credenciales en headers HTTP"

echo ""
echo "📋 PASOS PARA IMPLEMENTAR:"
echo "========================="

echo ""
echo "PASO 1: Modificar docker-compose.yml"
echo "────────────────────────────────────"
echo "1. Reemplazar la sección environment de guacamole"
echo "2. Con la configuración de /tmp/guacamole_new_config.txt"
echo "3. Reiniciar Guacamole"

echo ""
echo "PASO 2: Configurar Forward Auth en Authentik"
echo "───────────────────────────────────────────"
echo "1. Applications > Providers > Create"
echo "2. Tipo: Forward auth (single application)"
echo "3. External host: http://34.68.124.46:8080"
echo "4. Internal host: http://guacamole:8080"

echo ""
echo "PASO 3: Configurar Nginx/Proxy"
echo "─────────────────────────────"
echo "Necesitaremos un proxy que:"
echo "• Reciba requests a Guacamole"
echo "• Los envíe a Authentik para autenticación"
echo "• Authentik valide con LDAP y agregue headers"
echo "• Pase el request con headers a Guacamole"

echo ""
echo "🔍 VERIFICAR SI NECESITAMOS ESTO:"
echo "================================"
echo "¿Realmente necesitas que Authentik pase las credenciales LDAP?"
echo "¿O prefieres que Guacamole haga su propia autenticación LDAP?"

echo ""
echo "💡 ALTERNATIVA MÁS SIMPLE:"
echo "========================="
echo "1. Usuario hace login en Authentik (LDAP)"
echo "2. Authentik redirige a Guacamole con token"
echo "3. Guacamole valida token y hace login automático"
echo "4. Sin pasar credenciales, solo validación de identidad"

echo ""
echo "🤔 ¿CUÁL PREFIERES?"
echo "=================="
echo "A) Forward Auth con credenciales (más complejo)"
echo "B) OIDC con validación de token (más estándar)"
echo ""
echo "Dime cuál prefieres para configurar correctamente"