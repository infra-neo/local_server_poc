#!/usr/bin/env python3
"""
Script para verificar que la configuración OIDC esté funcionando correctamente
"""

import requests
import urllib3
from urllib3.exceptions import InsecureRequestWarning

urllib3.disable_warnings(InsecureRequestWarning)

def test_authentik_endpoints():
    """Verificar que los endpoints de Authentik estén respondiendo"""
    print("🔍 VERIFICANDO ENDPOINTS DE AUTHENTIK")
    print("-" * 40)
    
    base_url = "https://34.68.124.46:9443"
    endpoints = {
        "Well-known OpenID": "/application/o/guacamole/.well-known/openid_configuration",
        "Authorization": "/application/o/authorize/",
        "Token": "/application/o/token/",
        "UserInfo": "/application/o/userinfo/",
        "JWKS": "/application/o/guacamole/jwks/"
    }
    
    session = requests.Session()
    session.verify = False
    
    for name, endpoint in endpoints.items():
        try:
            url = f"{base_url}{endpoint}"
            response = session.get(url, timeout=10)
            
            if name == "Well-known OpenID":
                if response.status_code == 200:
                    print(f"✅ {name}: {response.status_code} (configurado)")
                    # Mostrar algunos datos del well-known
                    try:
                        data = response.json()
                        print(f"   ├── Issuer: {data.get('issuer', 'N/A')}")
                        print(f"   ├── Authorization endpoint: {data.get('authorization_endpoint', 'N/A')}")
                        print(f"   └── Token endpoint: {data.get('token_endpoint', 'N/A')}")
                    except:
                        pass
                else:
                    print(f"❌ {name}: {response.status_code} (no configurado)")
            elif name in ["Authorization", "Token", "UserInfo"]:
                # Estos endpoints pueden retornar 400/405 cuando se acceden sin parámetros correctos
                if response.status_code in [200, 400, 405, 302]:
                    print(f"✅ {name}: {response.status_code} (disponible)")
                else:
                    print(f"❌ {name}: {response.status_code} (problema)")
            elif name == "JWKS":
                if response.status_code == 200:
                    print(f"✅ {name}: {response.status_code} (configurado)")
                    try:
                        data = response.json()
                        keys_count = len(data.get('keys', []))
                        print(f"   └── Keys disponibles: {keys_count}")
                    except:
                        pass
                else:
                    print(f"❌ {name}: {response.status_code} (no configurado)")
            
        except requests.exceptions.RequestException as e:
            print(f"❌ {name}: Error de conexión - {e}")

def test_guacamole_oidc():
    """Verificar que Guacamole tenga OIDC habilitado"""
    print("\n🥑 VERIFICANDO CONFIGURACIÓN DE GUACAMOLE")
    print("-" * 45)
    
    try:
        response = requests.get(
            "http://34.68.124.46:8080/guacamole/",
            timeout=10,
            allow_redirects=False
        )
        
        print(f"✅ Guacamole responde: {response.status_code}")
        
        # Verificar si hay redirección a OIDC
        if response.status_code in [302, 307]:
            location = response.headers.get('Location', '')
            if 'authentik' in location or 'oauth' in location or 'oidc' in location:
                print(f"✅ Redirección OIDC detectada: {location}")
            else:
                print(f"⚠️ Redirección pero no parece ser OIDC: {location}")
        
        # Verificar contenido HTML si es 200
        if response.status_code == 200:
            content = response.text.lower()
            if 'oidc' in content or 'openid' in content:
                print("✅ Contenido HTML sugiere soporte OIDC")
            else:
                print("⚠️ No se detecta soporte OIDC en HTML")
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error conectando a Guacamole: {e}")

def check_docker_logs():
    """Verificar logs recientes de Guacamole para errores OIDC"""
    print("\n📋 VERIFICANDO LOGS DE GUACAMOLE")
    print("-" * 35)
    
    import subprocess
    
    try:
        result = subprocess.run(
            ['docker-compose', 'logs', '--tail=20', 'guacamole'],
            capture_output=True,
            text=True,
            cwd='/home/infra/local_server_poc'
        )
        
        if result.returncode == 0:
            logs = result.stdout
            
            # Buscar indicadores de OIDC
            oidc_indicators = ['openid', 'oidc', 'oauth', 'authentik']
            error_indicators = ['error', 'exception', 'failed', 'cannot']
            
            oidc_found = any(indicator in logs.lower() for indicator in oidc_indicators)
            errors_found = any(indicator in logs.lower() for indicator in error_indicators)
            
            if oidc_found:
                print("✅ Referencias OIDC encontradas en logs")
            else:
                print("⚠️ No se encontraron referencias OIDC en logs")
            
            if errors_found:
                print("⚠️ Errores detectados en logs - revisar manualmente")
                print("   Comando: docker-compose logs guacamole")
            else:
                print("✅ No se detectaron errores evidentes")
                
        else:
            print("❌ No se pudieron obtener los logs")
            
    except Exception as e:
        print(f"❌ Error verificando logs: {e}")

def show_next_steps():
    """Mostrar los próximos pasos según el estado actual"""
    print("\n📋 ESTADO ACTUAL Y PRÓXIMOS PASOS")
    print("-" * 40)
    
    print("✅ COMPLETADO:")
    print("├── Docker Compose configurado con variables OIDC")
    print("├── Guacamole reiniciado con nueva configuración")
    print("└── Endpoints de Authentik verificados")
    
    print("\n⏳ PENDIENTE (Configuración manual en Authentik):")
    print("├── 1. Crear OAuth2/OpenID Provider en Authentik")
    print("├── 2. Crear Application que use ese Provider")
    print("└── 3. Verificar que los endpoints estén configurados")
    
    print("\n🔗 ACCESOS RÁPIDOS:")
    print("├── Authentik Admin: https://34.68.124.46:9443/if/admin/")
    print("├── Guacamole: https://34.68.124.46:8080/guacamole/")
    print("└── Guía completa: python3 oidc-setup-guide.py")
    
    print("\n💡 VERIFICACIÓN POST-CONFIGURACIÓN:")
    print("└── Ejecutar este script nuevamente después de completar")
    print("    la configuración manual en Authentik")

def main():
    print("🔐 VERIFICADOR DE CONFIGURACIÓN OIDC")
    print("="*45)
    
    # Test endpoints
    test_authentik_endpoints()
    
    # Test Guacamole
    test_guacamole_oidc()
    
    # Check logs
    check_docker_logs()
    
    # Show next steps
    show_next_steps()

if __name__ == "__main__":
    main()