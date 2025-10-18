#!/usr/bin/env python3
"""
Script simple para configurar OIDC Provider para Guacamole
"""

import requests
import json
import subprocess
from urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

def show_guacamole_config():
    """Mostrar la configuración necesaria para Guacamole"""
    
    print("🔧 CONFIGURACIÓN OIDC PARA GUACAMOLE")
    print("="*50)
    
    print("\n📋 DATOS PARA AUTHENTIK PROVIDER:")
    print("▶️ Client ID: guacamole-rac-client")
    print("▶️ Client Secret: guacamole-rac-secret-2024")
    print("▶️ Redirect URI: https://34.68.124.46:8080/guacamole/")
    print("▶️ Scopes: openid profile email")
    
    print("\n🔗 ENDPOINTS:")
    print("▶️ Authorization: https://34.68.124.46:9443/application/o/authorize/")
    print("▶️ Token: https://34.68.124.46:9443/application/o/token/")
    print("▶️ UserInfo: https://34.68.124.46:9443/application/o/userinfo/")
    print("▶️ Issuer: https://34.68.124.46:9443/application/o/guacamole/")
    print("▶️ JWKS: https://34.68.124.46:9443/application/o/guacamole/jwks/")
    
    print("\n🐳 VARIABLES PARA DOCKER-COMPOSE GUACAMOLE:")
    config = {
        "OPENID_AUTHORIZATION_ENDPOINT": "https://34.68.124.46:9443/application/o/authorize/",
        "OPENID_CLIENT_ID": "guacamole-rac-client",
        "OPENID_ISSUER": "https://34.68.124.46:9443/application/o/guacamole/",
        "OPENID_JWKS_ENDPOINT": "https://34.68.124.46:9443/application/o/guacamole/jwks/",
        "OPENID_REDIRECT_URI": "https://34.68.124.46:8080/guacamole/",
        "OPENID_USERNAME_CLAIM_TYPE": "preferred_username",
        "OPENID_ENABLED": "true",
        "EXTENSION_PRIORITY": "*,openid"
    }
    
    for key, value in config.items():
        print(f"{key}={value}")
    
    return config

def update_docker_compose():
    """Actualizar docker-compose.yml con variables OIDC"""
    print("\n🔧 Actualizando docker-compose.yml...")
    
    # Leer el archivo actual
    try:
        with open('docker-compose.yml', 'r') as f:
            content = f.read()
        
        # Buscar la sección de guacamole
        if 'kolaboree-guacamole:' in content:
            print("✅ Encontrada sección de Guacamole")
            
            # Las variables OIDC que necesitamos agregar
            oidc_vars = """      # OIDC Configuration for Authentik
      - OPENID_AUTHORIZATION_ENDPOINT=https://34.68.124.46:9443/application/o/authorize/
      - OPENID_CLIENT_ID=guacamole-rac-client
      - OPENID_ISSUER=https://34.68.124.46:9443/application/o/guacamole/
      - OPENID_JWKS_ENDPOINT=https://34.68.124.46:9443/application/o/guacamole/jwks/
      - OPENID_REDIRECT_URI=https://34.68.124.46:8080/guacamole/
      - OPENID_USERNAME_CLAIM_TYPE=preferred_username
      - OPENID_ENABLED=true
      - EXTENSION_PRIORITY=*,openid"""
            
            # Verificar si ya están las variables OIDC
            if 'OPENID_ENABLED' in content:
                print("⚠️ Variables OIDC ya existen en docker-compose.yml")
                return True
            
            # Buscar donde insertar las variables (después de environment:)
            lines = content.split('\n')
            new_lines = []
            in_guacamole_env = False
            oidc_added = False
            
            for line in lines:
                new_lines.append(line)
                
                # Detectar sección de guacamole
                if 'kolaboree-guacamole:' in line:
                    in_guacamole_env = True
                
                # Si estamos en guacamole y encontramos environment:
                if in_guacamole_env and 'environment:' in line and not oidc_added:
                    # Agregar las variables OIDC
                    new_lines.extend(oidc_vars.split('\n'))
                    oidc_added = True
                
                # Salir de la sección si encontramos otro servicio
                if in_guacamole_env and line.strip() and not line.startswith(' ') and not line.startswith('\t') and 'kolaboree-guacamole:' not in line:
                    in_guacamole_env = False
            
            if oidc_added:
                # Escribir el archivo actualizado
                with open('docker-compose.yml', 'w') as f:
                    f.write('\n'.join(new_lines))
                print("✅ docker-compose.yml actualizado con variables OIDC")
                return True
            else:
                print("❌ No se pudo encontrar dónde insertar las variables OIDC")
                return False
        else:
            print("❌ No se encontró sección de Guacamole en docker-compose.yml")
            return False
            
    except Exception as e:
        print(f"❌ Error actualizando docker-compose.yml: {e}")
        return False

def create_guacamole_properties():
    """Crear archivo guacamole.properties si no existe"""
    print("\n📝 Verificando guacamole.properties...")
    
    properties_content = """# Guacamole Configuration
# Enable environment properties
enable-environment-properties: true

# PostgreSQL Database Configuration  
postgresql-hostname: kolaboree-postgres
postgresql-port: 5432
postgresql-database: kolaboree
postgresql-username: kolaboree
postgresql-password: kolaboree_password_2024

# OIDC Extension Configuration (from environment variables)
# OPENID_* variables will be loaded from environment
"""
    
    try:
        # Crear directorio si no existe
        subprocess.run(['mkdir', '-p', 'guacamole'], check=True)
        
        # Crear archivo de propiedades
        with open('guacamole/guacamole.properties', 'w') as f:
            f.write(properties_content)
        
        print("✅ Archivo guacamole/guacamole.properties creado")
        return True
        
    except Exception as e:
        print(f"❌ Error creando guacamole.properties: {e}")
        return False

def main():
    print("🔐 CONFIGURACIÓN OIDC PARA GUACAMOLE")
    print("Siguiendo: https://integrations.goauthentik.io/infrastructure/apache-guacamole/")
    print("="*60)
    
    # 1. Mostrar configuración
    config = show_guacamole_config()
    
    # 2. Actualizar docker-compose
    if update_docker_compose():
        print("✅ Docker Compose actualizado")
    
    # 3. Crear guacamole.properties
    if create_guacamole_properties():
        print("✅ Guacamole properties creado")
    
    print("\n📋 PRÓXIMOS PASOS MANUALES:")
    print("1. Acceder a Authentik Admin: https://34.68.124.46:9443/if/admin/")
    print("2. Ir a Applications > Providers")
    print("3. Crear OAuth2/OpenID Connect Provider con:")
    print("   - Name: Guacamole OIDC Provider")
    print("   - Client ID: guacamole-rac-client")
    print("   - Client Secret: guacamole-rac-secret-2024")
    print("   - Redirect URIs: https://34.68.124.46:8080/guacamole/")
    print("4. Crear Application:")
    print("   - Name: Apache Guacamole")
    print("   - Slug: guacamole")
    print("   - Provider: (seleccionar el creado arriba)")
    print("5. Reiniciar Guacamole: docker-compose restart kolaboree-guacamole")
    
    print("\n🎯 VERIFICACIÓN:")
    print("- URL Guacamole: https://34.68.124.46:8080/guacamole/")
    print("- Debería aparecer botón 'Login with OIDC' o redirect automático")
    
    return True

if __name__ == "__main__":
    main()