#!/bin/bash
# Guía paso a paso para configurar Forward Auth con envío de credenciales

echo "🎯 CONFIGURACIÓN FORWARD AUTH PARA ENVÍO SEGURO"
echo "==============================================="

echo ""
echo "✅ DOCKER-COMPOSE ACTUALIZADO:"
echo "• Header Authentication agregado ✓"
echo "• Extension priority ajustado ✓"
echo "• Sin romper OIDC existente ✓"

echo ""
echo "🔧 PASO 1: Crear Forward Auth Provider en Authentik"
echo "=================================================="

echo ""
echo "📍 URL: https://34.68.124.46:9443/if/admin/"
echo "📍 Ruta: Applications > Providers > Create"

echo ""
echo "📋 CONFIGURACIÓN EXACTA DEL PROVIDER:"
echo "┌─────────────────────────────────────────────────┐"
echo "│ BASIC SETTINGS:                                 │"
echo "│ ├── Name: Guacamole Forward Auth                │"
echo "│ ├── Type: Forward auth (single application)     │"
echo "│                                                 │"
echo "│ FORWARD AUTH SETTINGS:                          │"
echo "│ ├── External host: http://34.68.124.46:8080     │"
echo "│ ├── Internal host: http://kolaboree-guacamole:8080 │"
echo "│ ├── Internal host SSL validation: ❌           │"
echo "│ ├── Token validity: 8 hours                     │"
echo "│                                                 │"
echo "│ ADVANCED SETTINGS:                              │"
echo "│ ├── Access token validity: 5 minutes            │"
echo "│ ├── Authorization flow: implicit-consent        │"
echo "│ └── Mode: Forward auth (single application)     │"
echo "└─────────────────────────────────────────────────┘"

echo ""
echo "🔧 PASO 2: Configurar Headers Personalizados"
echo "============================================="

echo ""
echo "En el Provider creado, agregar en 'Additional headers':"
echo ""
cat > /tmp/authentik_headers.json << 'EOF'
{
  "X-AUTHENTIK-USERNAME": "{{ user.username }}",
  "X-AUTHENTIK-EMAIL": "{{ user.email }}",
  "X-AUTHENTIK-NAME": "{{ user.name }}",
  "X-AUTHENTIK-GROUPS": "{{ user.ak_groups.all|join:',' }}",
  "REMOTE_USER": "{{ user.username }}"
}
EOF

echo "📋 HEADERS JSON (copiar en Additional headers):"
echo "================================================"
cat /tmp/authentik_headers.json

echo ""
echo "🔧 PASO 3: Crear Application"
echo "============================"

echo ""
echo "📍 Ruta: Applications > Applications > Create"
echo ""
echo "📋 CONFIGURACIÓN DE LA APPLICATION:"
echo "┌─────────────────────────────────────────────────┐"
echo "│ Name: Apache Guacamole Secure                   │"
echo "│ Slug: guacamole-secure                          │"
echo "│ Provider: Guacamole Forward Auth                │"
echo "│                                                 │"
echo "│ UI SETTINGS:                                    │"
echo "│ ├── Launch URL: http://34.68.124.46:8080/      │"
echo "│ ├── Open in new tab: ✅                        │"
echo "│ ├── Icon: /static/dist/assets/icons/icon.svg    │"
echo "│                                                 │"
echo "│ POLICY ENGINE MODE:                             │"
echo "│ └── ANY (para permitir acceso)                 │"
echo "└─────────────────────────────────────────────────┘"

echo ""
echo "🔧 PASO 4: Configurar Outpost"
echo "============================="

echo ""
echo "📍 Ruta: Applications > Outposts > Create"
echo ""
echo "📋 CONFIGURACIÓN DEL OUTPOST:"
echo "┌─────────────────────────────────────────────────┐"
echo "│ Name: Guacamole Outpost                         │"
echo "│ Type: Forward auth (single application)         │"
echo "│ Providers: Guacamole Forward Auth               │"
echo "│                                                 │"
echo "│ CONFIGURATION:                                  │"
echo "│ authentik_host: https://34.68.124.46:9443       │"
echo "│ authentik_host_insecure: true                   │"
echo "│ log_level: info                                 │"
echo "│                                                 │"
echo "│ DOCKER INTEGRATION:                             │"
echo "│ ├── Docker integration: ✅                     │"
echo "│ ├── Network: kolaboree-ng_kolaboree-net        │"
echo "│ └── Service connection: Docker Socket           │"
echo "└─────────────────────────────────────────────────┘"

echo ""
echo "🔧 PASO 5: Actualizar Nginx (Opcional)"
echo "======================================"

