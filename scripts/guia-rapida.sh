#!/bin/bash

# Guía Rápida de Uso - Pre-Producción
# Este script muestra los comandos principales para trabajar con el stack

set -e

cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   Pre-Producción - Kolaboree con Headscale                   ║
║   Guía Rápida de Comandos                                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

📋 PREREQUISITOS
════════════════════════════════════════════════════════════════

1. Docker y Docker Compose instalados
2. Certificados SSL para los dominios
3. Archivo .env configurado

🚀 INICIO RÁPIDO
════════════════════════════════════════════════════════════════

# 1. Configurar variables de entorno
cp .env.preproduccion .env
nano .env  # Editar y configurar contraseñas

# 2. Iniciar servicios
./scripts/start-preproduccion.sh

# 3. Validar instalación
./scripts/validate-preproduccion.sh

🔧 COMANDOS DOCKER-COMPOSE
════════════════════════════════════════════════════════════════

# Iniciar todos los servicios
docker-compose -f docker-compose.preproduccion.yml up -d

# Ver logs
docker-compose -f docker-compose.preproduccion.yml logs -f

# Ver logs de un servicio específico
docker-compose -f docker-compose.preproduccion.yml logs -f headscale
docker-compose -f docker-compose.preproduccion.yml logs -f authentik-server
docker-compose -f docker-compose.preproduccion.yml logs -f guacamole

# Ver estado de servicios
docker-compose -f docker-compose.preproduccion.yml ps

# Detener servicios
docker-compose -f docker-compose.preproduccion.yml down

# Detener y eliminar volúmenes (⚠️ CUIDADO: borra todos los datos)
docker-compose -f docker-compose.preproduccion.yml down -v

# Reiniciar un servicio específico
docker-compose -f docker-compose.preproduccion.yml restart headscale

🌐 HEADSCALE - Comandos
════════════════════════════════════════════════════════════════

# Crear namespace
docker exec headscale-server headscale namespaces create kolaboree

# Listar namespaces
docker exec headscale-server headscale namespaces list

# Crear pre-auth key (reutilizable, 90 días)
docker exec headscale-server headscale --namespace kolaboree preauthkeys create --reusable --expiration 90d

# Listar nodos conectados
docker exec headscale-server headscale nodes list

# Ver detalles de un nodo
docker exec headscale-server headscale nodes get <node-id>

# Eliminar un nodo
docker exec headscale-server headscale nodes delete <node-id>

# Ver rutas
docker exec headscale-server headscale routes list

# Habilitar una ruta
docker exec headscale-server headscale routes enable --identifier <route-id>

# Ver usuarios
docker exec headscale-server headscale users list

# Crear API key
docker exec headscale-server headscale apikeys create --expiration 90d

🔐 AUTHENTIK - Configuración
════════════════════════════════════════════════════════════════

# Ver logs de Authentik
docker-compose -f docker-compose.preproduccion.yml logs -f authentik-server

# Obtener contraseña inicial de akadmin (si fue generada)
docker-compose -f docker-compose.preproduccion.yml logs authentik-server | grep "Bootstrap"

# Ejecutar comando en Authentik
docker exec -it kolaboree-authentik-server ak <comando>

# Crear superusuario manualmente
docker exec -it kolaboree-authentik-server ak create_admin_group

# Configuración automática
./scripts/auto-configure-authentik.sh

📁 LDAP - Gestión
════════════════════════════════════════════════════════════════

# Poblar LDAP con datos iniciales
./scripts/auto-populate-ldap.sh

# Búsqueda en LDAP
docker exec kolaboree-ldap ldapsearch -x -H ldap://localhost \
  -D "cn=admin,dc=kolaboree,dc=local" \
  -w "TU_PASSWORD" \
  -b "dc=kolaboree,dc=local"

# Agregar usuario LDAP manualmente
docker exec -i kolaboree-ldap ldapadd -x -H ldap://localhost \
  -D "cn=admin,dc=kolaboree,dc=local" \
  -w "TU_PASSWORD" < mi-usuario.ldif

# Verificar sincronización LDAP-Authentik
./verify-ldap-sync.py

🖥️ GUACAMOLE - Gestión
════════════════════════════════════════════════════════════════

# Ver logs de Guacamole
docker-compose -f docker-compose.preproduccion.yml logs -f guacamole

# Acceder a base de datos de Guacamole
docker exec -it kolaboree-postgres psql -U kolaboree -d kolaboree

# Queries útiles en PostgreSQL
SELECT * FROM guacamole_user;
SELECT * FROM guacamole_connection;
SELECT * FROM guacamole_connection_parameter;

