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
   - User Dashboard: Switch to "👤 User View" tab
   - Admin Dashboard: Switch to "⚙️ Admin View" tab

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
- **Required**: LXD API endpoint (e.g., https://localhost:8443)

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
- Verify credentials are correct
- Check network connectivity
- Review backend logs: `docker-compose logs backend`
- For GCP: Ensure service account has proper permissions
- For LXD: Verify endpoint is accessible

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
