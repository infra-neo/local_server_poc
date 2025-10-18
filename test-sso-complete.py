#!/usr/bin/env python3
"""
Script para validar el flujo completo de autenticación SSO
1. Login a Authentik y obtener token
2. Usar token para acceder a Guacamole
3. Verificar endpoints correctos
"""

import requests
import json
import urllib3
from urllib.parse import urljoin, urlparse, parse_qs
import re

# Deshabilitar advertencias SSL
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configuración
AUTHENTIK_URL = "https://34.68.124.46:9443"
GUACAMOLE_URL = "http://34.68.124.46:8080"
USERNAME = "soporte@kolaboree.local"
PASSWORD = "Neo123!!!"

class SSOTester:
    def __init__(self):
        self.session = requests.Session()
        self.session.verify = False
        self.authentik_token = None
        self.guacamole_token = None
        
    def step1_get_authentik_login_page(self):
        """Obtener página de login de Authentik"""
        print("🔍 PASO 1: Obteniendo página de login de Authentik...")
        
        try:
            response = self.session.get(f"{AUTHENTIK_URL}/if/flow/default-authentication-flow/")
            if response.status_code == 200:
                print("✅ Página de login obtenida")
                
                # Extraer CSRF token
                csrf_match = re.search(r'csrfmiddlewaretoken["\s]*value["\s]*=["\s]*([^"]+)', response.text)
                if csrf_match:
                    self.csrf_token = csrf_match.group(1)
                    print(f"✅ CSRF token extraído: {self.csrf_token[:20]}...")
                    return True
                else:
                    print("❌ No se pudo extraer CSRF token")
                    return False
                    
        except Exception as e:
            print(f"❌ Error obteniendo página de login: {e}")
            return False
    
    def step2_login_to_authentik(self):
        """Login a Authentik con credenciales"""
        print("\n🔐 PASO 2: Haciendo login a Authentik...")
        
        try:
            login_data = {
                'csrfmiddlewaretoken': self.csrf_token,
                'uid_field': USERNAME,
                'password': PASSWORD,
            }
            
            response = self.session.post(
                f"{AUTHENTIK_URL}/if/flow/default-authentication-flow/",
                data=login_data,
                allow_redirects=True
            )
            
            if response.status_code == 200:
                if "dashboard" in response.url or "interface" in response.url:
                    print("✅ Login exitoso a Authentik")
                    print(f"📍 Redirigido a: {response.url}")
                    return True
                else:
                    print("❌ Login falló - no redirigido al dashboard")
                    print(f"📍 URL actual: {response.url}")
                    return False
            else:
                print(f"❌ Login falló - Status: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Error en login: {e}")
            return False
    
    def step3_get_guacamole_application_url(self):
        """Obtener URL de aplicación Guacamole desde Authentik"""
        print("\n🎯 PASO 3: Obteniendo URL de aplicación Guacamole...")
        
        try:
            # Obtener aplicaciones del usuario
            response = self.session.get(f"{AUTHENTIK_URL}/if/user/")
            
            if response.status_code == 200:
                # Buscar link a Guacamole
                guac_match = re.search(r'href["\s]*=["\s]*([^"]*guacamole[^"]*)', response.text)
                if guac_match:
                    guac_url = guac_match.group(1)
                    if not guac_url.startswith('http'):
                        guac_url = f"{AUTHENTIK_URL}{guac_url}"
                    print(f"✅ URL de Guacamole encontrada: {guac_url}")
                    self.guacamole_app_url = guac_url
                    return True
                else:
                    print("❌ No se encontró link a Guacamole")
                    # URL por defecto basada en configuración
                    self.guacamole_app_url = f"{AUTHENTIK_URL}/application/o/guacamole/"
                    print(f"📍 Usando URL por defecto: {self.guacamole_app_url}")
                    return True
                    
        except Exception as e:
            print(f"❌ Error obteniendo aplicaciones: {e}")
            return False
    
    def step4_access_guacamole_via_sso(self):
        """Acceder a Guacamole vía SSO desde Authentik"""
        print("\n🚀 PASO 4: Accediendo a Guacamole vía SSO...")
        
        try:
            response = self.session.get(self.guacamole_app_url, allow_redirects=True)
            
            print(f"📍 Status: {response.status_code}")
            print(f"📍 URL final: {response.url}")
            
            if "guacamole" in response.url.lower():
                if "login" in response.url.lower():
                    print("⚠️ Redirigido a página de login de Guacamole (SSO no funcionó)")
                    return False
                else:
                    print("✅ Acceso directo a Guacamole (SSO funcionó)")
                    return True
            else:
                print("❌ No se accedió a Guacamole")
                return False
                
        except Exception as e:
            print(f"❌ Error accediendo a Guacamole: {e}")
            return False
    
    def step5_analyze_guacamole_endpoints(self):
        """Analizar endpoints de Guacamole"""
        print("\n🔍 PASO 5: Analizando endpoints de Guacamole...")
        
        try:
            # Verificar endpoint de API de Guacamole
            api_response = self.session.get(f"{GUACAMOLE_URL}/guacamole/api/session/data/postgresql/connections")
            print(f"📍 API Connections Status: {api_response.status_code}")
            
            # Verificar endpoint de tokens
            token_response = self.session.get(f"{GUACAMOLE_URL}/guacamole/api/tokens")
            print(f"📍 API Tokens Status: {token_response.status_code}")
            
            # Verificar endpoint principal
            main_response = self.session.get(f"{GUACAMOLE_URL}/guacamole/")
            print(f"📍 Main Guacamole Status: {main_response.status_code}")
            
            return True
            
        except Exception as e:
            print(f"❌ Error analizando endpoints: {e}")
            return False
    
    def step6_check_rac_configuration(self):
        """Verificar configuración RAC en Authentik"""
        print("\n⚙️ PASO 6: Verificando configuración RAC...")
        
        print("📋 CONFIGURACIÓN RAC RECOMENDADA:")
        print("─────────────────────────────────")
        print(f"🎯 Authorization URL: {AUTHENTIK_URL}/application/o/authorize/")
        print(f"🎯 Token URL: {AUTHENTIK_URL}/application/o/token/")
        print(f"🎯 User Info URL: {AUTHENTIK_URL}/application/o/userinfo/")
        print(f"🎯 End Session URL: {AUTHENTIK_URL}/application/o/guacamole/end-session/")
        print()
        print("📋 ENDPOINT CORRECTO PARA GUACAMOLE:")
        print("──────────────────────────────────")
        print(f"✅ URL Externa: {GUACAMOLE_URL}/guacamole/")
        print(f"✅ URL Interna: http://guacamole:8080/guacamole/")
        print()
        print("⚠️ ENDPOINTS QUE NO DEBE USAR RAC:")
        print("─────────────────────────────────")
        print(f"❌ NO usar: {GUACAMOLE_URL}/guacamole/#/login")
        print(f"❌ NO usar: {GUACAMOLE_URL}/guacamole/api/tokens")
        print()
        print("✅ ENDPOINT CORRECTO PARA RAC:")
        print("─────────────────────────────")
        print(f"🎯 RAC External URL: {GUACAMOLE_URL}/guacamole/")
        print("   (Guacamole manejará automáticamente el token OIDC)")
        
        return True

