#!/bin/bash
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
