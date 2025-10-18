# Kolaboree NG - Complete Features Guide

## Table of Contents
1. [Overview](#overview)
2. [Admin Features](#admin-features)
3. [User Features](#user-features)
4. [Remote Access](#remote-access)
5. [VM Management](#vm-management)
6. [User Management](#user-management)
7. [Application Management](#application-management)
8. [Drag & Drop](#drag--drop)

---

## Overview

Kolaboree NG is a comprehensive multi-cloud management and workspace access platform that combines infrastructure management with secure remote desktop capabilities.

### Key Capabilities
- **Multi-Cloud Management**: Unified interface for GCP, LXD, AWS, Azure, and more
- **Remote Desktop Access**: Browser-based RDP/VNC/SSH via Apache Guacamole
- **VM Lifecycle**: Create, start, stop, restart virtual machines
- **User Administration**: Centralized user and permission management
- **Package Management**: Install applications like Chocolatey/Snap
- **Drag & Drop UI**: Intuitive visual permission assignment

---

## Admin Features

### Cloud Connection Management

#### Add Cloud Connection
**Path**: Admin Dashboard → Add Cloud Connection

1. Click "Add Cloud Connection" button
2. Select provider (GCP, LXD, AWS, Azure, etc.)
3. Enter connection details:
   - **Name**: Friendly name for the connection
   - **Credentials**: Provider-specific authentication
   - **Region**: Default region (optional)
4. Review and connect

**Supported Providers**:
- ✅ **GCP** (Fully Functional) - Service Account JSON
- ✅ **LXD/MicroCloud** (Fully Functional) - Endpoint + Certificates
- 🔄 **AWS, Azure, DigitalOcean, Vultr, Alibaba, Oracle, Huawei** (Demo/Placeholder)

#### View Cloud Connections
All active cloud connections are displayed as cards with:
- Provider logo with custom colors
- Connection name and region
- Connection status (Connected/Error)
- Creation date
- Quick actions (View Nodes, Power Controls)

#### Provider Logos & Colors
Each provider has unique branding:
- **GCP**: Blue cloud (☁️) - #4285F4
- **LXD**: Package box (📦) - #E95420
- **AWS**: Orange circle (🟠) - #FF9900
- **Azure**: Blue diamond (🔷) - #0089D6
- **DigitalOcean**: Wave (🌊) - #0080FF
- **Vultr**: Lightning (⚡) - #007BFC
- **Alibaba**: Orange (🟠) - #FF6A00
- **Oracle**: Red circle (🔴) - #F80000
- **Huawei**: Red (🔴) - #FF0000

### VM/Container Management

#### View Nodes
**Path**: Admin Dashboard → Connection Card → View Nodes

Displays all VMs and containers for a cloud connection:
- Node name
- Current state (running, stopped)
- IP addresses
- Provider type
- Actions menu

#### Power Management
**Path**: Admin Dashboard → View Nodes → Actions menu (⋮)

Available actions:
- **Start**: Power on a stopped VM/container
- **Stop**: Gracefully shutdown a running instance
- **Restart**: Reboot the instance

**Supported Providers**:
- ✅ LXD: Full support for all actions
- ✅ GCP: Full support via Libcloud
- 🔄 Others: Coming soon

#### Create VM/Container
**Path**: Admin Dashboard → View Nodes → Create VM

**Step 1: Basic Configuration**
- VM Name (required)
- Operating System Image:
  - Ubuntu 22.04 LTS
  - Ubuntu 20.04 LTS
  - Debian 11
  - Debian 12
  - Alpine Linux 3.18
  - CentOS 8
  - Fedora 38

**Step 2: Resource Allocation**
- **CPU Cores**: 1-16 cores (slider)
- **Memory**: 512 MB - 16 GB (slider)
- **Disk**: 10 GB - 500 GB (slider)

**Step 3: Review & Create**
- Review all configuration
- Click "Create VM" to provision
- VM starts automatically after creation

**Current Support**: LXD containers (full), GCP (coming soon)

---

## User Features

### Workspace Access
**Path**: User Dashboard

View and access assigned workspaces:
- Workspace name
- Status (Online/Offline)
- Connection type
- Quick connect button

### Connect to Workspace
1. Click "Connect" on workspace card
2. Choose connection method (if multiple available)
3. Opens in new browser window via Guacamole

---

## Remote Access

### Apache Guacamole Integration
**Path**: Admin Dashboard → Remote Access

Kolaboree NG integrates **Apache Guacamole** for clientless remote desktop access.

#### Benefits
- ✅ **No Client Software**: Works entirely in web browser
- ✅ **HTML5 Based**: Uses modern web standards
- ✅ **Multiple Protocols**: RDP, VNC, SSH
- ✅ **WebRTC Support**: Low-latency connections
- ✅ **Clipboard Sharing**: Copy/paste between local and remote
- ✅ **File Transfer**: Upload/download files (protocol dependent)

#### Supported Protocols

**RDP (Remote Desktop Protocol)**
- Default Port: 3389
- Best for: Windows machines
- Features: Full desktop, audio, clipboard

**VNC (Virtual Network Computing)**
- Default Port: 5900
- Best for: Linux desktops, cross-platform
- Features: Screen sharing, keyboard/mouse control

**SSH (Secure Shell)**
- Default Port: 22
- Best for: Command-line access, Linux servers
- Features: Terminal access, SFTP

#### Connecting to a VM

1. Navigate to **Remote Access** page
2. Browse available machines
3. Click "Connect" on desired machine
4. Configure connection:
   - Select protocol (RDP/VNC/SSH)
   - Enter username (optional)
   - Enter password (optional)
   - Custom port (optional)
5. Click "Connect"
6. New window opens with Guacamole session

#### Connection URL Format
```
http://localhost:8080/guacamole/#/client/{node_id}
```

#### Advanced Configuration
For persistent connections, configure in Guacamole admin interface:
- Navigate to http://localhost:8080/guacamole
- Login with default credentials
- Configure connection parameters
- Set up connection groups
- Enable recording (if needed)

---

## User Management

**Path**: Admin Dashboard → Users

Centralized user administration interface.

### User List View
Table showing all users with:
- Username
- Email address
- Role (Admin/User)
- Status (Active/Inactive)
- Quick actions (Edit/Delete)

### Demo Users
Pre-configured for testing:
- **admin** - Administrator role (Active)
- **developer** - User role (Active)
- **guest** - User role (Inactive)

### Integration
Ready for integration with:
- **Authentik**: SSO and authentication
- **OpenLDAP**: Directory services
- **SAML/OAuth**: Enterprise SSO

### Future Features
- Add/Edit/Delete users
- Role assignment
- Permission templates
- Group management
- Workspace assignment via drag & drop

---

## Application Management

**Path**: VM Actions → Install Applications (coming soon)

Install and manage software on VMs similar to Chocolatey (Windows) or Snap (Linux).

### Supported Package Managers

#### Snap (Ubuntu/Linux)
Modern containerized applications with automatic updates:
```bash
snap install libreoffice firefox vscode
```

#### APT (Debian/Ubuntu)
Traditional package management:
```bash
apt-get install nginx postgresql redis
```

#### YUM/DNF (CentOS/Fedora)
Red Hat ecosystem packages:
```bash
yum install httpd mariadb
```

#### APK (Alpine)
Lightweight package manager:
```bash
apk add nginx python3
```

### Pre-configured Bundles

#### Productivity Suite
- LibreOffice (Office suite)
- Firefox (Web browser)
- Thunderbird (Email client)
- GIMP (Image editor)
- VLC (Media player)

#### Developer Tools
- Visual Studio Code
- Git version control
- Docker container platform
- Node.js runtime
- Python 3 + pip
- PostgreSQL database

#### Web Server Stack
- Nginx web server
- PostgreSQL database
- Redis cache
- Node.js
- Certbot (Let's Encrypt)

#### Office Applications
- OnlyOffice (Collaborative office)
- Inkscape (Vector graphics)
- Scribus (Desktop publishing)
- KeePassXC (Password manager)

### API Usage

**Install Single Package**:
```bash
POST /api/v1/admin/cloud_connections/{id}/nodes/{node_id}/packages/install
{
  "packages": ["firefox"],
  "package_manager": "snap"
}
```

**Install Bundle**:
```bash
POST /api/v1/admin/cloud_connections/{id}/nodes/{node_id}/bundles/install
{
  "bundle_name": "productivity_suite"
}
```

**List Installed**:
```bash
GET /api/v1/admin/cloud_connections/{id}/nodes/{node_id}/packages
```

See [PACKAGE_MANAGEMENT.md](PACKAGE_MANAGEMENT.md) for complete documentation.

---

## Drag & Drop

**Path**: Throughout Admin Dashboard

Powered by **React DnD** with HTML5 backend.

### Available Operations

#### User-to-VM Assignment (Coming Soon)
Drag users to VMs to assign workspace access:
1. Open Users panel
2. Drag user card
3. Drop on VM/container card
4. System creates assignment
5. User gains access

#### Cloud Connection Reordering
Organize connections by priority:
1. Click and hold connection card
2. Drag to new position
3. Drop to reorder
4. Order is preserved

#### Resource Grouping
Group VMs by project or environment:
1. Select multiple VMs
2. Drag to group area
3. Create logical organization
4. Manage as unit

#### Permission Templates
Visual permission management:
1. Create permission template
2. Drag template to user/group
3. Permissions applied automatically
4. Audit trail created

### Visual Feedback

**During Drag**:
- Source becomes semi-transparent (opacity: 0.5)
- Cursor changes to "grabbing"

**Valid Drop Zones**:
- Green dashed border
- Background color changes
- "Drop here" indicator

**Invalid Drops**:
- Red border
- Cursor shows "not-allowed"
- No action on drop

### Implementation

See [DRAG_DROP_GUIDE.md](DRAG_DROP_GUIDE.md) for:
- Complete code examples
- Advanced patterns
- Best practices
- Accessibility considerations
- Mobile support

---

## API Reference

### Admin Endpoints

#### Cloud Connections
```
POST   /api/v1/admin/cloud_connections          Create connection
GET    /api/v1/admin/cloud_connections          List all connections
GET    /api/v1/admin/cloud_connections/{id}     Get connection details
DELETE /api/v1/admin/cloud_connections/{id}     Delete connection
```

#### Nodes/VMs
```
GET    /api/v1/admin/cloud_connections/{id}/nodes              List nodes
POST   /api/v1/admin/cloud_connections/{id}/nodes              Create VM
POST   /api/v1/admin/cloud_connections/{id}/nodes/{node}/start Start VM
POST   /api/v1/admin/cloud_connections/{id}/nodes/{node}/stop  Stop VM
POST   /api/v1/admin/cloud_connections/{id}/nodes/{node}/restart Restart VM
```

#### Guacamole
```
POST   /api/v1/admin/guacamole/connect          Create remote connection
```

#### Users
```
GET    /api/v1/admin/users                       List all users
```

### Interactive API Documentation
Access Swagger UI at: **http://localhost:8000/docs**

---

## Troubleshooting

### Guacamole Connection Issues
**Problem**: Cannot connect to VM via Guacamole  
**Solution**:
1. Verify VM is running
2. Check firewall allows RDP/VNC/SSH port
3. Verify credentials are correct
4. Check Guacamole logs: `docker-compose logs guacamole`

### VM Creation Fails
**Problem**: VM creation returns error  
**Solution**:
1. Verify cloud connection is active
2. Check resource limits (quota)
3. Verify image name is correct
4. Check backend logs: `docker-compose logs backend`

### Admin Panel Shows Nothing
**Problem**: Admin dashboard is blank  
**Solution**:
1. Check backend is running: `curl http://localhost:8000/health`
2. Verify API endpoint: `curl http://localhost:8000/api/v1/admin/cloud_connections`
3. Check browser console for errors
4. Clear browser cache

### Power Management Not Working
**Problem**: Start/Stop buttons don't work  
**Solution**:
1. Only works with LXD and GCP currently
2. Verify cloud connection has proper permissions
3. Check node state is compatible (can't start running VM)
4. Check backend logs for error details

---

## Next Steps

### For Administrators
1. Add your cloud connections
2. Create some test VMs
3. Configure Guacamole connections
4. Set up users in Authentik
5. Assign workspaces to users

### For Developers
1. Review API documentation at `/docs`
2. Explore [DRAG_DROP_GUIDE.md](DRAG_DROP_GUIDE.md)
3. Check [PACKAGE_MANAGEMENT.md](PACKAGE_MANAGEMENT.md)
4. Contribute to cloud provider implementations
5. Add new features via pull requests

### For End Users
1. Login to platform
2. View assigned workspaces
3. Connect via browser
4. Access your applications
5. Provide feedback

---

## Additional Resources

- **Architecture**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **API Testing**: See [API_TESTING.md](API_TESTING.md)
- **Cloud Setup**: See [CLOUD_SETUP.md](CLOUD_SETUP.md)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Quick Reference**: See [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
