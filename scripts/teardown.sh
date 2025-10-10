#!/bin/bash

# Script de Teardown - Plataforma de Acceso Remoto Seguro
# Este script elimina el stack desplegado de forma segura

set -e

echo "=========================================="
echo "Iniciando eliminación de la plataforma..."
echo "=========================================="

# Verificar que existe el archivo .env
if [ ! -f .env ]; then
    echo "❌ ERROR: No se encontró el archivo .env"
    echo "No se puede determinar el nombre del stack"
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

# Verificar si Docker Swarm está activo
if ! docker info | grep -q "Swarm: active"; then
    echo "⚠️  ADVERTENCIA: Docker Swarm no está activo"
    echo "No hay stack para eliminar"
    exit 0
fi

# Eliminar el stack
echo "🗑️  Eliminando stack: $STACK_NAME..."
docker stack rm "$STACK_NAME"

echo ""
echo "⏳ Esperando a que los servicios se detengan..."
sleep 10

echo ""
echo "=========================================="
echo "✅ Stack eliminado exitosamente!"
echo "=========================================="
echo ""
echo "NOTA: Los volúmenes de datos persisten por seguridad."
echo ""
echo "Para eliminar TODOS los volúmenes (¡ADVERTENCIA: Se perderán todos los datos!):"
echo "  docker volume rm ${STACK_NAME}_postgres_data"
echo "  docker volume rm ${STACK_NAME}_redis_data"
echo "  docker volume rm ${STACK_NAME}_authentik_media"
echo "  docker volume rm ${STACK_NAME}_authentik_templates"
echo "  docker volume rm ${STACK_NAME}_authentik_certs"
echo "  docker volume rm ${STACK_NAME}_ziti_data"
echo "  docker volume rm ${STACK_NAME}_portal_data"
echo ""
echo "Para eliminar la red overlay:"
echo "  docker network rm ${STACK_NAME}_stack-net"
echo ""
echo "Para eliminar Docker Swarm completamente:"
echo "  docker swarm leave --force"
echo ""

# Comandos comentados por seguridad - descomentar solo si desea limpieza total
# echo "¿Desea eliminar también los volúmenes de datos? (s/N)"
# read -r response
# if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
#     echo "Eliminando volúmenes..."
#     docker volume rm ${STACK_NAME}_postgres_data || true
#     docker volume rm ${STACK_NAME}_redis_data || true
#     docker volume rm ${STACK_NAME}_authentik_media || true
#     docker volume rm ${STACK_NAME}_authentik_templates || true
#     docker volume rm ${STACK_NAME}_authentik_certs || true
#     docker volume rm ${STACK_NAME}_ziti_data || true
#     docker volume rm ${STACK_NAME}_portal_data || true
#     echo "✓ Volúmenes eliminados"
# fi
