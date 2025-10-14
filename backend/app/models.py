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


class VMCreateRequest(BaseModel):
    """Request model for creating a new VM"""
    name: str = Field(..., description="Name for the new VM/Container")
    image: str = Field(default="ubuntu:22.04", description="Image to use (e.g., ubuntu:22.04, debian:11)")
    cpu_count: Optional[int] = Field(default=2, description="Number of CPU cores")
    memory_mb: Optional[int] = Field(default=2048, description="Memory in MB")
    disk_gb: Optional[int] = Field(default=20, description="Disk size in GB")
    config: Dict[str, Any] = Field(default_factory=dict, description="Additional provider-specific configuration")


class GuacamoleConnectionRequest(BaseModel):
    """Request model for creating a Guacamole connection"""
    node_id: str = Field(..., description="ID of the node to connect to")
    protocol: str = Field(default="rdp", description="Connection protocol: rdp, vnc, ssh")
    port: Optional[int] = Field(default=None, description="Port number (defaults based on protocol)")
    username: Optional[str] = Field(default=None, description="Username for authentication")
    password: Optional[str] = Field(default=None, description="Password for authentication")

