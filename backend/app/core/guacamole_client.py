"""
Guacamole Integration for Kolaboree NG
Handles Guacamole connections and authentication
"""
import httpx
import base64
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)

class GuacamoleClient:
    def __init__(self, base_url: str = "http://34.68.124.46:8080/guacamole"):
        self.base_url = base_url
        self.auth_token = None
    
    async def authenticate(self, username: str = "guacadmin", password: str = "guacadmin") -> bool:
        """Authenticate with Guacamole and get auth token"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/api/tokens",
                    data={
                        "username": username,
                        "password": password
                    },
                    headers={"Content-Type": "application/x-www-form-urlencoded"}
                )
                
                if response.status_code == 200:
                    data = response.json()
                    self.auth_token = data.get("authToken")
                    return True
                else:
                    logger.error(f"Guacamole auth failed: {response.status_code}")
                    return False
        except Exception as e:
            logger.error(f"Error authenticating with Guacamole: {e}")
            return False
    
    async def get_connections(self) -> List[Dict]:
        """Get all available connections from Guacamole"""
        if not self.auth_token:
            if not await self.authenticate():
                return []
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/api/session/data/postgresql/connections",
                    params={"token": self.auth_token}
                )
                
                if response.status_code == 200:
                    connections_data = response.json()
                    connections = []
                    
                    for conn_id, conn_info in connections_data.items():
                        connections.append({
                            "id": conn_id,
                            "name": conn_info.get("name", "Unknown"),
                            "protocol": conn_info.get("protocol", "unknown"),
                            "parameters": conn_info.get("parameters", {}),
                            "guacamole_url": f"{self.base_url}/#/client/{conn_id}?token={self.auth_token}"
                        })
                    
                    return connections
                else:
                    logger.error(f"Failed to get connections: {response.status_code}")
                    return []
        except Exception as e:
            logger.error(f"Error getting connections: {e}")
            return []
    
    async def get_connection_url(self, connection_id: str) -> Optional[str]:
        """Get direct connection URL for a specific connection"""
        if not self.auth_token:
            if not await self.authenticate():
                return None
        
        return f"{self.base_url}/#/client/{connection_id}?token={self.auth_token}"

# Global instance
guacamole_client = GuacamoleClient()