# Verificar integración LDAP-Guacamole
./verify-guacamole-ldap.py

🔒 SSL/TLS - Certificados
════════════════════════════════════════════════════════════════

# Generar certificados autofirmados para desarrollo

# Para hs.kappa4.com
mkdir -p nginx/ssl/hs.kappa4.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/hs.kappa4.com/privkey.pem \
  -out nginx/ssl/hs.kappa4.com/fullchain.pem \
  -subj "/CN=hs.kappa4.com"

# Para gate.kappa4.com
mkdir -p nginx/ssl/gate.kappa4.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/gate.kappa4.com/privkey.pem \
  -out nginx/ssl/gate.kappa4.com/fullchain.pem \
  -subj "/CN=gate.kappa4.com"

# Verificar certificado
openssl x509 -in nginx/ssl/hs.kappa4.com/fullchain.pem -text -noout

🧪 VALIDACIÓN Y TESTING
════════════════════════════════════════════════════════════════

# Validación rápida
./quick-check.sh

# Validación completa del stack
./scripts/master-validation.sh

# Validación específica de pre-producción
./scripts/validate-preproduccion.sh

# Verificar SSO completo
./verify-sso-complete.sh

# Verificar sistema listo
./verify-system-ready.sh

# Test de login real
./test-real-login.py

# Test de flujo OIDC
./verify-oidc-flow.py

# Estado final del sistema
./final-status-ready.sh

🎨 BRANDING - Personalización
════════════════════════════════════════════════════════════════

# Configurar branding
./branding-final-guide.sh

# Subir logos
./upload-branding.sh

# Actualizar logo oficial
./update-official-logo.sh

🗄️ BASE DE DATOS - PostgreSQL
════════════════════════════════════════════════════════════════

# Conectar a PostgreSQL
docker exec -it kolaboree-postgres psql -U kolaboree -d kolaboree

# Backup de base de datos
docker exec kolaboree-postgres pg_dump -U kolaboree kolaboree > backup.sql

# Restore de base de datos
cat backup.sql | docker exec -i kolaboree-postgres psql -U kolaboree -d kolaboree

# Ver tablas
docker exec kolaboree-postgres psql -U kolaboree -d kolaboree -c "\dt"

🔍 TROUBLESHOOTING
════════════════════════════════════════════════════════════════

# Ver logs de todos los servicios
docker-compose -f docker-compose.preproduccion.yml logs --tail=100

# Reiniciar un servicio problemático
docker-compose -f docker-compose.preproduccion.yml restart <servicio>

# Ver uso de recursos
docker stats

# Limpiar contenedores detenidos y volúmenes sin usar
docker system prune -a
docker volume prune

# Reconstruir un servicio
docker-compose -f docker-compose.preproduccion.yml build --no-cache <servicio>
docker-compose -f docker-compose.preproduccion.yml up -d <servicio>

# Verificar conectividad de red
docker exec kolaboree-guacamole ping -c 3 tsplus.hs.kappa4.com
docker exec kolaboree-guacamole nc -zv openldap 389

📊 MONITOREO
════════════════════════════════════════════════════════════════

# Ver métricas de Headscale (Prometheus format)
curl http://localhost:9090/metrics

# Health checks
curl http://localhost/health
curl http://localhost:8080/health

# Ver estado de contenedores
docker-compose -f docker-compose.preproduccion.yml ps

🌍 ACCESO WEB
════════════════════════════════════════════════════════════════

Headscale UI:     https://hs.kappa4.com/admin/
Authentik:        https://gate.kappa4.com
Guacamole:        https://gate.kappa4.com/guacamole/

📚 DOCUMENTACIÓN
════════════════════════════════════════════════════════════════

README.preproduccion.md          - Guía completa de pre-producción
TSPLUS_CONFIGURATION.md          - Configuración de TSPlus
SCRIPTS_FILTRADOS.md             - Scripts incluidos y excluidos
CONFIGURACION_FINAL_NEOGENESYS.md - Configuración final del sistema
GUIA_CONFIGURACION_LDAP_AUTHENTIK.md - Guía LDAP + Authentik
RAC_NEOGENESYS_GUIDE.md          - Guía de RAC

════════════════════════════════════════════════════════════════

Para más información, consulta la documentación en:
  - README.preproduccion.md
  - https://headscale.net/
  - https://docs.goauthentik.io/
  - https://guacamole.apache.org/doc/gug/

════════════════════════════════════════════════════════════════
EOF
