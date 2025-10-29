# Instrucciones para Crear el Branch Pre-Producción

Este documento explica cómo crear y usar el branch `pre-produccion` basado en los cambios implementados.

## Estado Actual

Se han creado todos los archivos necesarios para el branch de pre-producción en el branch actual (`copilot/create-pre-produccion-branch`).

## Crear el Branch Pre-Producción

### Opción 1: Desde GitHub UI

1. Ir a GitHub: https://github.com/infra-neo/local_server_poc
2. Click en el dropdown de branches
3. Crear nuevo branch llamado `pre-produccion` desde `copilot/create-pre-produccion-branch`
4. O hacer merge del PR de este branch hacia un nuevo branch `pre-produccion`

### Opción 2: Desde línea de comandos (local)

```bash
# Clonar el repositorio
git clone https://github.com/infra-neo/local_server_poc.git
cd local_server_poc

# Fetch todos los branches
git fetch --all

# Crear pre-produccion desde copilot branch
git checkout -b pre-produccion origin/copilot/create-pre-produccion-branch

# Push del nuevo branch
git push -u origin pre-produccion
```

### Opción 3: Mergear el PR

1. Hacer merge del PR actual hacia `main` o crear un nuevo branch `pre-produccion`
2. Todos los archivos estarán disponibles

## Archivos Creados para Pre-Producción

### Configuración Principal
```
docker-compose.preproduccion.yml     - Stack completo con Headscale
.env.preproduccion                   - Variables de entorno
.gitignore                           - Actualizado para excluir backend/frontend
```

### Headscale
```
headscale/config.yaml                - Configuración del servidor
headscale/acl.yaml                   - Políticas de acceso
```

### Nginx
```
nginx/conf.d/preproduccion.conf      - Configuración para hs.kappa4.com y gate.kappa4.com
```

### Datos Iniciales
```
ldap/initial-data.ldif               - Datos LDAP
guacamole/initdb.d/01-schema.sql     - Schema de Guacamole
```

### Scripts
```
scripts/start-preproduccion.sh       - Iniciar el stack
scripts/validate-preproduccion.sh    - Validar instalación
scripts/guia-rapida.sh               - Guía rápida de comandos
```

### Documentación
```
README.preproduccion.md              - Guía completa
TSPLUS_CONFIGURATION.md              - Configuración TSPlus
SCRIPTS_FILTRADOS.md                 - Scripts incluidos
RESUMEN_PREPRODUCCION.md             - Resumen ejecutivo
INSTRUCCIONES_BRANCH.md              - Este archivo
```

## Uso del Branch Pre-Producción

### 1. Checkout del Branch

```bash
git checkout pre-produccion
```

### 2. Configurar Environment

```bash
cp .env.preproduccion .env
nano .env  # Editar contraseñas y tokens
```

### 3. Iniciar Servicios

```bash
./scripts/start-preproduccion.sh
```

O manualmente:

```bash
docker-compose -f docker-compose.preproduccion.yml up -d
```

### 4. Validar Instalación

```bash
./scripts/validate-preproduccion.sh
```

### 5. Configurar Headscale

```bash
# Crear namespace
docker exec headscale-server headscale namespaces create kolaboree

# Generar pre-auth key
docker exec headscale-server headscale --namespace kolaboree \
  preauthkeys create --reusable --expiration 90d
```

### 6. Acceder a los Servicios

- **Headscale UI**: https://hs.kappa4.com/admin/
- **Authentik**: https://gate.kappa4.com
- **Guacamole**: https://gate.kappa4.com/guacamole/

## Diferencias Clave con el Branch Principal

### Incluido en Pre-Producción ✅
- Headscale (red perimetral VPN)
- Headscale UI (administración)
- Authentik + Worker (SSO)
- OpenLDAP (directorio)
- PostgreSQL + Redis
- Guacamole (HTML5 RDP)
- RAC Outpost (proxy TSPlus)
- Nginx (reverse proxy)
- Scripts finales y de validación
- Documentación de producción

### NO Incluido (excluido vía .gitignore) ❌
- Backend FastAPI (desarrollo)
- Frontend React (desarrollo)
- Scripts de desarrollo/debug
- Tailscale (reemplazado por Headscale)

## Dominios Configurados

### hs.kappa4.com
- Headscale UI: `/admin/`
- Headscale API: `/api/`
- Headscale Metrics: `/metrics`
- MagicDNS base domain

### gate.kappa4.com
- Authentik (root): `/`
- Authentik API: `/api/`
- Guacamole: `/guacamole/`
- WebSockets: `/ws/`

## MagicDNS Interno

