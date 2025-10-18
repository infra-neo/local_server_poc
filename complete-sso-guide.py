#!/usr/bin/env python3
"""
Guía actualizada para configurar el flujo completo SSO:
Authentik (LDAP) -> OIDC -> Guacamole -> Conexión automática RDP
"""

def show_authentik_provider_config():
    """Configuración específica del Provider en Authentik"""
    print("🔧 CONFIGURACIÓN DEL PROVIDER EN AUTHENTIK")
    print("="*50)
    
    print("\n📋 DATOS EXACTOS PARA EL PROVIDER:")
    print("▶️ Name: Guacamole OIDC Provider")
    print("▶️ Client type: Confidential")  
    print("▶️ Client ID: guacamole-rac-client")
    print("▶️ Client Secret: guacamole-rac-secret-2024")
    print("▶️ Redirect URIs: http://34.68.124.46:8080/guacamole/")
    print("                  http://34.68.124.46:8080/guacamole")
    print("▶️ Scopes: openid profile email")
    print()
    print("🔧 CONFIGURACIÓN AVANZADA:")
    print("▶️ Subject mode: Based on the User's hashed ID")
    print("▶️ Include claims in id_token: ✅ ACTIVADO")
    print("▶️ Issuer mode: Each provider has a different issuer")
    print("▶️ Signing Key: (dejar por defecto)")

def show_authentik_application_config():
    """Configuración de la Application en Authentik"""
    print("\n🔗 CONFIGURACIÓN DE LA APPLICATION:")
    print("-" * 40)
    
    print("▶️ Name: Apache Guacamole")
    print("▶️ Slug: guacamole")
    print("▶️ Provider: Guacamole OIDC Provider")
    print("▶️ Launch URL: http://34.68.124.46:8080/guacamole/")
    print("▶️ Open in new tab: ❌ NO")
    print("▶️ Publisher: Kolaboree")
    print("▶️ Description: Remote Desktop Gateway")
    print("▶️ Policy engine mode: ANY")

def show_ldap_integration():
    """Configuración LDAP en Authentik"""
    print("\n🔌 INTEGRACIÓN LDAP EN AUTHENTIK:")  
    print("-" * 35)
    
    print("1. Ve a Directory > Federation & Social login > LDAP Sources")
    print("2. Crear/Verificar LDAP Source con:")
    print("   ├── Name: Kolaboree LDAP")
    print("   ├── Slug: kolaboree-ldap")
    print("   ├── Server URI: ldap://kolaboree-ldap:389")
    print("   ├── Bind CN: cn=admin,dc=kolaboree,dc=local")
    print("   ├── Bind Password: [contraseña LDAP]")
    print("   ├── Base DN: dc=kolaboree,dc=local")
    print("   ├── User DN: ou=users,dc=kolaboree,dc=local")
    print("   ├── User object filter: (objectClass=inetOrgPerson)")
    print("   ├── User object class: inetOrgPerson")
    print("   ├── Group DN: ou=groups,dc=kolaboree,dc=local")
    print("   └── Group object filter: (objectClass=groupOfNames)")
    
    print("\n3. En el login flow, configurar:")
    print("   ├── Identification Stage debe incluir fuentes LDAP")
    print("   └── Los usuarios podrán usar email o username")

def show_guacamole_config():
    """Estado actual de Guacamole"""
    print("\n🥑 CONFIGURACIÓN ACTUAL DE GUACAMOLE:")
    print("-" * 45)
    
    print("✅ OIDC configurado:")
    print("├── OPENID_AUTHORIZATION_ENDPOINT: https://34.68.124.46:9443/application/o/authorize/")
    print("├── OPENID_ISSUER: https://34.68.124.46:9443/application/o/guacamole/")
    print("├── OPENID_CLIENT_ID: guacamole-rac-client")
    print("├── OPENID_REDIRECT_URI: http://34.68.124.46:8080/guacamole/")
    print("└── OPENID_ENABLED: true")
    
    print("\n✅ LDAP configurado:")
    print("├── LDAP_HOSTNAME: openldap")
    print("├── LDAP_USER_BASE_DN: ou=users,dc=kolaboree,dc=local")
    print("├── LDAP_USERNAME_ATTRIBUTE: uid")
    print("└── EXTENSION_PRIORITY: *,ldap,openid")

