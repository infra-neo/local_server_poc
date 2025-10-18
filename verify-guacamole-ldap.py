#!/usr/bin/env python3
"""
Script para verificar la sincronización LDAP en Guacamole
"""

import psycopg2
import requests
import json
from urllib.parse import urljoin

# Configuración
GUACAMOLE_URL = "http://34.68.124.46:8080"
DB_CONFIG = {
    'host': 'localhost',
    'database': 'kolaboree',
    'user': 'kolaboree', 
    'password': 'KolaboreeDB2024',
    'port': 5432
}

def check_guacamole_users():
    """Verificar usuarios en la base de datos de Guacamole"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        print("🔍 VERIFICANDO USUARIOS EN BASE DE DATOS GUACAMOLE")
        print("=" * 55)
        
        # Verificar tabla de usuarios
        cursor.execute("""
            SELECT username, full_name, email_address, organization, organizational_role 
            FROM guacamole_user 
            ORDER BY username;
        """)
        
        users = cursor.fetchall()
        
        if users:
            print(f"\n📋 USUARIOS ENCONTRADOS ({len(users)}):")
            print("-" * 50)
            for user in users:
                username, full_name, email, org, role = user
                print(f"├── Username: {username}")
                if full_name:
                    print(f"│   Nombre: {full_name}")
                if email:
                    print(f"│   Email: {email}")
                if org:
                    print(f"│   Organización: {org}")
                if role:
                    print(f"│   Rol: {role}")
                print("│")
        else:
            print("❌ No se encontraron usuarios en Guacamole")
            
        # Verificar si existe el usuario 'soporte'
        cursor.execute("SELECT username FROM guacamole_user WHERE username = 'soporte'")
        soporte_user = cursor.fetchone()
        
        if soporte_user:
            print("✅ Usuario 'soporte' encontrado en Guacamole")
        else:
            print("❌ Usuario 'soporte' NO encontrado en Guacamole")
            
        cursor.close()
        conn.close()
        
        return users, bool(soporte_user)
        
    except Exception as e:
        print(f"❌ Error conectando a la base de datos: {e}")
        return [], False

def check_guacamole_permissions():
    """Verificar permisos de usuarios en Guacamole"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        print("\n🔐 VERIFICANDO PERMISOS DE USUARIOS")
        print("=" * 40)
        
        # Permisos de conexión
        cursor.execute("""
            SELECT u.username, c.connection_name, p.permission
            FROM guacamole_user u
            JOIN guacamole_connection_permission cp ON u.user_id = cp.user_id
            JOIN guacamole_connection c ON cp.connection_id = c.connection_id
            JOIN guacamole_permission p ON cp.permission = p.permission
            WHERE u.username = 'soporte'
            ORDER BY c.connection_name;
        """)
        
        permissions = cursor.fetchall()
        
        if permissions:
            print(f"📋 PERMISOS DEL USUARIO 'soporte':")
            print("-" * 35)
            for perm in permissions:
                username, conn_name, permission = perm
                print(f"├── Conexión: {conn_name}")
                print(f"│   Permiso: {permission}")
                print("│")
        else:
            print("❌ Usuario 'soporte' no tiene permisos de conexión")
            
        cursor.close()
        conn.close()
        
        return permissions
        
    except Exception as e:
        print(f"❌ Error verificando permisos: {e}")
        return []

def check_ldap_authentication():
    """Verificar si Guacamole está configurado para autenticación LDAP"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        print("\n🔗 VERIFICANDO CONFIGURACIÓN LDAP EN GUACAMOLE")
        print("=" * 50)
        
        # Verificar configuración LDAP en guacamole.properties
        print("📋 CONFIGURACIÓN LDAP REQUERIDA:")
        print("-" * 35)
        print("auth-provider: net.sourceforge.guacamole.net.auth.ldap.LDAPAuthenticationProvider")
        print("ldap-hostname: kolaboree-ldap")
        print("ldap-port: 389")
        print("ldap-user-base-dn: ou=users,dc=kolaboree,dc=local")
        print("ldap-search-bind-dn: cn=admin,dc=kolaboree,dc=local")
        print("ldap-search-bind-password: [PASSWORD_FROM_ENV]")
        print("ldap-username-attribute: uid")
        print("ldap-email-attribute: mail")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

def test_guacamole_ldap_login():
    """Probar login LDAP en Guacamole"""
    print("\n🧪 PRUEBA DE LOGIN LDAP EN GUACAMOLE")
    print("=" * 40)
    
    try:
        # Intentar acceder a Guacamole
        response = requests.get(f"{GUACAMOLE_URL}/guacamole/", timeout=10)
        if response.status_code == 200:
            print("✅ Guacamole accesible")
            
            # Verificar si hay formulario de login
            if 'login' in response.text.lower():
                print("✅ Formulario de login encontrado")
            else:
                print("❌ No se encontró formulario de login")
                
        else:
            print(f"❌ Guacamole no accesible: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error probando Guacamole: {e}")

def main():
    print("🔍 VERIFICACIÓN DE SINCRONIZACIÓN LDAP EN GUACAMOLE")
    print("=" * 60)
    
    # Verificar usuarios en DB
    users, soporte_exists = check_guacamole_users()
    
    # Verificar permisos
    permissions = check_guacamole_permissions()
    
    # Verificar configuración LDAP
    check_ldap_authentication()
    
    # Probar acceso a Guacamole
    test_guacamole_ldap_login()
    
    print("\n📋 RESUMEN DE VERIFICACIÓN")
    print("=" * 30)
    print(f"👥 Usuarios en DB Guacamole: {len(users)}")
    print(f"🎯 Usuario 'soporte' existe: {'✅ SÍ' if soporte_exists else '❌ NO'}")
    print(f"🔐 Permisos del usuario 'soporte': {len(permissions)}")
    
    if not soporte_exists:
        print("\n⚠️ PROBLEMA IDENTIFICADO:")
        print("El usuario 'soporte' no existe en la base de datos de Guacamole.")
        print("Esto significa que Guacamole NO está sincronizado con LDAP.")
        
        print("\n🔧 SOLUCIONES POSIBLES:")
        print("1. Configurar autenticación LDAP en Guacamole")
        print("2. Crear manualmente el usuario en Guacamole")
        print("3. Verificar configuración de guacamole.properties")
        
    else:
        print("\n✅ ESTADO:")
        print("El usuario 'soporte' existe en Guacamole.")
        if permissions:
            print("✅ El usuario tiene permisos de conexión.")
        else:
            print("⚠️ El usuario NO tiene permisos de conexión.")

if __name__ == "__main__":
    main()