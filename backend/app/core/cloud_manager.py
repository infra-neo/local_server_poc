"""
Cloud Manager using Apache Libcloud
Implements connections to multiple cloud providers
"""
import json
import base64
from typing import List, Dict, Any, Optional
from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver
import pylxd

from app.models import Node


class CloudManager:
    """Manager for multi-cloud connections using Apache Libcloud"""
    
    def __init__(self):
        self.connections = {}
        self.lxd_clients = {}
    
    # GCP Implementation (100% functional)
    def connect_gcp(self, connection_id: str, credentials: Dict[str, Any], region: str = "us-central1-a") -> bool:
        """
        Connect to Google Cloud Platform
        credentials should contain:
        - service_account_json: JSON string or dict with service account credentials
        """
        try:
            # Get GCP driver
            ComputeEngine = get_driver(Provider.GCE)
            
            # Parse service account JSON
            if isinstance(credentials.get("service_account_json"), str):
                sa_data = json.loads(credentials["service_account_json"])
            else:
                sa_data = credentials.get("service_account_json", {})
            
            service_account_email = sa_data.get("client_email")
            project_id = sa_data.get("project_id")
            
            # Create driver instance
            driver = ComputeEngine(
                service_account_email,
                credentials.get("service_account_json"),
                project=project_id,
                datacenter=region
            )
            
            # Test connection by listing nodes
            driver.list_nodes()
            
            self.connections[connection_id] = {
                "driver": driver,
                "type": "gcp",
                "project_id": project_id,
                "region": region
            }
            return True
        except Exception as e:
            print(f"Error connecting to GCP: {str(e)}")
            return False
    
    def list_gcp_nodes(self, connection_id: str) -> List[Node]:
        """List GCP Compute Engine instances"""
        try:
            conn = self.connections.get(connection_id)
            if not conn or conn["type"] != "gcp":
                return []
            
            driver = conn["driver"]
            libcloud_nodes = driver.list_nodes()
            
            nodes = []
            for node in libcloud_nodes:
                # Sanitize extra data - convert complex objects to simple types
                extra = {}
                if node.extra:
                    for key, value in node.extra.items():
                        # Convert complex objects to strings or skip them
                        if isinstance(value, (str, int, float, bool, type(None))):
                            extra[key] = value
                        elif isinstance(value, (list, dict)):
                            try:
                                # Try to convert to simple types
                                extra[key] = str(value)
                            except:
                                pass
                        else:
                            # For other objects (like GCEZone), get their name or string representation
                            try:
                                if hasattr(value, 'name'):
                                    extra[key] = value.name
                                elif hasattr(value, 'id'):
                                    extra[key] = value.id
                                else:
                                    extra[key] = str(value)
                            except:
                                pass
                
                nodes.append(Node(
                    id=node.id,
                    name=node.name,
                    state=node.state.lower(),
                    provider_type="gcp",
                    connection_id=connection_id,
                    ip_addresses=[ip for ip in node.public_ips + node.private_ips if ip],
                    extra=extra
                ))
            return nodes
        except Exception as e:
            print(f"Error listing GCP nodes: {str(e)}")
            import traceback
            traceback.print_exc()
            return []
    
    # LXD Implementation (100% functional)
    def connect_lxd(self, connection_id: str, credentials: Dict[str, Any], endpoint: str = None) -> bool:
        """
        Connect to LXD
        credentials should contain:
        - endpoint: LXD endpoint URL (e.g., https://localhost:8443)
        - cert: Client certificate (path or PEM content)
        - key: Client key (path or PEM content)
        - verify: Verify SSL (default: False for local)
        - trust_password: Trust password for initial setup (optional)
        """
        try:
            import tempfile
            import os
            
            endpoint = endpoint or credentials.get("endpoint", "https://localhost:8443")
            cert_data = credentials.get("cert")
            key_data = credentials.get("key")
            verify = credentials.get("verify", False)
            
            cert_path = None
            key_path = None
            temp_cert = None
            temp_key = None
            
            # Handle cert and key - can be file paths or PEM content
            if cert_data and key_data:
                # Check if it's PEM content (starts with -----BEGIN)
                if isinstance(cert_data, str) and cert_data.strip().startswith("-----BEGIN"):
                    # It's PEM content, write to temp file
                    temp_cert = tempfile.NamedTemporaryFile(mode='w', suffix='.crt', delete=False)
                    temp_cert.write(cert_data)
                    temp_cert.flush()
                    cert_path = temp_cert.name
                else:
                    # It's a file path
                    cert_path = cert_data
                
                if isinstance(key_data, str) and key_data.strip().startswith("-----BEGIN"):
                    # It's PEM content, write to temp file
                    temp_key = tempfile.NamedTemporaryFile(mode='w', suffix='.key', delete=False)
                    temp_key.write(key_data)
                    temp_key.flush()
                    key_path = temp_key.name
                else:
                    # It's a file path
                    key_path = key_data
                
                # Connect to LXD with certificates
                print(f"Connecting to LXD at {endpoint} with certificates")
                client = pylxd.Client(
                    endpoint=endpoint,
                    cert=(cert_path, key_path),
                    verify=verify
                )
            else:
                # Try without cert (for local unix socket)
                print(f"Connecting to LXD at {endpoint} without certificates")
                try:
                    client = pylxd.Client()
                except:
                    # Try with endpoint only
                    client = pylxd.Client(endpoint=endpoint, verify=verify)
            
            # Test connection
            print("Testing LXD connection by listing instances...")
            client.instances.all()
            print("LXD connection successful!")
            
            self.lxd_clients[connection_id] = client
            self.connections[connection_id] = {
                "client": client,
                "type": "lxd",
                "endpoint": endpoint,
                "temp_cert": temp_cert.name if temp_cert else None,
                "temp_key": temp_key.name if temp_key else None
            }
            
            # Close temp file handles but keep files (will be cleaned up on disconnect)
            if temp_cert:
                temp_cert.close()
            if temp_key:
                temp_key.close()
            
            return True
        except Exception as e:
            print(f"Error connecting to LXD: {str(e)}")
            import traceback
            traceback.print_exc()
            
            # Cleanup temp files on error
            if temp_cert:
                temp_cert.close()
                try:
                    os.unlink(temp_cert.name)
                except:
                    pass
            if temp_key:
                temp_key.close()
                try:
                    os.unlink(temp_key.name)
                except:
                    pass
            
            return False
    
    def list_lxd_nodes(self, connection_id: str) -> List[Node]:
        """List LXD containers and VMs"""
        try:
            conn = self.connections.get(connection_id)
            if not conn or conn["type"] != "lxd":
                return []
            
            client = conn["client"]
            instances = client.instances.all()
            
            nodes = []
            for instance in instances:
                # Get IP addresses
                ips = []
                if instance.state().network:
                    for interface, data in instance.state().network.items():
                        if interface != "lo":
                            for addr in data.get("addresses", []):
                                if addr.get("family") in ["inet", "inet6"]:
                                    ips.append(addr.get("address"))
                
                nodes.append(Node(
                    id=instance.name,
                    name=instance.name,
                    state=instance.status.lower(),
                    provider_type="lxd",
                    connection_id=connection_id,
                    ip_addresses=ips,
                    extra={
                        "type": instance.type,
                        "architecture": instance.architecture,
                        "profiles": instance.profiles
                    }
                ))
            return nodes
        except Exception as e:
            print(f"Error listing LXD nodes: {str(e)}")
            return []
    
    # Placeholder implementations for other providers
    def connect_huawei(self, connection_id: str, credentials: Dict[str, Any], region: str = None) -> bool:
        """Placeholder for Huawei Cloud connection"""
        self.connections[connection_id] = {
            "type": "huawei",
            "status": "placeholder"
        }
        return True
    
    def list_huawei_nodes(self, connection_id: str) -> List[Node]:
        """Placeholder for Huawei Cloud nodes"""
        return [
            Node(
                id="huawei-demo-1",
                name="Huawei Demo Instance 1",
                state="running",
                provider_type="huawei",
                connection_id=connection_id,
                ip_addresses=["192.168.1.100"]
            )
        ]
    
    def connect_oracle(self, connection_id: str, credentials: Dict[str, Any], region: str = None) -> bool:
        """Placeholder for Oracle Cloud connection"""
        self.connections[connection_id] = {
            "type": "oracle",
            "status": "placeholder"
        }
        return True
    
    def list_oracle_nodes(self, connection_id: str) -> List[Node]:
        """Placeholder for Oracle Cloud nodes"""
        return [
            Node(
                id="oracle-demo-1",
                name="Oracle Demo Instance 1",
                state="running",
                provider_type="oracle",
                connection_id=connection_id,
                ip_addresses=["10.0.1.50"]
            )
        ]
    
    def connect_azure(self, connection_id: str, credentials: Dict[str, Any], region: str = None) -> bool:
        """Placeholder for Azure connection"""
        self.connections[connection_id] = {
            "type": "azure",
            "status": "placeholder"
        }
        return True
    
    def list_azure_nodes(self, connection_id: str) -> List[Node]:
        """Placeholder for Azure nodes"""
        return [
            Node(
                id="azure-demo-1",
                name="Azure Demo VM 1",
                state="running",
                provider_type="azure",
                connection_id=connection_id,
                ip_addresses=["40.112.50.25"]
            )
        ]
    
    def connect_digitalocean(self, connection_id: str, credentials: Dict[str, Any], region: str = None) -> bool:
        """Placeholder for DigitalOcean connection"""
        self.connections[connection_id] = {
            "type": "digitalocean",
            "status": "placeholder"
        }
        return True
    
    def list_digitalocean_nodes(self, connection_id: str) -> List[Node]:
        """Placeholder for DigitalOcean nodes"""
        return [
            Node(
                id="do-demo-1",
                name="DigitalOcean Droplet 1",
                state="running",
                provider_type="digitalocean",
                connection_id=connection_id,
                ip_addresses=["178.128.1.10"]
            )
        ]
    
    def connect_aws(self, connection_id: str, credentials: Dict[str, Any], region: str = "us-east-1") -> bool:
        """Placeholder for AWS EC2 connection"""
        self.connections[connection_id] = {
            "type": "aws",
            "status": "placeholder"
        }
        return True
    
    def list_aws_nodes(self, connection_id: str) -> List[Node]:
        """Placeholder for AWS EC2 nodes"""
        return [
            Node(
                id="i-aws-demo-1",
                name="AWS EC2 Instance 1",
                state="running",
                provider_type="aws",
                connection_id=connection_id,
                ip_addresses=["54.210.100.50"]
            )
        ]
    
    def connect_vultr(self, connection_id: str, credentials: Dict[str, Any], region: str = None) -> bool:
        """Placeholder for Vultr connection"""
        self.connections[connection_id] = {
            "type": "vultr",
            "status": "placeholder"
        }
        return True
    
    def list_vultr_nodes(self, connection_id: str) -> List[Node]:
        """Placeholder for Vultr nodes"""
        return [
            Node(
                id="vultr-demo-1",
                name="Vultr Instance 1",
                state="running",
                provider_type="vultr",
                connection_id=connection_id,
                ip_addresses=["45.76.50.100"]
            )
        ]
    
    def connect_alibaba(self, connection_id: str, credentials: Dict[str, Any], region: str = None) -> bool:
        """Placeholder for Alibaba Cloud connection"""
        self.connections[connection_id] = {
            "type": "alibaba",
            "status": "placeholder"
        }
        return True
    
    def list_alibaba_nodes(self, connection_id: str) -> List[Node]:
        """Placeholder for Alibaba Cloud nodes"""
        return [
            Node(
                id="alibaba-demo-1",
                name="Alibaba ECS Instance 1",
                state="running",
                provider_type="alibaba",
                connection_id=connection_id,
                ip_addresses=["47.88.10.20"]
            )
        ]
    
    # Generic methods
    def connect_provider(self, connection_id: str, provider_type: str, credentials: Dict[str, Any], region: str = None) -> bool:
        """Connect to a cloud provider based on type"""
        provider_methods = {
            "gcp": self.connect_gcp,
            "lxd": self.connect_lxd,
            "huawei": self.connect_huawei,
            "oracle": self.connect_oracle,
            "azure": self.connect_azure,
            "digitalocean": self.connect_digitalocean,
            "aws": self.connect_aws,
            "vultr": self.connect_vultr,
            "alibaba": self.connect_alibaba,
        }
        
        connect_method = provider_methods.get(provider_type)
        if not connect_method:
            return False
        
        if region:
            return connect_method(connection_id, credentials, region)
        else:
            return connect_method(connection_id, credentials)
    
    def list_nodes(self, connection_id: str) -> List[Node]:
        """List nodes for a specific connection"""
        conn = self.connections.get(connection_id)
        if not conn:
            return []
        
        provider_type = conn["type"]
        
        list_methods = {
            "gcp": self.list_gcp_nodes,
            "lxd": self.list_lxd_nodes,
            "huawei": self.list_huawei_nodes,
            "oracle": self.list_oracle_nodes,
            "azure": self.list_azure_nodes,
            "digitalocean": self.list_digitalocean_nodes,
            "aws": self.list_aws_nodes,
            "vultr": self.list_vultr_nodes,
            "alibaba": self.list_alibaba_nodes,
        }
        
        list_method = list_methods.get(provider_type)
        if not list_method:
            return []
        
        return list_method(connection_id)
    
    def get_connection_status(self, connection_id: str) -> Dict[str, Any]:
        """Get status of a cloud connection"""
        conn = self.connections.get(connection_id)
        if not conn:
            return {"status": "not_found"}
        
        return {
            "status": "connected",
            "type": conn["type"],
            "connection_id": connection_id
        }
    
    def disconnect(self, connection_id: str) -> bool:
        """Disconnect from a cloud provider and cleanup resources"""
        import os
        
        conn = self.connections.get(connection_id)
        if not conn:
            return False
        
        # Cleanup temporary certificate files for LXD
        if conn["type"] == "lxd":
            temp_cert = conn.get("temp_cert")
            temp_key = conn.get("temp_key")
            
            if temp_cert:
                try:
                    os.unlink(temp_cert)
                except:
                    pass
            
            if temp_key:
                try:
                    os.unlink(temp_key)
                except:
                    pass
            
            # Remove from lxd_clients dict
            if connection_id in self.lxd_clients:
                del self.lxd_clients[connection_id]
        
        # Remove from connections dict
        del self.connections[connection_id]
        return True
    
    # Power management methods
    def start_node(self, connection_id: str, node_id: str) -> bool:
        """Start/power on a node"""
        conn = self.connections.get(connection_id)
        if not conn:
            return False
        
        provider_type = conn["type"]
        
        if provider_type == "lxd":
            client = self.lxd_clients.get(connection_id)
            if client:
                try:
                    container = client.containers.get(node_id)
                    container.start()
                    return True
                except:
                    pass
        elif provider_type == "gcp":
            driver = conn.get("driver")
            if driver:
                try:
                    nodes = driver.list_nodes()
                    node = next((n for n in nodes if n.id == node_id), None)
                    if node:
                        driver.ex_start_node(node)
                        return True
                except:
                    pass
        
        return False
    
    def stop_node(self, connection_id: str, node_id: str) -> bool:
        """Stop/power off a node"""
        conn = self.connections.get(connection_id)
        if not conn:
            return False
        
        provider_type = conn["type"]
        
        if provider_type == "lxd":
            client = self.lxd_clients.get(connection_id)
            if client:
                try:
                    container = client.containers.get(node_id)
                    container.stop()
                    return True
                except:
                    pass
        elif provider_type == "gcp":
            driver = conn.get("driver")
            if driver:
                try:
                    nodes = driver.list_nodes()
                    node = next((n for n in nodes if n.id == node_id), None)
                    if node:
                        driver.ex_stop_node(node)
                        return True
                except:
                    pass
        
        return False
    
    def restart_node(self, connection_id: str, node_id: str) -> bool:
        """Restart a node"""
        conn = self.connections.get(connection_id)
        if not conn:
            return False
        
        provider_type = conn["type"]
        
        if provider_type == "lxd":
            client = self.lxd_clients.get(connection_id)
            if client:
                try:
                    container = client.containers.get(node_id)
                    container.restart()
                    return True
                except:
                    pass
        elif provider_type == "gcp":
            driver = conn.get("driver")
            if driver:
                try:
                    nodes = driver.list_nodes()
                    node = next((n for n in nodes if n.id == node_id), None)
                    if node:
                        node.reboot()
                        return True
                except:
                    pass
        
        return False
    
    def create_node(self, connection_id: str, name: str, config: Dict[str, Any]) -> Optional[Node]:
        """Create a new VM/Container"""
        conn = self.connections.get(connection_id)
        if not conn:
            return None
        
        provider_type = conn["type"]
        
        if provider_type == "lxd":
            client = self.lxd_clients.get(connection_id)
            if client:
                try:
                    # Default configuration for LXD container
                    container_config = {
                        'name': name,
                        'source': {
                            'type': 'image',
                            'alias': config.get('image', 'ubuntu:22.04')
                        },
                        'config': config.get('config', {}),
                        'devices': config.get('devices', {})
                    }
                    
                    container = client.containers.create(container_config, wait=True)
                    container.start(wait=True)
                    
                    return Node(
                        id=container.name,
                        name=container.name,
                        state=container.status,
                        provider_type="lxd",
                        connection_id=connection_id,
                        ip_addresses=[]
                    )
                except Exception as e:
                    print(f"Error creating LXD container: {e}")
                    return None
        
        return None


# Global instance
cloud_manager = CloudManager()
