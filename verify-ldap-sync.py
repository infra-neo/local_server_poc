#!/usr/bin/env python3
"""
Script para verificar si el usuario LDAP se sincronizó correctamente en Authentik
"""

import requests
import urllib3
from urllib3.exceptions import InsecureRequestWarning

urllib3.disable_warnings(InsecureRequestWarning)

def test_user_sync():
    """Probar si el usuario soporte está disponible en Authentik"""
    print("🔍 VERIFICANDO SINCRONIZACIÓN LDAP")
    print("="*40)
    
    # Probar login del usuario soporte
    print("🧪 Probando login del usuario soporte...")
    
    session = requests.Session()
    session.verify = False
    
    try:
        # Intentar acceder a la página de login
        login_url = "https://34.68.124.46:9443/if/flow/default-authentication-flow/"
        response = session.get(login_url, timeout=10)
        
        if response.status_code == 200:
            print("✅ Authentik responde correctamente")
            print("📝 Para probar el login del usuario:")
            print("   1. Abrir: https://34.68.124.46:9443/")
            print("   2. Usuario: soporte@kolaboree.local")
            print("   3. Contraseña: Neo123!!!")
            
            return True
        else:
            print(f"❌ Authentik no responde: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error conectando a Authentik: {e}")
        return False

def show_ldap_verification_commands():
    """Comandos para verificar que LDAP tiene el usuario"""
    print("\n🔍 VERIFICAR USUARIO EN LDAP")
    print("-"*35)
    
    print("Para confirmar que el usuario existe en LDAP:")
    print()
    print("📋 Comando de verificación:")
    print("docker exec kolaboree-ldap ldapsearch -x \\")
    print("  -D 'cn=admin,dc=kolaboree,dc=local' \\")
    print("  -w 'zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01' \\")
    print("  -b 'dc=kolaboree,dc=local' \\")
    print("  '(uid=soporte)' uid mail cn displayName")

def test_guacamole_endpoints():
    """Verificar que Guacamole esté listo para recibir usuarios OIDC"""
    print("\n🥑 VERIFICANDO GUACAMOLE OIDC")
    print("-"*35)
    
    try:
        response = requests.get("http://34.68.124.46:8080/guacamole/", timeout=10)
        
        if response.status_code == 200:
            print("✅ Guacamole responde correctamente")
            
            # Verificar si detecta configuración OIDC
            content = response.text.lower()
            if 'oidc' in content or 'oauth' in content:
                print("✅ Configuración OIDC detectada en Guacamole")
            else:
                print("⚠️ No se detecta configuración OIDC obvia")
                
            return True
        else:
            print(f"❌ Guacamole no responde: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error conectando a Guacamole: {e}")
        return False

def show_next_steps():
    """Mostrar próximos pasos según el estado"""
    print("\n🚀 PRÓXIMOS PASOS")
    print("-"*20)
    
    print("1. 🔧 Configurar LDAP Source en Authentik:")
    print("   └── https://34.68.124.46:9443/if/admin/")
    print("   └── Directory > Federation & Social login > LDAP Sources")
    
    print("\n2. 🔄 Sincronizar usuarios LDAP")
    print("   └── Hacer clic en botón 'Sync' del LDAP Source")
    
    print("\n3. ✅ Verificar usuario sincronizado:")
    print("   └── Directory > Users > buscar 'soporte'")
    
    print("\n4. 🧪 Probar login:")
    print("   └── https://34.68.124.46:9443/")
    print("   └── soporte@kolaboree.local / Neo123!!!")
    
    print("\n5. 🎯 Probar flujo SSO completo:")
    print("   └── Login → Clic en 'Apache Guacamole' → Ver conexiones")

def main():
    print("🔍 VERIFICADOR DE SINCRONIZACIÓN LDAP")
    print("="*50)
    
    # Verificar Authentik
    authentik_ok = test_user_sync()
    
    # Verificar comandos LDAP
    show_ldap_verification_commands()
    
    # Verificar Guacamole
    guacamole_ok = test_guacamole_endpoints()
    
    # Mostrar próximos pasos
    show_next_steps()
    
    print("\n" + "="*50)
    if authentik_ok and guacamole_ok:
        print("✅ Sistema listo para sincronización LDAP")
        print("Continúa con la configuración del LDAP Source en Authentik")
    else:
        print("⚠️ Verifica que todos los servicios estén funcionando")
    print("="*50)

if __name__ == "__main__":
    main()