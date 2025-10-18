"""
RAC (Remote Access Control) API endpoints
Handles remote access connections including Guacamole integration
"""
from fastapi import APIRouter, HTTPException
from typing import List, Dict
import logging

from app.core.guacamole_client import guacamole_client

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/rac", tags=["rac"])


@router.get("/connections")
async def get_rac_connections() -> List[Dict]:
    """
    Get all available RAC connections including Guacamole connections
    """
    try:
        connections = []
        
        # Get Guacamole connections
        guac_connections = await guacamole_client.get_connections()
        
        for conn in guac_connections:
            # Add additional RAC-specific information
            rac_connection = {
                "id": f"guacamole_{conn['id']}",
                "name": conn['name'],
                "type": "guacamole",
                "protocol": conn['protocol'],
                "description": f"Remote desktop access to {conn['name']}",
                "connection_url": conn['guacamole_url'],
                "status": "available",
                "requires_permission": True,  # Indicates user needs to accept RDP prompt
                "metadata": {
                    "guacamole_id": conn['id'],
                    "parameters": conn['parameters']
                }
            }
            connections.append(rac_connection)
        
        return connections
    
    except Exception as e:
        logger.error(f"Error getting RAC connections: {e}")
        raise HTTPException(status_code=500, detail="Failed to get RAC connections")


@router.get("/connections/{connection_id}")
async def get_rac_connection(connection_id: str) -> Dict:
    """
    Get details for a specific RAC connection
    """
    try:
        # Extract the actual Guacamole connection ID
        if connection_id.startswith("guacamole_"):
            guac_id = connection_id.replace("guacamole_", "")
            
            # Get connection URL
            connection_url = await guacamole_client.get_connection_url(guac_id)
            
            if connection_url:
                return {
                    "id": connection_id,
                    "guacamole_id": guac_id,
                    "connection_url": connection_url,
                    "status": "ready",
                    "instructions": {
                        "title": "Connecting to Remote Desktop",
                        "steps": [
                            "Click 'Connect' to open the remote desktop",
                            "If prompted, click 'Yes' to allow the connection",
                            "On the Windows machine, click 'Yes' to allow remote access",
                            "Your local session may be disconnected - this is normal"
                        ]
                    }
                }
            else:
                raise HTTPException(status_code=404, detail="Connection not found")
        else:
            raise HTTPException(status_code=400, detail="Invalid connection ID format")
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting RAC connection {connection_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to get connection details")


@router.post("/connections/{connection_id}/connect")
async def connect_to_rac(connection_id: str) -> Dict:
    """
    Initiate connection to a RAC resource
    Returns connection details and URL
    """
    try:
        # Get connection details
        connection = await get_rac_connection(connection_id)
        
        return {
            "status": "connecting",
            "connection_url": connection["connection_url"],
            "message": "Opening remote desktop connection...",
            "instructions": connection["instructions"]
        }
    
    except Exception as e:
        logger.error(f"Error connecting to RAC {connection_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to initiate connection")