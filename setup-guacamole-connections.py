#!/usr/bin/env python3
"""
Script para configurar usuarios y conexiones en Guacamole
"""

import psycopg2
import hashlib
import os
from datetime import datetime

def connect_to_db():
    """Conectar a la base de datos PostgreSQL"""
    try:
        conn = psycopg2.connect(
            host="34.68.124.46",
            port="5432",
            database="kolaboree",
            user="kolaboree",
            password=os.getenv("POSTGRES_PASSWORD", "kolaboree_password_2024")
        )
        return conn
    except Exception as e:
        print(f"❌ Error conectando a la base de datos: {e}")
        return None

def create_guacamole_tables(conn):
    """Crear tablas adicionales de Guacamole si no existen"""
    
    tables_sql = """
    -- Crear tablas de Guacamole si no existen
    CREATE TABLE IF NOT EXISTS guacamole_entity (
        entity_id     SERIAL       NOT NULL,
        name          VARCHAR(128) NOT NULL,
        type          guacamole_entity_type NOT NULL,
        PRIMARY KEY (entity_id),
        UNIQUE (type, name)
    );

    CREATE TABLE IF NOT EXISTS guacamole_user (
        user_id       SERIAL       NOT NULL,
        entity_id     INTEGER      NOT NULL,
        password_hash BYTEA        NOT NULL,
        password_salt BYTEA,
        password_date TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
        disabled      BOOLEAN      NOT NULL DEFAULT FALSE,
        expired       BOOLEAN      NOT NULL DEFAULT FALSE,
        access_window_start    TIME,
        access_window_end      TIME,
        valid_from    DATE,
        valid_until   DATE,
        timezone      VARCHAR(64),
        full_name     VARCHAR(256),
        email_address VARCHAR(256),
        organization  VARCHAR(256),
        organizational_role VARCHAR(256),
        PRIMARY KEY (user_id),
        UNIQUE (entity_id),
        CONSTRAINT guacamole_user_single_entity 
            FOREIGN KEY (entity_id) 
            REFERENCES guacamole_entity (entity_id) 
            ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS guacamole_connection (
        connection_id   SERIAL       NOT NULL,
        connection_name VARCHAR(128) NOT NULL,
        parent_id       INTEGER,
        protocol        guacamole_protocol NOT NULL,
        proxy_port      INTEGER,
        proxy_hostname  VARCHAR(512),
        proxy_encryption_method guacamole_proxy_encryption_method,
        max_connections          INTEGER,
        max_connections_per_user INTEGER,
        connection_weight        INTEGER,
        failover_only            BOOLEAN NOT NULL DEFAULT FALSE,
        PRIMARY KEY (connection_id),
        UNIQUE (connection_name, parent_id),
        CONSTRAINT guacamole_connection_parent
            FOREIGN KEY (parent_id) 
            REFERENCES guacamole_connection (connection_id) 
            ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS guacamole_connection_parameter (
        connection_id   INTEGER       NOT NULL,
        parameter_name  VARCHAR(128)  NOT NULL,
        parameter_value VARCHAR(4096) NOT NULL,
        PRIMARY KEY (connection_id, parameter_name),
        CONSTRAINT guacamole_connection_parameter_connection
            FOREIGN KEY (connection_id) 
            REFERENCES guacamole_connection (connection_id) 
            ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS guacamole_connection_permission (
        entity_id     INTEGER NOT NULL,
        connection_id INTEGER NOT NULL,
        permission    guacamole_object_permission NOT NULL,
        PRIMARY KEY (entity_id, connection_id, permission),
        CONSTRAINT guacamole_connection_permission_entity
            FOREIGN KEY (entity_id) 
            REFERENCES guacamole_entity (entity_id) 
            ON DELETE CASCADE,
        CONSTRAINT guacamole_connection_permission_connection
            FOREIGN KEY (connection_id) 
            REFERENCES guacamole_connection (connection_id) 
            ON DELETE CASCADE
    );

    -- Crear tipos si no existen
    DO $$ 
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'guacamole_entity_type') THEN
            CREATE TYPE guacamole_entity_type AS ENUM(
                'USER',
                'USER_GROUP'
            );
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'guacamole_protocol') THEN
            CREATE TYPE guacamole_protocol AS ENUM(
                'rdp',
                'ssh',
                'vnc',
                'telnet'
            );
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'guacamole_proxy_encryption_method') THEN
            CREATE TYPE guacamole_proxy_encryption_method AS ENUM(
                'NONE',
                'SSL'
            );
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'guacamole_object_permission') THEN
            CREATE TYPE guacamole_object_permission AS ENUM(
                'READ',
                'UPDATE',
                'DELETE',
                'ADMINISTER'
            );
        END IF;
    END$$;
    """
    
    cursor = conn.cursor()
    try:
        cursor.execute(tables_sql)
        conn.commit()
        print("✅ Tablas de Guacamole verificadas/creadas")
        return True
    except Exception as e:
        print(f"❌ Error creando tablas: {e}")
        conn.rollback()
        return False
    finally:
        cursor.close()

