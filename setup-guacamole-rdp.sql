
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
    '\xca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb',  -- hash de 'admin'
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
