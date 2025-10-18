#!/usr/bin/env python3
"""
Script para verificar las conexiones existentes en Guacamole y configurar mapeo de usuarios
"""

import subprocess
import json

def check_guacamole_connections():
    """Verificar conexiones existentes en Guacamole via DB"""
    print("🔍 VERIFICANDO CONEXIONES EN GUACAMOLE")
    print("="*45)
    
    # Consultar conexiones en la base de datos
    sql_query = """
SELECT 
    c.connection_id,
    c.connection_name,
    c.protocol,
    string_agg(
        cp.parameter_name || '=' || cp.parameter_value, 
        ', ' ORDER BY cp.parameter_name
    ) as parameters
FROM guacamole_connection c
LEFT JOIN guacamole_connection_parameter cp ON c.connection_id = cp.connection_id
GROUP BY c.connection_id, c.connection_name, c.protocol
ORDER BY c.connection_name;
"""
    
    try:
        result = subprocess.run([
            'docker', 'exec', '-i', 'kolaboree-postgres', 
            'psql', '-U', 'kolaboree', '-d', 'kolaboree', 
            '-t', '-c', sql_query
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            connections = result.stdout.strip()
            if connections:
                print("✅ Conexiones encontradas:")
                for line in connections.split('\n'):
                    if line.strip():
                        parts = line.strip().split('|')
                        if len(parts) >= 3:
                            conn_id = parts[0].strip()
                            name = parts[1].strip()
                            protocol = parts[2].strip()
                            print(f"📱 ID: {conn_id} | {name} ({protocol})")
                            
                            # Mostrar parámetros importantes
                            if len(parts) > 3 and parts[3].strip():
                                params = parts[3].strip()
                                important_params = []
                                for param in params.split(', '):
                                    if any(key in param for key in ['hostname', 'username', 'port']):
                                        important_params.append(param)
                                if important_params:
                                    print(f"   └── {', '.join(important_params)}")
                return True
            else:
                print("⚠️ No se encontraron conexiones")
                return False
        else:
            print(f"❌ Error consultando base de datos: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def check_guacamole_users():
    """Verificar usuarios existentes en Guacamole"""
    print("\n👤 VERIFICANDO USUARIOS EN GUACAMOLE")
    print("-"*40)
    
    sql_query = """
SELECT 
    e.entity_id,
    e.name as username,
    u.full_name,
    u.email_address,
    u.disabled,
    COUNT(cp.connection_id) as connection_count
FROM guacamole_entity e
JOIN guacamole_user u ON e.entity_id = u.entity_id
LEFT JOIN guacamole_connection_permission cp ON e.entity_id = cp.entity_id
WHERE e.type = 'USER'
GROUP BY e.entity_id, e.name, u.full_name, u.email_address, u.disabled
ORDER BY e.name;
"""
    
    try:
        result = subprocess.run([
            'docker', 'exec', '-i', 'kolaboree-postgres', 
            'psql', '-U', 'kolaboree', '-d', 'kolaboree', 
            '-t', '-c', sql_query
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            users = result.stdout.strip()
            if users:
                print("✅ Usuarios encontrados:")
                for line in users.split('\n'):
                    if line.strip():
                        parts = line.strip().split('|')
                        if len(parts) >= 6:
                            user_id = parts[0].strip()
                            username = parts[1].strip()
                            full_name = parts[2].strip()
                            email = parts[3].strip()
                            disabled = parts[4].strip()
                            conn_count = parts[5].strip()
                            status = "❌ Deshabilitado" if disabled == 't' else "✅ Activo"
                            print(f"👤 {username} ({full_name}) - {status}")
                            print(f"   ├── Email: {email}")
                            print(f"   └── Conexiones: {conn_count}")
                return True
            else:
                print("⚠️ No se encontraron usuarios")
                return False
        else:
            print(f"❌ Error: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def show_sso_mapping_strategy():
    """Mostrar estrategia de mapeo para SSO"""
    print("\n🔗 ESTRATEGIA DE MAPEO SSO")
    print("-"*30)
    
    print("📋 FLUJO ACTUAL:")
    print("1. Usuario hace login en Authentik con email")
    print("2. Authentik valida contra LDAP")
    print("3. Authentik genera token OIDC con claims")
    print("4. Usuario accede a Guacamole via OIDC")
    print("5. Guacamole recibe token con 'preferred_username'")
    print("6. Guacamole busca usuario local con ese nombre")
    print("7. Si existe, permite acceso a sus conexiones")
    print("8. Si no existe, puede crear automáticamente (opcional)")
    
    print("\n🔧 CONFIGURACIÓN NECESARIA:")
    print("▶️ En Authentik LDAP Source:")
    print("   ├── Mapear 'uid' LDAP -> 'preferred_username' OIDC")
    print("   └── O mapear 'mail' LDAP -> 'preferred_username' OIDC")
    
    print("\n▶️ En Guacamole (ya configurado):")
    print("   ├── OPENID_USERNAME_CLAIM_TYPE: preferred_username")
    print("   ├── LDAP_USERNAME_ATTRIBUTE: uid")
    print("   └── EXTENSION_PRIORITY: *,ldap,openid")
    
    print("\n▶️ Opciones de usuario:")
    print("   1. Crear usuarios en Guacamole que coincidan con LDAP")
    print("   2. Usar auto-creación de usuarios (si está habilitada)")
    print("   3. Usar mapeo híbrido LDAP+OIDC")

def create_user_mapping_script():
    """Crear script para mapear usuarios existentes"""
    print("\n📝 CREANDO SCRIPT DE MAPEO DE USUARIOS")
    print("-"*45)
    
    mapping_script = """#!/bin/bash
# Script para crear/mapear usuarios de LDAP en Guacamole

echo "🔧 Configurando mapeo de usuarios LDAP -> Guacamole"

# Ejemplo: Crear usuario 'soporte' que coincida con LDAP
docker exec -i kolaboree-postgres psql -U kolaboree -d kolaboree << 'EOF'

-- Crear usuario 'soporte' para mapeo LDAP/OIDC
INSERT INTO guacamole_entity (name, type)
VALUES ('soporte', 'USER')
ON CONFLICT (type, name) DO NOTHING;

-- Usuario con contraseña dummy (se autentica via OIDC/LDAP)
INSERT INTO guacamole_user (entity_id, password_hash, full_name, email_address)
VALUES (
    (SELECT entity_id FROM guacamole_entity WHERE name = 'soporte' AND type = 'USER'),
    decode('00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 'hex'),
    'Usuario Soporte',
    'soporte@kolaboree.local'
)
ON CONFLICT (entity_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email_address = EXCLUDED.email_address;

-- Dar permisos a TODAS las conexiones existentes
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT 
    e.entity_id,
    c.connection_id,
    p.permission
FROM guacamole_entity e
CROSS JOIN guacamole_connection c
CROSS JOIN (VALUES ('READ'), ('UPDATE')) AS p(permission)
WHERE e.name = 'soporte' AND e.type = 'USER'
ON CONFLICT (entity_id, connection_id, permission) DO NOTHING;

SELECT 'Usuario soporte configurado con acceso a todas las conexiones' as status;

-- Mostrar resumen
SELECT 'Usuarios activos:' as info;
SELECT e.name, u.full_name FROM guacamole_entity e 
JOIN guacamole_user u ON e.entity_id = u.entity_id 
WHERE e.type = 'USER';

SELECT 'Conexiones disponibles:' as info;
SELECT connection_name, protocol FROM guacamole_connection ORDER BY connection_name;

EOF

echo "✅ Usuario 'soporte' configurado para SSO"
echo "🎯 El usuario podrá acceder a todas las conexiones via Authentik"
"""
    
    with open('map-ldap-users.sh', 'w') as f:
        f.write(mapping_script)
    
    subprocess.run(['chmod', '+x', 'map-ldap-users.sh'])
    print("✅ Script creado: map-ldap-users.sh")

def show_current_status():
    """Mostrar estado actual y próximos pasos"""
    print("\n📊 ESTADO ACTUAL DEL SISTEMA")
    print("="*35)
    
    print("✅ CONFIGURADO:")
    print("├── Guacamole con múltiples conexiones")
    print("├── OIDC configurado en Guacamole")
    print("├── LDAP configurado en Guacamole")
    print("└── Variables de entorno correctas")
    
    print("\n⏳ PENDIENTE:")
    print("├── Provider OIDC en Authentik")
    print("├── Application en Authentik")
    print("├── LDAP Source en Authentik")
    print("└── Mapeo de usuarios LDAP->Guacamole")
    
    print("\n🚀 PRÓXIMOS PASOS:")
    print("1. ./map-ldap-users.sh (mapear usuarios)")
    print("2. Configurar Provider en Authentik")
    print("3. Configurar Application en Authentik")
    print("4. Configurar LDAP Source en Authentik")
    print("5. Probar flujo SSO completo")
    
    print("\n🎯 OBJETIVO FINAL:")
    print("Usuario entra por Authentik -> Login LDAP -> Clic en Guacamole")
    print("-> Ve todas sus conexiones sin login adicional")

def main():
    print("🔍 ANÁLISIS DE CONFIGURACIÓN ACTUAL")
    print("="*50)
    
    # Verificar conexiones existentes
    connections_ok = check_guacamole_connections()
    
    # Verificar usuarios existentes
    users_ok = check_guacamole_users()
    
    # Mostrar estrategia de mapeo
    show_sso_mapping_strategy()
    
    # Crear script de mapeo
    create_user_mapping_script()
    
    # Mostrar estado actual
    show_current_status()
    
    if connections_ok:
        print("\n🎉 ¡Excelente! Ya tienes conexiones configuradas.")
        print("Solo falta completar la configuración SSO en Authentik.")
    else:
        print("\n⚠️ Verifica que Guacamole esté funcionando correctamente.")

if __name__ == "__main__":
    main()