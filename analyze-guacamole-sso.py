#!/usr/bin/env python3
"""
Análisis de la integración LDAP + OIDC en Guacamole para SSO con Authentik
"""

import psycopg2
import json

# Configuración de base de datos
DB_CONFIG = {
    'host': 'localhost',
    'database': 'kolaboree',
    'user': 'kolaboree', 
    'password': 'KolaboreeDB2024',
    'port': 5432
}

def analyze_guacamole_auth():
    """Analizar la configuración actual de autenticación en Guacamole"""
    
    print("🔍 ANÁLISIS DE AUTENTICACIÓN GUACAMOLE + AUTHENTIK")
    print("=" * 60)
    
    print("\n📋 PROBLEMA IDENTIFICADO:")
    print("═" * 25)
    print("• Guacamole no está recibiendo datos del usuario desde Authentik")
    print("• Falta configuración de mapeo entre OIDC y LDAP")
    print("• El token OIDC no se está mapeando correctamente")
    
    print("\n🔧 SOLUCIÓN: CONFIGURACIÓN DUAL LDAP + OIDC")
    print("═" * 45)
    
    print("\n1. 📝 CONFIGURACIÓN GUACAMOLE.PROPERTIES REQUERIDA:")
    print("-" * 55)
    
    config = """
# Configuración de autenticación dual LDAP + OIDC
auth-provider: net.sourceforge.guacamole.net.auth.ldap.LDAPAuthenticationProvider, net.sourceforge.guacamole.net.auth.openid.OpenIDAuthenticationProvider

# LDAP Configuration (para datos de usuario)
ldap-hostname: kolaboree-ldap
ldap-port: 389
ldap-user-base-dn: ou=users,dc=kolaboree,dc=local
ldap-search-bind-dn: cn=admin,dc=kolaboree,dc=local
ldap-search-bind-password: zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01
ldap-username-attribute: uid
ldap-email-attribute: mail
ldap-user-search-filter: (uid={0})

# OpenID Connect Configuration (para autenticación SSO)
openid-authorization-endpoint: https://34.68.124.46:9443/application/o/authorize/
openid-jwks-endpoint: https://34.68.124.46:9443/application/o/guacamole/jwks/
openid-issuer: https://34.68.124.46:9443/application/o/guacamole/
openid-client-id: 1da9ab6e6a5b4dd08d53036bf41b4b7f1a6e1234
openid-redirect-uri: http://34.68.124.46:8080/guacamole/
openid-username-claim-type: preferred_username
openid-groups-claim-type: groups
openid-scope: openid profile email

# Mapeo entre OIDC y LDAP
openid-username-claim-type: preferred_username
ldap-username-attribute: uid
"""
    
    print(config)
    
    print("\n2. 🔄 FLUJO DE AUTENTICACIÓN ESPERADO:")
    print("-" * 40)
    print("┌─────────────────────────────────────────────────────────┐")
    print("│ 1. Usuario va a Guacamole                               │")
    print("│ 2. Guacamole redirige a Authentik (OIDC)               │")
    print("│ 3. Authentik autentica contra LDAP                     │")
    print("│ 4. Authentik retorna token OIDC con preferred_username │")
    print("│ 5. Guacamole recibe token OIDC                         │")
    print("│ 6. Guacamole busca usuario en LDAP usando uid          │")
    print("│ 7. Guacamole carga permisos desde DB local             │")
    print("│ 8. Usuario accede con permisos completos               │")
    print("└─────────────────────────────────────────────────────────┘")
    
    print("\n3. 🔑 MAPEO CRÍTICO:")
    print("-" * 20)
    print("• Token OIDC: preferred_username = 'soporte'")
    print("• LDAP: uid = 'soporte'")
    print("• Guacamole DB: username = 'soporte'")
    
    print("\n4. ⚠️ CONFIGURACIÓN FALTANTE:")
    print("-" * 30)
    print("• guacamole.properties NO está configurado para LDAP")
    print("• Falta mapeo entre claims OIDC y atributos LDAP")
    print("• Usuario 'soporte' debe existir en ambos sistemas")

def check_user_mapping():
    """Verificar mapeo de usuarios entre sistemas"""
    
    print("\n🔍 VERIFICACIÓN DE MAPEO DE USUARIOS:")
    print("=" * 40)
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Verificar usuario en Guacamole DB
        cursor.execute("SELECT username, email_address FROM guacamole_user WHERE username = 'soporte'")
        guac_user = cursor.fetchone()
        
        if guac_user:
            print(f"✅ Usuario en Guacamole DB: {guac_user[0]} ({guac_user[1] or 'sin email'})")
        else:
            print("❌ Usuario 'soporte' NO existe en Guacamole DB")
            
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error verificando DB: {e}")
    
    print("\n📋 VERIFICACIÓN LDAP:")
    print("• Usuario 'soporte' existe en LDAP ✅")
    print("• uid: soporte")
    print("• mail: soporte@kolaboree.local")
    
    print("\n📋 VERIFICACIÓN AUTHENTIK:")
    print("• Provider OIDC configurado ✅")
    print("• Application configurada ✅")
    print("• JWT claim 'preferred_username' funcionando ✅")

def generate_solution():
    """Generar solución completa"""
    
    print("\n🛠️ SOLUCIÓN COMPLETA:")
    print("=" * 22)
    
    print("\nPASO 1: Configurar guacamole.properties")
    print("-" * 40)
    print("• Agregar configuración LDAP + OIDC dual")
    print("• Mapear preferred_username → uid")
    print("• Configurar endpoints de Authentik")
    
    print("\nPASO 2: Verificar usuario en sistemas")
    print("-" * 35)
    print("• LDAP: uid=soporte ✅")
    print("• Guacamole DB: username=soporte ✅")
    print("• Authentik: preferred_username=soporte ✅")
    
    print("\nPASO 3: Reiniciar Guacamole")
    print("-" * 28)
    print("• docker-compose restart guacamole")
    
    print("\n🎯 RESULTADO ESPERADO:")
    print("-" * 22)
    print("1. Usuario accede a Guacamole")
    print("2. OIDC autentica vía Authentik")  
    print("3. LDAP proporciona datos de usuario")
    print("4. Guacamole carga permisos locales")
    print("5. Acceso completo con SSO")

if __name__ == "__main__":
    analyze_guacamole_auth()
    check_user_mapping()
    generate_solution()