#!/bin/bash
# Implementación de Forward Auth para pasar credenciales LDAP

echo "🔧 IMPLEMENTANDO FORWARD AUTH CON CREDENCIALES LDAP"
echo "=================================================="

echo ""
echo "📋 FLUJO IMPLEMENTADO:"
echo "1. Usuario → email en Authentik"
echo "2. Authentik → busca en LDAP (usuario+password)"
echo "3. Authentik → valida credenciales LDAP"
echo "4. Authentik → pasa credenciales en headers HTTP"
echo "5. Guacamole → recibe headers y hace login automático"

echo ""
echo "🔧 PASO 1: Configurar Authentik LDAP para bind password"
echo "======================================================"

# Crear script para configurar LDAP bind password en Authentik
cat > /tmp/configure_authentik_ldap.py << 'EOF'
#!/usr/bin/env python3
"""
Configurar LDAP Source en Authentik para mantener credenciales
"""

print("📋 CONFIGURACIÓN LDAP SOURCE EN AUTHENTIK:")
print("==========================================")
print()
print("1. Ir a: https://34.68.124.46:9443/if/admin/")
print("2. Directory > Federation & Social login > LDAP Sources")
print("3. Editar el LDAP Source existente")
print()
print("CONFIGURACIÓN CRÍTICA:")
print("├── Bind password source: ✅ ACTIVAR")
print("├── Password login update internal password: ✅ ACTIVAR") 
print("├── Sync users password: ✅ ACTIVAR")
print("└── User password writeback: ✅ ACTIVAR")
print()
print("Esto permite que Authentik:")
print("• Mantenga las credenciales LDAP del usuario")
print("• Las pase a aplicaciones backend")
print("• Haga autenticación transparente")
EOF

python3 /tmp/configure_authentik_ldap.py

echo ""
echo "🔧 PASO 2: Modificar Guacamole para Header Authentication"
echo "========================================================"

# Crear nueva configuración de Guacamole
cat > /tmp/new_guacamole_config.yml << 'EOF'
  guacamole:
    image: guacamole/guacamole:latest
    container_name: kolaboree-guacamole
    environment:
      GUACD_HOSTNAME: guacd
      GUACD_PORT: 4822
      
      # PostgreSQL Configuration
      POSTGRESQL_HOSTNAME: postgres
      POSTGRESQL_PORT: 5432
      POSTGRESQL_DATABASE: ${POSTGRES_DB:-kolaboree}
      POSTGRESQL_USER: ${POSTGRES_USER:-kolaboree}
      POSTGRESQL_PASSWORD: ${POSTGRES_PASSWORD:-CHANGEME_SECURE_PASSWORD}
      POSTGRESQL_SSL_MODE: disable
      
      # Header Authentication (recibir de Authentik)
      HTTP_AUTH_HEADER: "REMOTE_USER"
      HTTP_AUTH_NAME_ATTRIBUTE: "username"
      HTTP_AUTH_EMAIL_ATTRIBUTE: "email"
      
      # LDAP Configuration (validación backend)
      LDAP_HOSTNAME: "kolaboree-ldap"
      LDAP_PORT: "389"
      LDAP_ENCRYPTION_METHOD: "none"
      LDAP_USER_BASE_DN: "ou=users,dc=kolaboree,dc=local"
      LDAP_USERNAME_ATTRIBUTE: "uid"
      LDAP_USER_SEARCH_FILTER: "(objectClass=inetOrgPerson)"
      LDAP_BIND_DN: "cn=admin,dc=kolaboree,dc=local"
      LDAP_BIND_PASSWORD: "${LDAP_ADMIN_PASSWORD:-CHANGEME_LDAP_PASSWORD}"
      
      # Extension Priority (header primero, luego LDAP)
      EXTENSION_PRIORITY: "header,ldap,*"
    ports:
      - "${GUACAMOLE_PORT:-8080}:8080"
    networks:
      - kolaboree-net
    depends_on:
      - postgres
      - guacd
    restart: unless-stopped
