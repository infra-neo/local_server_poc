#!/usr/bin/env python3
"""
Configurar OAuth2/OIDC Provider para Guacamole en Authentik
Siguiendo: https://integrations.goauthentik.io/infrastructure/apache-guacamole/
"""

import requests
import json
import sys
from urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

class AuthentikConfigurator:
    def __init__(self):
        self.base_url = "https://34.68.124.46:9443"
        self.session = requests.Session()
        self.session.verify = False
        self.token = None
        
    def login_admin(self):
        """Login como admin para obtener token de autenticación"""
        print("🔐 Iniciando sesión en Authentik como admin...")
        
        # Paso 1: Obtener flow
        response = self.session.get(f"{self.base_url}/api/v3/flows/executor/default-authentication-flow/")
        if response.status_code != 200:
            print(f"❌ Error obteniendo flow: {response.status_code}")
            return False
        
        # Paso 2: Enviar username
        response = self.session.post(
            f"{self.base_url}/api/v3/flows/executor/default-authentication-flow/",
            json={'uid_field': 'akadmin'},
            headers={'Content-Type': 'application/json'}
        )
        if response.status_code != 200:
            print(f"❌ Error enviando username: {response.status_code}")
            return False
        
        # Paso 3: Enviar password
        response = self.session.post(
            f"{self.base_url}/api/v3/flows/executor/default-authentication-flow/",
            json={'password': 'Kolaboree2024!Admin'},
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get('component') == 'xak-flow-redirect':
                print("✅ Login exitoso")
                return True
        
        print(f"❌ Error en login: {response.status_code}")
        return False
    
    def get_oauth_providers(self):
        """Obtener providers OAuth2 existentes"""
        response = self.session.get(f"{self.base_url}/api/v3/providers/oauth2/")
        if response.status_code == 200:
            return response.json()
        return None
    
    def create_oauth_provider(self):
        """Crear OAuth2/OIDC Provider para Guacamole"""
        print("🏗️ Creando OAuth2/OIDC Provider para Guacamole...")
        
        # Configuración del provider según la documentación
        provider_config = {
            "name": "Guacamole OIDC Provider",
            "authorization_flow": "e3eb4c5e-10b6-4cb6-abc6-5b27c2b08055",  # default-authentication-flow UUID
            "property_mappings": [],
            "client_id": "guacamole-rac-client",
            "client_secret": "guacamole-rac-secret-2024",
            "client_type": "confidential",
            "jwks_sources": [],
            "redirect_uris": "https://34.68.124.46:8080/guacamole/",
            "sub_mode": "hashed_user_id",
            "include_claims_in_id_token": True,
            "issuer_mode": "per_provider",
            "access_token_validity": "minutes=30",
            "refresh_token_validity": "days=30",
            "signing_key": None  # Usará la clave por defecto
        }
        
        response = self.session.post(
            f"{self.base_url}/api/v3/providers/oauth2/",
            json=provider_config,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 201:
            provider_data = response.json()
            print(f"✅ Provider creado con ID: {provider_data['pk']}")
            return provider_data
        else:
            print(f"❌ Error creando provider: {response.status_code}")
            print(f"Response: {response.text}")
            return None
    
    def get_applications(self):
        """Obtener aplicaciones existentes"""
        response = self.session.get(f"{self.base_url}/api/v3/core/applications/")
        if response.status_code == 200:
            return response.json()
        return None
    
    def create_application(self, provider_id):
        """Crear aplicación para Guacamole"""
        print("📱 Creando aplicación para Guacamole...")
        
        app_config = {
            "name": "Apache Guacamole",
            "slug": "guacamole",
            "provider": provider_id,
            "meta_launch_url": "https://34.68.124.46:8080/guacamole/",
            "meta_description": "Apache Guacamole - Clientless Remote Desktop Gateway",
            "meta_publisher": "Apache Software Foundation",
            "policy_engine_mode": "any",
            "open_in_new_tab": True
        }
        
        response = self.session.post(
            f"{self.base_url}/api/v3/core/applications/",
            json=app_config,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 201:
            app_data = response.json()
            print(f"✅ Aplicación creada con slug: {app_data['slug']}")
            return app_data
        else:
            print(f"❌ Error creando aplicación: {response.status_code}")
            print(f"Response: {response.text}")
            return None
    
    def configure_guacamole_oidc(self):
        """Configurar integración completa"""
        print("🔧 Configurando integración OIDC para Guacamole...")
        
        # 1. Login como admin
        if not self.login_admin():
            return False
        
        # 2. Verificar si ya existe el provider
        providers = self.get_oauth_providers()
        if providers:
            existing = [p for p in providers['results'] if p['client_id'] == 'guacamole-rac-client']
            if existing:
                print(f"⚠️ Provider ya existe: {existing[0]['name']}")
                provider_data = existing[0]
            else:
                provider_data = self.create_oauth_provider()
                if not provider_data:
                    return False
        else:
            provider_data = self.create_oauth_provider()
            if not provider_data:
                return False
        
        # 3. Verificar si ya existe la aplicación
        apps = self.get_applications()
        if apps:
            existing_app = [a for a in apps['results'] if a['slug'] == 'guacamole']
            if existing_app:
                print(f"⚠️ Aplicación ya existe: {existing_app[0]['name']}")
                app_data = existing_app[0]
            else:
                app_data = self.create_application(provider_data['pk'])
                if not app_data:
                    return False
        else:
            app_data = self.create_application(provider_data['pk'])
            if not app_data:
                return False
        
        # 4. Mostrar información de configuración
        self.show_configuration_info(provider_data, app_data)
        
        return True
    
    def show_configuration_info(self, provider_data, app_data):
        """Mostrar información de configuración para Guacamole"""
        print("\n" + "="*60)
        print("🎯 CONFIGURACIÓN COMPLETADA - INFORMACIÓN PARA GUACAMOLE")
        print("="*60)
        
        print(f"\n📋 DATOS DEL PROVIDER:")
        print(f"▶️ Client ID: {provider_data['client_id']}")
        print(f"▶️ Client Secret: {provider_data['client_secret']}")
        print(f"▶️ Provider ID: {provider_data['pk']}")
        print(f"▶️ Slug: {app_data['slug']}")
        
        print(f"\n🔗 ENDPOINTS OIDC:")
        print(f"▶️ Authorization: {self.base_url}/application/o/authorize/")
        print(f"▶️ Token: {self.base_url}/application/o/token/")
        print(f"▶️ UserInfo: {self.base_url}/application/o/userinfo/")
        print(f"▶️ Issuer: {self.base_url}/application/o/{app_data['slug']}/")
        print(f"▶️ JWKS: {self.base_url}/application/o/{app_data['slug']}/jwks/")
        
        print(f"\n🐳 VARIABLES DE ENTORNO PARA GUACAMOLE:")
        print(f"OPENID_AUTHORIZATION_ENDPOINT={self.base_url}/application/o/authorize/")
        print(f"OPENID_CLIENT_ID={provider_data['client_id']}")
        print(f"OPENID_ISSUER={self.base_url}/application/o/{app_data['slug']}/")
        print(f"OPENID_JWKS_ENDPOINT={self.base_url}/application/o/{app_data['slug']}/jwks/")
        print(f"OPENID_REDIRECT_URI=https://34.68.124.46:8080/guacamole/")
        print(f"OPENID_USERNAME_CLAIM_TYPE=preferred_username")
        print(f"OPENID_ENABLED=true")
        print(f"EXTENSION_PRIORITY=*,openid")
        
        print(f"\n✅ URLs de Acceso:")
        print(f"▶️ Authentik Admin: {self.base_url}/if/admin/")
        print(f"▶️ Guacamole: https://34.68.124.46:8080/guacamole/")
        print(f"▶️ Aplicación: {self.base_url}/if/flow/default-authentication-flow/?next=/application/launch/{app_data['slug']}/")

def main():
    print("🔐 CONFIGURADOR OIDC PARA GUACAMOLE")
    print("Siguiendo: https://integrations.goauthentik.io/infrastructure/apache-guacamole/")
    print("=" * 60)
    
    configurator = AuthentikConfigurator()
    
    if configurator.configure_guacamole_oidc():
        print("\n🎉 ¡CONFIGURACIÓN COMPLETADA EXITOSAMENTE!")
        print("\n📝 Próximos pasos:")
        print("1. Aplicar las variables de entorno a Guacamole")
        print("2. Reiniciar el contenedor de Guacamole")
        print("3. Probar el login con OIDC")
        return True
    else:
        print("\n❌ Error en la configuración")
        return False

if __name__ == "__main__":
    sys.exit(0 if main() else 1)