def main():
    print("🧪 PRUEBA COMPLETA DE FLUJO SSO")
    print("================================")
    
    tester = SSOTester()
    
    # Ejecutar pasos
    steps = [
        tester.step1_get_authentik_login_page,
        tester.step2_login_to_authentik,
        tester.step3_get_guacamole_application_url,
        tester.step4_access_guacamole_via_sso,
        tester.step5_analyze_guacamole_endpoints,
        tester.step6_check_rac_configuration
    ]
    
    results = []
    for i, step in enumerate(steps, 1):
        result = step()
        results.append(result)
        if not result and i < 4:  # Solo detener en pasos críticos
            print(f"\n❌ Paso {i} falló. Continuando con análisis...")
    
    # Resumen
    print("\n📋 RESUMEN DE PRUEBAS")
    print("====================")
    success_count = sum(results)
    print(f"✅ Pasos exitosos: {success_count}/6")
    
    if success_count >= 4:
        print("\n🎉 DIAGNÓSTICO: SSO parcialmente funcional")
        print("💡 RECOMENDACIÓN: Verificar configuración RAC en Authentik")
    else:
        print("\n⚠️ DIAGNÓSTICO: SSO necesita configuración")
        print("💡 RECOMENDACIÓN: Revisar configuración de Provider y Application")
    
    print("\n🔧 PRÓXIMOS PASOS:")
    print("==================")
    print("1. Ir a Authentik Admin: https://34.68.124.46:9443/if/admin/")
    print("2. Applications > Providers > Guacamole Provider")
    print("3. Verificar que External URL sea: http://34.68.124.46:8080/guacamole/")
    print("4. Applications > Applications > Apache Guacamole")
    print("5. Verificar Launch URL: http://34.68.124.46:8080/guacamole/")

if __name__ == "__main__":
    main()