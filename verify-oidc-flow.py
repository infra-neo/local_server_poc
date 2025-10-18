#!/usr/bin/env python3
"""
Script para verificar y obtener token de Authentik para Guacamole
"""

import requests
import json
import urllib3
import base64
from urllib.parse import urlparse, parse_qs

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

AUTHENTIK_URL = "https://34.68.124.46:9443"
GUACAMOLE_URL = "http://34.68.124.46:8080"

def test_oidc_endpoints():
    """Probar endpoints OIDC de Authentik"""
    print("🔍 VERIFICANDO ENDPOINTS OIDC DE AUTHENTIK")
    print("==========================================")
    
    session = requests.Session()
    session.verify = False
    
    # 1. Well-known configuration
    try:
        well_known_url = f"{AUTHENTIK_URL}/application/o/guacamole/.well-known/openid-configuration"
        response = session.get(well_known_url)
        print(f"📍 Well-known config: {response.status_code}")
        
        if response.status_code == 200:
            config = response.json()
            print("✅ Configuración OIDC obtenida:")
            print(f"   📋 Issuer: {config.get('issuer', 'N/A')}")
            print(f"   📋 Authorization endpoint: {config.get('authorization_endpoint', 'N/A')}")
            print(f"   📋 Token endpoint: {config.get('token_endpoint', 'N/A')}")
            print(f"   📋 Userinfo endpoint: {config.get('userinfo_endpoint', 'N/A')}")
            print(f"   📋 End session endpoint: {config.get('end_session_endpoint', 'N/A')}")
            return config
        else:
            print("❌ No se pudo obtener configuración OIDC")
            return None
            
    except Exception as e:
        print(f"❌ Error obteniendo well-known config: {e}")
        return None

def check_guacamole_oidc_config():
    """Verificar configuración OIDC en Guacamole"""
    print("\n🔍 VERIFICANDO CONFIGURACIÓN OIDC EN GUACAMOLE")
    print("==============================================")
    
    # Verificar variables de entorno de Guacamole
    import subprocess
    
    try:
        result = subprocess.run([
            'docker', 'exec', 'kolaboree-guacamole', 'env'
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            env_vars = result.stdout
            oidc_vars = [line for line in env_vars.split('\n') if 'OIDC' in line or 'OAUTH' in line]
            
            print("📋 Variables OIDC encontradas:")
            for var in oidc_vars:
                if var.strip():
                    print(f"   {var}")
            
            return oidc_vars
        else:
            print("❌ No se pudieron obtener variables de entorno")
            return []
            
    except Exception as e:
        print(f"❌ Error verificando variables: {e}")
        return []

def test_guacamole_oidc_flow():
    """Probar flujo OIDC completo"""
    print("\n🧪 PROBANDO FLUJO OIDC COMPLETO")
    print("===============================")
    
    session = requests.Session()
    session.verify = False
    
    # 1. Acceder a Guacamole directamente
    try:
        guac_response = session.get(f"{GUACAMOLE_URL}/guacamole/")
        print(f"📍 Guacamole directo: {guac_response.status_code}")
        
        if "login" in guac_response.url:
            print("🔄 Redirigido a login - verificando si es OIDC...")
            
            # Verificar si hay botón/link de OIDC
            if "oidc" in guac_response.text.lower() or "authentik" in guac_response.text.lower():
                print("✅ Login OIDC disponible en Guacamole")
            else:
                print("❌ No se encontró opción de login OIDC")
                
        # 2. Acceder vía Authentik
        print("\n🔄 Accediendo vía Authentik...")
        auth_response = session.get(f"{AUTHENTIK_URL}/application/o/guacamole/")
        print(f"📍 Authentik redirect: {auth_response.status_code}")
        print(f"📍 URL final: {auth_response.url}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error en flujo OIDC: {e}")
        return False

def generate_rac_config_guide():
    """Generar guía de configuración RAC"""
    print("\n📋 GUÍA DE CONFIGURACIÓN RAC PROVIDER")
    print("====================================")
    
    print("\n🎯 CONFIGURACIÓN EXACTA PARA RAC PROVIDER:")
    print("──────────────────────────────────────────")
    print("┌─────────────────────────────────────────────────────────────┐")
    print("│ Name: Guacamole RAC Provider                                │")
    print("│ Authentication flow: default-authentication-flow            │")
    print("│ Authorization flow: default-provider-authorization-explicit │")
    print("│                                                             │")
    print("│ PROTOCOL SETTINGS:                                          │")
    print("│ Client type: Confidential                                   │")
    print("│ Client ID: (generar automáticamente)                       │")
    print("│ Client secret: (generar automáticamente)                   │")
    print("│ Redirect URIs/Origins (HTTPS): https://34.68.124.46:9443/  │")
    print("│ Redirect URIs/Origins (HTTP): http://34.68.124.46:8080/    │")
    print("│                              guacamole/                     │")
    print("│                                                             │")
    print("│ ADVANCED PROTOCOL SETTINGS:                                │")
    print("│ Access code validity: 1 minutes                            │")
    print("│ Access token validity: 5 minutes                           │")
    print("│ Refresh token validity: 720 minutes                        │")
    print("│ Scopes: openid,profile,email                               │")
    print("│                                                             │")
    print("│ MACHINE-TO-MACHINE AUTHENTICATION:                         │")
    print("│ Algorithm: RS256                                            │")
    print("│ Key: authentik Self-signed Certificate                     │")
    print("└─────────────────────────────────────────────────────────────┘")
    
    print("\n🎯 CONFIGURACIÓN EXACTA PARA APPLICATION:")
    print("─────────────────────────────────────────")
    print("┌─────────────────────────────────────────────────────────────┐")
    print("│ Name: Apache Guacamole                                      │")
    print("│ Slug: guacamole                                             │")
    print("│ Provider: Guacamole RAC Provider                            │")
    print("│                                                             │")
    print("│ UI SETTINGS:                                                │")
    print("│ Launch URL: http://34.68.124.46:8080/guacamole/            │")
    print("│ Open in new tab: ✅ (marcado)                              │")
    print("│                                                             │")
    print("│ ICON:                                                       │")
    print("│ Icon: /static/dist/assets/icons/icon.svg                   │")
    print("└─────────────────────────────────────────────────────────────┘")

def main():
    print("🔧 VERIFICACIÓN COMPLETA DE CONFIGURACIÓN OIDC")
    print("==============================================")
    
    # Ejecutar verificaciones
    oidc_config = test_oidc_endpoints()
    guac_vars = check_guacamole_oidc_config()
    flow_test = test_guacamole_oidc_flow()
    
    # Generar guía
    generate_rac_config_guide()
    
    print("\n✅ VERIFICACIÓN COMPLETADA")
    print("=========================")
    
    print("\n🎯 ENDPOINT CORRECTO PARA RAC:")
    print("External URL: http://34.68.124.46:8080/guacamole/")
    print("(NO debe incluir #/login ni /api/tokens)")
    
    print("\n💡 FLUJO ESPERADO:")
    print("1. Usuario hace clic en 'Apache Guacamole' en Authentik")
    print("2. Authentik genera token OIDC y redirige a Guacamole")
    print("3. Guacamole recibe token, lo valida con Authentik")
    print("4. Guacamole autentica usuario y muestra conexiones")

if __name__ == "__main__":
    main()