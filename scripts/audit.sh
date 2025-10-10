#!/bin/bash

# Script de Auditoría - Plataforma de Acceso Remoto Seguro
# Verifica los prerrequisitos y disponibilidad de puertos antes del despliegue

set -e

echo "=========================================="
echo "Auditoría del Sistema - Pre-Despliegue"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de errores
ERRORS=0
WARNINGS=0

# Función para verificar comandos
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 está instalado"
        return 0
    else
        echo -e "${RED}✗${NC} $1 NO está instalado"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Función para verificar disponibilidad de puerto
check_port() {
    local port=$1
    local service=$2
    
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${RED}✗${NC} Puerto $port ($service) está en uso"
            ERRORS=$((ERRORS + 1))
            return 1
        else
            echo -e "${GREEN}✓${NC} Puerto $port ($service) está disponible"
            return 0
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$port "; then
            echo -e "${RED}✗${NC} Puerto $port ($service) está en uso"
            ERRORS=$((ERRORS + 1))
            return 1
        else
            echo -e "${GREEN}✓${NC} Puerto $port ($service) está disponible"
            return 0
        fi
    else
        echo -e "${YELLOW}⚠${NC} No se puede verificar el puerto $port ($service) - netstat/ss no disponible"
        WARNINGS=$((WARNINGS + 1))
        return 0
    fi
}

# Verificar sistema operativo
echo "1. Sistema Operativo:"
echo "   $(uname -s) $(uname -r)"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "   $NAME $VERSION"
fi
echo ""

# Verificar prerrequisitos de software
echo "2. Verificando prerrequisitos de software..."
check_command docker
check_command docker-compose || echo -e "${YELLOW}⚠${NC} docker-compose no es obligatorio (se puede usar 'docker compose')"

# Verificar que Docker está corriendo
if command -v docker &> /dev/null; then
    if docker info &> /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Docker daemon está corriendo"
        
        # Verificar versión de Docker
        DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
        echo "   Versión: $DOCKER_VERSION"
    else
        echo -e "${RED}✗${NC} Docker daemon NO está corriendo"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo ""

# Verificar archivo .env
echo "3. Verificando configuración..."
if [ -f .env ]; then
    echo -e "${GREEN}✓${NC} Archivo .env existe"
    
    # Cargar variables
    export $(grep -v '^#' .env | xargs 2>/dev/null || true)
    
    # Verificar variables críticas
    if [ -z "$STACK_NAME" ]; then
        echo -e "${RED}✗${NC} STACK_NAME no está definido en .env"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✓${NC} STACK_NAME: $STACK_NAME"
    fi
    
    if [ -z "$POSTGRES_PASSWORD" ] || [ "$POSTGRES_PASSWORD" = "CHANGEME_32_CHAR_RANDOM_PASSWORD" ]; then
        echo -e "${YELLOW}⚠${NC} POSTGRES_PASSWORD usa valor por defecto - CÁMBIALO en producción"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if [ -z "$AUTHENTIK_SECRET_KEY" ] || [ "$AUTHENTIK_SECRET_KEY" = "CHANGEME_SUPER_SECRET_RANDOM_KEY" ]; then
        echo -e "${YELLOW}⚠${NC} AUTHENTIK_SECRET_KEY usa valor por defecto - CÁMBIALO en producción"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}✗${NC} Archivo .env NO existe"
    echo "   Copia .env.example a .env y configúralo:"
    echo "   cp .env.example .env"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Verificar disponibilidad de puertos
echo "4. Verificando disponibilidad de puertos..."

# Cargar puertos desde .env o usar valores por defecto
PORTAL_WEB_PORT=${PORTAL_WEB_PORT:-80}
API_GATEWAY_PORT=${API_GATEWAY_PORT:-3000}
GUACAMOLE_PORT=${GUACAMOLE_PORT:-8080}
AUTHENTIK_PORT_HTTP=${AUTHENTIK_PORT_HTTP:-9000}
AUTHENTIK_PORT_HTTPS=${AUTHENTIK_PORT_HTTPS:-9443}
ZITI_PORT_API=${ZITI_PORT_API:-1280}
ZITI_PORT_CTRL=${ZITI_PORT_CTRL:-6262}

check_port "$PORTAL_WEB_PORT" "Portal Web"
check_port "$API_GATEWAY_PORT" "API Gateway"
check_port "$GUACAMOLE_PORT" "Guacamole"
check_port "$AUTHENTIK_PORT_HTTP" "Authentik HTTP"
check_port "$AUTHENTIK_PORT_HTTPS" "Authentik HTTPS"
check_port "$ZITI_PORT_API" "Ziti Edge API"
check_port "$ZITI_PORT_CTRL" "Ziti Controller"
echo ""

# Verificar recursos del sistema
echo "5. Verificando recursos del sistema..."

# Memoria disponible
if command -v free &> /dev/null; then
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    echo "   Memoria total: ${TOTAL_MEM}GB"
    if [ "$TOTAL_MEM" -lt 4 ]; then
        echo -e "${YELLOW}⚠${NC} Se recomienda al menos 4GB de RAM"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Espacio en disco
if command -v df &> /dev/null; then
    AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    echo "   Espacio disponible en disco: ${AVAILABLE_SPACE}GB"
    if [ "$AVAILABLE_SPACE" -lt 20 ]; then
        echo -e "${YELLOW}⚠${NC} Se recomienda al menos 20GB de espacio libre"
        WARNINGS=$((WARNINGS + 1))
    fi
fi
echo ""

# Resumen final
echo "=========================================="
echo "Resumen de Auditoría"
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Sistema listo para despliegue${NC}"
    echo ""
    echo "Puedes proceder con el despliegue ejecutando:"
    echo "  bash scripts/deploy.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Sistema listo con advertencias: $WARNINGS${NC}"
    echo ""
    echo "Puedes proceder con el despliegue ejecutando:"
    echo "  bash scripts/deploy.sh"
    echo ""
    echo "Sin embargo, revisa las advertencias anteriores."
    exit 0
else
    echo -e "${RED}❌ Se encontraron $ERRORS errores${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Y $WARNINGS advertencias${NC}"
    fi
    echo ""
    echo "Por favor, corrige los errores antes de continuar."
    exit 1
fi