def show_expected_flow():
    """Flujo esperado del SSO"""
    print("\n🔄 FLUJO ESPERADO DE SSO:")
    print("-" * 30)
    
    print("1. 👤 Usuario accede a: https://34.68.124.46:9443/")
    print("2. 🔐 Login con email (ej: usuario@kolaboree.local)")
    print("3. 🔍 Authentik detecta dominio -> consulta LDAP")
    print("4. ✅ LDAP valida credenciales")
    print("5. 🎫 Authentik genera token OIDC")
    print("6. 🖱️ Usuario hace clic en 'Apache Guacamole'")
    print("7. 🔄 Redirect a Guacamole con token OIDC")
    print("8. 🥑 Guacamole valida token con Authentik")
    print("9. 👤 Guacamole mapea usuario OIDC -> usuario LDAP") 
    print("10. 🖥️ Conexión automática a Windows RDP (100.95.223.18)")
    print("11. ✨ Usuario ve escritorio Windows sin más logins")

def show_troubleshooting():
    """Solución de problemas comunes"""
    print("\n🔧 SOLUCIÓN DE PROBLEMAS:")
    print("-" * 30)
    
    print("❌ Si redirect loop:")
    print("   └── Verificar que redirect URI sea HTTP (no HTTPS)")
    
    print("\n❌ Si no mapea usuario:")
    print("   ├── Verificar claim 'preferred_username' en token")
    print("   ├── Verificar que usuario existe en LDAP")
    print("   └── Verificar LDAP_USERNAME_ATTRIBUTE en Guacamole")
    
    print("\n❌ Si no conecta a RDP:")
    print("   ├── Verificar IP 100.95.223.18 accesible")
    print("   ├── Verificar credenciales soporte/Neo123!!!")
    print("   └── Verificar puerto 3389 abierto")
    
    print("\n🔍 Comandos de debugging:")
    print("├── docker-compose logs guacamole")
    print("├── docker-compose logs authentik-server")
    print("└── python3 verify-oidc-config.py")

def show_urls():
    """URLs importantes del sistema"""
    print("\n🔗 URLS IMPORTANTES:")
    print("-" * 25)
    
    print("🌐 ACCESO USUARIO:")
    print("├── Authentik Dashboard: https://34.68.124.46:9443/")
    print("└── Guacamole (directo): http://34.68.124.46:8080/guacamole/")
    
    print("\n⚙️ ADMINISTRACIÓN:")
    print("├── Authentik Admin: https://34.68.124.46:9443/if/admin/")
    print("└── Usuario admin: akadmin / Kolaboree2024!Admin")
    
    print("\n🎯 FLUJO NORMAL:")
    print("Usuario debe SIEMPRE entrar por:")
    print("👉 https://34.68.124.46:9443/ (Authentik)")
    print("NO por http://34.68.124.46:8080/guacamole/ (directo)")

def main():
    print("🔐 CONFIGURACIÓN COMPLETA SSO")
    print("Authentik (LDAP) -> OIDC -> Guacamole -> RDP")
    print("="*60)
    
    show_authentik_provider_config()
    show_authentik_application_config() 
    show_ldap_integration()
    show_guacamole_config()
    show_expected_flow()
    show_troubleshooting()
    show_urls()
    
    print("\n" + "="*60)
    print("💡 ESTADO ACTUAL:")
    print("✅ Guacamole configurado con OIDC + LDAP")
    print("⏳ Falta completar Provider y Application en Authentik")
    print("⏳ Falta configurar LDAP Source en Authentik")
    print("⏳ Falta crear conexión RDP en Guacamole DB")
    print("="*60)

if __name__ == "__main__":
    main()