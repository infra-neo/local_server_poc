#!/usr/bin/env python3
"""
Script para corregir el RAC Provider en Authentik
Soluciona el error: 'NoneType' object has no attribute 'slug'
"""

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class AuthentikRACFixer:
    def __init__(self):
        self.base_url = "https://34.68.124.46:9443"
        self.session = requests.Session()
        self.session.verify = False
        
    def get_auth_token(self, username, password):
        """Obtener token de autenticación"""
        print("🔐 Obteniendo token de autenticación...")
        
        # Obtener la página de login para el token CSRF
        login_page = self.session.get(f"{self.base_url}/if/flow/default-authentication-flow/")
        
        # Buscar token CSRF en la página
        csrf_token = None
        for line in login_page.text.split('\n'):
            if 'csrfmiddlewaretoken' in line and 'value=' in line:
                csrf_token = line.split('value="')[1].split('"')[0]
                break
        
        if not csrf_token:
            print("❌ No se pudo obtener token CSRF")
            return None
            
        # Realizar login
        login_data = {
            'uid_field': username,
            'password': password,
            'csrfmiddlewaretoken': csrf_token
        }
        
        response = self.session.post(
            f"{self.base_url}/if/flow/default-authentication-flow/",
            data=login_data,
            allow_redirects=False
        )
        
        if response.status_code in [302, 200]:
            print("✅ Autenticación exitosa")
            return True
        else:
            print(f"❌ Error en autenticación: {response.status_code}")
            return False
    
    def get_flows(self):
        """Obtener flows disponibles"""
        print("📋 Obteniendo flows disponibles...")
        
        response = self.session.get(f"{self.base_url}/api/v3/flows/instances/")
        
        if response.status_code == 200:
            flows = response.json()['results']
            print(f"✅ Encontrados {len(flows)} flows")
            
            for flow in flows:
                print(f"  🔄 {flow['name']} (slug: {flow['slug']}) - {flow['designation']}")
                
            return flows
        else:
            print(f"❌ Error obteniendo flows: {response.status_code}")
            return []
    
    def get_providers(self):
        """Obtener providers configurados"""
        print("🔌 Obteniendo providers...")
        
        response = self.session.get(f"{self.base_url}/api/v3/providers/rac/")
        
        if response.status_code == 200:
            providers = response.json()['results']
            print(f"✅ Encontrados {len(providers)} RAC providers")
            
            for provider in providers:
                print(f"  🖥️  {provider['name']}")
                print(f"     PK: {provider['pk']}")
                print(f"     Auth Flow: {provider.get('authorization_flow', 'NO CONFIGURADO')}")
                print(f"     Settings: {provider.get('settings', {})}")
                
            return providers
        else:
            print(f"❌ Error obteniendo providers: {response.status_code}")
            return []
    
    def fix_rac_provider(self, provider_pk, auth_flow_slug="default-authorization-flow"):
        """Corregir RAC provider asignando flow de autorización"""
        print(f"🔧 Corrigiendo RAC provider {provider_pk}...")
        
        # Obtener detalles del provider actual
        response = self.session.get(f"{self.base_url}/api/v3/providers/rac/{provider_pk}/")
        
        if response.status_code != 200:
            print(f"❌ Error obteniendo provider: {response.status_code}")
            return False
        
        provider_data = response.json()
        print(f"📋 Provider actual: {provider_data['name']}")
        
        # Actualizar provider con flow de autorización
        update_data = {
            "name": provider_data['name'],
            "authorization_flow": auth_flow_slug,
            "invalidation_flow": "default-invalidation-flow",
            "settings": provider_data.get('settings', {})
        }
        
        response = self.session.put(
            f"{self.base_url}/api/v3/providers/rac/{provider_pk}/",
            json=update_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ RAC provider corregido exitosamente")
            updated_provider = response.json()
            print(f"  ✅ Authorization flow: {updated_provider.get('authorization_flow')}")
            return True
        else:
            print(f"❌ Error actualizando provider: {response.status_code}")
            print(f"Response: {response.text}")
            return False
    
    def run_fix(self):
        """Ejecutar corrección completa"""
        print("🚀 Iniciando corrección del RAC Provider")
        print("=" * 50)
        
        # Autenticación
        if not self.get_auth_token("akadmin", "Kolaboree2024!Admin"):
            print("❌ No se pudo autenticar")
            return False
        
        # Obtener flows
        flows = self.get_flows()
        auth_flows = [f for f in flows if f['designation'] == 'authorization']
        
        if not auth_flows:
            print("❌ No se encontraron flows de autorización")
            return False
        
        default_auth_flow = auth_flows[0]['slug']
        print(f"🔄 Usando flow de autorización: {default_auth_flow}")
        
        # Obtener providers RAC
        providers = self.get_providers()
        
        if not providers:
            print("❌ No se encontraron RAC providers")
            return False
        
        # Corregir cada provider
        success = True
        for provider in providers:
            if not provider.get('authorization_flow'):
                print(f"\n🔧 Provider sin authorization_flow: {provider['name']}")
                if not self.fix_rac_provider(provider['pk'], default_auth_flow):
                    success = False
            else:
                print(f"✅ Provider OK: {provider['name']}")
        
        return success

if __name__ == "__main__":
    print("🔧 RAC Provider Fixer - Authentik")
    print("Solucionando: 'NoneType' object has no attribute 'slug'")
    print("=" * 60)
    
    try:
        fixer = AuthentikRACFixer()
        success = fixer.run_fix()
        
        if success:
            print("\n✅ Corrección completada exitosamente")
            print("🎯 Próximos pasos:")
            print("   1. Probar acceso RAC nuevamente")
            print("   2. Verificar que no hay más errores en logs")
            print("   3. Configurar OAuth2 provider para Guacamole")
        else:
            print("\n❌ Hubo errores durante la corrección")
            print("🔍 Revisa los logs y configura manualmente")
            
    except Exception as e:
        print(f"\n❌ Error inesperado: {e}")
        import traceback
        traceback.print_exc()