#!/bin/bash

# Script de Validación para Pre-Producción
# Verifica que todos los componentes estén funcionando correctamente

set -e

echo "=================================================="
echo "  Pre-Producción - Script de Validación"
echo "=================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to check service
check_service() {
    local service_name=$1
    local container_name=$2
    
    echo -n "Verificando $service_name... "
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        echo -e "${GREEN}✅ Running${NC}"
        return 0
    else
        echo -e "${RED}❌ Not Running${NC}"
        ((ERRORS++))
        return 1
    fi
}

# Function to check port
check_port() {
    local port=$1
    local service_name=$2
    
    echo -n "Verificando puerto $port ($service_name)... "
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✅ Listening${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Not listening${NC}"
        ((WARNINGS++))
        return 1
    fi
}

# Function to check URL
check_url() {
    local url=$1
    local service_name=$2
    
    echo -n "Verificando $service_name ($url)... "
    if curl -k -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|301\|302\|401\|403"; then
        echo -e "${GREEN}✅ Accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ Not accessible${NC}"
        ((ERRORS++))
        return 1
    fi
}

echo -e "${BLUE}=== Verificando Contenedores ===${NC}"
echo ""

check_service "Headscale Server" "headscale-server"
check_service "Headscale UI" "headscale-ui"
check_service "PostgreSQL" "kolaboree-postgres"
check_service "Redis" "kolaboree-redis"
check_service "OpenLDAP" "kolaboree-ldap"
check_service "Authentik Server" "kolaboree-authentik-server"
check_service "Authentik Worker" "kolaboree-authentik-worker"
check_service "Guacamole Daemon" "kolaboree-guacd"
check_service "Guacamole Web" "kolaboree-guacamole"
check_service "Nginx" "kolaboree-nginx"
check_service "Authentik Outpost" "kolaboree-authentik-outpost"

echo ""
echo -e "${BLUE}=== Verificando Puertos ===${NC}"
echo ""

check_port 80 "HTTP"
check_port 443 "HTTPS"
check_port 389 "LDAP"
check_port 636 "LDAPS"
check_port 8080 "Headscale"

echo ""
echo -e "${BLUE}=== Verificando Endpoints HTTP ===${NC}"
echo ""

check_url "http://localhost:8080/health" "Headscale Health"
check_url "http://localhost/health" "Nginx Health"

echo ""
echo -e "${BLUE}=== Verificando Conectividad de Base de Datos ===${NC}"
echo ""

echo -n "Verificando PostgreSQL... "
if docker exec kolaboree-postgres pg_isready -U kolaboree &>/dev/null; then
    echo -e "${GREEN}✅ Ready${NC}"
else
    echo -e "${RED}❌ Not Ready${NC}"
    ((ERRORS++))
fi

echo -n "Verificando Redis... "
if docker exec kolaboree-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}✅ Ready${NC}"
else
    echo -e "${RED}❌ Not Ready${NC}"
    ((ERRORS++))
fi

echo ""
echo -e "${BLUE}=== Verificando Volúmenes ===${NC}"
echo ""

VOLUMES=(
    "kolaboree-preproduccion_headscale_config"
    "kolaboree-preproduccion_headscale_data"
    "kolaboree-preproduccion_postgres_data"
    "kolaboree-preproduccion_redis_data"
    "kolaboree-preproduccion_ldap_data"
    "kolaboree-preproduccion_authentik_media"
)

for volume in "${VOLUMES[@]}"; do
    echo -n "Verificando volumen $volume... "
    if docker volume inspect "$volume" &>/dev/null; then
        echo -e "${GREEN}✅ Exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Not found${NC}"
        ((WARNINGS++))
    fi
done

echo ""
echo -e "${BLUE}=== Verificando Configuración ===${NC}"
echo ""

echo -n "Verificando .env... "
if [ -f .env ]; then
    echo -e "${GREEN}✅ Exists${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    ((ERRORS++))
fi

echo -n "Verificando headscale/config.yaml... "
if [ -f headscale/config.yaml ]; then
    echo -e "${GREEN}✅ Exists${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    ((ERRORS++))
fi

echo -n "Verificando headscale/acl.yaml... "
if [ -f headscale/acl.yaml ]; then
    echo -e "${GREEN}✅ Exists${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    ((ERRORS++))
fi

echo -n "Verificando nginx/conf.d/preproduccion.conf... "
if [ -f nginx/conf.d/preproduccion.conf ]; then
    echo -e "${GREEN}✅ Exists${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    ((ERRORS++))
fi

echo ""
echo -e "${BLUE}=== Verificando Certificados SSL ===${NC}"
echo ""

echo -n "Verificando SSL para hs.kappa4.com... "
if [ -f nginx/ssl/hs.kappa4.com/fullchain.pem ] && [ -f nginx/ssl/hs.kappa4.com/privkey.pem ]; then
    echo -e "${GREEN}✅ Exists${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    ((ERRORS++))
fi

echo -n "Verificando SSL para gate.kappa4.com... "
if [ -f nginx/ssl/gate.kappa4.com/fullchain.pem ] && [ -f nginx/ssl/gate.kappa4.com/privkey.pem ]; then
    echo -e "${GREEN}✅ Exists${NC}"
else
    echo -e "${RED}❌ Missing${NC}"
    ((ERRORS++))
fi

echo ""
echo "=================================================="
echo -e "${BLUE}  Resumen de Validación${NC}"
echo "=================================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los checks pasaron exitosamente${NC}"
    echo ""
    echo "El sistema está listo para usar:"
    echo "  - Headscale UI:  https://hs.kappa4.com/admin/"
    echo "  - Authentik:     https://gate.kappa4.com"
    echo "  - Guacamole:     https://gate.kappa4.com/guacamole/"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Validación completada con $WARNINGS advertencias${NC}"
    echo ""
    echo "El sistema debería funcionar, pero revisa las advertencias arriba."
    exit 0
else
    echo -e "${RED}❌ Validación falló con $ERRORS errores y $WARNINGS advertencias${NC}"
    echo ""
    echo "Por favor, corrige los errores antes de continuar."
    echo ""
    echo "Para ver logs:"
    echo "  docker-compose -f docker-compose.preproduccion.yml logs -f"
    exit 1
fi