cat > /tmp/nginx_forward_auth.conf << 'EOF'
# Configuración Nginx para Forward Auth
server {
    listen 8080;
    server_name _;
    
    location / {
        # Forward auth a Authentik
        auth_request /outpost.goauthentik.io/auth/guacamole-secure;
        
        # Pasar headers de autenticación
        auth_request_set $username $upstream_http_x_authentik_username;
        auth_request_set $email $upstream_http_x_authentik_email;
        auth_request_set $name $upstream_http_x_authentik_name;
        
        # Enviar headers a Guacamole
        proxy_set_header X-AUTHENTIK-USERNAME $username;
        proxy_set_header X-AUTHENTIK-EMAIL $email;
        proxy_set_header X-AUTHENTIK-NAME $name;
        proxy_set_header REMOTE_USER $username;
        
        # Proxy a Guacamole
        proxy_pass http://kolaboree-guacamole:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Endpoint de autenticación
    location = /outpost.goauthentik.io/auth/guacamole-secure {
        internal;
        proxy_pass http://authentik-outpost:9000/outpost.goauthentik.io/auth/guacamole-secure;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    }
}
EOF

echo "📄 Configuración Nginx creada en /tmp/nginx_forward_auth.conf"

echo ""
echo "🔧 PASO 6: Reiniciar servicios"
echo "=============================="

echo "1. Reiniciar Guacamole para aplicar headers:"
echo "   docker-compose restart guacamole"
echo ""
echo "2. Verificar logs:"
echo "   docker logs kolaboree-guacamole"

echo ""
echo "🧪 PASO 7: Probar el flujo"
echo "=========================="

echo ""
echo "📋 FLUJO DE TESTING:"
echo "1. Ir a: https://34.68.124.46:9443/if/user/"
echo "2. Login: soporte@kolaboree.local / Neo123!!!"
echo "3. Buscar 'Apache Guacamole Secure' en aplicaciones"
echo "4. Hacer clic → Debería abrir Guacamole automáticamente"
echo "5. Sin pedir credenciales adicionales"

echo ""
echo "🔍 VERIFICAR HEADERS:"
echo "===================="
echo "En Guacamole, verificar en logs que llegan headers:"
echo "• X-AUTHENTIK-USERNAME: soporte"
echo "• X-AUTHENTIK-EMAIL: soporte@kolaboree.local"
echo "• REMOTE_USER: soporte"

echo ""
echo "📋 PREPARACIÓN TSPLUS:"
echo "====================="

cat > /tmp/tsplus_preparation.yml << 'EOF'
# Preparación para TSplus (agregar al docker-compose.yml)

  tsplus:
    image: tsplus/html5-gateway:latest  # Ajustar según TSplus
    container_name: kolaboree-tsplus
    environment:
      # Header Authentication (mismo que Guacamole)
      HTTP_AUTH_HEADER: "X-AUTHENTIK-USERNAME"
      HTTP_AUTH_NAME_ATTRIBUTE: "username"
      HTTP_AUTH_EMAIL_ATTRIBUTE: "email"
      HTTP_AUTH_AUTO_CREATE_USER: "true"
      
      # TSplus específico
      TSPLUS_SERVER: "100.95.223.18"  # Servidor Windows
      TSPLUS_DOMAIN: "kolaboree.local"
      TSPLUS_GATEWAY_PORT: "443"
      
      # Extension priority
      EXTENSION_PRIORITY: "header,ldap,*"
    ports:
      - "8081:8080"
    networks:
      - kolaboree-net
    restart: unless-stopped
EOF

echo "📄 Preparación TSplus en /tmp/tsplus_preparation.yml"

echo ""
echo "✅ RESUMEN DE IMPLEMENTACIÓN:"
echo "============================"
echo "• Header Authentication configurado en Guacamole ✓"
echo "• Forward Auth Provider listo para crear ✓"
echo "• Application configuration preparada ✓"
echo "• Outpost configuration lista ✓"
echo "• TSplus preparación documentada ✓"

echo ""
echo "🎯 VENTAJAS DE ESTA SOLUCIÓN:"
echo "============================="
echo "• Authentik como puerta única ✓"
echo "• Headers seguros con credenciales ✓"
echo "• Roles y permisos granulares ✓"
echo "• Escalable para TSplus ✓"
echo "• Sin romper configuración actual ✓"
echo "• Fallback a OIDC si falla Header Auth ✓"

echo ""
echo "🚀 PRÓXIMO PASO:"
echo "================"
echo "Configurar el Forward Auth Provider en Authentik Admin"
echo "usando las configuraciones exactas proporcionadas arriba."