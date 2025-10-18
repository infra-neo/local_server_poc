# Application Management System

## Overview

Kolaboree NG includes an application management system inspired by Chocolatey (Windows) and Snap (Linux) for easy software deployment to VMs and containers.

## Supported Package Managers

### 1. **Snap** (Ubuntu/Linux Containers)
- Modern, containerized applications
- Automatic updates
- Cross-distribution compatibility

### 2. **APT** (Debian/Ubuntu)
- Traditional package management
- Extensive package repository
- System-level installations

### 3. **YUM/DNF** (CentOS/Fedora/RHEL)
- Red Hat package manager
- Enterprise software support

### 4. **APK** (Alpine Linux)
- Lightweight package manager
- Minimal footprint

## Pre-configured Application Bundles

### Office & Productivity
```yaml
bundle_name: "productivity_suite"
applications:
  - libreoffice  # Open source office suite
  - onlyoffice   # Collaborative office platform
  - gimp         # Image editing
  - inkscape     # Vector graphics
  - kdenlive     # Video editing
```

### Development Tools
```yaml
bundle_name: "dev_tools"
applications:
  - vscode       # Visual Studio Code
  - git          # Version control
  - docker       # Containerization
  - nodejs       # Node.js runtime
  - python3      # Python interpreter
  - postgresql   # Database
```

### Web Applications
```yaml
bundle_name: "web_apps"
applications:
  - firefox      # Web browser
  - chromium     # Chromium browser
  - filezilla    # FTP client
  - thunderbird  # Email client
```

### Server Applications
```yaml
bundle_name: "server_stack"
applications:
  - nginx        # Web server
  - apache2      # Apache web server
  - mysql        # MySQL database
  - redis        # Cache server
  - rabbitmq     # Message broker
```

## API Endpoints

### Install Application

```bash
POST /api/v1/admin/cloud_connections/{connection_id}/nodes/{node_id}/packages/install
```

**Request Body**:
```json
{
  "packages": ["libreoffice", "firefox"],
  "package_manager": "snap",
  "auto_update": true
}
```

**Response**:
```json
{
  "job_id": "install-job-123",
  "status": "in_progress",
  "packages": ["libreoffice", "firefox"]
}
```

### Install Bundle

```bash
POST /api/v1/admin/cloud_connections/{connection_id}/nodes/{node_id}/bundles/install
```

**Request Body**:
```json
{
  "bundle_name": "productivity_suite"
}
```

### List Installed Packages

```bash
GET /api/v1/admin/cloud_connections/{connection_id}/nodes/{node_id}/packages
```

### Remove Package

```bash
DELETE /api/v1/admin/cloud_connections/{connection_id}/nodes/{node_id}/packages/{package_name}
```

## Backend Implementation

```python
# backend/app/api/v1/endpoints_admin.py

@router.post("/cloud_connections/{connection_id}/nodes/{node_id}/packages/install")
async def install_packages(
    connection_id: str,
    node_id: str,
    request: PackageInstallRequest
):
    """
    Install packages on a node
    """
    if connection_id not in cloud_connections_db:
        raise HTTPException(status_code=404, detail="Connection not found")
    
    # Get node details
    nodes = cloud_manager.list_nodes(connection_id)
    node = next((n for n in nodes if n.id == node_id), None)
    
    if not node:
        raise HTTPException(status_code=404, detail="Node not found")
    
    # Execute package installation
    job_id = await package_manager.install_packages(
        connection_id=connection_id,
        node_id=node_id,
        packages=request.packages,
        package_manager=request.package_manager
    )
    
    return {
        "job_id": job_id,
        "status": "in_progress",
        "packages": request.packages
    }
```

## Package Manager Implementation

```python
# backend/app/core/package_manager.py

class PackageManager:
    """Manage software packages on VMs/Containers"""
    
    async def install_packages(
        self,
        connection_id: str,
        node_id: str,
        packages: List[str],
        package_manager: str = "snap"
    ) -> str:
        """Install packages using specified package manager"""
        
        commands = {
            "snap": f"snap install {' '.join(packages)}",
            "apt": f"apt-get update && apt-get install -y {' '.join(packages)}",
            "yum": f"yum install -y {' '.join(packages)}",
            "dnf": f"dnf install -y {' '.join(packages)}",
            "apk": f"apk add {' '.join(packages)}"
        }
        
        command = commands.get(package_manager)
        if not command:
            raise ValueError(f"Unsupported package manager: {package_manager}")
        
        # Execute command on node (implementation depends on provider)
        job_id = await self._execute_remote_command(
            connection_id, node_id, command
        )
        
        return job_id
    
    async def _execute_remote_command(
        self,
        connection_id: str,
        node_id: str,
        command: str
    ) -> str:
        """Execute command on remote node"""
        # LXD implementation
        conn = cloud_manager.connections.get(connection_id)
        
        if conn["type"] == "lxd":
            client = cloud_manager.lxd_clients.get(connection_id)
            container = client.containers.get(node_id)
            
            result = container.execute(["/bin/bash", "-c", command])
            
            return str(uuid.uuid4())  # Return job ID
        
        # Other providers...
        return str(uuid.uuid4())
```

## Frontend Components

### Package Installation Dialog

