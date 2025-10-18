#!/usr/bin/env python3
"""
Script simplificado para agregar conexión RDP a Guacamole usando SQL directo
"""

import os

def generate_sql_setup():
    """Generar SQL para configurar Guacamole"""
    
    sql_script = """
-- Configuración de usuario y conexión RDP para Guacamole
-- Usuario: soporte, Conexión: Windows 100.95.223.18

-- 1. Insertar conexión RDP
INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user)
VALUES ('Windows Soporte RDP', 'rdp', 10, 2)
ON CONFLICT (connection_name, parent_id) DO NOTHING;

-- 2. Obtener connection_id (asumiendo que es 1 si es la primera)
-- Configurar parámetros de conexión RDP
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
VALUES 
    (1, 'hostname', '100.95.223.18'),
    (1, 'port', '3389'),
    (1, 'username', 'soporte'), 
    (1, 'password', 'Neo123!!!'),
    (1, 'security', 'any'),
    (1, 'ignore-cert', 'true'),
    (1, 'color-depth', '32'),
    (1, 'width', '1920'),
    (1, 'height', '1080'),
    (1, 'dpi', '96'),
    (1, 'resize-method', 'reconnect'),
    (1, 'enable-drive', 'true'),
    (1, 'drive-name', 'GuacamoleDrive'),
    (1, 'enable-printing', 'true'),
    (1, 'enable-clipboard', 'true')
ON CONFLICT (connection_id, parameter_name) DO UPDATE SET
    parameter_value = EXCLUDED.parameter_value;

-- 3. Crear usuario guacadmin si no existe
INSERT INTO guacamole_entity (name, type)
VALUES ('guacadmin', 'USER')
ON CONFLICT (type, name) DO NOTHING;

-- 4. Crear usuario admin con hash de contraseña
INSERT INTO guacamole_user (entity_id, password_hash, full_name, email_address)
VALUES (
    (SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'),
    '\\xca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb',  -- hash de 'admin'
    'Guacamole Admin',
    'admin@kolaboree.local'
)
ON CONFLICT (entity_id) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    password_date = CURRENT_TIMESTAMP;

-- 5. Dar permisos al admin sobre la conexión
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
VALUES 
    ((SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'), 1, 'READ'),
    ((SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'), 1, 'UPDATE'),
    ((SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'), 1, 'DELETE'),
    ((SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'), 1, 'ADMINISTER')
ON CONFLICT (entity_id, connection_id, permission) DO NOTHING;

-- 6. Verificar configuración
SELECT 'Conexiones configuradas:' as info;
SELECT connection_id, connection_name, protocol FROM guacamole_connection;

SELECT 'Parámetros de conexión:' as info;
SELECT cp.connection_id, cp.parameter_name, cp.parameter_value 
FROM guacamole_connection_parameter cp
JOIN guacamole_connection c ON cp.connection_id = c.connection_id
WHERE c.connection_name = 'Windows Soporte RDP';

SELECT 'Usuarios configurados:' as info;
SELECT e.name, u.full_name, u.email_address
FROM guacamole_entity e
JOIN guacamole_user u ON e.entity_id = u.entity_id;
"""
    
    return sql_script

def save_sql_file():
    """Guardar el script SQL a un archivo"""
    sql_content = generate_sql_setup()
    
    with open('setup-guacamole-rdp.sql', 'w') as f:
        f.write(sql_content)
    
    print("✅ Archivo SQL generado: setup-guacamole-rdp.sql")
    return True

def show_manual_steps():
    """Mostrar pasos manuales para ejecutar el SQL"""
    print("\n📋 PASOS PARA APLICAR LA CONFIGURACIÓN:")
    print("-" * 45)
    
    print("1. Ejecutar el SQL en PostgreSQL:")
    print("   docker exec -i kolaboree-postgres psql -U kolaboree -d kolaboree < setup-guacamole-rdp.sql")
    
    print("\n2. O conectar manualmente:")
    print("   docker exec -it kolaboree-postgres psql -U kolaboree -d kolaboree")
    print("   \\i /tmp/setup-guacamole-rdp.sql")
    
    print("\n3. Reiniciar Guacamole:")
    print("   docker-compose restart guacamole")
    
    print("\n4. Verificar conexión:")
    print("   - Login directo en Guacamole: http://34.68.124.46:8080/guacamole/")
    print("   - Usuario: guacadmin")
    print("   - Contraseña: admin")
    print("   - Debería aparecer conexión 'Windows Soporte RDP'")

