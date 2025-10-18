#!/bin/bash
# Script corregido para arreglar permisos del usuario soporte

echo "🔧 Arreglando permisos del usuario soporte (versión corregida)..."

docker exec -i kolaboree-postgres psql -U kolaboree -d kolaboree << 'EOF'

-- Limpiar permisos existentes del usuario soporte
DELETE FROM guacamole_connection_permission 
WHERE entity_id = (SELECT entity_id FROM guacamole_entity WHERE name = 'soporte' AND type = 'USER');

-- Dar permisos READ a TODAS las conexiones usando el tipo correcto
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT 
    e.entity_id,
    c.connection_id,
    'READ'::guacamole_object_permission_type
FROM guacamole_entity e
CROSS JOIN guacamole_connection c
WHERE e.name = 'soporte' AND e.type = 'USER';

-- Mostrar resultado
SELECT 'Permisos configurados para usuario soporte:' as info;
SELECT 
    c.connection_name,
    cp.permission::text
FROM guacamole_connection_permission cp
JOIN guacamole_connection c ON cp.connection_id = c.connection_id
JOIN guacamole_entity e ON cp.entity_id = e.entity_id
WHERE e.name = 'soporte'
ORDER BY c.connection_name;

-- Verificar que el usuario soporte existe
SELECT 'Usuario soporte verificado:' as info;
SELECT e.name, u.full_name, u.email_address
FROM guacamole_entity e
JOIN guacamole_user u ON e.entity_id = u.entity_id
WHERE e.name = 'soporte';

EOF

echo "✅ Permisos del usuario soporte actualizados correctamente"