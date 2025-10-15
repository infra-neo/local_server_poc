#!/bin/bash
set -e

echo "🔗 Kolaboree Backend - Starting (Tailscale disabled for testing)"

# Check if we should enable Tailscale
if [ "$ENABLE_TAILSCALE" = "true" ] && [ -n "$TAILSCALE_AUTH_KEY" ] && [ "$TAILSCALE_AUTH_KEY" != "tskey-auth-kHCHSxfcu321CNTRL-qh4mk5yedn5Bp6mkqauLn5itcCyWdnmCP" ]; then
    echo "Starting Tailscale daemon..."
    tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &

    # Wait for tailscaled to start
    sleep 2

    echo "Authenticating with Tailscale..."
    tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="kolaboree-backend" --accept-routes
    echo "✅ Tailscale connected successfully!"
    
    # Show Tailscale status
    tailscale status
else
    echo "⚠️  Tailscale disabled for this session"
    echo "⚠️  Set ENABLE_TAILSCALE=true and provide valid TAILSCALE_AUTH_KEY to enable"
    echo "⚠️  Note: Local LXD connections will work without Tailscale"
fi

# Execute the main command
echo "Starting FastAPI application..."
exec "$@"
