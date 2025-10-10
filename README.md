# Plataforma de Acceso Remoto Seguro

## Descripción

La **Plataforma de Acceso Remoto Seguro** es una solución integral de código abierto diseñada para proporcionar acceso seguro y centralizado a infraestructura híbrida (on-premise y en la nube). La plataforma combina múltiples tecnologías de vanguardia para ofrecer autenticación robusta, gestión de acceso remoto y conectividad de red de confianza cero (Zero Trust).

Esta solución está diseñada para organizaciones que necesitan:
- 🔐 **Gestión centralizada de identidades y acceso (IAM/SSO)**
- 🖥️ **Acceso remoto seguro a servidores mediante RDP y SSH desde un navegador web**
- 🌐 **Redes de confianza cero (Zero Trust) para comunicaciones seguras**
- 📊 **Portal web centralizado para gestión de recursos**

## Stack Tecnológico

La plataforma está construida utilizando las siguientes tecnologías de código abierto:

| Componente | Tecnología | Propósito |
|------------|-----------|-----------|
| **Identidad y Acceso (IAM/SSO)** | [Authentik](https://goauthentik.io/) | Gestión de identidades, autenticación y autorización con soporte SSO |
| **Gateway de Acceso Remoto** | [Apache Guacamole](https://guacamole.apache.org/) | Acceso a RDP/SSH/VNC mediante HTML5 sin cliente |
| **Red Segura (Zero Trust)** | [OpenZiti](https://openziti.io/) | Red de confianza cero para conectividad segura |
| **Base de Datos** | [PostgreSQL](https://www.postgresql.org/) | Base de datos relacional para persistencia |
| **Caché/Cola de Mensajes** | [Redis](https://redis.io/) | Caché en memoria y sistema de mensajería |
| **Portal Web** | Nginx | Frontend del portal (placeholder) |
| **API Gateway** | Node.js | Backend de la API (placeholder) |
| **Orquestación** | [Docker Swarm](https://docs.docker.com/engine/swarm/) | Orquestación de contenedores |

## Prerrequisitos

Antes de desplegar la plataforma, asegúrate de tener:

### Sistema Operativo
- **Ubuntu 22.04 LTS** o superior (recomendado)
- Otras distribuciones Linux compatibles con Docker

### Software Requerido
- **Docker Engine** versión 20.10 o superior
- **Docker Compose** (opcional, para validación)
- Al menos **4GB de RAM** disponible
- Al menos **20GB de espacio libre en disco**

### Permisos
- Acceso con privilegios de superusuario (sudo) para inicializar Docker Swarm

### Puertos Requeridos
Los siguientes puertos deben estar disponibles en el host:
- `80` - Portal Web
- `3000` - API Gateway
- `8080` - Apache Guacamole
- `9000` - Authentik (HTTP)
- `9443` - Authentik (HTTPS)
- `1280` - OpenZiti Edge API
- `6262` - OpenZiti Controller

## Guía de Inicio Rápido

Sigue estos pasos para desplegar la plataforma:

### 1. Clonar el Repositorio

```bash
git clone https://github.com/infra-neo/local_server_poc.git
cd local_server_poc
```

### 2. Configurar Variables de Entorno

Copia el archivo de ejemplo `.env.example` a `.env`:

```bash
cp .env.example .env
```

Edita el archivo `.env` con tus valores seguros:

```bash
nano .env
```

**⚠️ IMPORTANTE:** Cambia todas las contraseñas y claves secretas por valores seguros antes de desplegar en producción.

### 3. Ejecutar Auditoría del Sistema

Verifica que tu sistema cumple con todos los prerrequisitos:

```bash
bash scripts/audit.sh
```

Este script verificará:
- Instalación de Docker
- Disponibilidad de puertos
- Recursos del sistema
- Configuración del archivo `.env`

### 4. Desplegar la Plataforma

Ejecuta el script de despliegue:

```bash
bash scripts/deploy.sh
```

Este script:
- Inicializa Docker Swarm (si no está activo)
- Despliega todos los servicios
- Muestra las URLs de acceso a cada componente

### 5. Acceder a los Servicios

Una vez desplegado, podrás acceder a:

- **Portal Web:** http://localhost
- **API Gateway:** http://localhost:3000
- **Apache Guacamole:** http://localhost:8080/guacamole
- **Authentik:** http://localhost:9000 o https://localhost:9443
- **OpenZiti Edge API:** https://localhost:1280

## Configuración

### Variables de Entorno (`.env`)

El archivo `.env` contiene todas las configuraciones necesarias para la plataforma:

#### Configuración General
- `STACK_NAME`: Nombre del stack de Docker Swarm (default: `secure-access-platform`)

#### Base de Datos PostgreSQL
- `POSTGRES_DB`: Nombre de la base de datos principal
- `POSTGRES_USER`: Usuario de PostgreSQL
- `POSTGRES_PASSWORD`: Contraseña de PostgreSQL (**¡Cámbiala!**)

#### Redis
- `REDIS_PASSWORD`: Contraseña de Redis (**¡Cámbiala!**)

#### Authentik
- `AUTHENTIK_SECRET_KEY`: Clave secreta para Authentik (**¡Cámbiala!**)
- `AUTHENTIK_ERROR_REPORTING`: Habilitar/deshabilitar reporte de errores

#### Apache Guacamole
- `GUACD_HOSTNAME`: Hostname del daemon de Guacamole
- `GUACAMOLE_DB`: Base de datos de Guacamole
- `GUACAMOLE_USER`: Usuario de la base de datos de Guacamole
- `GUACAMOLE_PASSWORD`: Contraseña de Guacamole (**¡Cámbiala!**)

#### OpenZiti
- `ZITI_CTRL_NAME`: Nombre del controlador Ziti
- `ZITI_CTRL_PORT`: Puerto del controlador
- `ZITI_EDGE_API_PORT`: Puerto de la API Edge

#### Puertos (Opcionales)
Puedes personalizar los puertos expuestos modificando estas variables:
- `PORTAL_WEB_PORT` (default: 80)
- `API_GATEWAY_PORT` (default: 3000)
- `GUACAMOLE_PORT` (default: 8080)
- `AUTHENTIK_PORT_HTTP` (default: 9000)
- `AUTHENTIK_PORT_HTTPS` (default: 9443)
- `ZITI_PORT_API` (default: 1280)
- `ZITI_PORT_CTRL` (default: 6262)

## Scripts Disponibles

### `scripts/deploy.sh`

**Propósito:** Despliega la plataforma completa en Docker Swarm.

**Funcionalidad:**
- Verifica la existencia del archivo `.env`
- Carga las variables de entorno
- Verifica que Docker está instalado y corriendo
- Inicializa Docker Swarm si no está activo
- Despliega el stack usando `docker stack deploy`
- Muestra las URLs de acceso a todos los servicios

**Uso:**
```bash
bash scripts/deploy.sh
```

### `scripts/teardown.sh`

**Propósito:** Elimina el stack desplegado de forma segura.

**Funcionalidad:**
- Carga las variables de entorno del archivo `.env`
- Elimina el stack de Docker Swarm
- Preserva los volúmenes de datos por seguridad
- Proporciona comandos (comentados) para limpieza completa

**Uso:**
```bash
bash scripts/teardown.sh
```

**Nota:** Los volúmenes de datos persisten después del teardown para evitar pérdida de datos accidental. Si deseas eliminarlos, sigue las instrucciones que muestra el script.

### `scripts/audit.sh`

**Propósito:** Verifica los prerrequisitos y la configuración antes del despliegue.

**Funcionalidad:**
- Verifica la instalación de Docker
- Comprueba que Docker está corriendo
- Valida la existencia y configuración del archivo `.env`
- Verifica la disponibilidad de los puertos requeridos
- Comprueba los recursos del sistema (RAM y espacio en disco)
- Detecta contraseñas por defecto y emite advertencias de seguridad

**Uso:**
```bash
bash scripts/audit.sh
```

## Comandos Útiles

### Verificar el Estado de los Servicios

```bash
docker stack services secure-access-platform
```

### Ver Logs de un Servicio

```bash
docker service logs secure-access-platform_<nombre-servicio>
```

Ejemplos:
```bash
docker service logs secure-access-platform_authentik-server
docker service logs secure-access-platform_guacamole-client
```

### Escalar un Servicio

```bash
docker service scale secure-access-platform_api-gateway=3
```

### Listar Volúmenes

```bash
docker volume ls | grep secure-access-platform
```

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Swarm Cluster                    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  Portal Web  │  │ API Gateway  │  │  Authentik   │    │
│  │   (Nginx)    │  │   (Node.js)  │  │    (IAM)     │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  Guacamole   │  │  OpenZiti    │  │  PostgreSQL  │    │
│  │  (Gateway)   │  │ (Zero Trust) │  │  (Database)  │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────┐                                          │
│  │    Redis     │                                          │
│  │   (Cache)    │                                          │
│  └──────────────┘                                          │
│                                                             │
│                    Red Overlay: stack-net                  │
└─────────────────────────────────────────────────────────────┘
```

## Seguridad

### Mejores Prácticas

1. **Cambia todas las contraseñas por defecto** en el archivo `.env`
2. **Usa contraseñas fuertes** de al menos 32 caracteres para servicios críticos
3. **No subas el archivo `.env` al repositorio** (está en `.gitignore`)
4. **Configura HTTPS** para todos los servicios expuestos públicamente
5. **Implementa firewall** para restringir el acceso a puertos sensibles
6. **Actualiza regularmente** las imágenes de Docker para obtener parches de seguridad

### Generación de Contraseñas Seguras

Puedes generar contraseñas seguras usando:

```bash
# Contraseña de 32 caracteres
openssl rand -base64 32

# Contraseña de 64 caracteres
openssl rand -base64 64
```

## Mantenimiento

### Actualizar Imágenes

```bash
docker service update --image <nueva-imagen> secure-access-platform_<servicio>
```

### Backup de Datos

Los datos persisten en volúmenes de Docker. Para hacer backup:

```bash
# Ejemplo: Backup de PostgreSQL
docker run --rm \
  --volumes-from secure-access-platform_postgres.1.xxxx \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/postgres_backup.tar.gz /var/lib/postgresql/data
```

### Restore de Datos

```bash
# Ejemplo: Restore de PostgreSQL
docker run --rm \
  --volumes-from secure-access-platform_postgres.1.xxxx \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/postgres_backup.tar.gz -C /
```

## Solución de Problemas

### Los servicios no inician

1. Verifica los logs: `docker service logs <servicio>`
2. Comprueba el estado: `docker stack services secure-access-platform`
3. Verifica que los puertos no estén en uso: `bash scripts/audit.sh`

### No puedo acceder a un servicio

1. Verifica que el servicio está corriendo: `docker stack services secure-access-platform`
2. Comprueba el firewall del host
3. Verifica que el puerto está correctamente mapeado

### Problemas de rendimiento

1. Verifica los recursos del sistema: `docker stats`
2. Escala los servicios según necesidad
3. Revisa los logs en busca de errores

## Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto es de código abierto y está disponible bajo la licencia que determines.

## Soporte

Para reportar problemas o solicitar nuevas características, por favor abre un issue en el repositorio de GitHub.

---

**Desarrollado con ❤️ para facilitar el acceso remoto seguro**