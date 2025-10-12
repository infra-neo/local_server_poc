#!/bin/bash

# Kolaboree NG - Teardown Script (redirects to new stop.sh)
# This script has been updated for the new Kolaboree NG platform

echo "=========================================="
echo "Kolaboree NG - Teardown"
echo "=========================================="
echo ""
echo "NOTE: This script now uses Docker Compose instead of Docker Swarm."
echo "Redirecting to the new stop.sh script..."
echo ""

# Run the new stop script
bash "$(dirname "$0")/stop.sh"
