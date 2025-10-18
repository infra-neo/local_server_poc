-- Script PostgreSQL para crear conexiones de prueba en Guacamole
-- Compatible con PostgreSQL y esquema Guacamole

DO $$
DECLARE
    connection_id_rdp INTEGER;
    connection_id_vnc INTEGER;
    connection_id_ssh INTEGER;
    user_id_akadmin INTEGER;
BEGIN
    -- 1. Crear conexión Windows RDP
    INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user)
    VALUES ('Windows Server Demo', 'rdp', 2, 1)
    RETURNING connection_id INTO connection_id_rdp;

    -- Configurar parámetros de conexión RDP
    INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES
    (connection_id_rdp, 'hostname', '192.168.1.100'),
    (connection_id_rdp, 'port', '3389'),
    (connection_id_rdp, 'username', 'administrator'),
    (connection_id_rdp, 'password', 'AdminPass123'),
    (connection_id_rdp, 'domain', 'NEOGENESYS'),
    (connection_id_rdp, 'security', 'rdp'),
    (connection_id_rdp, 'ignore-cert', 'true'),
    (connection_id_rdp, 'resize-method', 'reconnect'),
    (connection_id_rdp, 'width', '1920'),
    (connection_id_rdp, 'height', '1080'),
    (connection_id_rdp, 'dpi', '96'),
    (connection_id_rdp, 'color-depth', '32');

    -- 2. Crear conexión Linux VNC
    INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user)
    VALUES ('Linux Desktop VNC', 'vnc', 1, 1)
    RETURNING connection_id INTO connection_id_vnc;

    -- Configurar parámetros de conexión VNC
    INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES
    (connection_id_vnc, 'hostname', '192.168.1.101'),
    (connection_id_vnc, 'port', '5901'),
    (connection_id_vnc, 'password', 'vncpass123'),
    (connection_id_vnc, 'width', '1920'),
    (connection_id_vnc, 'height', '1080'),
    (connection_id_vnc, 'color-depth', '32'),
    (connection_id_vnc, 'cursor', 'remote');

    -- 3. Crear conexión SSH
    INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user)
    VALUES ('Ubuntu Server SSH', 'ssh', 5, 2)
    RETURNING connection_id INTO connection_id_ssh;

    -- Configurar parámetros de conexión SSH
    INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES
    (connection_id_ssh, 'hostname', '192.168.1.102'),
    (connection_id_ssh, 'port', '22'),
    (connection_id_ssh, 'username', 'admin'),
    (connection_id_ssh, 'password', 'sshpass123'),
    (connection_id_ssh, 'font-size', '14'),
    (connection_id_ssh, 'color-scheme', 'green-black'),
    (connection_id_ssh, 'terminal-type', 'xterm-256color');

    -- Obtener el ID del usuario akadmin
    SELECT entity_id INTO user_id_akadmin 
    FROM guacamole_entity 
    WHERE name = 'akadmin' AND type = 'USER';

    -- Dar permisos de conexión al usuario akadmin
    INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
    VALUES 
    (user_id_akadmin, connection_id_rdp, 'READ'),
    (user_id_akadmin, connection_id_vnc, 'READ'),
    (user_id_akadmin, connection_id_ssh, 'READ');

    -- Mostrar resumen
    RAISE NOTICE 'Conexiones creadas exitosamente:';
    RAISE NOTICE 'RDP Connection ID: %', connection_id_rdp;
    RAISE NOTICE 'VNC Connection ID: %', connection_id_vnc;
    RAISE NOTICE 'SSH Connection ID: %', connection_id_ssh;
    RAISE NOTICE 'User akadmin ID: %', user_id_akadmin;
END $$;