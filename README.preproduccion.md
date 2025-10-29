# Pre-Producción - Kolaboree con Headscale

Branch de pre-producción con Headscale como red perimetral para acceso seguro a servicios.

## 🌐 Arquitectura

### Componentes Principales

1. **Headscale** - Red perimetral VPN (reemplazo open-source de Tailscale)
   - Dominio: `hs.kappa4.com`
   - MagicDNS habilitado para resolución automática de nombres
   - UI de administración disponible

2. **Authentik** - Sistema de autenticación y SSO
   - Accesible vía: `https://gate.kappa4.com`
   - Integración con LDAP para validación de usuarios
   - RAC Provider para acceso remoto

3. **Guacamole** - Acceso HTML5 RDP
   - Accesible vía: `https://gate.kappa4.com/guacamole/`
   - Integrado con Authentik para SSO
   - Soporte para conexión a TSPlus endpoint

4. **OpenLDAP** - Directorio de usuarios
   - Puerto: 389 (LDAP), 636 (LDAPS)
   - Base DN: `dc=kolaboree,dc=local`

5. **Nginx** - Reverse Proxy
   - Punto de entrada principal
   - Maneja SSL/TLS
   - Enrutamiento a servicios internos

### Dominios

- **hs.kappa4.com**: Headscale UI y API
- **gate.kappa4.com**: Punto de entrada principal (Authentik + Guacamole)

### Endpoints TSPlus

- IP: `201.151.150.226` o Ubuntu bare metal
- Puerto: 3389 (RDP)
- Acceso vía RAC proxy a través de Headscale

## 🚀 Inicio Rápido

### Prerrequisitos

1. Docker y Docker Compose instalados
2. Certificados SSL para los dominios:
   - `nginx/ssl/hs.kappa4.com/fullchain.pem`
   - `nginx/ssl/hs.kappa4.com/privkey.pem`
   - `nginx/ssl/gate.kappa4.com/fullchain.pem`
   - `nginx/ssl/gate.kappa4.com/privkey.pem`

### Configuración

1. Copiar el archivo de configuración de ejemplo:
```bash
cp .env.preproduccion .env
```

2. Editar `.env` y configurar:
   - Contraseñas seguras para PostgreSQL, Redis, LDAP
   - Secret key de Authentik (mínimo 50 caracteres)
   - Token de Authentik Outpost
   - Credenciales OIDC de Guacamole
   - Endpoint de TSPlus

3. Asegurar que los certificados SSL estén en su lugar

### Iniciar Servicios

```bash
# Usar el docker-compose de pre-producción
docker-compose -f docker-compose.preproduccion.yml up -d
```

### Verificar Estado

```bash
# Ver logs
docker-compose -f docker-compose.preproduccion.yml logs -f

# Verificar servicios
docker-compose -f docker-compose.preproduccion.yml ps
```

## 🔧 Configuración de Headscale

### Crear un Usuario/Namespace

```bash
docker exec headscale-server headscale namespaces create kolaboree
```

### Generar Pre-Auth Key

```bash
docker exec headscale-server headscale --namespace kolaboree preauthkeys create --reusable --expiration 90d
```

### Listar Nodos Conectados

```bash
docker exec headscale-server headscale nodes list
```

### Acceder a la UI

1. Navegar a: `https://hs.kappa4.com/admin/`
2. Configurar la API key desde la línea de comandos
3. Administrar nodos, rutas y políticas

## 🔐 Configuración de Authentik

### Acceso Inicial

1. Navegar a: `https://gate.kappa4.com`
2. Usuario por defecto: `akadmin`
3. La contraseña se genera automáticamente. Revisar logs:
```bash
docker-compose -f docker-compose.preproduccion.yml logs authentik-server | grep "Bootstrap"
```

### Configurar LDAP Source

1. Admin > Directory > Federation > LDAP Sources
2. Crear nueva fuente LDAP:
   - Server URI: `ldap://openldap:389`
   - Bind DN: `cn=admin,dc=kolaboree,dc=local`
   - Bind Password: (de .env)
   - Base DN: `dc=kolaboree,dc=local`

### Configurar RAC Provider

1. Admin > Applications > Providers
2. Crear RAC Provider para TSPlus
3. Configurar endpoint: `201.151.150.226:3389`

### Configurar Outpost

1. Admin > Outposts
2. Crear nuevo outpost
3. Copiar el token generado a `.env` como `AUTHENTIK_OUTPOST_TOKEN`
4. Reiniciar el servicio outpost:
```bash
docker-compose -f docker-compose.preproduccion.yml restart authentik-outpost
```

## 🖥️ Configuración de Guacamole

