#!/bin/bash
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
