# Kolaboree NG - Architecture Documentation

## System Overview

Kolaboree NG is a modern, full-stack platform designed for multi-cloud infrastructure management and secure workspace access. This document describes the architecture, components, and data flow.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Kolaboree NG Platform                           │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                     Presentation Layer                         │   │
│  │  ┌──────────────────┐         ┌──────────────────┐            │   │
│  │  │  React Frontend  │         │  Nginx Reverse   │            │   │
│  │  │  - Material-UI   │  ←───→  │      Proxy       │            │   │
│  │  │  - Framer Motion │         │  - SSL/TLS       │            │   │
│  │  │  - React DnD     │         │  - Load Balance  │            │   │
│  │  └──────────────────┘         └──────────────────┘            │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                 │                                       │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                     Application Layer                          │   │
│  │  ┌──────────────────┐         ┌──────────────────┐            │   │
│  │  │  FastAPI Backend │         │   Authentik IAM  │            │   │
│  │  │  - REST API      │  ←───→  │  - SSO/OIDC      │            │   │
│  │  │  - Apache        │         │  - LDAP Source   │            │   │
│  │  │    Libcloud      │         │  - Proxy Auth    │            │   │
│  │  └──────────────────┘         └──────────────────┘            │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                 │                                       │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                      Data Layer                                │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │   │
│  │  │   PostgreSQL     │  │      Redis       │  │   OpenLDAP   │ │   │
│  │  │  - App Data      │  │  - Cache         │  │  - Users     │ │   │
│  │  │  - Connections   │  │  - Sessions      │  │  - Groups    │ │   │
│  │  └──────────────────┘  └──────────────────┘  └──────────────┘ │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                 │                                       │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                   Cloud Integration Layer                      │   │
│  │                                                                │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐          │   │
│  │  │   GCP   │  │   LXD   │  │   AWS   │  │  Azure  │  ...     │   │
│  │  │   ✓     │  │   ✓     │  │   🔄    │  │   🔄    │          │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘          │   │
│  └────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

Legend:
  ✓  - Fully Functional
  🔄 - Placeholder (Ready for Implementation)
```

## Component Details

### Frontend (React Application)

**Technology Stack:**
- React 18.2
- Material-UI 5.14
- Framer Motion 10.16
- React DnD 16.0
- Axios 1.6

**Key Components:**

1. **Admin Dashboard** (`AdminDashboard.js`)
   - Displays connected cloud providers
   - Cloud provider management wizard
   - Node/instance viewer
   - Drag-and-drop UI preparation

2. **User Dashboard** (`UserDashboard.js`)
   - Workspace cards display
   - Connection status indicators
   - Quick connect functionality

3. **Shared Components**
   - `CloudProviderCard.js` - Cloud connection display
   - `WizardConector.js` - Multi-step connection wizard
   - `WorkspaceCard.js` - Workspace access card

**Features:**
- Responsive design for mobile and desktop
- Smooth animations and transitions
- Real-time status updates
- Intuitive user experience

### Backend (FastAPI Application)

**Technology Stack:**
- Python 3.11
- FastAPI 0.104
- Apache Libcloud 3.8
- PyLXD 2.3
- Pydantic 2.4
- Uvicorn (ASGI server)

**Architecture:**

```
backend/
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints_admin.py    # Admin operations
│   │       └── endpoints_user.py     # User operations
│   ├── core/
│   │   └── cloud_manager.py          # Cloud provider logic
│   ├── main.py                        # FastAPI application
│   └── models.py                      # Data models
```

**Key Modules:**

1. **Cloud Manager** (`cloud_manager.py`)
   - Cloud provider abstraction
   - Connection management
   - Resource listing and control
   - Provider-specific implementations

2. **API Endpoints**
   - Admin endpoints for cloud management
   - User endpoints for workspace access
   - Health checks and monitoring

3. **Data Models**
   - CloudConnection
   - Node (VM/Container)
   - Workspace
   - Credentials handling

### Infrastructure Services

#### PostgreSQL Database
- **Purpose**: Primary data store
- **Stores**: Cloud connections, user assignments, configuration
- **Version**: PostgreSQL 15 Alpine
- **Port**: 5432 (internal)

#### Redis Cache
- **Purpose**: Caching and session storage
- **Features**: Fast in-memory data access
- **Version**: Redis 7 Alpine
- **Port**: 6379 (internal)

#### Authentik IAM
- **Purpose**: Identity and access management
- **Features**:
  - Single Sign-On (SSO)
  - OIDC/SAML provider
  - LDAP integration
  - Proxy authentication
- **Ports**: 9000 (HTTP), 9443 (HTTPS)

#### OpenLDAP Directory
- **Purpose**: User and group management
- **Integration**: Source for Authentik
- **Version**: Bitnami OpenLDAP
- **Ports**: 389 (LDAP), 636 (LDAPS)

#### Nginx Reverse Proxy
- **Purpose**: Request routing and load balancing
- **Routes**:
  - `/` → Frontend
  - `/api/` → Backend
  - `/auth/` → Authentik
- **Features**: SSL termination, caching, compression

## Data Flow

### Admin: Adding a Cloud Connection

```
User → Frontend → Backend → Cloud Manager → Cloud Provider
                                    ↓
                              PostgreSQL
                              (Save Connection)
