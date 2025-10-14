#!/bin/bash

# Kolaboree NG - Quick Start Script
# This script helps you get started quickly with the platform

set -e

echo "=========================================="
echo "Kolaboree NG - Quick Start"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠${NC} No .env file found. Creating from .env.example..."
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env file"
    echo ""
    echo -e "${YELLOW}⚠ IMPORTANT:${NC} Please edit .env and change all passwords!"
    echo "  nano .env"
    echo ""
    read -r -p "Press Enter to continue after editing .env, or Ctrl+C to exit..."
fi

# Load environment variables
echo -e "${BLUE}ℹ${NC} Loading environment variables..."
set -a
# shellcheck source=/dev/null
source .env
set +a

# Check Docker
echo ""
echo "Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗${NC} Docker is not installed"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker is installed"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗${NC} Docker Compose is not available"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker Compose is available"

# Validate configuration
echo ""
echo "Validating platform structure..."
if [ -f scripts/validate.sh ]; then
    bash scripts/validate.sh
else
    echo -e "${YELLOW}⚠${NC} Validation script not found, skipping..."
fi

# Build and start services
echo ""
echo "=========================================="
echo "Starting Kolaboree NG Platform..."
echo "=========================================="
echo ""

docker compose up -d --build

echo ""
echo "Waiting for services to start..."
sleep 10

echo ""
echo "=========================================="
echo "✅ Kolaboree NG is starting!"
echo "=========================================="
echo ""
echo "Services will be available at:"
echo ""
echo -e "  ${GREEN}🌐 Main Application:${NC}    http://localhost:${NGINX_PORT:-80}"
echo -e "  ${GREEN}🔌 Backend API:${NC}         http://localhost:${BACKEND_PORT:-8000}"
echo -e "  ${GREEN}📚 API Documentation:${NC}   http://localhost:${BACKEND_PORT:-8000}/docs"
echo -e "  ${GREEN}🔐 Authentik:${NC}           http://localhost:${AUTHENTIK_PORT_HTTP:-9000}"
echo -e "  ${GREEN}📁 OpenLDAP:${NC}            ldap://localhost:${LDAP_PORT:-389}"
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
echo ""
echo "To stop the platform:"
echo "  docker compose down"
echo ""
echo "To completely reset (WARNING: deletes all data):"
echo "  docker compose down -v"
echo ""
echo -e "${YELLOW}⚠${NC} First time setup:"
echo "  1. Wait 2-3 minutes for all services to initialize"
echo "  2. Configure Authentik at http://localhost:${AUTHENTIK_PORT_HTTP:-9000}"
echo "  3. Connect Authentik to OpenLDAP (see README.md)"
echo "  4. Access the main application"
echo ""
