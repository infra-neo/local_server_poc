#!/usr/bin/env python3
"""
Script para crear usuario de prueba 'soporte' en OpenLDAP
"""

import subprocess
import tempfile
import os

def create_ldap_user():
    """Crear usuario soporte en LDAP"""
    print("🔐 CREANDO USUARIO DE PRUEBA EN LDAP")
    print("="*45)
    
    # LDIF para crear el usuario soporte
    ldif_content = """# Crear unidad organizacional para usuarios si no existe
dn: ou=users,dc=kolaboree,dc=local
objectClass: organizationalUnit
ou: users

# Crear usuario soporte
dn: uid=soporte,ou=users,dc=kolaboree,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: soporte
sn: Soporte
givenName: Usuario
cn: Usuario Soporte
displayName: Usuario Soporte
mail: soporte@kolaboree.local
userPassword: {SSHA}Neo123!!!
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/soporte
loginShell: /bin/bash
description: Usuario de prueba para SSO

# Crear unidad organizacional para grupos si no existe
dn: ou=groups,dc=kolaboree,dc=local
objectClass: organizationalUnit
ou: groups

# Crear grupo para el usuario
dn: cn=usuarios,ou=groups,dc=kolaboree,dc=local
objectClass: groupOfNames
cn: usuarios
description: Grupo de usuarios
member: uid=soporte,ou=users,dc=kolaboree,dc=local
"""
    
    # Guardar LDIF temporalmente
    with tempfile.NamedTemporaryFile(mode='w', suffix='.ldif', delete=False) as f:
        f.write(ldif_content)
        ldif_file = f.name
    
    try:
        print("📝 Creando archivo LDIF...")
        print(f"✅ LDIF guardado en: {ldif_file}")
        
        # Aplicar LDIF al contenedor OpenLDAP
        print("\n🔧 Aplicando configuración a OpenLDAP...")
        
        # Copiar LDIF al contenedor
        copy_cmd = [
            'docker', 'cp', ldif_file, 'kolaboree-ldap:/tmp/usuario-soporte.ldif'
        ]
        
        result = subprocess.run(copy_cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ LDIF copiado al contenedor")
        else:
            print(f"❌ Error copiando LDIF: {result.stderr}")
            return False
        
        # Aplicar LDIF con ldapadd
        ldapadd_cmd = [
            'docker', 'exec', 'kolaboree-ldap',
            'ldapadd', '-x', '-D', 'cn=admin,dc=kolaboree,dc=local',
            '-w', 'CHANGEME_LDAP_PASSWORD',
            '-f', '/tmp/usuario-soporte.ldif'
        ]
        
        print("🔄 Ejecutando ldapadd...")
        result = subprocess.run(ldapadd_cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Usuario creado exitosamente en LDAP")
            print(result.stdout)
            return True
        else:
            # Si hay error, podría ser porque ya existe
            if "already exists" in result.stderr or "Type or value exists" in result.stderr:
                print("⚠️ Usuario ya existe, intentando actualizar...")
                return update_ldap_user()
            else:
                print(f"❌ Error creando usuario: {result.stderr}")
                return False
        
    finally:
        # Limpiar archivo temporal
        if os.path.exists(ldif_file):
            os.unlink(ldif_file)
    
def update_ldap_user():
    """Actualizar usuario existente en LDAP"""
    print("🔄 Actualizando usuario existente...")
    
    # LDIF para actualizar contraseña
    ldif_update = """dn: uid=soporte,ou=users,dc=kolaboree,dc=local
changetype: modify
replace: userPassword
userPassword: {SSHA}Neo123!!!
-
replace: mail
mail: soporte@kolaboree.local
-
replace: displayName
displayName: Usuario Soporte
"""
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.ldif', delete=False) as f:
        f.write(ldif_update)
        ldif_file = f.name
    
    try:
        # Copiar al contenedor
        subprocess.run(['docker', 'cp', ldif_file, 'kolaboree-ldap:/tmp/update-soporte.ldif'])
        
        # Aplicar actualización
        update_cmd = [
            'docker', 'exec', 'kolaboree-ldap',
            'ldapmodify', '-x', '-D', 'cn=admin,dc=kolaboree,dc=local',
            '-w', 'CHANGEME_LDAP_PASSWORD',
            '-f', '/tmp/update-soporte.ldif'
        ]
        
        result = subprocess.run(update_cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Usuario actualizado exitosamente")
            return True
        else:
            print(f"❌ Error actualizando usuario: {result.stderr}")
            return False
    
    finally:
        if os.path.exists(ldif_file):
            os.unlink(ldif_file)

def verify_ldap_user():
    """Verificar que el usuario se creó correctamente"""
    print("\n🔍 VERIFICANDO USUARIO EN LDAP")
    print("-"*35)
    
    search_cmd = [
        'docker', 'exec', 'kolaboree-ldap',
        'ldapsearch', '-x', '-D', 'cn=admin,dc=kolaboree,dc=local',
        '-w', 'CHANGEME_LDAP_PASSWORD',
        '-b', 'dc=kolaboree,dc=local',
        '(uid=soporte)'
    ]
    
    result = subprocess.run(search_cmd, capture_output=True, text=True)
    
    if result.returncode == 0 and 'uid=soporte' in result.stdout:
        print("✅ Usuario encontrado en LDAP:")
        
        # Extraer información relevante
        lines = result.stdout.split('\n')
        for line in lines:
            if any(attr in line for attr in ['dn:', 'uid:', 'mail:', 'cn:', 'displayName:']):
                print(f"   {line}")
        
        return True
    else:
        print(f"❌ Usuario no encontrado: {result.stderr}")
        return False

def test_ldap_authentication():
    """Probar autenticación del usuario"""
    print("\n🧪 PROBANDO AUTENTICACIÓN LDAP")
    print("-"*40)
    
    # Intentar bind con el usuario creado
    auth_cmd = [
        'docker', 'exec', 'kolaboree-ldap',
        'ldapwhoami', '-x', '-D', 'uid=soporte,ou=users,dc=kolaboree,dc=local',
        '-w', 'Neo123!!!'
    ]
    
    result = subprocess.run(auth_cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✅ Autenticación exitosa!")
        print(f"   Respuesta: {result.stdout.strip()}")
        return True
    else:
        print(f"❌ Fallo en autenticación: {result.stderr}")
        return False

def show_next_steps():
    """Mostrar próximos pasos"""
    print("\n🚀 PRÓXIMOS PASOS")
    print("-"*20)
    
    print("1. 🔐 Probar login en Authentik:")
    print("   ├── URL: https://34.68.124.46:9443/")
    print("   ├── Usuario: soporte@kolaboree.local")
    print("   ├── Contraseña: Neo123!!!")
    print("   └── Debería autenticar via LDAP")
    
    print("\n2. ✅ Si el login funciona:")
    print("   ├── Continuar con configuración de Provider OIDC")
    print("   ├── Crear Application en Authentik")
    print("   └── Probar flujo SSO completo")
    
    print("\n3. 🔧 Si hay problemas:")
    print("   ├── Verificar logs: docker-compose logs authentik-server")
    print("   ├── Verificar LDAP Source en Authentik")
    print("   └── Revisar property mappings")
    
    print("\n📋 DATOS DEL USUARIO CREADO:")
    print("├── UID: soporte")
    print("├── Email: soporte@kolaboree.local")
    print("├── Nombre completo: Usuario Soporte")
    print("├── Contraseña: Neo123!!!")
    print("└── DN: uid=soporte,ou=users,dc=kolaboree,dc=local")

def main():
    print("🔐 CREACIÓN DE USUARIO LDAP PARA SSO")
    print("="*50)
    
    # Crear usuario
    if create_ldap_user():
        print("\n✅ Usuario creado/actualizado exitosamente")
        
        # Verificar usuario
        if verify_ldap_user():
            # Probar autenticación
            if test_ldap_authentication():
                print("\n🎉 ¡Usuario LDAP configurado correctamente!")
                show_next_steps()
                return True
    
    print("\n❌ Hubo problemas creando el usuario")
    print("💡 Intenta verificar:")
    print("├── Que el contenedor OpenLDAP esté funcionando")
    print("├── Que la contraseña LDAP sea correcta")
    print("└── Logs: docker-compose logs openldap")
    
    return False

if __name__ == "__main__":
    main()