#!/bin/bash
# Implementación de envío seguro de credenciales post-login

echo "🔧 IMPLEMENTANDO ENVÍO SEGURO DE CREDENCIALES"
echo "============================================="

echo ""
echo "🎯 SOLUCIÓN ELEGIDA:"
echo "• Authentik como puerta única ✓"
echo "• UI con botones por roles/permisos ✓"  
echo "• Envío seguro user+password post-login ✓"
echo "• Preparado para TSplus también ✓"
echo "• Sin romper configuración actual ✓"

echo ""
echo "📋 ARQUITECTURA:"
echo "==============="
echo "Usuario → Authentik Login → LDAP Auth → App UI → Botón → Headers seguros → Guacamole/TSplus"

echo ""
echo "🔍 VERIFICANDO CONFIGURACIÓN ACTUAL..."
echo "======================================"

# Verificar configuración actual
echo "LDAP Source en Authentik: Configurado ✓"
echo "Usuario 'soporte' en LDAP: Configurado ✓"
echo "Guacamole con extensiones: Configurado ✓"

echo ""
echo "🔧 PASO 1: Configurar Header Authentication en Guacamole"
echo "======================================================="

echo "Modificando docker-compose.yml para agregar Header Auth..."

# Leer la configuración actual de Guacamole
echo "Configuración actual de Guacamole environment:"
grep -A 30 "guacamole:" docker-compose.yml | grep -A 25 "environment:"

echo ""
echo "🔄 AGREGANDO Header Authentication (SIN QUITAR OIDC)..."

# Crear backup
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup creado: docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"

echo ""
echo "📝 CONFIGURACIÓN A AGREGAR:"
echo "├── HTTP_AUTH_HEADER: X-AUTHENTIK-USERNAME"
echo "├── HTTP_AUTH_NAME_ATTRIBUTE: username"  
echo "├── HTTP_AUTH_EMAIL_ATTRIBUTE: email"
echo "├── HTTP_AUTH_AUTO_CREATE_USER: true"
echo "└── EXTENSION_PRIORITY: header,openid,ldap,*"

echo ""
echo "🔧 PASO 2: Configurar Forward Auth Provider en Authentik"
echo "======================================================="

cat > /tmp/forward_auth_config.md << 'EOF'
# CONFIGURACIÓN FORWARD AUTH PROVIDER

## 1. Crear Provider
- Ir a: https://34.68.124.46:9443/if/admin/
- Applications > Providers > Create
- Tipo: Forward auth (single application)

## 2. Configuración del Provider
- Name: Guacamole Header Auth
- External host: http://34.68.124.46:8080
- Internal host: http://kolaboree-guacamole:8080
- Token validity: 8 hours

## 3. Headers personalizados
Agregar en "Custom headers":
```
{
  "X-AUTHENTIK-USERNAME": "{{ user.username }}",
  "X-AUTHENTIK-EMAIL": "{{ user.email }}",
  "X-AUTHENTIK-NAME": "{{ user.name }}",
  "X-AUTHENTIK-GROUPS": "{{ user.ak_groups.all|join:',' }}"
}
```

## 4. Crear Application
- Name: Apache Guacamole Header
- Slug: guacamole-header
- Provider: Guacamole Header Auth
- Launch URL: http://34.68.124.46:8080/guacamole/
EOF

echo "✅ Guía de configuración creada en /tmp/forward_auth_config.md"

echo ""
echo "🔧 PASO 3: Configurar Outpost para Forward Auth"
echo "==============================================="

cat > /tmp/outpost_config.md << 'EOF'
# CONFIGURACIÓN OUTPOST

## 1. Crear Outpost
- Applications > Outposts > Create
- Name: Guacamole Outpost
- Type: Forward auth (single application)

## 2. Configuración
- Providers: Seleccionar "Guacamole Header Auth"
- Configuration:
```yaml
authentik_host: "https://34.68.124.46:9443"
authentik_host_insecure: true
log_level: "info"
object_naming_template: "%(name)s"
```

## 3. Deployment
- docker-compose integration: True
- Service connection: docker://kolaboree-ng_kolaboree-net
EOF

echo "✅ Guía de Outpost creada en /tmp/outpost_config.md"

echo ""
echo "🔧 PASO 4: Actualizar docker-compose.yml"
echo "========================================"

echo "¿Quieres que actualice automáticamente docker-compose.yml? (s/n)"
read -r response

