"""
User API endpoints for Kolaboree NG
Handles workspace access for end users
"""
from fastapi import APIRouter, HTTPException
from typing import List

from app.models import Workspace, Node
from app.core.cloud_manager import cloud_manager


router = APIRouter(prefix="/user", tags=["user"])


@router.get("/my_workspaces", response_model=List[Workspace])
async def get_my_workspaces():
    """
    Get list of workspaces (VMs/Containers) accessible to the current user
    
    In a real implementation, this would:
    1. Get the authenticated user from the request
    2. Query the database for user-to-node assignments
    3. Return only nodes the user has access to
    
    For this MVP, we return demo data from all connections
    """
    workspaces = []
    
    # Demo: Return some sample workspaces
    # In production, this would query based on user permissions
    demo_workspaces = [
        Workspace(
            id="ws-1",
            name="Development Environment",
            status="online",
            connection_url="https://workspace1.example.com",
            node=Node(
                id="demo-vm-1",
                name="dev-vm-001",
                state="running",
                provider_type="gcp",
                connection_id="demo",
                ip_addresses=["10.0.1.100"],
                cpu_count=4,
                memory_mb=8192
            )
        ),
        Workspace(
            id="ws-2",
            name="Testing Container",
            status="online",
            connection_url="https://workspace2.example.com",
            node=Node(
                id="demo-container-1",
                name="test-container-001",
                state="running",
                provider_type="lxd",
                connection_id="demo",
                ip_addresses=["10.0.2.50"],
                cpu_count=2,
                memory_mb=4096
            )
        ),
        Workspace(
            id="ws-3",
            name="Production Server",
            status="offline",
            connection_url=None,
            node=Node(
                id="demo-vm-2",
                name="prod-vm-001",
                state="stopped",
                provider_type="aws",
                connection_id="demo",
                ip_addresses=[],
                cpu_count=8,
                memory_mb=16384
            )
        )
    ]
    
    return demo_workspaces
