# Kolaboree NG (Next Generation)

<div align="center">

**Multi-Cloud Management and Workspace Access Platform**

A modern, full-stack platform for managing multi-cloud infrastructure and providing secure workspace access through the browser.

[![Docker](https://img.shields.io/badge/Docker-Compose-blue)](https://docs.docker.com/compose/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104-green)](https://fastapi.tiangolo.com/)
[![React](https://img.shields.io/badge/React-18.2-blue)](https://reactjs.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Technology Stack](#-technology-stack)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Cloud Providers](#-cloud-providers)
- [Usage Guide](#-usage-guide)
- [Development](#-development)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

---

## 🌟 Overview

**Kolaboree NG** is a comprehensive platform that combines:

1. **Multi-Cloud Infrastructure Management** (like Mist.io): A unified admin panel to connect, visualize, and manage multiple cloud providers and virtualization platforms
2. **Secure Workspace Access** (like Kasm): A user portal to access virtual machines and applications through HTML5 browser connections
3. **Robust Identity Architecture**: Centralized IAM with well-defined roles using Authentik and OpenLDAP

## ✨ Features

### Admin Dashboard
- 🌐 **Multi-Cloud Connectivity**: Connect to GCP, LXD, AWS, Azure, DigitalOcean, Vultr, Alibaba Cloud, Oracle Cloud, and Huawei Cloud
- 📊 **Unified Dashboard**: Manage all cloud resources from a single interface
- 🔧 **Visual Configuration**: Modern wizard-based connector setup
- 🖱️ **Drag & Drop UI**: Prepare for advanced permission assignment (UI ready with React DnD)
- 📈 **Real-time Monitoring**: View instance status across all clouds

### User Dashboard
- 💻 **Workspace Access**: Clean interface to access assigned VMs and containers
- 🎯 **One-Click Connect**: Direct browser-based access to workspaces
- 📱 **Responsive Design**: Works seamlessly on desktop and mobile
- 🔄 **Live Status**: Real-time online/offline status of workspaces

### Identity & Access Management
- 🔐 **Authentik Integration**: Enterprise-grade SSO and authentication
- 📁 **OpenLDAP Directory**: Centralized user and group management
- 👥 **Role-Based Access**: Admin and user roles with appropriate permissions
- 🔒 **Secure by Default**: All services protected by authentication

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kolaboree NG Platform                        │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   Frontend   │  │   Backend    │  │  Authentik   │        │
│  │   (React)    │  │  (FastAPI)   │  │    (IAM)     │        │
│  │              │  │              │  │              │        │
│  │  Material-UI │  │  Libcloud    │  │   OpenLDAP   │        │
│  │  Framer      │  │  Multi-Cloud │  │  Integration │        │
│  │  React DnD   │  │  Manager     │  │              │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│         │                  │                   │               │
│         └──────────────────┴───────────────────┘               │
│                            │                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │    Nginx     │  │  PostgreSQL  │  │    Redis     │        │
│  │    Proxy     │  │   Database   │  │    Cache     │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
           │                     │                     │
           ▼                     ▼                     ▼
    ┌──────────┐         ┌──────────┐         ┌──────────┐
    │   GCP    │         │   LXD    │         │  Others  │
    └──────────┘         └──────────┘         └──────────┘
```

## 🛠️ Technology Stack

### Backend
- **Framework**: FastAPI (Python 3.11)
- **Cloud Integration**: Apache Libcloud 3.8.0
- **Container Management**: PyLXD 2.3.1
- **Database ORM**: Pydantic 2.4.2
- **Web Server**: Uvicorn

### Frontend
- **Framework**: React 18.2
- **UI Library**: Material-UI (MUI) 5.14
- **Animations**: Framer Motion 10.16
- **Drag & Drop**: React DnD 16.0
- **HTTP Client**: Axios 1.6
- **Build Tool**: Create React App

### Infrastructure
- **Identity Provider**: Authentik (latest)
- **Directory Service**: OpenLDAP (Bitnami)
- **Database**: PostgreSQL 15 Alpine
- **Cache**: Redis 7 Alpine
- **Reverse Proxy**: Nginx Alpine
- **Orchestration**: Docker Compose 3.8

## 🚀 Quick Start

### Prerequisites

- **Docker Engine** 20.10+ and **Docker Compose** 2.0+
- At least **4GB RAM** available
- At least **10GB disk space**

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/infra-neo/local_server_poc.git
   cd local_server_poc
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   nano .env  # Edit with your secure passwords
   ```
   
   ⚠️ **IMPORTANT**: Change all default passwords and secrets!

3. **Build and start the platform**
   ```bash
   docker-compose up -d
   ```

4. **Wait for services to be ready** (2-3 minutes)
   ```bash
   docker-compose ps  # Check status
   docker-compose logs -f  # Watch logs
   ```

5. **Access the platform**
   - **Main Application**: http://localhost:80
   - **Backend API**: http://localhost:8000
   - **API Documentation**: http://localhost:8000/docs
   - **Authentik Admin**: http://localhost:9000
   - **Guacamole Remote Desktop**: http://localhost:8080/guacamole

### First-Time Setup

1. **Configure Authentik**
   - Access Authentik at http://localhost:9000
   - Complete the initial setup wizard
   - Create admin user

2. **Configure OpenLDAP Connection in Authentik**
   - Navigate to **Directory** → **Federation & Social Login** → **Sources**
   - Add LDAP source:
     - Server URI: `ldap://openldap:1389`
     - Bind DN: `cn=admin,dc=kolaboree,dc=local`
     - Bind Password: (from your .env file)
     - Base DN: `dc=kolaboree,dc=local`

3. **Access the Application**
   - User Dashboard: Navigate to "User View"
   - Admin Dashboard: Navigate to "Admin View"
   - User Management: Click "Users" in Admin toolbar
   - Remote Access: Click "Remote Access" in Admin toolbar

## 🆕 New Features

### Apache Guacamole Integration
Kolaboree NG now includes **Apache Guacamole** for clientless remote desktop access:
- **HTML5-based**: No plugins or client software required
- **Multiple Protocols**: RDP, VNC, and SSH support
- **Browser Access**: Connect to VMs directly from your web browser
- **WebRTC Support**: Low-latency connections

**Access**: Admin Dashboard → Remote Access button

### VM/Container Management
Complete lifecycle management for virtual machines and containers:

#### Power Management
- **Start**: Power on stopped VMs/containers
- **Stop**: Gracefully shutdown running instances
- **Restart**: Reboot instances
- **Status Monitoring**: Real-time state tracking

**Access**: Admin Dashboard → View Nodes → Actions menu (⋮)

#### VM Creation Wizard
Create new VMs with a guided 3-step wizard:
1. **Basic Configuration**: Name and OS image selection
   - Ubuntu 22.04/20.04 LTS
   - Debian 11/12
   - Alpine Linux
   - CentOS, Fedora
2. **Resource Allocation**: CPU, RAM, and Disk sizing with sliders
3. **Review & Create**: Confirm and provision

**Access**: Admin Dashboard → View Nodes → Create VM button

### User Management
Centralized user administration interface:
- View all users with roles and status
- User/role assignment (demo interface)
- Integration ready for Authentik/LDAP
- Active/Inactive status tracking

**Access**: Admin Dashboard → Users button

### Application Package Management
Install and manage software on VMs similar to Chocolatey/Snap:

#### Supported Package Managers
- **Snap**: Modern containerized apps
- **APT**: Debian/Ubuntu packages
- **YUM/DNF**: Red Hat/CentOS packages
- **APK**: Alpine packages

#### Pre-configured Bundles
- **Productivity Suite**: LibreOffice, Firefox, GIMP, Thunderbird
- **Developer Tools**: VS Code, Git, Docker, Node.js, Python
- **Web Server Stack**: Nginx, PostgreSQL, Redis
- **Office Applications**: OnlyOffice, Inkscape, VLC

See [PACKAGE_MANAGEMENT.md](PACKAGE_MANAGEMENT.md) for complete documentation.

### Drag & Drop UI Framework
Advanced drag-and-drop functionality powered by React DnD:
- **User-to-VM Assignment**: Drag users to machines for access
- **Resource Grouping**: Organize VMs by project/environment
- **Permission Templates**: Visual permission management
- **Cloud Connection Reordering**: Prioritize connections

See [DRAG_DROP_GUIDE.md](DRAG_DROP_GUIDE.md) for implementation examples.

### Enhanced Cloud Provider Cards
- **Color-coded Logos**: Visual identification by provider
- **Power Controls**: Quick access to start/stop/restart
- **Status Indicators**: Real-time connection status
- **Custom Branding**: Provider-specific colors and icons

## ⚙️ Configuration

### Environment Variables

All configuration is managed through the `.env` file. Key variables:

#### Database & Cache
- `POSTGRES_DB`: PostgreSQL database name
- `POSTGRES_USER`: PostgreSQL user
- `POSTGRES_PASSWORD`: **Change this!**
- `REDIS_PASSWORD`: **Change this!**

#### LDAP Directory
- `LDAP_ADMIN_USERNAME`: LDAP admin username (default: admin)
- `LDAP_ADMIN_PASSWORD`: **Change this!**
- `LDAP_ROOT`: LDAP base DN
- `LDAP_PORT`: LDAP port (default: 389)

#### Authentik IAM
- `AUTHENTIK_SECRET_KEY`: **Must be 50+ characters!**
- `AUTHENTIK_PORT_HTTP`: HTTP port (default: 9000)
- `AUTHENTIK_PORT_HTTPS`: HTTPS port (default: 9443)

#### Application Ports
- `BACKEND_PORT`: FastAPI backend (default: 8000)
- `FRONTEND_PORT`: React frontend (default: 3000)
- `NGINX_PORT`: Main proxy (default: 80)
- `GUACAMOLE_PORT`: Guacamole web interface (default: 8080)

#### Tailscale VPN (Required for Remote Cloud Access)
- `TAILSCALE_AUTH_KEY`: **Required for connecting to remote LXD servers and other clouds**
- Generate at: https://login.tailscale.com/admin/settings/keys
- See [TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md) for complete setup guide

**⚠️ IMPORTANTE**: Este proyecto **requiere Tailscale** para comunicarse con proveedores de nube remotos.

## ☁️ Cloud Providers

### Fully Functional Providers

#### 🔵 Google Cloud Platform (GCP)
- **Status**: ✅ 100% Functional
- **Features**: List Compute Engine instances, view details
- **Setup**: Provide service account JSON credentials
- **Required**: Project ID, Service Account with Compute Engine permissions

#### 📦 LXD / MicroCloud
- **Status**: ✅ 100% Functional
- **Features**: List containers and VMs, view status and IPs
- **Setup**: Provide LXD endpoint and optional certificates
- **Required**: LXD API endpoint (e.g., https://100.94.245.27:8443)
- **⚠️ Important**: Requires Tailscale for remote LXD server access
- **Documentation**: See [TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md) and [CLOUD_SETUP.md](./CLOUD_SETUP.md)

### Placeholder Providers

The following providers have placeholder implementations that return demo data:

- 🟠 **AWS EC2**: Ready for implementation with Libcloud
- 🔷 **Microsoft Azure**: Ready for implementation with Libcloud
- 🌊 **DigitalOcean**: Ready for implementation with Libcloud
- ⚡ **Vultr**: Ready for implementation with Libcloud
- 🟠 **Alibaba Cloud**: Ready for implementation with Libcloud
- 🔴 **Oracle Cloud**: Ready for implementation with Libcloud
- 🔴 **Huawei Cloud**: Ready for implementation with Libcloud

To make these functional, update the respective methods in `backend/app/core/cloud_manager.py`.

## 📖 Usage Guide

### Admin: Adding a Cloud Connection

1. Navigate to the **Admin View** (⚙️ tab)
2. Click **"Add Cloud Connection"**
3. Follow the wizard:
   - **Step 1**: Select your cloud provider
   - **Step 2**: Enter connection name and credentials
   - **Step 3**: Review and connect
4. View the new connection card on your dashboard
5. Click **"View Nodes"** to see instances/containers

### Admin: Viewing Cloud Resources

- Each cloud connection displays as a card
- Cards show provider type, name, region, and status
- Click "View Nodes" to see all VMs/containers for that connection
- Real-time status updates from cloud providers

### User: Accessing Workspaces

1. Navigate to the **User View** (👤 tab)
2. See all assigned workspaces
3. Each card shows:
   - Workspace name
   - Online/Offline status
   - Provider information
   - Resource specifications
4. Click **"Connect"** on online workspaces to access

## 🔧 Development

### Running in Development Mode

#### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Access API docs at http://localhost:8000/docs

#### Frontend
```bash
cd frontend
npm install
npm start
```

Access frontend at http://localhost:3000

### Project Structure

```
kolaboree-ng/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── endpoints_admin.py    # Admin API
│   │   │       └── endpoints_user.py     # User API
│   │   ├── core/
│   │   │   └── cloud_manager.py          # Libcloud integration
│   │   ├── main.py                        # FastAPI app
│   │   └── models.py                      # Pydantic models
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── admin/
│   │   │   │   ├── CloudProviderCard.js
│   │   │   │   └── WizardConector.js
│   │   │   └── user/
│   │   │       └── WorkspaceCard.js
│   │   ├── pages/
│   │   │   ├── AdminDashboard.js
│   │   │   └── UserDashboard.js
│   │   ├── App.js
│   │   └── index.js
│   ├── Dockerfile
│   └── package.json
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       └── default.conf
├── docker-compose.yml
├── .env.example
└── README.md
```

### API Endpoints

#### Admin Endpoints
- `POST /api/v1/admin/cloud_connections` - Create cloud connection
- `GET /api/v1/admin/cloud_connections` - List all connections
- `GET /api/v1/admin/cloud_connections/{id}` - Get connection details
- `GET /api/v1/admin/cloud_connections/{id}/nodes` - List nodes
- `DELETE /api/v1/admin/cloud_connections/{id}` - Delete connection

#### User Endpoints
- `GET /api/v1/user/my_workspaces` - Get user's workspaces

## 🐛 Troubleshooting

### Common Issues

#### Services not starting
```bash
# Check logs
docker-compose logs -f

# Restart specific service
docker-compose restart <service-name>

# Rebuild and restart
docker-compose up -d --build
```

#### Cannot connect to cloud provider
- **For remote LXD servers**: Verify Tailscale is connected (see [TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md))
  ```bash
  bash scripts/check-tailscale.sh
  docker exec kolaboree-backend tailscale status
  ```
- Verify credentials are correct
- Check network connectivity
- Review backend logs: `docker-compose logs backend`
- For GCP: Ensure service account has proper permissions
- For LXD: Verify endpoint is accessible and Tailscale is connected

#### Frontend can't reach backend
- Verify `REACT_APP_API_URL` in frontend environment
- Check nginx proxy configuration
- Ensure backend is running: `docker-compose ps backend`

#### Authentik configuration issues
- Reset Authentik: `docker-compose down -v && docker-compose up -d`
- Check Authentik logs: `docker-compose logs authentik-server`
- Verify PostgreSQL connection

### Logs & Debugging

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f authentik-server

# Check service health
docker-compose ps

# Restart all services
docker-compose restart

# Full reset (WARNING: deletes data)
docker-compose down -v
docker-compose up -d
```

## 📚 Documentation

Complete documentation is available:

### Setup & Configuration
- **[README.md](./README.md)** - This file, main documentation
- **[TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md)** - Tailscale VPN setup (Required for remote clouds)
- **[CLOUD_SETUP.md](./CLOUD_SETUP.md)** - Cloud provider configuration (LXD, GCP)
- **[QUICK_START_LXD.md](./QUICK_START_LXD.md)** - Quick guide for LXD connections
- **.env.example** - Environment variable template

### Usage & Reference
- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Command reference and common tasks
- **[API_TESTING.md](./API_TESTING.md)** - API testing guide
- **[EXAMPLES.md](./EXAMPLES.md)** - API usage examples

### Architecture & Development
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture and design
- **[TESTING.md](./TESTING.md)** - Testing guide and checklist
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Contribution guidelines
- **[FEATURES.md](./FEATURES.md)** - Detailed feature documentation
- **[PACKAGE_MANAGEMENT.md](./PACKAGE_MANAGEMENT.md)** - Package management guide
- **[DRAG_DROP_GUIDE.md](./DRAG_DROP_GUIDE.md)** - Drag & drop UI implementation

### Implementation Details
- **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - Project overview and metrics
- **[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)** - Implementation details
- **[TAILSCALE_IMPLEMENTATION.md](./TAILSCALE_IMPLEMENTATION.md)** - Tailscale integration details
- **[CHANGELOG.md](./CHANGELOG.md)** - Version history

### Scripts
- **scripts/check-tailscale.sh** - Comprehensive Tailscale health check
- **scripts/validate.sh** - Validate project structure
- **scripts/start.sh** - Start all services
- **scripts/stop.sh** - Stop all services

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Apache Libcloud**: Multi-cloud abstraction library
- **Authentik**: Identity provider and SSO
- **Material-UI**: React component library
- **Framer Motion**: Animation library
- **FastAPI**: Modern Python web framework

---

<div align="center">

**Built with ❤️ for the cloud-native community**

[Report Bug](https://github.com/infra-neo/local_server_poc/issues) · [Request Feature](https://github.com/infra-neo/local_server_poc/issues)

</div>## Stack Tecnológico