### Acceso

1. Navegar a: `https://gate.kappa4.com/guacamole/`
2. Se redirigirá a Authentik para login
3. Después del SSO, se crea automáticamente el usuario

### Crear Conexión RDP a TSPlus

1. Settings > Connections > New Connection
2. Configurar:
   - Protocol: RDP
   - Hostname: `201.151.150.226` (o usar MagicDNS: `tsplus.hs.kappa4.com`)
   - Port: 3389
   - Username: (usuario de TSPlus)
   - Password: (contraseña de TSPlus)

## 📋 Scripts Finales Incluidos

### Validación del Sistema

```bash
# Validación completa del stack
./scripts/master-validation.sh

# Verificación rápida
./quick-check.sh

# Verificar SSO completo
./verify-sso-complete.sh
```

### Configuración de Branding

```bash
# Subir logos y personalización
./branding-final-guide.sh

# Actualizar logo oficial
./update-official-logo.sh
```

### Verificación de LDAP

```bash
# Verificar sincronización LDAP con Authentik
./verify-ldap-sync.py

# Verificar flujo de login LDAP
./test-ldap-authentik-flow.py
```

### Estado del Sistema

```bash
# Ver estado final
./final-status-ready.sh

# Verificar sistema listo
./verify-system-ready.sh
```

## 🔍 Troubleshooting

### Ver Logs de Headscale

```bash
docker-compose -f docker-compose.preproduccion.yml logs -f headscale
```

### Ver Logs de Authentik

```bash
docker-compose -f docker-compose.preproduccion.yml logs -f authentik-server authentik-worker
```

### Verificar Conectividad Headscale

```bash
# Desde un nodo conectado
headscale ping tsplus.hs.kappa4.com
```

### Resetear Headscale

```bash
docker-compose -f docker-compose.preproduccion.yml down
docker volume rm kolaboree-preproduccion_headscale_data
docker-compose -f docker-compose.preproduccion.yml up -d headscale
```

## 🌍 MagicDNS

Headscale proporciona MagicDNS automático para todos los servicios:

- `authentik.hs.kappa4.com` → 100.64.0.10
- `ldap.hs.kappa4.com` → 100.64.0.11
- `guacamole.hs.kappa4.com` → 100.64.0.12
- `postgres.hs.kappa4.com` → 100.64.0.13
- `tsplus.hs.kappa4.com` → 201.151.150.226

Los contenedores pueden usar estos nombres para comunicarse entre sí.

## 🔒 Seguridad

### ACL de Headscale

El archivo `headscale/acl.yaml` define las políticas de acceso:

- Servicios pueden comunicarse entre sí
- Guacamole tiene acceso a TSPlus
- Authentik tiene acceso a LDAP
- Administradores tienen acceso completo

### Certificados SSL

Asegurar que los certificados sean válidos y de una CA confiable. Para desarrollo, se pueden generar certificados autofirmados:

```bash
# Para hs.kappa4.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/hs.kappa4.com/privkey.pem \
  -out nginx/ssl/hs.kappa4.com/fullchain.pem \
  -subj "/CN=hs.kappa4.com"

# Para gate.kappa4.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/gate.kappa4.com/privkey.pem \
  -out nginx/ssl/gate.kappa4.com/fullchain.pem \
  -subj "/CN=gate.kappa4.com"
```

## 📚 Documentación Adicional

- `CONFIGURACION_FINAL_NEOGENESYS.md` - Configuración final del sistema
- `GUIA_CONFIGURACION_LDAP_AUTHENTIK.md` - Guía de integración LDAP
- `RAC_NEOGENESYS_GUIDE.md` - Guía de configuración RAC
- `BRANDING_README.md` - Personalización de marca

## 🎯 Diferencias con la Rama Principal

### Componentes Removidos

- Backend FastAPI (no necesario en producción)
- Frontend React (no necesario en producción)
- Tailscale (reemplazado por Headscale)

### Componentes Agregados

- Headscale server (red perimetral)
- Headscale UI (administración)
- Configuración MagicDNS
- ACL policies para control de acceso

### Arquitectura Simplificada

Esta rama contiene **solo** los componentes de producción necesarios:
- Autenticación (Authentik + LDAP)
- Acceso remoto (Guacamole + RAC)
- Red perimetral (Headscale)
- Reverse proxy (Nginx)
- Base de datos y cache (PostgreSQL + Redis)

## 📞 Soporte

Para problemas o preguntas:
1. Revisar los logs de los contenedores
2. Verificar la configuración en `.env`
3. Consultar la documentación de cada componente
4. Revisar el archivo `headscale/acl.yaml` para políticas de red