def create_user_and_connection(conn):
    """Crear usuario y conexión RDP para Windows"""
    
    cursor = conn.cursor()
    
    try:
        # 1. Crear entity para usuario
        cursor.execute("""
            INSERT INTO guacamole_entity (name, type)
            VALUES ('soporte', 'USER')
            ON CONFLICT (type, name) DO NOTHING
            RETURNING entity_id;
        """)
        
        result = cursor.fetchone()
        if result:
            entity_id = result[0]
            print(f"✅ Entity creada con ID: {entity_id}")
        else:
            # Si ya existe, obtener el ID
            cursor.execute("""
                SELECT entity_id FROM guacamole_entity 
                WHERE name = 'soporte' AND type = 'USER';
            """)
            entity_id = cursor.fetchone()[0]
            print(f"✅ Entity ya existe con ID: {entity_id}")
        
        # 2. Crear usuario con hash de contraseña
        # Generar hash para la contraseña 'Neo123!!!'
        password = 'Neo123!!!'
        password_bytes = password.encode('utf-8')
        password_hash = hashlib.sha256(password_bytes).hexdigest().encode('utf-8')
        
        cursor.execute("""
            INSERT INTO guacamole_user (
                entity_id, password_hash, full_name, email_address
            )
            VALUES (%s, %s, 'Usuario Soporte', 'soporte@kolaboree.local')
            ON CONFLICT (entity_id) DO UPDATE SET
                password_hash = EXCLUDED.password_hash,
                password_date = CURRENT_TIMESTAMP;
        """, (entity_id, password_hash))
        
        print("✅ Usuario 'soporte' creado/actualizado")
        
        # 3. Crear conexión RDP
        cursor.execute("""
            INSERT INTO guacamole_connection (
                connection_name, protocol, max_connections, max_connections_per_user
            )
            VALUES ('Windows Soporte RDP', 'rdp', 10, 2)
            ON CONFLICT (connection_name, parent_id) DO NOTHING
            RETURNING connection_id;
        """)
        
        result = cursor.fetchone()
        if result:
            connection_id = result[0]
            print(f"✅ Conexión RDP creada con ID: {connection_id}")
        else:
            cursor.execute("""
                SELECT connection_id FROM guacamole_connection 
                WHERE connection_name = 'Windows Soporte RDP';
            """)
            connection_id = cursor.fetchone()[0]
            print(f"✅ Conexión RDP ya existe con ID: {connection_id}")
        
        # 4. Configurar parámetros de la conexión RDP
        rdp_params = {
            'hostname': '100.95.223.18',
            'port': '3389',
            'username': 'soporte',
            'password': 'Neo123!!!',
            'security': 'any',
            'ignore-cert': 'true',
            'color-depth': '32',
            'width': '1920',
            'height': '1080',
            'dpi': '96',
            'resize-method': 'reconnect',
            'enable-drive': 'true',
            'drive-name': 'GuacamoleDrive',
            'drive-path': '/tmp/guacamole-drive',
            'enable-printing': 'true',
            'enable-clipboard': 'true'
        }
        
        # Eliminar parámetros existentes
        cursor.execute("""
            DELETE FROM guacamole_connection_parameter 
            WHERE connection_id = %s;
        """, (connection_id,))
        
        # Insertar nuevos parámetros
        for param_name, param_value in rdp_params.items():
            cursor.execute("""
                INSERT INTO guacamole_connection_parameter 
                (connection_id, parameter_name, parameter_value)
                VALUES (%s, %s, %s);
            """, (connection_id, param_name, param_value))
        
        print("✅ Parámetros RDP configurados")
        
        # 5. Dar permisos al usuario sobre la conexión
        permissions = ['READ', 'UPDATE', 'DELETE', 'ADMINISTER']
        
        for permission in permissions:
            cursor.execute("""
                INSERT INTO guacamole_connection_permission 
                (entity_id, connection_id, permission)
                VALUES (%s, %s, %s)
                ON CONFLICT (entity_id, connection_id, permission) DO NOTHING;
            """, (entity_id, connection_id, permission))
        
        print("✅ Permisos asignados al usuario")
        
        conn.commit()
        print("\n🎉 Configuración completada exitosamente!")
        print(f"📋 Usuario: soporte")
        print(f"📋 Contraseña: Neo123!!!")
        print(f"📋 Conexión RDP: Windows Soporte RDP (100.95.223.18)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error configurando usuario y conexión: {e}")
        conn.rollback()
        return False
    finally:
        cursor.close()

