#!/bin/bash

# Script de Inicio para Pre-Producción
# Configura y arranca el stack de Headscale + Authentik + Guacamole

set -e

echo "=================================================="
echo "  Pre-Producción Stack - Setup Script"
echo "=================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado${NC}"
    echo "Copiando .env.preproduccion a .env..."
    cp .env.preproduccion .env
    echo -e "${GREEN}✅ Archivo .env creado${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE: Edita .env y configura las contraseñas y tokens antes de continuar${NC}"
    echo "   - POSTGRES_PASSWORD"
    echo "   - REDIS_PASSWORD"
    echo "   - LDAP_ADMIN_PASSWORD"
    echo "   - AUTHENTIK_SECRET_KEY (mínimo 50 caracteres)"
    echo "   - AUTHENTIK_OUTPOST_TOKEN"
    echo "   - GUACAMOLE_OIDC_CLIENT_SECRET"
    echo ""
    read -p "Presiona Enter cuando hayas configurado .env..."
fi

echo ""
echo "Verificando directorios necesarios..."

# Create SSL directories if they don't exist
mkdir -p nginx/ssl/hs.kappa4.com
mkdir -p nginx/ssl/gate.kappa4.com
mkdir -p guacamole/initdb.d
mkdir -p ldap
mkdir -p headscale

echo -e "${GREEN}✅ Directorios creados${NC}"
echo ""

# Check if SSL certificates exist
echo "Verificando certificados SSL..."
if [ ! -f nginx/ssl/hs.kappa4.com/fullchain.pem ] || [ ! -f nginx/ssl/hs.kappa4.com/privkey.pem ]; then
    echo -e "${YELLOW}⚠️  Certificados SSL no encontrados para hs.kappa4.com${NC}"
    read -p "¿Generar certificados autofirmados para desarrollo? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo "Generando certificados autofirmados para hs.kappa4.com..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/hs.kappa4.com/privkey.pem \
            -out nginx/ssl/hs.kappa4.com/fullchain.pem \
            -subj "/CN=hs.kappa4.com" 2>/dev/null
        echo -e "${GREEN}✅ Certificados generados para hs.kappa4.com${NC}"
    else
        echo -e "${RED}❌ Por favor, coloca los certificados en nginx/ssl/hs.kappa4.com/${NC}"
        exit 1
    fi
fi

if [ ! -f nginx/ssl/gate.kappa4.com/fullchain.pem ] || [ ! -f nginx/ssl/gate.kappa4.com/privkey.pem ]; then
    echo -e "${YELLOW}⚠️  Certificados SSL no encontrados para gate.kappa4.com${NC}"
    read -p "¿Generar certificados autofirmados para desarrollo? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo "Generando certificados autofirmados para gate.kappa4.com..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/gate.kappa4.com/privkey.pem \
            -out nginx/ssl/gate.kappa4.com/fullchain.pem \
            -subj "/CN=gate.kappa4.com" 2>/dev/null
        echo -e "${GREEN}✅ Certificados generados para gate.kappa4.com${NC}"
    else
        echo -e "${RED}❌ Por favor, coloca los certificados en nginx/ssl/gate.kappa4.com/${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Certificados SSL verificados${NC}"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose no está instalado${NC}"
    exit 1
fi

echo "Iniciando servicios con docker-compose..."
echo ""

# Start services
docker-compose -f docker-compose.preproduccion.yml up -d

echo ""
echo -e "${GREEN}✅ Servicios iniciados${NC}"
echo ""

# Wait for services to be ready
echo "Esperando a que los servicios estén listos..."
sleep 10

# Check service status
echo ""
echo "Estado de los servicios:"
docker-compose -f docker-compose.preproduccion.yml ps

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Pre-Producción Stack iniciado correctamente${NC}"
echo "=================================================="
echo ""
echo "Acceso a los servicios:"
echo "  - Headscale UI:  https://hs.kappa4.com/admin/"
echo "  - Authentik:     https://gate.kappa4.com"
echo "  - Guacamole:     https://gate.kappa4.com/guacamole/"
echo ""
echo "Próximos pasos:"
echo "  1. Configurar namespace en Headscale:"
echo "     docker exec headscale-server headscale namespaces create kolaboree"
echo ""
echo "  2. Generar pre-auth key:"
echo "     docker exec headscale-server headscale --namespace kolaboree preauthkeys create --reusable --expiration 90d"
echo ""
echo "  3. Acceder a Authentik y completar configuración inicial"
echo ""
echo "  4. Configurar LDAP source en Authentik"
echo ""
echo "  5. Configurar RAC provider y outpost"
echo ""
echo "Para ver logs:"
echo "  docker-compose -f docker-compose.preproduccion.yml logs -f"
echo ""
echo "Para detener:"
echo "  docker-compose -f docker-compose.preproduccion.yml down"
echo ""