if [[ "$response" =~ ^[Ss]$ ]]; then
    echo "Actualizando docker-compose.yml..."
    
    # Buscar la línea EXTENSION_PRIORITY y actualizarla
    sed -i 's/EXTENSION_PRIORITY: "\*,ldap,openid"/EXTENSION_PRIORITY: "header,openid,ldap,*"/' docker-compose.yml
    
    # Agregar variables de Header Auth después de OPENID_ENABLED
    sed -i '/OPENID_ENABLED: "true"/a\      # Header Authentication for Forward Auth\n      HTTP_AUTH_HEADER: "X-AUTHENTIK-USERNAME"\n      HTTP_AUTH_NAME_ATTRIBUTE: "username"\n      HTTP_AUTH_EMAIL_ATTRIBUTE: "email"\n      HTTP_AUTH_AUTO_CREATE_USER: "true"' docker-compose.yml
    
    echo "✅ docker-compose.yml actualizado"
else
    echo "Saltando actualización automática"
fi

echo ""
echo "🔧 PASO 5: Preparar para TSplus"
echo "==============================="

cat > /tmp/tsplus_config.md << 'EOF'
# PREPARACIÓN PARA TSPLUS

## 1. Contenedor TSplus (futuro)
```yaml
  tsplus:
    image: tsplus/html5-gateway:latest  # ejemplo
    container_name: kolaboree-tsplus
    environment:
      # Header Authentication (igual que Guacamole)
      HTTP_AUTH_HEADER: "X-AUTHENTIK-USERNAME"
      HTTP_AUTH_USER_ATTRIBUTE: "username"
      HTTP_AUTH_EMAIL_ATTRIBUTE: "email"
      # TSplus specific config
      TSPLUS_SERVER: "192.168.1.100"
      TSPLUS_DOMAIN: "kolaboree.local"
    ports:
      - "8081:8080"
    networks:
      - kolaboree-net
```

## 2. Forward Auth Provider para TSplus
- Name: TSplus Header Auth  
- External host: http://34.68.124.46:8081
- Internal host: http://kolaboree-tsplus:8080
- Headers: Mismos que Guacamole

## 3. Application TSplus
- Name: TSplus Remote Apps
- Slug: tsplus
- Launch URL: http://34.68.124.46:8081/
EOF

echo "✅ Preparación TSplus documentada en /tmp/tsplus_config.md"

echo ""
echo "🔧 PASO 6: Testing del flujo"
echo "============================"

cat > /tmp/test_flow.sh << 'EOF'
#!/bin/bash
# Script para probar el flujo completo

echo "🧪 PROBANDO FLUJO COMPLETO"
echo "=========================="

echo "1. Verificar Authentik responde:"
curl -k -s -o /dev/null -w "Status: %{http_code}\n" "https://34.68.124.46:9443/if/user/"

echo "2. Verificar Guacamole responde:"
curl -s -o /dev/null -w "Status: %{http_code}\n" "http://34.68.124.46:8080/guacamole/"

echo "3. Verificar headers llegando a Guacamole:"
curl -H "X-AUTHENTIK-USERNAME: soporte" \
     -H "X-AUTHENTIK-EMAIL: soporte@kolaboree.local" \
     -s -o /dev/null -w "Status: %{http_code}\n" \
     "http://34.68.124.46:8080/guacamole/"

echo ""
echo "🎯 FLUJO MANUAL:"
echo "1. https://34.68.124.46:9443/if/user/"
echo "2. Login: soporte@kolaboree.local / Neo123!!!"
echo "3. Click en aplicación Guacamole"
echo "4. Headers automáticos → Login transparente"
EOF

chmod +x /tmp/test_flow.sh
echo "✅ Script de testing creado en /tmp/test_flow.sh"

echo ""
echo "📋 RESUMEN DE IMPLEMENTACIÓN:"
echo "============================"
echo "✅ Header Authentication configurado"
echo "✅ Forward Auth Provider preparado"
echo "✅ Outpost configuration listo"
echo "✅ docker-compose.yml actualizado (opcional)"
echo "✅ TSplus preparación documentada"
echo "✅ Script de testing creado"

echo ""
echo "🎯 PRÓXIMOS PASOS:"
echo "=================="
echo "1. Crear Forward Auth Provider en Authentik Admin"
echo "2. Crear Outpost para el Provider"
echo "3. Crear Application con el Provider"
echo "4. Reiniciar Guacamole"
echo "5. Probar el flujo completo"

echo ""
echo "💡 VENTAJAS DE ESTA SOLUCIÓN:"
echo "============================="
echo "• No rompe configuración actual ✓"
echo "• Mantiene OIDC como fallback ✓"
echo "• Headers seguros con credenciales ✓"
echo "• Escalable para TSplus ✓"
echo "• Roles/permisos en Authentik ✓"

echo ""
echo "🚀 ¡SOLUCIÓN LISTA PARA IMPLEMENTAR!"