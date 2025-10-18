#!/usr/bin/env python3
"""
Guía para sincronizar usuarios LDAP en Authentik
"""

def show_ldap_sync_configuration():
    """Mostrar configuración LDAP Source en Authentik"""
    print("🔌 CONFIGURACIÓN LDAP SOURCE EN AUTHENTIK")
    print("="*50)
    
    print("📍 NAVEGACIÓN:")
    print("1. Ir a: https://34.68.124.46:9443/if/admin/")
    print("2. Login: akadmin / Kolaboree2024!Admin")
    print("3. Directory > Federation & Social login > LDAP Sources")
    print()
    
    print("🔧 CREAR/EDITAR LDAP SOURCE:")
    print("1. Si no existe, hacer clic en [Create]")
    print("2. Si existe 'Kolaboree LDAP', hacer clic para editar")
    print()
    
    print("📝 CONFIGURACIÓN EXACTA:")
    print("├── Name: Kolaboree LDAP")
    print("├── Slug: kolaboree-ldap")
    print("├── Enabled: ✅ ACTIVADO")
    print("├── Server URI: ldap://openldap:389")
    print("├── Bind CN: cn=admin,dc=kolaboree,dc=local")
    print("├── Bind Password: zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01")
    print("├── Base DN: dc=kolaboree,dc=local")
    print("├── Addition User DN: ou=users")
    print("├── Addition Group DN: ou=groups")
    print("├── User object filter: (objectClass=inetOrgPerson)")
    print("├── User object class: inetOrgPerson")
    print("├── Group object filter: (objectClass=groupOfNames)")
    print("├── Group object class: groupOfNames")
    print("├── Group membership field: member")
    print("├── Object uniqueness field: uid")
    print("└── Sync users: ✅ ACTIVADO")

def show_property_mappings():
    """Configuración de Property Mappings"""
    print("\n🗂️ PROPERTY MAPPINGS (MUY IMPORTANTE)")
    print("-"*45)
    
    print("En la sección 'User Property Mappings', seleccionar:")
    print("✅ authentik default LDAP Mapping: mail")
    print("✅ authentik default OpenLDAP Mapping: cn")
    print("✅ authentik default OpenLDAP Mapping: uid")
    print()
    print("⚠️ CRÍTICO: El mapping 'uid' debe estar seleccionado")
    print("   Esto mapea uid=soporte -> preferred_username=soporte")

def show_sync_process():
    """Proceso de sincronización"""
    print("\n🔄 PROCESO DE SINCRONIZACIÓN")
    print("-"*35)
    
    print("1. 💾 Guardar la configuración LDAP Source")
    print("2. 🔄 En la lista de LDAP Sources, buscar 'Kolaboree LDAP'")
    print("3. 🖱️ Hacer clic en el botón 'Sync' (⟲) junto al source")
    print("4. ⏳ Esperar que complete la sincronización")
    print("5. ✅ Verificar que aparezca 'Last sync: hace X minutos'")

def show_verification_steps():
    """Verificar que la sincronización funcionó"""
    print("\n🔍 VERIFICAR SINCRONIZACIÓN")
    print("-"*30)
    
    print("1. 👥 Ir a Directory > Users")
    print("2. 🔍 Buscar 'soporte' en la lista")
    print("3. ✅ Debería aparecer:")
    print("   ├── Username: soporte")
    print("   ├── Name: Usuario Soporte")
    print("   ├── Email: soporte@kolaboree.local")
    print("   └── Active: ✅ Yes")
    print()
    print("4. 🧪 Probar login:")
    print("   ├── Abrir nueva pestaña incógnito")
    print("   ├── Ir a: https://34.68.124.46:9443/")
    print("   ├── Usuario: soporte@kolaboree.local")
    print("   ├── Contraseña: Neo123!!!")
    print("   └── Debería hacer login exitoso")

def show_troubleshooting():
    """Solución de problemas de sincronización"""
    print("\n🔧 SOLUCIÓN DE PROBLEMAS LDAP")
    print("-"*35)
    
    print("❌ Si no sincroniza usuarios:")
    print("1. Verificar que LDAP Source esté 'Enabled'")
    print("2. Verificar conexión LDAP:")
    print("   - Server URI correcto")
    print("   - Bind CN y Password correctos")
    print("3. Verificar filtros:")
    print("   - User object filter: (objectClass=inetOrgPerson)")
    print("   - Base DN + Addition User DN correctos")
    print()
    
    print("❌ Si el usuario aparece pero no puede hacer login:")
    print("1. Verificar que 'Sync users' esté activado")
    print("2. Verificar Property Mappings seleccionados")
    print("3. En Directory > Users > soporte:")
    print("   - Verificar que esté 'Active'")
    print("   - Verificar Source: debe mostrar 'Kolaboree LDAP'")
    print()
    
    print("❌ Si preferred_username no coincide:")
    print("1. Verificar que 'uid' mapping esté seleccionado")
    print("2. Re-sincronizar el LDAP Source")
    print("3. Verificar en JWT payload que preferred_username=soporte")

def show_final_test():
    """Prueba final del flujo completo"""
    print("\n🧪 PRUEBA FINAL DEL FLUJO SSO")
    print("-"*35)
    
    print("Una vez que el usuario 'soporte' esté sincronizado:")
    print()
    print("1. 🔐 Login en Authentik:")
    print("   ├── https://34.68.124.46:9443/")
    print("   ├── soporte@kolaboree.local / Neo123!!!")
    print("   └── Debería ver dashboard con aplicaciones")
    print()
    print("2. 🖱️ Hacer clic en 'Apache Guacamole'")
    print("   ├── Debería redirigir automáticamente")
    print("   ├── Sin pedir login adicional")
    print("   └── Usuario logueado como 'soporte'")
    print()
    print("3. 🖥️ Ver conexiones disponibles:")
    print("   ├── Debería ver las 7 conexiones")
    print("   ├── Incluida 'windows' (100.95.223.18)")
    print("   └── Todas con permisos READ")
    print()
    print("4. 🎯 Conectar a Windows:")
    print("   ├── Clic en conexión 'windows'")
    print("   ├── Debería conectar automáticamente")
    print("   └── Ver escritorio Windows - ¡OBJETIVO CUMPLIDO!")

def main():
    print("🔌 SINCRONIZACIÓN LDAP EN AUTHENTIK")
    print("="*50)
    
    show_ldap_sync_configuration()
    show_property_mappings()
    show_sync_process()
    show_verification_steps()
    show_troubleshooting()
    show_final_test()
    
    print("\n" + "="*60)
    print("🎯 RESUMEN DE PASOS:")
    print("1. Configurar LDAP Source en Authentik")
    print("2. Sincronizar usuarios LDAP")
    print("3. Probar login con usuario 'soporte'")
    print("4. Probar flujo SSO completo a Guacamole")
    print("="*60)

if __name__ == "__main__":
    main()