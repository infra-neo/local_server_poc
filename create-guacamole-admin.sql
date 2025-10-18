-- Script para crear usuario administrador de Guacamole
-- Usuario: akadmin
-- Contraseña: KolaboreeAdmin2024

-- 1. Crear la entidad del usuario
INSERT INTO guacamole_entity (name, type) VALUES ('akadmin', 'USER');

-- 2. Obtener el entity_id que se acaba de crear
-- 3. Crear el usuario con hash de contraseña
INSERT INTO guacamole_user (
    entity_id, 
    password_hash, 
    password_salt, 
    password_date,
    full_name,
    email_address
) VALUES (
    (SELECT entity_id FROM guacamole_entity WHERE name = 'akadmin' AND type = 'USER'),
    decode(encode(digest('KolaboreeAdmin2024' || '\x02', 'sha256'), 'hex'), 'hex'),
    '\x02'::bytea,
    NOW(),
    'Kolaboree Administrator',
    'akadmin@kolaboree.local'
);

-- 4. Otorgar permisos de administrador del sistema
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission_type::guacamole_system_permission_type
FROM guacamole_entity, (
    VALUES 
    ('ADMINISTER'),
    ('CREATE_CONNECTION'),
    ('CREATE_CONNECTION_GROUP'),
    ('CREATE_SHARING_PROFILE'),
    ('CREATE_USER'),
    ('CREATE_USER_GROUP')
) AS perms(permission_type)
WHERE name = 'akadmin' AND type = 'USER';

-- 5. Otorgar permisos sobre usuarios (para administrar otros usuarios)
INSERT INTO guacamole_user_permission (entity_id, affected_user_id, permission)
SELECT 
    u1.entity_id,
    u2.user_id,
    'ADMINISTER'::guacamole_object_permission_type
FROM guacamole_entity e1
JOIN guacamole_user u1 ON e1.entity_id = u1.entity_id
CROSS JOIN guacamole_user u2
WHERE e1.name = 'akadmin' AND e1.type = 'USER';