```

1. User fills wizard in frontend
2. Frontend sends POST to `/api/v1/admin/cloud_connections`
3. Backend validates credentials
4. Cloud Manager attempts connection
5. Connection metadata saved to PostgreSQL
6. Success/failure returned to user

### Admin: Viewing Cloud Resources

```
User → Frontend → Backend → Cloud Manager → Cloud Provider
                                              (List Instances)
                                    ↓
                              Return Node List
```

1. User clicks "View Nodes"
2. Frontend requests `/api/v1/admin/cloud_connections/{id}/nodes`
3. Cloud Manager queries provider
4. Node list returned and displayed

### User: Accessing Workspaces

```
User → Frontend → Backend → Database
                   ↓
            User Workspaces
                   ↓
        Workspace Connection URLs
```

1. User opens User Dashboard
2. Frontend requests `/api/v1/user/my_workspaces`
3. Backend queries assigned workspaces
4. Workspace cards displayed
5. User clicks "Connect" → Opens workspace URL

## Security Architecture

### Authentication Flow

```
User → Nginx → Authentik Proxy → Backend
                    ↓
                OpenLDAP
            (User Verification)
```

**Current State**: Authentication prepared but not enforced
**Production**: All routes should be protected by Authentik forward auth

### Data Protection

- **Credentials**: Stored encrypted in PostgreSQL
- **Sessions**: Managed by Redis with TTL
- **API Keys**: Environment variables, not in code
- **HTTPS**: Enforced in production via Nginx

## Scalability Considerations

### Horizontal Scaling

**Frontend:**
- Stateless React app
- Can run multiple replicas
- Load balanced by Nginx

**Backend:**
- Stateless FastAPI service
- Can run multiple instances
- Shared PostgreSQL and Redis

**Database:**
- PostgreSQL: Read replicas for scaling
- Redis: Cluster mode for high availability

### Performance Optimization

1. **Caching**:
   - API responses cached in Redis
   - Cloud provider data cached with TTL

2. **Async Operations**:
   - FastAPI async endpoints
   - Background tasks for long operations

3. **Connection Pooling**:
   - Database connection pools
   - HTTP connection reuse

## Deployment Architecture

### Docker Compose (Development)

```yaml
services:
  - frontend (React)
  - backend (FastAPI)
  - postgres (Database)
  - redis (Cache)
  - authentik-server (IAM)
  - authentik-worker (IAM Worker)
  - openldap (Directory)
  - nginx (Proxy)
```

### Kubernetes (Production - Future)

```
Namespaces:
  - kolaboree-app (Frontend, Backend)
  - kolaboree-data (PostgreSQL, Redis)
  - kolaboree-iam (Authentik, LDAP)

Ingress:
  - External load balancer
  - SSL/TLS termination
  - Path-based routing
```

## Network Architecture

### Internal Network (Docker)

```
Network: kolaboree-net (bridge)

Services:
  - frontend:80
  - backend:8000
  - postgres:5432
  - redis:6379
  - authentik-server:9000,9443
  - openldap:389,636
  - nginx:80,443 (exposed)
```

### External Access

- **Port 80**: HTTP (redirects to HTTPS in production)
- **Port 443**: HTTPS (Nginx SSL termination)
- **Port 8000**: Backend API (development only)
- **Port 9000/9443**: Authentik UI (admin access)

## Monitoring and Logging

### Logs

- **Backend**: Structured JSON logs via Uvicorn
- **Frontend**: Browser console and error tracking
- **Infrastructure**: Docker Compose logs
- **Aggregation**: Can integrate with ELK stack

### Metrics

- **API Performance**: Response times, error rates
- **Resource Usage**: CPU, memory, disk
- **Cloud Operations**: Connection status, API calls
- **User Activity**: Logins, workspace access

### Health Checks

- Backend: `/health` endpoint
- Frontend: Served by Nginx
- Database: PostgreSQL health check
- Cache: Redis PING command

## Future Enhancements

1. **Microservices Architecture**
   - Separate cloud connector services
   - Event-driven communication
   - Service mesh (Istio)

2. **Advanced Features**
   - WebSocket for real-time updates
   - GraphQL API option
   - Multi-tenancy support
   - Advanced RBAC

3. **Cloud-Native**
   - Kubernetes operators
   - Auto-scaling policies
   - Service discovery
   - Circuit breakers

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Apache Libcloud](https://libcloud.apache.org/)
- [React Documentation](https://react.dev/)
- [Material-UI](https://mui.com/)
- [Authentik](https://goauthentik.io/)
- [Docker Compose](https://docs.docker.com/compose/)
