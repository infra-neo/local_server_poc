#!/bin/bash
set -e

echo "🔗 Kolaboree Backend - Starting with Tailscale"

# Start Tailscale daemon in the background
echo "Starting Tailscale daemon..."
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &

# Wait for tailscaled to start
sleep 2

# Connect to Tailscale if auth key is provided
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "Authenticating with Tailscale..."
    tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="kolaboree-backend" --accept-routes
    echo "✅ Tailscale connected successfully!"
    
    # Show Tailscale status
    tailscale status
else
    echo "⚠️  TAILSCALE_AUTH_KEY not set. Tailscale will not be authenticated."
    echo "⚠️  To connect to other clouds via Tailscale, set TAILSCALE_AUTH_KEY environment variable."
    echo "⚠️  Generate an auth key at: https://login.tailscale.com/admin/settings/keys"
fi

# Execute the main command
echo "Starting FastAPI application..."
exec "$@"
