# Kolaboree NG - Quick Demo & Examples

This file contains example API calls and usage scenarios for testing Kolaboree NG.

## Quick API Testing

### 1. Health Check

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "kolaboree-ng-backend"
}
```

### 2. API Documentation

Open in browser: http://localhost:8000/docs

This provides interactive Swagger UI for testing all endpoints.

## Admin Dashboard Examples

### Create Cloud Connection (Placeholder)

You can test with placeholder providers that return demo data:

```bash
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo AWS Account",
    "provider_type": "aws",
    "credentials": {},
    "region": "us-east-1"
  }'
```

### List All Cloud Connections

```bash
curl http://localhost:8000/api/v1/admin/cloud_connections
```

### List Nodes for a Connection

```bash
# Replace {connection_id} with actual ID from previous response
curl http://localhost:8000/api/v1/admin/cloud_connections/{connection_id}/nodes
```

## Real Cloud Provider Examples

### GCP (Fully Functional)

**Prerequisites:**
- GCP service account with Compute Engine permissions
- Service account JSON key file

**Create Connection:**
```bash
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections \
  -H "Content-Type: application/json" \
  -d @- << 'EOF'
{
  "name": "Production GCP",
  "provider_type": "gcp",
  "region": "us-central1-a",
  "credentials": {
    "service_account_json": "{
      \"type\": \"service_account\",
      \"project_id\": \"your-project-id\",
      \"private_key_id\": \"...\",
      \"private_key\": \"...\",
      \"client_email\": \"...\",
      \"client_id\": \"...\",
      \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",
      \"token_uri\": \"https://oauth2.googleapis.com/token\",
      \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",
      \"client_x509_cert_url\": \"...\"
    }"
  }
}
EOF
```

### LXD (Fully Functional)

**Prerequisites:**
- LXD installed and running
- LXD API accessible

**Local LXD Connection:**
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

**Remote LXD with Certificates:**
```bash
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Remote LXD Server",
    "provider_type": "lxd",
    "credentials": {
      "endpoint": "https://lxd-server.example.com:8443",
      "cert": "/path/to/client.crt",
      "key": "/path/to/client.key",
      "verify": false
    }
  }'
```

## User Dashboard Examples

### Get User Workspaces

```bash
curl http://localhost:8000/api/v1/user/my_workspaces
```

Expected response (demo data):
```json
[
  {
    "id": "ws-1",
    "name": "Development Environment",
    "status": "online",
    "connection_url": "https://workspace1.example.com",
    "node": {
      "id": "demo-vm-1",
      "name": "dev-vm-001",
      "state": "running",
      "provider_type": "gcp",
      "connection_id": "demo",
      "ip_addresses": ["10.0.1.100"],
      "cpu_count": 4,
      "memory_mb": 8192
    }
  }
]
```

## Frontend Testing Scenarios

### Admin Dashboard Workflow

1. **Access Admin View**
   - Open http://localhost (or configured port)
   - Click "⚙️ Admin View" tab

2. **Add Cloud Connection**
   - Click "Add Cloud Connection" button
   - Select provider from dropdown
   - Fill in credentials
   - Click through wizard steps
   - Submit and verify connection appears

3. **View Nodes**
   - Click "View Nodes" on a connection card
   - Verify nodes are listed in the dialog

### User Dashboard Workflow

1. **Access User View**
   - Open http://localhost
   - Click "👤 User View" tab

2. **View Workspaces**
   - Verify workspace cards are displayed
   - Check online/offline status badges
   - Verify resource information is shown

3. **Connect to Workspace**
   - Click "Connect" on an online workspace
   - (Currently shows placeholder URL)

## Python API Client Example

```python
import requests

BASE_URL = "http://localhost:8000"

# Create a connection
response = requests.post(
    f"{BASE_URL}/api/v1/admin/cloud_connections",
    json={
        "name": "Demo Provider",
        "provider_type": "aws",
        "credentials": {},
        "region": "us-east-1"
    }
)
connection = response.json()
print(f"Created connection: {connection['id']}")

# List all connections
response = requests.get(f"{BASE_URL}/api/v1/admin/cloud_connections")
connections = response.json()
print(f"Total connections: {len(connections)}")

# Get nodes for a connection
connection_id = connection['id']
response = requests.get(
    f"{BASE_URL}/api/v1/admin/cloud_connections/{connection_id}/nodes"
)
nodes = response.json()
print(f"Nodes: {nodes}")
```

## JavaScript/Axios Example

```javascript
import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000';

// Create a connection
async function createConnection() {
  const response = await axios.post(
    `${API_BASE_URL}/api/v1/admin/cloud_connections`,
    {
      name: 'Demo Provider',
      provider_type: 'aws',
      credentials: {},
      region: 'us-east-1'
    }
  );
  return response.data;
}

// List connections
async function listConnections() {
  const response = await axios.get(
    `${API_BASE_URL}/api/v1/admin/cloud_connections`
  );
  return response.data;
}

// Get nodes
async function getNodes(connectionId) {
  const response = await axios.get(
    `${API_BASE_URL}/api/v1/admin/cloud_connections/${connectionId}/nodes`
  );
  return response.data;
}

// Usage
(async () => {
  const connection = await createConnection();
  console.log('Created:', connection);
  
  const connections = await listConnections();
  console.log('All connections:', connections);
  
  const nodes = await getNodes(connection.id);
  console.log('Nodes:', nodes);
})();
```

## Testing with Different Providers

### Test All Placeholder Providers

```bash
# Create connections for all providers
for provider in aws azure digitalocean vultr alibaba oracle huawei; do
  curl -X POST http://localhost:8000/api/v1/admin/cloud_connections \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"Demo $provider\",
      \"provider_type\": \"$provider\",
      \"credentials\": {}
    }"
  sleep 1
done

# List all connections
curl http://localhost:8000/api/v1/admin/cloud_connections | jq
```

## Performance Testing

### Basic Load Test

```bash
# Install Apache Bench if not available
# Ubuntu/Debian: apt-get install apache2-utils
# macOS: brew install httpd

# Run 1000 requests with 10 concurrent connections
ab -n 1000 -c 10 http://localhost:8000/health

# With authentication (when implemented)
ab -n 1000 -c 10 -H "Authorization: Bearer YOUR_TOKEN" \
   http://localhost:8000/api/v1/user/my_workspaces
```

## Cleanup

### Delete All Connections

```bash
# Get all connection IDs and delete them
curl http://localhost:8000/api/v1/admin/cloud_connections | \
  jq -r '.[].id' | \
  while read id; do
    curl -X DELETE http://localhost:8000/api/v1/admin/cloud_connections/$id
  done
```

## Troubleshooting Examples

### Check if Backend is Running

```bash
curl -f http://localhost:8000/health && echo "Backend is healthy" || echo "Backend is down"
```

### Test CORS

```bash
curl -X OPTIONS http://localhost:8000/api/v1/admin/cloud_connections \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

### View API Schema

```bash
curl http://localhost:8000/openapi.json | jq
```

## Next Steps

After testing the examples:
1. Try with real cloud credentials (GCP or LXD)
2. Implement additional cloud provider connectors
3. Add authentication and authorization
4. Set up monitoring and logging
5. Configure SSL/TLS for production
