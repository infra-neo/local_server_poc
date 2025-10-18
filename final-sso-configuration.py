#!/usr/bin/env python3
"""
Configuración final completa para SSO Authentik -> Guacamole
"""

def show_final_configuration_steps():
    """Mostrar pasos finales de configuración"""
    print("🎯 CONFIGURACIÓN FINAL COMPLETA")
    print("="*50)
    
    print("📊 ESTADO ACTUAL:")
    print("✅ Guacamole: 7 conexiones configuradas")
    print("✅ Usuario 'soporte' creado para mapeo LDAP")
    print("✅ Conexión principal: Windows (100.95.223.18)")
    print("✅ Variables OIDC + LDAP configuradas")
    
    print("\n🔧 AUTHENTIK - PASO 1: CREAR PROVIDER OIDC")
    print("-"*50)
    print("1. Ir a: https://34.68.124.46:9443/if/admin/")
    print("2. Login: akadmin / Kolaboree2024!Admin")
    print("3. Applications > Providers > Create")
    print("4. Seleccionar: OAuth2/OpenID Provider")
    print()
    print("📝 CONFIGURACIÓN EXACTA DEL PROVIDER:")
    print("├── Name: Guacamole OIDC Provider")
    print("├── Authorization flow: default-provider-authorization-explicit-consent")
    print("├── Client type: Confidential")
    print("├── Client ID: guacamole-rac-client")
    print("├── Client Secret: guacamole-rac-secret-2024")
    print("├── Redirect URIs:")
    print("│   http://34.68.124.46:8080/guacamole/")
    print("│   http://34.68.124.46:8080/guacamole")
    print("├── Scopes: openid profile email")
    print("├── Subject mode: Based on the User's hashed ID")
    print("├── Include claims in id_token: ✅ HABILITADO")
    print("└── Issuer mode: Each provider has a different issuer")
    
    print("\n🔗 AUTHENTIK - PASO 2: CREAR APPLICATION")
    print("-"*45)
    print("1. Applications > Applications > Create")
    print()
    print("📝 CONFIGURACIÓN DE LA APPLICATION:")
    print("├── Name: Apache Guacamole")
    print("├── Slug: guacamole")
    print("├── Provider: Guacamole OIDC Provider (seleccionar)")
    print("├── Launch URL: http://34.68.124.46:8080/guacamole/")
    print("├── Open in new tab: ❌ NO")
    print("├── Icon: (opcional)")
    print("├── Publisher: Kolaboree")
    print("├── Description: Remote Desktop Gateway")
    print("└── Policy engine mode: ANY")
    
    print("\n🔌 AUTHENTIK - PASO 3: CONFIGURAR LDAP SOURCE")
    print("-"*50)
    print("1. Directory > Federation & Social login > LDAP Sources")
    print("2. Create (o editar si ya existe)")
    print()
    print("📝 CONFIGURACIÓN LDAP SOURCE:")
    print("├── Name: Kolaboree LDAP")
    print("├── Slug: kolaboree-ldap")
    print("├── Enabled: ✅ SI")
    print("├── Server URI: ldap://openldap:389")
    print("├── Bind CN: cn=admin,dc=kolaboree,dc=local")
    print("├── Bind Password: [tu contraseña LDAP]")
    print("├── Base DN: dc=kolaboree,dc=local")
    print("├── Addition User DN: ou=users")
    print("├── Addition Group DN: ou=groups")
    print("├── User object filter: (objectClass=inetOrgPerson)")
    print("├── User object class: inetOrgPerson")
    print("├── Group object filter: (objectClass=groupOfNames)")
    print("├── Group object class: groupOfNames")
    print("├── Group membership field: member")
    print("├── Object uniqueness field: uid")
    print("└── Sync users: ✅ SI")
    
    print("\n🗂️ AUTHENTIK - PASO 4: PROPERTY MAPPINGS")
    print("-"*45)
    print("En LDAP Source > Property Mappings, asegurar:")
    print("├── authentik default LDAP Mapping: Name -> name")
    print("├── authentik default LDAP Mapping: mail -> email") 
    print("└── authentik default LDAP Mapping: uid -> username")
    print()
    print("⚠️ IMPORTANTE: El campo 'username' debe mapear a 'uid' de LDAP")
    print("   Esto asegura que el claim 'preferred_username' coincida")

def show_testing_flow():
    """Mostrar cómo probar el flujo completo"""
    print("\n🧪 PRUEBA DEL FLUJO COMPLETO")
    print("-"*35)
    
    print("1. 🔐 CREAR USUARIO DE PRUEBA EN LDAP:")
    print("   ├── Nombre: soporte")
    print("   ├── Email: soporte@kolaboree.local")
    print("   ├── UID: soporte")
    print("   └── Contraseña: Neo123!!!")
    
    print("\n2. 🌐 PROBAR LOGIN:")
    print("   ├── Acceder: https://34.68.124.46:9443/")
    print("   ├── Usuario: soporte@kolaboree.local")
    print("   ├── Contraseña: Neo123!!!")
    print("   └── Debería autenticar via LDAP")
    
    print("\n3. 🖱️ ACCEDER A GUACAMOLE:")
    print("   ├── En Authentik dashboard, clic en 'Apache Guacamole'")
    print("   ├── Debería redirigir a Guacamole automáticamente")
    print("   ├── Usuario debería estar logueado como 'soporte'")
    print("   └── Debería ver todas las conexiones disponibles")
    
    print("\n4. 🖥️ CONECTAR A WINDOWS:")
    print("   ├── Clic en conexión 'windows' (100.95.223.18)")
    print("   ├── Debería conectar automáticamente")
    print("   ├── Sin pedir credenciales adicionales")
    print("   └── Mostrar escritorio Windows")

