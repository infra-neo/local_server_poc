#!/usr/bin/env python3
"""
Script para verificar la configuración de la aplicación RAC en Authentik
"""

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

AUTHENTIK_URL = "https://34.68.124.46:9443"

def check_authentik_applications():
    """Verificar aplicaciones disponibles en Authentik"""
    print("🔍 VERIFICANDO APLICACIONES EN AUTHENTIK")
    print("========================================")
    
    session = requests.Session()
    session.verify = False
    
    try:
        # Intentar obtener la página de usuario
        response = session.get(f"{AUTHENTIK_URL}/if/user/")
        print(f"📍 Status interfaz usuario: {response.status_code}")
        
        if response.status_code == 200:
            # Buscar aplicaciones en el HTML
            if "guacamole" in response.text.lower():
                print("✅ Aplicación Guacamole encontrada en interfaz")
            else:
                print("❌ Aplicación Guacamole NO encontrada en interfaz")
                
            # Buscar otros indicadores
            if "Apache" in response.text:
                print("✅ Referencia a Apache encontrada")
            else:
                print("❌ No se encontró referencia a Apache")
                
        return response.status_code == 200
        
    except Exception as e:
        print(f"❌ Error verificando aplicaciones: {e}")
        return False

def check_rac_provider():
    """Verificar configuración del RAC Provider"""
    print("\n🔍 VERIFICANDO RAC PROVIDER")
    print("===========================")
    
    # Verificar well-known configuration
    try:
        response = requests.get(
            f"{AUTHENTIK_URL}/application/o/guacamole/.well-known/openid-configuration",
            verify=False,
            timeout=10
        )
        
        if response.status_code == 200:
            config = response.json()
            print("✅ RAC Provider configurado correctamente")
            print(f"📋 Issuer: {config.get('issuer', 'N/A')}")
            print(f"📋 Authorization endpoint: {config.get('authorization_endpoint', 'N/A')}")
            print(f"📋 Token endpoint: {config.get('token_endpoint', 'N/A')}")
            return True
        else:
            print(f"❌ RAC Provider no configurado (Status: {response.status_code})")
            return False
            
    except Exception as e:
        print(f"❌ Error verificando RAC Provider: {e}")
        return False

def generate_fix_guide():
    """Generar guía de solución"""
    print("\n🔧 GUÍA DE SOLUCIÓN")
    print("==================")
    
    print("\n1. CREAR RAC PROVIDER:")
    print("---------------------")
    print("URL: https://34.68.124.46:9443/if/admin/")
    print("Ruta: Applications > Providers > Create")
    print("Tipo: OAuth2/OpenID Provider")
    print("")
    print("Configuración:")
    print("  Name: Guacamole RAC Provider")
    print("  Client ID: guacamole-rac-client")
    print("  Client type: Confidential")
    print("  Redirect URIs: http://34.68.124.46:8080/guacamole/")
    print("  Scopes: openid,profile,email,groups")
    
    print("\n2. CREAR APPLICATION:")
    print("--------------------")
    print("Ruta: Applications > Applications > Create")
    print("")
    print("Configuración:")
    print("  Name: Apache Guacamole")
    print("  Slug: guacamole")
    print("  Provider: Guacamole RAC Provider")
    print("  Launch URL: http://34.68.124.46:8080/guacamole/")
    print("  Open in new tab: ✅")
    
    print("\n3. ASIGNAR A USUARIO:")
    print("--------------------")
    print("Ruta: Applications > Applications > Apache Guacamole")
    print("Tab: Policy / Group / User Bindings")
    print("Agregar binding para usuario 'soporte' o grupo correspondiente")

def test_sso_flow():
    """Probar el flujo SSO manualmente"""
    print("\n🧪 PRUEBA MANUAL RECOMENDADA")
    print("============================")
    
    print("1. Abrir navegador en modo incógnito")
    print("2. Ir a: https://34.68.124.46:9443/if/user/")
    print("3. Login: soporte@kolaboree.local / Neo123!!!")
    print("4. Buscar 'Apache Guacamole' en la lista de aplicaciones")
    print("5. Hacer clic en la aplicación")
    print("6. Debería abrir Guacamole automáticamente")
    
    print("\n❌ SI NO VES LA APLICACIÓN:")
    print("  • La aplicación no está creada")
    print("  • El usuario no tiene permisos")
    print("  • La aplicación no está asignada al usuario")
    
    print("\n✅ SI VES LA APLICACIÓN PERO DA ERROR:")
    print("  • Verificar Launch URL")
    print("  • Verificar Client Secret")
    print("  • Revisar logs de Guacamole")

def main():
    print("🔍 DIAGNÓSTICO COMPLETO DE APLICACIÓN RAC")
    print("=========================================")
    
    # Verificar componentes
    apps_ok = check_authentik_applications()
    provider_ok = check_rac_provider()
    
    # Generar guía basada en resultados
    print(f"\n📊 RESULTADOS:")
    print(f"  Interfaz usuario Authentik: {'✅' if apps_ok else '❌'}")
    print(f"  RAC Provider configurado: {'✅' if provider_ok else '❌'}")
    
    if not apps_ok or not provider_ok:
        generate_fix_guide()
    else:
        print("\n✅ CONFIGURACIÓN BÁSICA CORRECTA")
        print("Si el SSO no funciona, el problema puede ser:")
        print("• Aplicación no creada en Authentik")
        print("• Usuario sin permisos a la aplicación")
        print("• Client Secret incorrecto")
    
    test_sso_flow()

if __name__ == "__main__":
    main()