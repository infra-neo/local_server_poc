#!/bin/bash

# Kolaboree NG - Stop Script
# This script stops all platform services

set -e

echo "=========================================="
echo "Kolaboree NG - Stopping Services"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ask for confirmation
read -p "Stop all Kolaboree NG services? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Stop services
docker compose down

echo ""
echo -e "${GREEN}✓${NC} All services stopped"
echo ""
echo "To remove all data (volumes), run:"
echo "  docker compose down -v"
echo ""
echo "To start again, run:"
echo "  bash scripts/start.sh"
echo ""