Los servicios pueden resolverse entre sí usando:
- `authentik.hs.kappa4.com` → 100.64.0.10
- `ldap.hs.kappa4.com` → 100.64.0.11
- `guacamole.hs.kappa4.com` → 100.64.0.12
- `postgres.hs.kappa4.com` → 100.64.0.13
- `tsplus.hs.kappa4.com` → 201.151.150.226

## Configuración TSPlus

El endpoint TSPlus está configurado para:
- **IP**: 201.151.150.226 (o Ubuntu bare metal)
- **Puerto**: 3389
- **Acceso**: Via RAC proxy a través de Headscale
- **Configuración**: Ver `TSPLUS_CONFIGURATION.md`

## Scripts de Validación Disponibles

### En scripts/
- `master-validation.sh` - Validación completa del sistema
- `validate-features.sh` - Validar características
- `validate.sh` - Validación general
- `start.sh`, `stop.sh`, `logs.sh` - Gestión básica
- `audit.sh` - Auditoría
- `auto-configure-authentik.sh` - Auto-config Authentik
- `auto-populate-ldap.sh` - Poblar LDAP

### En root/
- `bootstrap.sh` - Bootstrap inicial
- `verify-sso-complete.sh` - Verificar SSO
- `verify-system-ready.sh` - Sistema listo
- `final-status-ready.sh` - Estado final
- `quick-check.sh` - Check rápido
- Python scripts de validación (verify-*.py, test-*.py)

## Estructura de Carpetas

```
local_server_poc/
├── docker-compose.preproduccion.yml
├── .env.preproduccion
├── README.preproduccion.md
├── RESUMEN_PREPRODUCCION.md
├── TSPLUS_CONFIGURATION.md
├── SCRIPTS_FILTRADOS.md
│
├── headscale/
│   ├── config.yaml
│   └── acl.yaml
│
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── default.conf
│       └── preproduccion.conf
│
├── authentik/
│   ├── branding/
│   └── *.yaml (configuraciones)
│
├── ldap/
│   └── initial-data.ldif
│
├── guacamole/
│   └── initdb.d/
│       └── 01-schema.sql
│
└── scripts/
    ├── start-preproduccion.sh
    ├── validate-preproduccion.sh
    ├── guia-rapida.sh
    └── ... (otros scripts de validación)
```

## Notas Importantes

### Certificados SSL
Antes de usar en producción, configurar certificados SSL válidos:
```bash
nginx/ssl/hs.kappa4.com/fullchain.pem
nginx/ssl/hs.kappa4.com/privkey.pem
nginx/ssl/gate.kappa4.com/fullchain.pem
nginx/ssl/gate.kappa4.com/privkey.pem
```

### Variables de Entorno Críticas
En `.env`, configurar:
- `POSTGRES_PASSWORD` - Contraseña segura
- `REDIS_PASSWORD` - Contraseña segura
- `LDAP_ADMIN_PASSWORD` - Contraseña segura
- `AUTHENTIK_SECRET_KEY` - Mínimo 50 caracteres
- `AUTHENTIK_OUTPOST_TOKEN` - Generar desde Authentik UI
- `GUACAMOLE_OIDC_CLIENT_SECRET` - Generar desde Authentik
- `TSPLUS_ENDPOINT` - IP del servidor TSPlus

### Puertos Necesarios
- 80, 443 - HTTP/HTTPS (Nginx)
- 389, 636 - LDAP/LDAPS
- 8080 - Headscale HTTP
- 9090 - Headscale Metrics
- 50443 - Headscale gRPC

## Troubleshooting

### Ver Logs
```bash
docker-compose -f docker-compose.preproduccion.yml logs -f
```

### Reiniciar un Servicio
```bash
docker-compose -f docker-compose.preproduccion.yml restart <servicio>
```

### Verificar Estado
```bash
docker-compose -f docker-compose.preproduccion.yml ps
```

### Guía Rápida Completa
```bash
./scripts/guia-rapida.sh
```

## Referencias

- **Headscale**: https://headscale.net/
- **Authentik**: https://docs.goauthentik.io/
- **Guacamole**: https://guacamole.apache.org/doc/gug/
- **OpenLDAP**: https://www.openldap.org/doc/

## Soporte

Para problemas o preguntas:
1. Revisar `README.preproduccion.md`
2. Ejecutar `./scripts/validate-preproduccion.sh`
3. Revisar logs de contenedores
4. Consultar documentación específica

---

**Versión**: 1.0.0  
**Fecha**: Octubre 29, 2025  
**Branch Base**: copilot/create-pre-produccion-branch  
**Branch Destino**: pre-produccion
