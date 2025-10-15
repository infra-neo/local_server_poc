#!/bin/bash
# Tailscale Health Check Script for Kolaboree
# This script verifies that Tailscale is properly configured and running

set -e

echo "🔍 Kolaboree Tailscale Health Check"
echo "===================================="
echo ""

# Check if backend container is running
echo "1. Checking if backend container is running..."
if docker ps | grep -q kolaboree-backend; then
    echo "   ✅ Backend container is running"
else
    echo "   ❌ Backend container is not running"
    echo "   Run: docker compose up -d"
    exit 1
fi
echo ""

# Check if Tailscale is installed in the container
echo "2. Checking if Tailscale is installed..."
if docker exec kolaboree-backend which tailscale > /dev/null 2>&1; then
    echo "   ✅ Tailscale is installed"
else
    echo "   ❌ Tailscale is not installed"
    echo "   Rebuild the backend: docker compose build backend"
    exit 1
fi
echo ""

# Check if TAILSCALE_AUTH_KEY is set
echo "3. Checking environment configuration..."
if docker exec kolaboree-backend printenv TAILSCALE_AUTH_KEY > /dev/null 2>&1; then
    AUTH_KEY=$(docker exec kolaboree-backend printenv TAILSCALE_AUTH_KEY)
    if [ -n "$AUTH_KEY" ]; then
        echo "   ✅ TAILSCALE_AUTH_KEY is configured"
    else
        echo "   ⚠️  TAILSCALE_AUTH_KEY is empty"
        echo "   Set it in .env file and restart: docker compose restart backend"
    fi
else
    echo "   ⚠️  TAILSCALE_AUTH_KEY environment variable not found"
    echo "   Add it to .env file and restart: docker compose restart backend"
fi
echo ""

# Check Tailscale daemon status
echo "4. Checking Tailscale daemon status..."
if docker exec kolaboree-backend pgrep tailscaled > /dev/null 2>&1; then
    echo "   ✅ Tailscale daemon is running"
else
    echo "   ❌ Tailscale daemon is not running"
    echo "   Restart backend: docker compose restart backend"
    exit 1
fi
echo ""

# Check Tailscale connection status
echo "5. Checking Tailscale connection..."
TAILSCALE_STATUS=$(docker exec kolaboree-backend tailscale status 2>&1 || true)
if echo "$TAILSCALE_STATUS" | grep -q "not logged in"; then
    echo "   ⚠️  Tailscale is not authenticated"
    echo "   Check TAILSCALE_AUTH_KEY in .env and restart"
elif echo "$TAILSCALE_STATUS" | grep -q "100\."; then
    echo "   ✅ Tailscale is connected"
    TAILSCALE_IP=$(docker exec kolaboree-backend tailscale ip -4 2>/dev/null || echo "unknown")
    echo "   📍 Tailscale IP: $TAILSCALE_IP"
else
    echo "   ⚠️  Tailscale status unclear"
    echo "   Status output:"
    echo "$TAILSCALE_STATUS" | sed 's/^/      /'
fi
echo ""

# Test connectivity to LXD server
echo "6. Testing connectivity to LXD server (100.94.245.27)..."
if docker exec kolaboree-backend timeout 5 ping -c 1 100.94.245.27 > /dev/null 2>&1; then
    echo "   ✅ Can ping LXD server via Tailscale"
else
    echo "   ❌ Cannot ping LXD server"
    echo "   Verify Tailscale is connected and LXD server is in your Tailscale network"
fi
echo ""

# Test HTTPS connectivity to LXD API
echo "7. Testing HTTPS connectivity to LXD API..."
if docker exec kolaboree-backend timeout 5 curl -sk https://100.94.245.27:8443 > /dev/null 2>&1; then
    echo "   ✅ LXD API is reachable"
else
    echo "   ⚠️  LXD API might not be reachable"
    echo "   This is normal if LXD server requires client certificates"
fi
echo ""

# Check backend health endpoint
echo "8. Checking backend health endpoint..."
HEALTH_CHECK=$(curl -s http://localhost:8000/health 2>/dev/null || echo "{}")
if echo "$HEALTH_CHECK" | grep -q "tailscale"; then
    echo "   ✅ Health endpoint includes Tailscale status"
    TAILSCALE_HEALTH=$(echo "$HEALTH_CHECK" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('tailscale', {}).get('status', 'unknown'))")
    echo "   📊 Tailscale status from API: $TAILSCALE_HEALTH"
else
    echo "   ⚠️  Health endpoint doesn't include Tailscale status"
fi
echo ""

echo "===================================="
echo "🎯 Summary"
echo "===================================="
echo ""

# Count checks
TOTAL_CHECKS=8
PASSED_CHECKS=0

if docker ps | grep -q kolaboree-backend; then ((PASSED_CHECKS++)); fi
if docker exec kolaboree-backend which tailscale > /dev/null 2>&1; then ((PASSED_CHECKS++)); fi
if docker exec kolaboree-backend pgrep tailscaled > /dev/null 2>&1; then ((PASSED_CHECKS++)); fi

echo "Passed $PASSED_CHECKS basic checks"
echo ""

if echo "$TAILSCALE_STATUS" | grep -q "100\."; then
    echo "✅ Tailscale is properly configured and connected!"
    echo ""
    echo "You can now:"
    echo "  - Connect to remote LXD servers via Tailscale"
    echo "  - Access cloud resources in your Tailscale network"
    echo ""
    echo "Next steps:"
    echo "  - Add LXD connection in Kolaboree UI"
    echo "  - See CLOUD_SETUP.md for configuration details"
else
    echo "⚠️  Tailscale needs attention"
    echo ""
    echo "To fix:"
    echo "  1. Get auth key from https://login.tailscale.com/admin/settings/keys"
    echo "  2. Add to .env: TAILSCALE_AUTH_KEY=tskey-auth-..."
    echo "  3. Restart: docker compose restart backend"
    echo ""
    echo "For help, see: TAILSCALE_SETUP.md"
fi
echo ""