def create_quick_setup():
    """Crear script de configuración rápida"""
    
    setup_script = """#!/bin/bash
# Script rápido para configurar Guacamole

echo "🔧 Configurando conexión RDP en Guacamole..."

# Ejecutar SQL de configuración
docker exec -i kolaboree-postgres psql -U kolaboree -d kolaboree << 'EOF'
INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user)
VALUES ('Windows Soporte RDP', 'rdp', 10, 2)
ON CONFLICT (connection_name, parent_id) DO NOTHING;

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT 
    c.connection_id,
    p.param_name,
    p.param_value
FROM guacamole_connection c
CROSS JOIN (
    VALUES 
        ('hostname', '100.95.223.18'),
        ('port', '3389'),
        ('username', 'soporte'),
        ('password', 'Neo123!!!'),
        ('security', 'any'),
        ('ignore-cert', 'true'),
        ('color-depth', '32'),
        ('width', '1920'),
        ('height', '1080'),
        ('resize-method', 'reconnect'),
        ('enable-drive', 'true'),
        ('enable-clipboard', 'true')
) AS p(param_name, param_value)
WHERE c.connection_name = 'Windows Soporte RDP'
ON CONFLICT (connection_id, parameter_name) DO UPDATE SET
    parameter_value = EXCLUDED.parameter_value;

INSERT INTO guacamole_entity (name, type)
VALUES ('guacadmin', 'USER')
ON CONFLICT (type, name) DO NOTHING;

INSERT INTO guacamole_user (entity_id, password_hash, full_name, email_address)
VALUES (
    (SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'),
    decode('ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb', 'hex'),
    'Guacamole Admin',
    'admin@kolaboree.local'
)
ON CONFLICT (entity_id) DO UPDATE SET
    password_hash = EXCLUDED.password_hash;

INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT 
    e.entity_id,
    c.connection_id,
    p.permission
FROM guacamole_entity e
CROSS JOIN guacamole_connection c
CROSS JOIN (VALUES ('READ'), ('UPDATE'), ('DELETE'), ('ADMINISTER')) AS p(permission)
WHERE e.name = 'guacadmin' AND e.type = 'USER' AND c.connection_name = 'Windows Soporte RDP'
ON CONFLICT (entity_id, connection_id, permission) DO NOTHING;

SELECT 'Configuración completada' as status;
EOF

echo "✅ Configuración completada"
echo "🔄 Reiniciando Guacamole..."
docker-compose restart guacamole

echo "🎉 ¡Configuración terminada!"
echo "🔗 Acceder a: http://34.68.124.46:8080/guacamole/"
echo "👤 Usuario: guacadmin"
echo "🔑 Contraseña: admin"
"""
    
    with open('quick-setup-guacamole.sh', 'w') as f:
        f.write(setup_script)
    
    # Hacer ejecutable
    os.chmod('quick-setup-guacamole.sh', 0o755)
    
    print("✅ Script de configuración rápida creado: quick-setup-guacamole.sh")

def main():
    print("🔧 CONFIGURACIÓN RDP PARA GUACAMOLE")
    print("="*50)
    
    # Generar archivos
    save_sql_file()
    create_quick_setup()
    
    print("\n📋 ARCHIVOS GENERADOS:")
    print("├── setup-guacamole-rdp.sql (configuración SQL)")
    print("└── quick-setup-guacamole.sh (script automático)")
    
    show_manual_steps()
    
    print("\n🚀 OPCIÓN RÁPIDA:")
    print("└── ./quick-setup-guacamole.sh")
    
    print("\n💡 DESPUÉS DE CONFIGURAR:")
    print("1. Probar login directo en Guacamole (guacadmin/admin)")
    print("2. Configurar Provider y Application en Authentik")
    print("3. Probar flujo SSO completo desde Authentik")

if __name__ == "__main__":
    main()