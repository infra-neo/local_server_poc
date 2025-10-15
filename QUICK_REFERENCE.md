# Kolaboree NG - Quick Reference Guide

Quick reference for common tasks and commands.

## 🚀 Quick Start

```bash
# 1. Clone and setup
git clone https://github.com/infra-neo/local_server_poc.git
cd local_server_poc

# 2. Configure
cp .env.example .env
nano .env  # Change all passwords!

# IMPORTANT: Add Tailscale auth key for remote cloud access
# Get it from: https://login.tailscale.com/admin/settings/keys
# Add to .env: TAILSCALE_AUTH_KEY=tskey-auth-...

# 3. Start
bash scripts/start.sh

# 4. Access
open http://localhost
```

## 📋 Common Commands

### Start/Stop

```bash
# Start all services
bash scripts/start.sh
# or
docker compose up -d

# Stop all services
bash scripts/stop.sh
# or
docker compose down

# Restart a specific service
docker compose restart backend

# Rebuild and restart
docker compose up -d --build
```

### Logs

```bash
# View all logs
docker compose logs -f

# View specific service
docker compose logs -f backend
docker compose logs -f frontend

# Last 100 lines
docker compose logs --tail=100 backend
```

### Status

```bash
# Check service status
docker compose ps

# Check service health
docker compose ps --format "table {{.Service}}\t{{.Status}}"

# Resource usage
docker stats
```

## 🔧 Development

### Backend Development

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Access: http://localhost:8000/docs

### Frontend Development

```bash
cd frontend
npm install
npm start
```

Access: http://localhost:3000

## 🌐 URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Main App | http://localhost | Web interface |
| Backend API | http://localhost:8000 | REST API |
| API Docs | http://localhost:8000/docs | Swagger UI |
| Authentik | http://localhost:9000 | IAM/SSO |
| PostgreSQL | localhost:5432 | Database |
| Redis | localhost:6379 | Cache |
| OpenLDAP | ldap://localhost:389 | Directory |

## 📡 API Quick Reference

### Admin Endpoints

```bash
# Create connection
POST /api/v1/admin/cloud_connections

# List connections
GET /api/v1/admin/cloud_connections

# Get connection
GET /api/v1/admin/cloud_connections/{id}

# List nodes
GET /api/v1/admin/cloud_connections/{id}/nodes

# Delete connection
DELETE /api/v1/admin/cloud_connections/{id}
```

### User Endpoints

```bash
# Get workspaces
GET /api/v1/user/my_workspaces
```

## 🔐 Default Credentials

**⚠️ Change these in .env!**

| Service | Username | Password | Location |
|---------|----------|----------|----------|
| PostgreSQL | kolaboree | CHANGEME_SECURE_PASSWORD | .env |
| Redis | - | CHANGEME_REDIS_PASSWORD | .env |
| OpenLDAP | admin | CHANGEME_LDAP_PASSWORD | .env |
| Authentik | Set during first login | - | UI |

## 🐛 Troubleshooting

### Service won't start

```bash
# Check logs
docker compose logs <service-name>

# Check if port is in use
sudo lsof -i :80
sudo lsof -i :8000

# Remove old containers
docker compose down
docker compose up -d
```

### Database issues

```bash
# Reset database (⚠️ DELETES DATA)
docker compose down -v
docker compose up -d

# Access database
docker compose exec postgres psql -U kolaboree -d kolaboree
```

### Backend errors

```bash
# Check Python syntax
cd backend
python3 -m py_compile app/main.py

# Check dependencies
pip install -r requirements.txt

# View logs
docker compose logs -f backend
```

### Tailscale issues

```bash
# Run comprehensive health check
bash scripts/check-tailscale.sh

# Check if Tailscale is running
docker exec kolaboree-backend pgrep tailscaled

# Check Tailscale status
docker exec kolaboree-backend tailscale status

# View Tailscale logs
docker logs kolaboree-backend | grep -i tailscale

# Restart backend with Tailscale
docker compose restart backend

# Test LXD server connectivity via Tailscale
docker exec kolaboree-backend ping -c 3 100.94.245.27
docker exec kolaboree-backend curl -k https://100.94.245.27:8443

# For detailed help, see:
# - TAILSCALE_SETUP.md
# - CLOUD_SETUP.md
```

### Frontend errors