def verify_configuration(conn):
    """Verificar que la configuración se haya aplicado correctamente"""
    
    cursor = conn.cursor()
    
    try:
        # Verificar usuario
        cursor.execute("""
            SELECT e.name, u.full_name, u.email_address, u.disabled
            FROM guacamole_entity e
            JOIN guacamole_user u ON e.entity_id = u.entity_id
            WHERE e.name = 'soporte';
        """)
        
        user = cursor.fetchone()
        if user:
            print(f"✅ Usuario verificado: {user[0]} - {user[1]} ({user[2]})")
        else:
            print("❌ Usuario no encontrado")
            return False
        
        # Verificar conexión
        cursor.execute("""
            SELECT connection_name, protocol
            FROM guacamole_connection
            WHERE connection_name = 'Windows Soporte RDP';
        """)
        
        connection = cursor.fetchone()
        if connection:
            print(f"✅ Conexión verificada: {connection[0]} ({connection[1]})")
        else:
            print("❌ Conexión no encontrada")
            return False
        
        # Verificar parámetros
        cursor.execute("""
            SELECT parameter_name, parameter_value
            FROM guacamole_connection_parameter
            WHERE connection_id = (
                SELECT connection_id FROM guacamole_connection 
                WHERE connection_name = 'Windows Soporte RDP'
            );
        """)
        
        params = cursor.fetchall()
        print(f"✅ Parámetros de conexión: {len(params)} configurados")
        
        # Mostrar algunos parámetros importantes
        for param in params:
            if param[0] in ['hostname', 'username', 'port']:
                print(f"   ├── {param[0]}: {param[1]}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error verificando configuración: {e}")
        return False
    finally:
        cursor.close()

def main():
    print("🔧 CONFIGURACIÓN DE GUACAMOLE")
    print("Configurando usuario 'soporte' y conexión RDP...")
    print("="*50)
    
    # Conectar a la base de datos
    conn = connect_to_db()
    if not conn:
        return False
    
    try:
        # Crear tablas si es necesario
        if not create_guacamole_tables(conn):
            return False
        
        # Configurar usuario y conexión
        if not create_user_and_connection(conn):
            return False
        
        # Verificar configuración
        print("\n🔍 VERIFICANDO CONFIGURACIÓN:")
        if verify_configuration(conn):
            print("\n✅ ¡Configuración completada exitosamente!")
            print("\n📋 PRÓXIMOS PASOS:")
            print("1. Reiniciar Guacamole: docker-compose restart guacamole")
            print("2. Acceder vía Authentik: https://34.68.124.46:9443/")
            print("3. Login con usuario LDAP")
            print("4. Hacer clic en aplicación 'Apache Guacamole'")
            print("5. Debería conectar automáticamente a Windows RDP")
            return True
        else:
            print("❌ Error en la verificación")
            return False
        
    finally:
        conn.close()

if __name__ == "__main__":
    main()