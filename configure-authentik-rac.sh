#!/bin/bash

# Script para configurar Authentik OAuth2/OIDC con Guacamole
# Configura la integración completa para RAC

echo "� Configurando Authentik OAuth2 Provider para Guacamole RAC"
echo "==========================================================="

# Función para configurar el proveedor OAuth2 en Authentik
configure_oauth_provider() {
    echo "🏗️  Configurando proveedor OAuth2 para Guacamole..."
    
    docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.providers.oauth2.models import OAuth2Provider
from authentik.core.models import Application
from authentik.flows.models import Flow

# Crear OAuth2 Provider
try:
    provider = OAuth2Provider.objects.create(
        name="Guacamole RAC Provider",
        client_id="guacamole-rac-client",
        client_secret="guacamole-rac-secret-2024",
        client_type="confidential",
        redirect_uris="http://34.68.124.46:8080/guacamole/\nhttp://34.68.124.46:8080/guacamole/api/ext/oidc/callback",
        sub_mode="hashed_user_id",
        include_claims_in_id_token=True,
        issuer_mode="per_provider"
    )
    print(f"✅ OAuth2 Provider creado: {provider.name}")
    
    # Crear aplicación
    app = Application.objects.create(
        name="Guacamole RAC",
        slug="guacamole-rac", 
        provider=provider,
        meta_launch_url="http://34.68.124.46:8080/guacamole/",
        meta_description="Remote Access Control through Guacamole",
        meta_publisher="Neogenesys",
        open_in_new_tab=True
    )
    print(f"✅ Aplicación creada: {app.name}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print("El proveedor puede ya existir")
EOF
}
# Función para configurar Guacamole con OIDC
configure_guacamole_oidc() {
    echo "⚙️  Configurando Guacamole con OIDC..."
    echo "Esta configuración debe agregarse al docker-compose.yml:"
    echo ""
    cat << 'EOF'
# Agregar estas variables al servicio guacamole en docker-compose.yml:
environment:
  # ... variables existentes ...
  # OAuth2/OIDC Configuration
  OPENID_AUTHORIZATION_ENDPOINT: "http://34.68.124.46:9000/application/o/authorize/"
  OPENID_JWKS_ENDPOINT: "http://34.68.124.46:9000/application/o/guacamole-rac/jwks/"
  OPENID_ISSUER: "http://34.68.124.46:9000/application/o/guacamole-rac/"
  OPENID_CLIENT_ID: "guacamole-rac-client"
  OPENID_REDIRECT_URI: "http://34.68.124.46:8080/guacamole/"
  OPENID_USERNAME_CLAIM_TYPE: "preferred_username"
  OPENID_GROUPS_CLAIM_TYPE: "groups"
  OPENID_SCOPE: "openid profile email groups"
EOF
}

# Función para mostrar acceso directo
show_access_info() {
    echo ""
    echo "🔗 INFORMACIÓN DE ACCESO"
    echo "========================"
    echo ""
    echo "1. Acceso a Authentik Admin:"
    echo "   URL: https://34.68.124.46:9443/if/admin/"
    echo "   Usuario: akadmin"
    echo "   Password: Kolaboree2024!Admin"
    echo ""
    echo "2. Una vez configurado OAuth2, acceso directo a Guacamole:"
    echo "   URL: https://34.68.124.46:9443/if/flow/default-authentication-flow/"
    echo "   → Aplicaciones → Guacamole RAC"
    echo ""
    echo "3. Para pruebas directas:"
    echo "   URL: http://34.68.124.46:8080/guacamole/"
    echo "   Usuario: akadmin"
    echo "   Password: Kolaboree2024"
    echo ""
}

# Función principal
main() {
    case "${1:-all}" in
        "oauth")
            configure_oauth_provider
            ;;
        "guac")
            configure_guacamole_oidc
            ;;
        "info")
            show_access_info
            ;;
        "all"|*)
            configure_oauth_provider
            echo ""
            configure_guacamole_oidc
            echo ""
            show_access_info
            ;;
    esac
}

# Ejecutar
main "$@"
EOF

# 3. Crear Applications
echo "🎯 Creando aplicaciones..."
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.core.models import Application
from authentik.providers.rac.models import RacProvider

# Obtener los providers
user_provider = RacProvider.objects.get(slug="kolaboree-user-panel")
admin_provider = RacProvider.objects.get(slug="kolaboree-admin-panel")

# Crear Application para usuarios
user_app = Application.objects.create(
    name="Kolaboree User Dashboard",
    slug="kolaboree-user",
    provider=user_provider,
    meta_launch_url="http://34.68.124.46/user",
    meta_description="Panel de usuario de Kolaboree NG",
    meta_icon="https://cdn-icons-png.flaticon.com/512/1077/1077114.png"
)

# Crear Application para admin
admin_app = Application.objects.create(
    name="Kolaboree Admin Dashboard", 
    slug="kolaboree-admin",
    provider=admin_provider,
    meta_launch_url="http://34.68.124.46/admin",
    meta_description="Panel administrativo de Kolaboree NG",
    meta_icon="https://cdn-icons-png.flaticon.com/512/1077/1077063.png"
)

print(f"✅ Aplicación Usuario creada: {user_app.name}")
print(f"✅ Aplicación Admin creada: {admin_app.name}")
EOF

echo "🎉 Configuración básica de RAC completada!"
echo "🌐 Accede a Authentik en: http://localhost:9000"
echo "👤 Usuario: akadmin"
echo "🔑 Ve a Applications para ver las aplicaciones creadas"