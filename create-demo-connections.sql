-- Script SQL para crear conexiones de prueba en Guacamole
-- Estas conexiones aparecerán en el dashboard RAC

-- 1. Crear conexión Windows RDP
INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user)
VALUES ('Windows Server Demo', 'rdp', 2, 1);

-- Obtener el ID de la conexión recién creada
SET @connection_id = LAST_INSERT_ID();

-- Configurar parámetros de conexión RDP
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES
(@connection_id, 'hostname', '192.168.1.100'),
(@connection_id, 'port', '3389'),
(@connection_id, 'username', 'administrator'),
(@connection_id, 'password', 'AdminPass123'),
(@connection_id, 'domain', 'NEOGENESYS'),
(@connection_id, 'security', 'rdp'),
(@connection_id, 'ignore-cert', 'true'),
(@connection_id, 'resize-method', 'reconnect'),
(@connection_id, 'width', '1920'),
(@connection_id, 'height', '1080'),
(@connection_id, 'dpi', '96'),
(@connection_id, 'color-depth', '32');

-- 2. Crear conexión Linux VNC
INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user)
VALUES ('Linux Desktop VNC', 'vnc', 1, 1);

SET @connection_id2 = LAST_INSERT_ID();

-- Configurar parámetros de conexión VNC
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES
(@connection_id2, 'hostname', '192.168.1.101'),
(@connection_id2, 'port', '5901'),
(@connection_id2, 'password', 'vncpass123'),
(@connection_id2, 'width', '1920'),
(@connection_id2, 'height', '1080'),
(@connection_id2, 'color-depth', '32'),
(@connection_id2, 'cursor', 'remote');

-- 3. Crear conexión SSH
INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user)
VALUES ('Ubuntu Server SSH', 'ssh', 5, 2);

SET @connection_id3 = LAST_INSERT_ID();

-- Configurar parámetros de conexión SSH
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES
(@connection_id3, 'hostname', '192.168.1.102'),
(@connection_id3, 'port', '22'),
(@connection_id3, 'username', 'admin'),
(@connection_id3, 'password', 'sshpass123'),
(@connection_id3, 'font-size', '14'),
(@connection_id3, 'color-scheme', 'green-black'),
(@connection_id3, 'terminal-type', 'xterm-256color');

-- Obtener el ID del usuario akadmin
SELECT @user_id := user_id FROM guacamole_user WHERE username = 'akadmin';

-- Dar permisos de conexión al usuario akadmin
INSERT INTO guacamole_connection_permission (user_id, connection_id, permission)
SELECT @user_id, connection_id, 'READ'
FROM guacamole_connection 
WHERE connection_name IN ('Windows Server Demo', 'Linux Desktop VNC', 'Ubuntu Server SSH');

-- Verificar las conexiones creadas
SELECT 
    c.connection_id,
    c.connection_name,
    c.protocol,
    GROUP_CONCAT(CONCAT(cp.parameter_name, '=', cp.parameter_value) SEPARATOR ', ') as parameters
FROM guacamole_connection c
LEFT JOIN guacamole_connection_parameter cp ON c.connection_id = cp.connection_id
WHERE c.connection_name IN ('Windows Server Demo', 'Linux Desktop VNC', 'Ubuntu Server SSH')
GROUP BY c.connection_id, c.connection_name, c.protocol;

-- Verificar permisos del usuario
SELECT 
    u.username,
    c.connection_name,
    cp.permission
FROM guacamole_user u
JOIN guacamole_connection_permission cp ON u.user_id = cp.user_id
JOIN guacamole_connection c ON cp.connection_id = c.connection_id
WHERE u.username = 'akadmin';