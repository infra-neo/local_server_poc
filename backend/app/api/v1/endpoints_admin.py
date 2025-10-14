"""
Admin API endpoints for Kolaboree NG
Handles cloud connection management and node listing
"""
from fastapi import APIRouter, HTTPException, status
from typing import List
from datetime import datetime
import uuid

from app.models import CloudConnectionCreate, CloudConnection, Node
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