```bash
# Clear node_modules
cd frontend
rm -rf node_modules package-lock.json
npm install

# Check for errors
npm run build

# View logs
docker compose logs -f frontend
```

## 🔄 Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild services
docker compose down
docker compose up -d --build

# Clean rebuild
docker compose down -v
docker system prune -a
docker compose up -d --build
```

## 🗄️ Data Management

### Backup

```bash
# Backup PostgreSQL
docker compose exec postgres pg_dump -U kolaboree kolaboree > backup.sql

# Backup volumes
docker run --rm \
  -v local_server_poc_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup.tar.gz -C /data .
```

### Restore

```bash
# Restore PostgreSQL
cat backup.sql | docker compose exec -T postgres psql -U kolaboree kolaboree

# Restore volumes
docker run --rm \
  -v local_server_poc_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/postgres_backup.tar.gz -C /data
```

## 🔍 Monitoring

### Check Service Health

```bash
# Backend health (includes Tailscale status)
curl http://localhost:8000/health

# Check Tailscale connectivity (comprehensive)
bash scripts/check-tailscale.sh

# Frontend
curl -I http://localhost

# PostgreSQL
docker compose exec postgres pg_isready -U kolaboree

# Redis
docker compose exec redis redis-cli ping

# Tailscale status in backend
docker exec kolaboree-backend tailscale status
```

### Resource Usage

```bash
# Container stats
docker stats

# Disk usage
docker system df

# Volume sizes
docker volume ls -q | xargs docker volume inspect \
  | grep Mountpoint | awk '{print $2}' \
  | xargs du -sh
```

## 📦 Environment Variables

### Essential Variables

```bash
# Database
POSTGRES_DB=kolaboree
POSTGRES_USER=kolaboree
POSTGRES_PASSWORD=<change-me>

# Redis
REDIS_PASSWORD=<change-me>

# Authentik
AUTHENTIK_SECRET_KEY=<50-chars-minimum>

# LDAP
LDAP_ADMIN_PASSWORD=<change-me>
```

### Port Configuration

```bash
BACKEND_PORT=8000
FRONTEND_PORT=3000
NGINX_PORT=80
NGINX_HTTPS_PORT=443
AUTHENTIK_PORT_HTTP=9000
AUTHENTIK_PORT_HTTPS=9443
```

## 🧪 Testing

### Quick Validation

```bash
bash scripts/validate.sh
```

### API Testing

```bash
# Health check
curl http://localhost:8000/health

# Create test connection
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","provider_type":"aws","credentials":{}}'

# List connections
curl http://localhost:8000/api/v1/admin/cloud_connections
```

### Load Testing

```bash
# Install ab (Apache Bench)
apt-get install apache2-utils

# Run test
ab -n 1000 -c 10 http://localhost:8000/health
```

## 📚 Documentation Files

- `README.md` - Main documentation
- `ARCHITECTURE.md` - System architecture
- `TESTING.md` - Testing guidelines
- `CONTRIBUTING.md` - Contribution guide
- `EXAMPLES.md` - API examples
- `CHANGELOG.md` - Version history
- `QUICK_REFERENCE.md` - This file

## 🆘 Getting Help

- **Issues**: https://github.com/infra-neo/local_server_poc/issues
- **Discussions**: https://github.com/infra-neo/local_server_poc/discussions
- **Documentation**: See README.md

## ⚡ Tips & Tricks

### Speed up rebuilds

```bash
# Build specific service
docker compose build backend

# No cache rebuild
docker compose build --no-cache backend

# Parallel builds
docker compose build --parallel
```

### Development workflow

```bash
# Frontend only (React dev server)
cd frontend && npm start

# Backend only (with hot reload)
cd backend && uvicorn app.main:app --reload

# Full stack with logs
docker compose up --build && docker compose logs -f
```

### Clean environment

```bash
# Remove all containers and volumes
docker compose down -v

# Remove all images
docker compose down --rmi all

# Full cleanup
docker system prune -a --volumes
```

## 🎯 Next Steps

1. ✅ Platform is running
2. ⚙️ Configure Authentik and LDAP
3. 🔌 Add real cloud credentials
4. 👥 Create users and assign permissions
5. 🔒 Enable SSL/TLS
6. 📊 Set up monitoring
7. 🚀 Deploy to production

---

**Last Updated**: 2025-10-10
**Version**: 1.0.0
