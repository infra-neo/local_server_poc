-- Script para resetear la contraseña del usuario akadmin
-- Contraseña: admin123

-- Generar un salt aleatorio simple
UPDATE guacamole_user 
SET 
    password_hash = decode('5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 'hex'),
    password_salt = decode('00', 'hex'),
    password_date = NOW()
WHERE entity_id = (SELECT entity_id FROM guacamole_entity WHERE name = 'akadmin');