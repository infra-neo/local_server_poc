#!/bin/bash

# Kolaboree NG - Deploy Script (redirects to new start.sh)
# This script has been updated for the new Kolaboree NG platform

echo "=========================================="
echo "Kolaboree NG - Deployment"
echo "=========================================="
echo ""
echo "NOTE: This script now uses Docker Compose instead of Docker Swarm."
echo "Redirecting to the new start.sh script..."
echo ""

# Run the new start script
bash "$(dirname "$0")/start.sh"
