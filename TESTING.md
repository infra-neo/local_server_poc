# Kolaboree NG - Testing Guide

This document provides guidance on testing the Kolaboree NG platform.

## Quick Validation

Run the validation script to check if all files are in place:

```bash
bash scripts/validate.sh
```

This will verify:
- Backend structure and files
- Frontend structure and files
- Infrastructure configuration
- Python syntax
- Docker Compose configuration

### Tailscale Connectivity Check

**⚠️ IMPORTANT**: Tailscale is required for connecting to remote cloud providers.

Run the Tailscale health check:

```bash
bash scripts/check-tailscale.sh
```

This comprehensive check verifies:
- Backend container is running
- Tailscale is installed
- TAILSCALE_AUTH_KEY is configured
- Tailscale daemon is running
- Tailscale is connected to the network
- LXD server (100.94.245.27) is reachable
- Health endpoint includes Tailscale status

For detailed Tailscale setup, see [TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md).

## Testing Components

### Backend API

The backend can be tested locally without Docker:

```bash
cd backend

# Create a virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn app.main:app --reload --port 8000
```

Then access:
- API: http://localhost:8000
- API Documentation: http://localhost:8000/docs
- Health Check: http://localhost:8000/health

### Testing Cloud Connections

#### GCP Testing

To test GCP connectivity, you need:
1. A Google Cloud service account with Compute Engine permissions
2. The service account JSON key file

Example API call:
```bash
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My GCP Project",
    "provider_type": "gcp",
    "region": "us-central1-a",
    "credentials": {
      "service_account_json": "{ ... your service account JSON ... }"
    }
  }'
```

#### LXD Testing

**⚠️ PREREQUISITE**: Tailscale must be connected to access remote LXD servers.

To test LXD connectivity:
1. Ensure Tailscale is configured and connected (see [TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md))
2. Verify LXD server is accessible via Tailscale:
   ```bash
   docker exec kolaboree-backend ping -c 3 100.94.245.27
   docker exec kolaboree-backend curl -k https://100.94.245.27:8443
   ```
3. Ensure you have LXD client certificates

Example API call:
```bash
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Local LXD",
    "provider_type": "lxd",
    "credentials": {
      "endpoint": "https://localhost:8443"
    }
  }'
```

### Frontend Development

The frontend can be tested locally:

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm start
```

Access at http://localhost:3000

### Full Stack Testing

To test the complete platform with Docker Compose:

```bash
# Start all services
bash scripts/start.sh

# Or manually
cp .env.example .env
# Edit .env with your configuration
docker compose up -d

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

## API Endpoints Reference

### Admin Endpoints

- `POST /api/v1/admin/cloud_connections` - Create a cloud connection
- `GET /api/v1/admin/cloud_connections` - List all connections
- `GET /api/v1/admin/cloud_connections/{id}` - Get connection details
- `GET /api/v1/admin/cloud_connections/{id}/nodes` - List nodes for a connection
- `DELETE /api/v1/admin/cloud_connections/{id}` - Delete a connection

### User Endpoints

- `GET /api/v1/user/my_workspaces` - Get user's workspaces

## Testing Checklist

- [ ] Backend starts without errors
- [ ] Frontend builds successfully
- [ ] API documentation is accessible
- [ ] **Tailscale is installed in backend container**
- [ ] **Tailscale daemon is running**
- [ ] **Tailscale is connected (if auth key provided)**
- [ ] **Can ping LXD server via Tailscale (100.94.245.27)**
- [ ] **Health endpoint includes Tailscale status**
- [ ] Can create a cloud connection (placeholder)
- [ ] Can list cloud connections
- [ ] Can view nodes for a connection
- [ ] User dashboard displays workspaces
- [ ] Admin dashboard displays connections
- [ ] Wizard flow works for adding connections
- [ ] PostgreSQL is accessible
- [ ] Redis is accessible
- [ ] Authentik initializes correctly
- [ ] OpenLDAP is accessible

**Note**: Items in **bold** are Tailscale-related tests added as part of the requirement that this project always uses Tailscale for cloud communication.

## Troubleshooting Tests

### Tailscale not connecting
- Check TAILSCALE_AUTH_KEY is set in .env
- Verify auth key is valid (not expired)
- Check container has NET_ADMIN capability
- Verify /dev/net/tun device is available
- Run: `bash scripts/check-tailscale.sh`
- See: [TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md)

### Backend won't start
- Check Python version (3.11+)
- Verify all dependencies are installed
- Check for import errors in logs

### Frontend build fails
- Verify Node.js version (18+)
- Clear node_modules and reinstall: `rm -rf node_modules && npm install`
- Check for syntax errors in JSX files

### Docker Compose fails
- Verify Docker and Docker Compose are installed
- Check .env file exists and is properly configured
- Ensure ports are not already in use
- Check Docker daemon is running

### API returns errors
- Check backend logs: `docker compose logs backend`
- Verify database connection
- Check Redis connection
- Ensure environment variables are set correctly

## Performance Testing

For load testing the API:

```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:8000/health

# Using wrk
wrk -t12 -c400 -d30s http://localhost:8000/health
```

## Security Testing

- Verify all default passwords are changed in .env
- Check that Authentik requires authentication
- Verify CORS is properly configured
- Test API endpoints require appropriate permissions
- Ensure sensitive data is not logged

## Next Steps

After testing:
1. Review logs for any warnings or errors
2. Test with real cloud credentials
3. Configure Authentik and LDAP properly
4. Set up SSL/TLS for production
5. Configure backup procedures
6. Set up monitoring and alerting
