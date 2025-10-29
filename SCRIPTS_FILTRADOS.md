# Pre-Producción - Scripts y Archivos Filtrados

## Scripts Mantenidos (Final y Validación)

Esta rama mantiene solo los scripts finales y de validación necesarios para producción.

### Scripts de Validación y Configuración (scripts/)

- `master-validation.sh` - Validación maestra del sistema completo
- `validate-features.sh` - Validación de características
- `validate.sh` - Script de validación general
- `start.sh` - Iniciar servicios
- `stop.sh` - Detener servicios
- `logs.sh` - Ver logs de servicios
- `audit.sh` - Auditoría del sistema
- `auto-configure-authentik.sh` - Configuración automática de Authentik
- `auto-populate-ldap.sh` - Poblar LDAP con datos iniciales
- `start-preproduccion.sh` - **NUEVO** - Iniciar stack de pre-producción
- `validate-preproduccion.sh` - **NUEVO** - Validar stack de pre-producción

### Scripts de Nivel Raíz

#### Inicialización y Bootstrap
- `bootstrap.sh` - Script de bootstrap inicial del sistema

#### Branding y Personalización
- `branding-final-guide.sh` - Guía final de configuración de branding
- `upload-branding.sh` - Subir archivos de branding
- `update-official-logo.sh` - Actualizar logo oficial

#### Verificación y Validación
- `verify-sso-complete.sh` - Verificar SSO completo
- `verify-system-ready.sh` - Verificar que el sistema está listo
- `final-status-ready.sh` - Estado final del sistema
- `quick-check.sh` - Verificación rápida del sistema

### Scripts Python de Validación

- `verify-ldap-sync.py` - Verificar sincronización LDAP
- `test-ldap-authentik-flow.py` - Probar flujo LDAP con Authentik
- `validate-authentik-login.py` - Validar login de Authentik
- `verify-oidc-config.py` - Verificar configuración OIDC
- `test-real-login.py` - Probar login real
- `test-sso-complete.py` - Probar SSO completo
- `verify-oidc-flow.py` - Verificar flujo OIDC
- `verify-guacamole-ldap.py` - Verificar integración Guacamole-LDAP
- `final-status.py` - Estado final en Python

## Archivos de Configuración Mantenidos

### Docker Compose
- `docker-compose.preproduccion.yml` - **NUEVO** - Stack de pre-producción con Headscale

### Nginx
- `nginx/nginx.conf` - Configuración principal de Nginx
- `nginx/conf.d/default.conf` - Configuración por defecto
- `nginx/conf.d/preproduccion.conf` - **NUEVO** - Configuración para pre-producción

### Headscale
- `headscale/config.yaml` - **NUEVO** - Configuración de Headscale
- `headscale/acl.yaml` - **NUEVO** - ACL de Headscale

### Authentik
- `authentik/ldap-source.yaml` - Configuración de fuente LDAP
- `authentik/rac-provider-config.yaml` - Configuración de RAC provider
- `authentik/tsplus-application.yaml` - Aplicación TSPlus
- `authentik/users-groups.yaml` - Usuarios y grupos
- `authentik/branding/` - Archivos de branding personalizados

### LDAP
- `ldap-initial-data.ldif` - Datos iniciales LDAP
- `ldap/initial-data.ldif` - **NUEVO** - Copia para docker-compose

### Guacamole
- `guacamole-initdb.sql` - SQL de inicialización
- `guacamole/initdb.d/01-schema.sql` - **NUEVO** - Schema para docker-compose

### Environment
- `.env.example` - Ejemplo de variables de entorno (original)
- `.env.preproduccion` - **NUEVO** - Ejemplo para pre-producción

## Documentación Mantenida

### Guías Principales
- `README.md` - README principal del proyecto
- `README.preproduccion.md` - **NUEVO** - README de pre-producción

### Configuración Final
- `CONFIGURACION_FINAL_NEOGENESYS.md` - Configuración final del sistema
- `CONFIGURACION_FINAL_RAC_BRANDING.md` - Configuración de RAC y branding
- `GUIA_CONFIGURACION_LDAP_AUTHENTIK.md` - Guía de LDAP con Authentik
- `LDAP_AUTHENTIK_SETUP_COMPLETE.md` - Setup completo de LDAP
- `BRANDING_README.md` - README de branding
- `TSPLUS_CONFIGURATION.md` - **NUEVO** - Configuración de TSPlus

### Guías RAC
- `RAC_NEOGENESYS_GUIDE.md` - Guía de RAC para Neogenesys
- `RAC_CONFIGURACION_EXITOSA.md` - Configuración exitosa de RAC
- `OUTPOST_RAC_CONFIGURADO.md` - Outpost RAC configurado
- `RESUMEN_EJECUTIVO_RAC.md` - Resumen ejecutivo de RAC

### Arquitectura y Features
- `ARCHITECTURE.md` - Arquitectura del sistema
- `FEATURES.md` - Características del sistema
- `PROJECT_SUMMARY.md` - Resumen del proyecto

## Archivos Excluidos (vía .gitignore)

- `backend/` - Código del backend (desarrollo)
- `frontend/` - Código del frontend (desarrollo)
- `.env` - Variables de entorno locales
- `nginx/ssl/**/*.pem` - Certificados SSL (configurados por usuario)
- `nginx/ssl/**/*.key` - Claves SSL
- `headscale/private.key` - Clave privada de Headscale (generada)
- `headscale/noise_private.key` - Clave noise de Headscale (generada)

## Scripts de Desarrollo/Debug NO Incluidos en Pre-Producción

Los siguientes scripts son para desarrollo y debugging, no se incluyen en el branch pre-producción:

### Scripts de Configuración Iterativa
- `configure-*.sh` - Scripts de configuración paso a paso
- `setup-*.sh` - Scripts de setup
- `create-*.sh` - Scripts de creación
- `fix-*.sh` - Scripts de corrección
- `implement-*.sh` - Scripts de implementación

### Scripts de Análisis y Debug
- `analyze-*.py` - Scripts de análisis
- `debug-*.py` - Scripts de debugging
- `diagnose-*.py` - Scripts de diagnóstico
- `test-api-connections.py` - Testing de APIs
- `test-cloud-connections.py` - Testing de cloud

### Scripts de Desarrollo
- Scripts en desarrollo o experimentales
- Scripts temporales o one-off
- Scripts de migración
- Scripts de backup/restore de desarrollo

## Uso Recomendado

Para iniciar el stack de pre-producción:

```bash
# 1. Iniciar servicios
./scripts/start-preproduccion.sh

# 2. Validar instalación
./scripts/validate-preproduccion.sh

# 3. Configurar Authentik automáticamente (si es necesario)
./scripts/auto-configure-authentik.sh

# 4. Poblar LDAP con datos iniciales
./scripts/auto-populate-ldap.sh

# 5. Verificar SSO completo
./verify-sso-complete.sh

# 6. Configurar branding
./branding-final-guide.sh
```

## Notas

- Esta rama está enfocada en **producción**, no en desarrollo
- Los scripts mantenidos son solo los necesarios para:
  - Iniciar y detener servicios
  - Validar configuración
  - Verificar funcionamiento
  - Configurar componentes finales
- Los scripts de desarrollo/debug/iteración están excluidos
- Backend y Frontend están excluidos (no necesarios en producción)
