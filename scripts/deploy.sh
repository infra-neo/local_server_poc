#!/bin/bash

# Script de Despliegue - Plataforma de Acceso Remoto Seguro
# Este script inicializa Docker Swarm y despliega el stack completo

set -e

echo "=========================================="
echo "Iniciando despliegue de la plataforma..."
echo "=========================================="

# Verificar que existe el archivo .env
if [ ! -f .env ]; then
    echo "❌ ERROR: No se encontró el archivo .env"
    echo "Por favor, copia .env.example a .env y configura las variables necesarias:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Cargar variables de entorno desde .env
echo "✓ Cargando variables de entorno desde .env..."
export $(grep -v '^#' .env | xargs)

# Verificar que STACK_NAME está definido
if [ -z "$STACK_NAME" ]; then
    echo "❌ ERROR: STACK_NAME no está definido en el archivo .env"
    exit 1
fi

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ ERROR: Docker no está instalado"
    echo "Por favor, instala Docker antes de continuar"
    exit 1
fi

# Verificar si Docker está corriendo
if ! docker info &> /dev/null; then
    echo "❌ ERROR: Docker no está corriendo"
    echo "Por favor, inicia el servicio de Docker"
    exit 1
fi

# Inicializar Docker Swarm si no está activo
if ! docker info | grep -q "Swarm: active"; then
    echo "⚙️  Inicializando Docker Swarm..."
    docker swarm init
    echo "✓ Docker Swarm inicializado"
else
    echo "✓ Docker Swarm ya está activo"
fi

# Desplegar el stack
echo "🚀 Desplegando stack: $STACK_NAME..."
docker stack deploy -c deployment/docker-compose.yml "$STACK_NAME"

echo ""
echo "=========================================="
echo "✅ Despliegue completado exitosamente!"
echo "=========================================="
echo ""
echo "Los siguientes servicios están disponibles:"
echo ""
echo "  🌐 Portal Web:          http://localhost:${PORTAL_WEB_PORT:-80}"
echo "  🔌 API Gateway:         http://localhost:${API_GATEWAY_PORT:-3000}"
echo "  🖥️  Apache Guacamole:    http://localhost:${GUACAMOLE_PORT:-8080}/guacamole"
echo "  🔐 Authentik HTTP:      http://localhost:${AUTHENTIK_PORT_HTTP:-9000}"
echo "  🔒 Authentik HTTPS:     https://localhost:${AUTHENTIK_PORT_HTTPS:-9443}"
echo "  🌐 Ziti Edge API:       https://localhost:${ZITI_PORT_API:-1280}"
echo "  🎛️  Ziti Controller:     https://localhost:${ZITI_PORT_CTRL:-6262}"
echo ""
echo "Para verificar el estado de los servicios:"
echo "  docker stack services $STACK_NAME"
echo ""
echo "Para ver los logs de un servicio específico:"
echo "  docker service logs ${STACK_NAME}_<nombre-servicio>"
echo ""
