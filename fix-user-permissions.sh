#!/bin/bash
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
    '\x0000000000000000000000000000000000000000000000000000000000000000',
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
