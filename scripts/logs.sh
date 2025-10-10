#!/bin/bash

# Kolaboree NG - Logs Viewer
# View logs from all or specific services

SERVICE=${1:-}

if [ -z "$SERVICE" ]; then
    echo "Viewing logs from all services..."
    echo "Press Ctrl+C to exit"
    echo ""
    docker compose logs -f
else
    echo "Viewing logs from $SERVICE..."
    echo "Press Ctrl+C to exit"
    echo ""
    docker compose logs -f "$SERVICE"
fi