EOF

echo "✅ Nueva configuración de Guacamole creada en /tmp/new_guacamole_config.yml"

echo ""
echo "🔧 PASO 3: Configurar Forward Auth Provider en Authentik"
echo "======================================================="

cat > /tmp/authentik_forward_auth.py << 'EOF'
#!/usr/bin/env python3
"""
Configuración Forward Auth Provider en Authentik
"""

print("📋 CREAR FORWARD AUTH PROVIDER:")
print("================================")
print()
print("1. Ir a: https://34.68.124.46:9443/if/admin/")
print("2. Applications > Providers > Create")
print("3. Seleccionar: Forward auth (single application)")
print()
print("CONFIGURACIÓN:")
print("├── Name: Guacamole Forward Auth")
print("├── External host: http://34.68.124.46:8080")
print("├── Internal host: http://guacamole:8080")
print("├── Internal host SSL validation: ❌ Desactivar")
print("├── Mode: Forward auth (single application)")
print("└── Token validity: 24 hours")
print()
print("HEADERS PERSONALIZADOS:")
print("Agregar headers personalizados para pasar credenciales:")
print("├── REMOTE_USER: {{ user.username }}")
print("├── HTTP_X_USER: {{ user.username }}")
print("├── HTTP_X_EMAIL: {{ user.email }}")
print("└── HTTP_X_GROUPS: {{ user.groups_list }}")
EOF

python3 /tmp/authentik_forward_auth.py

echo ""
echo "🔧 PASO 4: Configurar Nginx como Proxy"
echo "======================================"

# Crear configuración Nginx para Forward Auth
cat > /tmp/nginx_forward_auth.conf << 'EOF'
server {
    listen 8080;
    server_name localhost;
    
    location / {
        # Forward auth a Authentik
        auth_request /outpost.goauthentik.io/auth/guacamole;
        
        # Pasar headers de autenticación
        auth_request_set $user $upstream_http_x_authentik_username;
        auth_request_set $email $upstream_http_x_authentik_email;
        auth_request_set $groups $upstream_http_x_authentik_groups;
        
        # Enviar headers a Guacamole
        proxy_set_header REMOTE_USER $user;
        proxy_set_header HTTP_X_USER $user;
        proxy_set_header HTTP_X_EMAIL $email;
        proxy_set_header HTTP_X_GROUPS $groups;
        
        # Proxy a Guacamole
        proxy_pass http://guacamole:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Endpoint de autenticación
    location = /outpost.goauthentik.io/auth/guacamole {
        internal;
        proxy_pass https://34.68.124.46:9443/outpost.goauthentik.io/auth/guacamole;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    }
}
EOF

echo "✅ Configuración Nginx Forward Auth creada en /tmp/nginx_forward_auth.conf"

echo ""
echo "📋 PRÓXIMOS PASOS PARA IMPLEMENTAR:"
echo "==================================="

echo ""
echo "1. MODIFICAR DOCKER-COMPOSE.YML:"
echo "   Reemplazar sección guacamole con /tmp/new_guacamole_config.yml"

echo ""
echo "2. CONFIGURAR AUTHENTIK:"
echo "   Ejecutar configuraciones en Authentik Admin"

echo ""
echo "3. ACTUALIZAR NGINX:"
echo "   Agregar configuración Forward Auth"

echo ""
echo "4. REINICIAR SERVICIOS:"
echo "   docker-compose restart"

echo ""
echo "💡 FLUJO FINAL:"
echo "==============="
echo "Usuario → email → Authentik → LDAP → headers → Guacamole → login automático"

echo ""
echo "🚨 IMPORTANTE:"
echo "=============="
echo "Esta configuración es más compleja que OIDC estándar."
echo "¿Confirmas que necesitas pasar credenciales LDAP reales"
echo "en lugar de usar tokens de identificación?"