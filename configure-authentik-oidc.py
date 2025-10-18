#!/usr/bin/env python3
"""
Script para configurar automaticamente el OIDC Provider en Authentik para Guacamole
"""

import requests
import json
import urllib3
from urllib3.exceptions import InsecureRequestWarning

# Deshabilitar warnings SSL
urllib3.disable_warnings(InsecureRequestWarning)

class AuthentikConfigurator:
    def __init__(self, base_url, username, password):
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.session.verify = False
        self.token = None
        
    def login(self):
        """Login en Authentik y obtener token de sesión"""
        print("🔐 Logging into Authentik...")
        
        # Primero obtener el formulario de login
        login_url = f"{self.base_url}/if/flow/default-authentication-flow/"
        response = self.session.get(login_url)
        
        if response.status_code != 200:
            print(f"❌ Error getting login form: {response.status_code}")
            return False
        
        # Extraer CSRF token si es necesario
        # En este caso usaremos la API directamente
        
        # Intentar login directo con las credenciales
        api_login_url = f"{self.base_url}/api/v3/core/tokens/"
        
        # Primero intentar obtener token API
        auth_data = {
            "username": self.username,
            "password": self.password
        }
        
        # Usar autenticación básica para obtener token
        response = self.session.post(
            f"{self.base_url}/api/v3/core/tokens/",
            auth=(self.username, self.password),
            json={
                "identifier": f"guacamole-config-{self.username}",
                "description": "Token for Guacamole OIDC configuration"
            }
        )
        
        if response.status_code == 201:
            token_data = response.json()
            self.token = token_data.get('key')
            self.session.headers.update({'Authorization': f'Bearer {self.token}'})
            print("✅ Successfully logged into Authentik API")
            return True
        else:
            print(f"❌ Login failed: {response.status_code} - {response.text}")
            return False
    
    def create_oauth_provider(self):
        """Crear el OAuth2/OpenID Connect Provider"""
        print("📝 Creating OAuth2 Provider...")
        
        provider_data = {
            "name": "Guacamole OIDC Provider",
            "client_id": "guacamole-rac-client",
            "client_secret": "guacamole-rac-secret-2024",
            "client_type": "confidential",
            "include_claims_in_id_token": True,
            "authorization_grant_type": "authorization-code",
            "redirect_uris": "https://34.68.124.46:8080/guacamole/",
            "sub_mode": "hashed_user_id",
            "issuer_mode": "per_provider",
            "signing_key": None  # Will use default
        }
        
        response = self.session.post(
            f"{self.base_url}/api/v3/providers/oauth2/",
            json=provider_data
        )
        
        if response.status_code == 201:
            provider = response.json()
            print(f"✅ OAuth2 Provider created with ID: {provider['pk']}")
            return provider
        else:
            print(f"❌ Failed to create provider: {response.status_code} - {response.text}")
            return None
    
    def create_application(self, provider_id):
        """Crear la Application que usa el provider"""
        print("🔗 Creating Application...")
        
        app_data = {
            "name": "Apache Guacamole",
            "slug": "guacamole",
            "provider": provider_id,
            "meta_launch_url": "https://34.68.124.46:8080/guacamole/",
            "meta_description": "Remote Desktop Gateway",
            "meta_publisher": "Kolaboree",
            "policy_engine_mode": "any",
            "open_in_new_tab": False
        }
        
        response = self.session.post(
            f"{self.base_url}/api/v3/core/applications/",
            json=app_data
        )
        
        if response.status_code == 201:
            app = response.json()
            print(f"✅ Application created: {app['name']}")
            return app
        else:
            print(f"❌ Failed to create application: {response.status_code} - {response.text}")
            return None
    
    def verify_configuration(self):
        """Verificar que todo esté configurado correctamente"""
        print("🔍 Verifying configuration...")
        
        # Verificar provider
        response = self.session.get(f"{self.base_url}/api/v3/providers/oauth2/")
        if response.status_code == 200:
            providers = response.json()['results']
            guac_provider = next((p for p in providers if p['client_id'] == 'guacamole-rac-client'), None)
            if guac_provider:
                print(f"✅ Provider found: {guac_provider['name']}")
                
                # Verificar application
                app_response = self.session.get(f"{self.base_url}/api/v3/core/applications/")
                if app_response.status_code == 200:
                    apps = app_response.json()['results']
                    guac_app = next((a for a in apps if a['slug'] == 'guacamole'), None)
                    if guac_app:
                        print(f"✅ Application found: {guac_app['name']}")
                        print(f"✅ Configuration complete!")
                        
                        print("\n🔗 ENDPOINTS CONFIGURADOS:")
                        print(f"Authorization: {self.base_url}/application/o/authorize/")
                        print(f"Token: {self.base_url}/application/o/token/")
                        print(f"UserInfo: {self.base_url}/application/o/userinfo/")
                        print(f"Issuer: {self.base_url}/application/o/guacamole/")
                        print(f"JWKS: {self.base_url}/application/o/guacamole/jwks/")
                        
                        return True
        
        print("❌ Configuration verification failed")
        return False

def main():
    print("🔐 AUTHENTIK OIDC PROVIDER CONFIGURATOR")
    print("Configurando provider para Guacamole...")
    print("="*50)
    
    # Configuración
    authentik_url = "https://34.68.124.46:9443"
    username = "akadmin"
    password = "Kolaboree2024!Admin"
    
    # Inicializar configurador
    configurator = AuthentikConfigurator(authentik_url, username, password)
    
    # Login
    if not configurator.login():
        print("❌ No se pudo hacer login en Authentik")
        return False
    
    # Crear provider
    provider = configurator.create_oauth_provider()
    if not provider:
        print("❌ No se pudo crear el OAuth2 Provider")
        return False
    
    # Crear application
    app = configurator.create_application(provider['pk'])
    if not app:
        print("❌ No se pudo crear la Application")
        return False
    
    # Verificar configuración
    if configurator.verify_configuration():
        print("\n🎉 ¡CONFIGURACIÓN COMPLETADA!")
        print("\n📋 PRÓXIMOS PASOS:")
        print("1. Reiniciar Guacamole para aplicar la configuración OIDC:")
        print("   docker-compose restart guacamole")
        print("\n2. Acceder a Guacamole:")
        print("   https://34.68.124.46:8080/guacamole/")
        print("\n3. Debería aparecer opción de login con OIDC")
        
        return True
    else:
        print("❌ La verificación falló")
        return False

if __name__ == "__main__":
    main()