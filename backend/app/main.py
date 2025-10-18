"""
Kolaboree NG - FastAPI Backend
Main application entry point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import endpoints_admin, endpoints_user, endpoints_rac, health


app = FastAPI(
    title="Kolaboree NG API",
    description="Multi-Cloud Management and Workspace Access Platform",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(endpoints_admin.router, prefix="/api/v1")
app.include_router(endpoints_user.router, prefix="/api/v1")
app.include_router(endpoints_rac.router, prefix="/api/v1")
app.include_router(health.router, prefix="/api/v1")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "Kolaboree NG API",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint with Tailscale status"""
    import subprocess
    import os
    
    health = {
        "status": "healthy",
        "service": "kolaboree-ng-backend",
        "tailscale": {
            "required": True,
            "configured": bool(os.getenv("TAILSCALE_AUTH_KEY")),
            "status": "unknown"
        }
    }
    
    # Check if Tailscale is running
    try:
        result = subprocess.run(
            ["tailscale", "status", "--json"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            import json
            ts_status = json.loads(result.stdout)
            health["tailscale"]["status"] = "connected" if ts_status.get("BackendState") == "Running" else "disconnected"
            health["tailscale"]["self_ip"] = ts_status.get("Self", {}).get("TailscaleIPs", [None])[0]
        else:
            health["tailscale"]["status"] = "not_running"
    except Exception as e:
        health["tailscale"]["status"] = "error"
        health["tailscale"]["error"] = str(e)
    
    return health


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
