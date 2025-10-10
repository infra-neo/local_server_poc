"""
Data models for the Kolaboree NG platform
"""
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime


class CloudProvider(BaseModel):
    """Cloud provider types supported"""
    id: str
    name: str
    type: str  # gcp, lxd, aws, azure, etc.
    enabled: bool = True


class CloudConnectionCreate(BaseModel):
    """Model for creating a new cloud connection"""
    name: str = Field(..., description="Friendly name for this connection")
    provider_type: str = Field(..., description="Provider type: gcp, lxd, huawei, oracle, azure, digitalocean, aws, vultr, alibaba")
    credentials: Dict[str, Any] = Field(..., description="Provider-specific credentials")
    region: Optional[str] = Field(None, description="Default region for this connection")


class CloudConnection(BaseModel):
    """Model for a cloud connection"""
    id: str
    name: str
    provider_type: str
    region: Optional[str] = None
    status: str = "connected"  # connected, error, disconnected
    created_at: datetime
    last_checked: Optional[datetime] = None


class NodeBase(BaseModel):
    """Base model for compute nodes (VMs/Containers)"""
    id: str
    name: str
    state: str  # running, stopped, etc.
    provider_type: str
    connection_id: str


class Node(NodeBase):
    """Full node model with additional details"""
    ip_addresses: List[str] = []
    cpu_count: Optional[int] = None
    memory_mb: Optional[int] = None
    created_at: Optional[datetime] = None
    extra: Dict[str, Any] = {}


class Workspace(BaseModel):
    """User workspace (assigned VM/Container)"""
    id: str
    name: str
    status: str  # online, offline
    connection_url: Optional[str] = None
    node: Node


class UserWorkspacesList(BaseModel):
    """List of user workspaces"""
    workspaces: List[Workspace]
