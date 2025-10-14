"""
Admin API endpoints for Kolaboree NG
Handles cloud connection management and node listing
"""
from fastapi import APIRouter, HTTPException, status
from typing import List
from datetime import datetime
import uuid

from app.models import CloudConnectionCreate, CloudConnection, Node, VMCreateRequest, GuacamoleConnectionRequest
from app.core.cloud_manager import cloud_manager


router = APIRouter(prefix="/admin", tags=["admin"])

# In-memory storage for cloud connections (in production, use database)
cloud_connections_db = {}


@router.post("/cloud_connections", response_model=CloudConnection, status_code=status.HTTP_201_CREATED)
async def create_cloud_connection(connection: CloudConnectionCreate):
    """
    Create a new cloud connection
    
    Supports: gcp, lxd, huawei, oracle, azure, digitalocean, aws, vultr, alibaba
    """
    connection_id = str(uuid.uuid4())
    
    # Attempt to connect to the cloud provider
    success = cloud_manager.connect_provider(
        connection_id=connection_id,
        provider_type=connection.provider_type,
        credentials=connection.credentials,
        region=connection.region
    )
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to connect to {connection.provider_type}. Check credentials."
        )
    
    # Store connection metadata
    cloud_conn = CloudConnection(
        id=connection_id,
        name=connection.name,
        provider_type=connection.provider_type,
        region=connection.region,
        status="connected",
        created_at=datetime.utcnow(),
        last_checked=datetime.utcnow()
    )
    
    cloud_connections_db[connection_id] = cloud_conn
    
    return cloud_conn


@router.get("/cloud_connections", response_model=List[CloudConnection])
async def list_cloud_connections():
    """
    List all configured cloud connections
    """
    return list(cloud_connections_db.values())


@router.get("/cloud_connections/{connection_id}/nodes", response_model=List[Node])
async def list_connection_nodes(connection_id: str):
    """
    List all nodes (VMs/Containers) for a specific cloud connection
    """
    if connection_id not in cloud_connections_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cloud connection {connection_id} not found"
        )
    
    nodes = cloud_manager.list_nodes(connection_id)
    return nodes


@router.get("/cloud_connections/{connection_id}", response_model=CloudConnection)
async def get_cloud_connection(connection_id: str):
    """
    Get details of a specific cloud connection
    """
    if connection_id not in cloud_connections_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cloud connection {connection_id} not found"
        )
    
    return cloud_connections_db[connection_id]


@router.delete("/cloud_connections/{connection_id}")
async def delete_cloud_connection(connection_id: str):
    """
    Delete a cloud connection
    """
    if connection_id not in cloud_connections_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cloud connection {connection_id} not found"
        )
    
    # Disconnect and cleanup resources
    cloud_manager.disconnect(connection_id)
    
    # Remove from database
    del cloud_connections_db[connection_id]
    
    return {"message": "Cloud connection deleted successfully"}


@router.post("/cloud_connections/{connection_id}/nodes/{node_id}/start")
async def start_node(connection_id: str, node_id: str):
    """
    Start/power on a node
    """
    if connection_id not in cloud_connections_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cloud connection {connection_id} not found"
        )
    
    success = cloud_manager.start_node(connection_id, node_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to start node"
        )
    
    return {"message": "Node started successfully", "node_id": node_id}


@router.post("/cloud_connections/{connection_id}/nodes/{node_id}/stop")
async def stop_node(connection_id: str, node_id: str):
    """
    Stop/power off a node
    """
    if connection_id not in cloud_connections_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cloud connection {connection_id} not found"
        )
    
    success = cloud_manager.stop_node(connection_id, node_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to stop node"
        )
    
    return {"message": "Node stopped successfully", "node_id": node_id}


@router.post("/cloud_connections/{connection_id}/nodes/{node_id}/restart")
async def restart_node(connection_id: str, node_id: str):
    """
    Restart a node
    """
    if connection_id not in cloud_connections_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cloud connection {connection_id} not found"
        )
    
    success = cloud_manager.restart_node(connection_id, node_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to restart node"
        )
    
    return {"message": "Node restarted successfully", "node_id": node_id}


@router.post("/cloud_connections/{connection_id}/nodes", response_model=Node)
async def create_node(connection_id: str, vm_request: VMCreateRequest):
    """
    Create a new VM/Container
    """
    if connection_id not in cloud_connections_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cloud connection {connection_id} not found"
        )
    
    # Build configuration from request
    config = vm_request.config.copy()
    config.update({
        "image": vm_request.image,
        "limits.cpu": str(vm_request.cpu_count),
        "limits.memory": f"{vm_request.memory_mb}MB"
    })
    
    node = cloud_manager.create_node(
        connection_id=connection_id,
        name=vm_request.name,
        config=config
    )
    
    if not node:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create node"
        )
    
    return node


@router.post("/guacamole/connect")
async def create_guacamole_connection(connection_request: GuacamoleConnectionRequest):
    """
    Create a Guacamole connection for remote access
    Returns connection token/URL for accessing the node via Guacamole
    """
    # Default ports based on protocol
    default_ports = {
        "rdp": 3389,
        "vnc": 5900,
        "ssh": 22
    }
    
    port = connection_request.port or default_ports.get(connection_request.protocol, 22)
    
    # In a real implementation, this would create a Guacamole connection configuration
    # For now, return a connection configuration that the frontend can use
    connection_config = {
        "connection_id": str(uuid.uuid4()),
        "node_id": connection_request.node_id,
        "protocol": connection_request.protocol,
        "port": port,
        "guacamole_url": f"/guacamole/#/client/{connection_request.node_id}",
        "status": "ready"
    }
    
    return connection_config


@router.get("/users")
async def list_users():
    """
    List all users (placeholder for user management)
    """
    # This is a placeholder - in production, integrate with Authentik/LDAP
    demo_users = [
        {
            "id": "user-1",
            "username": "admin",
            "email": "admin@kolaboree.local",
            "role": "admin",
            "active": True
        },
        {
            "id": "user-2",
            "username": "developer",
            "email": "dev@kolaboree.local",
            "role": "user",
            "active": True
        },
        {
            "id": "user-3",
            "username": "guest",
            "email": "guest@kolaboree.local",
            "role": "user",
            "active": False
        }
    ]
    
    return demo_users