```javascript
// frontend/src/components/admin/PackageInstaller.js

import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Autocomplete,
  TextField,
  Chip,
  Box
} from '@mui/material';

const availablePackages = [
  { name: 'libreoffice', category: 'Office', description: 'Office suite' },
  { name: 'firefox', category: 'Browser', description: 'Web browser' },
  { name: 'vscode', category: 'Development', description: 'Code editor' },
  { name: 'gimp', category: 'Graphics', description: 'Image editor' },
  // ... more packages
];

const PackageInstaller = ({ open, onClose, nodeId, connectionId }) => {
  const [selectedPackages, setSelectedPackages] = useState([]);
  
  const handleInstall = async () => {
    await axios.post(
      `/api/v1/admin/cloud_connections/${connectionId}/nodes/${nodeId}/packages/install`,
      {
        packages: selectedPackages.map(p => p.name),
        package_manager: 'snap'
      }
    );
    onClose();
  };
  
  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>Install Applications</DialogTitle>
      <DialogContent>
        <Autocomplete
          multiple
          options={availablePackages}
          getOptionLabel={(option) => option.name}
          value={selectedPackages}
          onChange={(e, newValue) => setSelectedPackages(newValue)}
          renderInput={(params) => (
            <TextField {...params} label="Select packages" />
          )}
          renderTags={(value, getTagProps) =>
            value.map((option, index) => (
              <Chip label={option.name} {...getTagProps({ index })} />
            ))
          }
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button onClick={handleInstall} variant="contained">
          Install
        </Button>
      </DialogActions>
    </Dialog>
  );
};
```

## Common Application Packages

### Office Applications
- **LibreOffice**: Complete office suite (Writer, Calc, Impress)
- **OnlyOffice**: Collaborative office platform
- **GIMP**: GNU Image Manipulation Program
- **Inkscape**: Vector graphics editor
- **Scribus**: Desktop publishing

### Browsers
- **Firefox**: Mozilla Firefox browser
- **Chromium**: Open-source Chromium browser
- **Brave**: Privacy-focused browser

### Development
- **VS Code**: Visual Studio Code
- **Atom**: Hackable text editor
- **PyCharm Community**: Python IDE
- **Git**: Version control system
- **Docker**: Container platform
- **Node.js**: JavaScript runtime
- **Python3**: Python programming language

### Communication
- **Slack**: Team collaboration (snap)
- **Telegram**: Messaging app
- **Thunderbird**: Email client
- **Zoom**: Video conferencing

### Utilities
- **VLC**: Media player
- **7zip**: File archiver
- **FileZilla**: FTP client
- **KeePassXC**: Password manager
- **Remmina**: Remote desktop client

## Bundle Definitions

```python
# backend/app/core/bundles.py

BUNDLES = {
    "productivity_suite": {
        "name": "Productivity Suite",
        "description": "Office and productivity tools",
        "packages": [
            "libreoffice",
            "firefox",
            "thunderbird",
            "gimp",
            "vlc"
        ]
    },
    "dev_essential": {
        "name": "Developer Essentials",
        "description": "Essential development tools",
        "packages": [
            "vscode",
            "git",
            "docker",
            "nodejs",
            "python3-pip"
        ]
    },
    "web_server": {
        "name": "Web Server Stack",
        "description": "Complete web server environment",
        "packages": [
            "nginx",
            "postgresql",
            "redis",
            "nodejs",
            "certbot"
        ]
    }
}
```

## Update Management

### Auto-Update Configuration

```python
@router.put("/cloud_connections/{connection_id}/nodes/{node_id}/packages/config")
async def configure_package_updates(
    connection_id: str,
    node_id: str,
    config: PackageUpdateConfig
):
    """Configure automatic package updates"""
    
    if config.auto_update:
        # Enable automatic updates
        commands = {
            "snap": "snap set system refresh.timer=00:00-23:59",
            "apt": "dpkg-reconfigure -plow unattended-upgrades"
        }
        # Execute configuration command
    
    return {"status": "configured", "auto_update": config.auto_update}
```

## Security Considerations

1. **Package Verification**: Only install packages from trusted repositories
2. **Sandboxing**: Prefer Snap packages for better isolation
3. **Updates**: Enable automatic security updates
4. **Audit**: Log all package installations for compliance
5. **Permissions**: Require admin approval for system-level packages

## Usage Examples

### Install Office Suite via API

```bash
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections/conn-123/nodes/vm-456/packages/install \
  -H "Content-Type: application/json" \
  -d '{
    "packages": ["libreoffice", "firefox", "thunderbird"],
    "package_manager": "snap",
    "auto_update": true
  }'
```

### Install Development Bundle

```bash
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections/conn-123/nodes/vm-456/bundles/install \
  -H "Content-Type: application/json" \
  -d '{
    "bundle_name": "dev_essential"
  }'
```

## Future Enhancements

1. **Custom Repositories**: Add private package repositories
2. **Version Pinning**: Install specific package versions
3. **Dependency Management**: Automatic dependency resolution
4. **Rollback**: Revert package installations
5. **Usage Analytics**: Track package usage and performance
6. **License Management**: Track software licenses
7. **Container Images**: Pre-built images with package bundles