def show_troubleshooting_guide():
    """Guía de solución de problemas"""
    print("\n🔧 SOLUCIÓN DE PROBLEMAS")
    print("-"*30)
    
    print("❌ Si falla el redirect OIDC:")
    print("   1. Verificar redirect URI en Provider")
    print("   2. Revisar logs: docker-compose logs guacamole")
    print("   3. Verificar endpoint: python3 verify-oidc-config.py")
    
    print("\n❌ Si no mapea el usuario:")
    print("   1. Verificar claim 'preferred_username' en token")
    print("   2. Verificar que usuario 'soporte' existe en Guacamole")
    print("   3. Verificar mapping LDAP: uid -> username")
    
    print("\n❌ Si no aparecen conexiones:")
    print("   1. Verificar permisos del usuario en BD")
    print("   2. Ejecutar: ./fix-user-permissions.sh")
    
    print("\n❌ Si no conecta a Windows:")
    print("   1. Verificar IP 100.95.223.18 accesible")
    print("   2. Verificar credenciales soporte/Neo123!!!")
    print("   3. Verificar puerto 3389 abierto")
    
    print("\n🔍 COMANDOS DE DEBUG:")
    print("├── docker-compose logs guacamole")
    print("├── docker-compose logs authentik-server") 
    print("├── python3 verify-oidc-config.py")
    print("└── python3 analyze-guacamole-setup.py")

def create_user_permissions_fix():
    """Crear script para arreglar permisos de usuario"""
    
    fix_script = """#!/bin/bash
# Script para arreglar permisos del usuario soporte

echo "🔧 Arreglando permisos del usuario soporte..."

docker exec -i kolaboree-postgres psql -U kolaboree -d kolaboree << 'EOF'

-- Asegurar que el usuario soporte existe
INSERT INTO guacamole_entity (name, type)
VALUES ('soporte', 'USER')
ON CONFLICT (type, name) DO NOTHING;

-- Actualizar usuario con datos correctos
INSERT INTO guacamole_user (
    entity_id, 
    password_hash, 
    password_date,
    full_name, 
    email_address
)
VALUES (
    (SELECT entity_id FROM guacamole_entity WHERE name = 'soporte' AND type = 'USER'),
    '\\x0000000000000000000000000000000000000000000000000000000000000000',
    CURRENT_TIMESTAMP,
    'Usuario Soporte',
    'soporte@kolaboree.local'
)
ON CONFLICT (entity_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email_address = EXCLUDED.email_address,
    password_date = CURRENT_TIMESTAMP;

-- Dar permisos READ a TODAS las conexiones
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT 
    e.entity_id,
    c.connection_id,
    'READ'::guacamole_object_permission
FROM guacamole_entity e
CROSS JOIN guacamole_connection c
WHERE e.name = 'soporte' AND e.type = 'USER'
ON CONFLICT (entity_id, connection_id, permission) DO NOTHING;

-- Mostrar resultado
SELECT 'Permisos configurados para usuario soporte:' as info;
SELECT 
    c.connection_name,
    cp.permission
FROM guacamole_connection_permission cp
JOIN guacamole_connection c ON cp.connection_id = c.connection_id
JOIN guacamole_entity e ON cp.entity_id = e.entity_id
WHERE e.name = 'soporte'
ORDER BY c.connection_name;

EOF

echo "✅ Permisos del usuario soporte actualizados"
"""
    
    with open('fix-user-permissions.sh', 'w') as f:
        f.write(fix_script)
    
    import os
    os.chmod('fix-user-permissions.sh', 0o755)
    print("✅ Script creado: fix-user-permissions.sh")

def show_final_summary():
    """Resumen final"""
    print("\n🎉 RESUMEN FINAL")
    print("="*25)
    
    print("✅ LO QUE TIENES:")
    print("├── Guacamole con 7 conexiones funcionando")
    print("├── Conexión principal a Windows (100.95.223.18)")
    print("├── Usuario 'soporte' mapeado para SSO")
    print("├── OIDC + LDAP configurado en Guacamole")
    print("└── Scripts de debugging y reparación")
    
    print("\n⏳ LO QUE FALTA:")
    print("├── Provider OIDC en Authentik")
    print("├── Application en Authentik")
    print("├── LDAP Source en Authentik")
    print("└── Usuario 'soporte' en LDAP")
    
    print("\n🎯 RESULTADO ESPERADO:")
    print("Usuario entra a Authentik → Login único → Clic en Guacamole")
    print("→ Ve todas las conexiones → Clic en Windows → Conecta sin más logins")
    
    print("\n🔗 URLS IMPORTANTES:")
    print("├── Authentik Admin: https://34.68.124.46:9443/if/admin/")
    print("├── Authentik User: https://34.68.124.46:9443/")
    print("├── Guacamole: http://34.68.124.46:8080/guacamole/")
    print("└── Login: akadmin / Kolaboree2024!Admin")

def main():
    show_final_configuration_steps()
    show_testing_flow()
    show_troubleshooting_guide()
    create_user_permissions_fix()
    show_final_summary()

if __name__ == "__main__":
    main()