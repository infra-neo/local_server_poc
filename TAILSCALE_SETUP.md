# 🔗 Tailscale Integration - Kolaboree NG

## ⚠️ IMPORTANTE / IMPORTANT

**Este proyecto SIEMPRE debe usar la conexión por Tailscale para poder comunicarse con las otras nubes.**

**This project MUST ALWAYS use Tailscale connection to communicate with other clouds.**

---

## 📋 Overview

Kolaboree NG requires Tailscale to securely connect to remote LXD servers and other cloud infrastructure. Tailscale provides:

- 🔐 **Secure VPN connectivity** - End-to-end encrypted connections
- 🌐 **Mesh networking** - Direct peer-to-peer connections between devices
- 🚀 **Easy setup** - No complex firewall configuration needed
- 📍 **Stable IPs** - Consistent IP addresses (100.x.x.x range)

---

## 🚀 Quick Start

### 1. Get Tailscale Auth Key

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Click **"Generate auth key"**
3. Configure the key:
   - ✅ **Reusable** - Check this option
   - ✅ **Ephemeral** - Uncheck (we want persistent connection)
   - **Expiration** - Set to a reasonable time (90 days recommended)
4. Copy the generated key (starts with `tskey-auth-`)

### 2. Configure Kolaboree

Add the Tailscale auth key to your `.env` file:

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and add your Tailscale auth key
nano .env
```

Add this line:
```bash
TAILSCALE_AUTH_KEY=tskey-auth-xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Start Kolaboree

```bash
# Start all services
docker compose up -d

# Check backend logs to verify Tailscale connection
docker logs kolaboree-backend
```

You should see:
```
🔗 Kolaboree Backend - Starting with Tailscale
Starting Tailscale daemon...
Authenticating with Tailscale...
✅ Tailscale connected successfully!
```

---

## 🔍 Verify Tailscale Connection

### Check Tailscale Status

```bash
# Enter the backend container
docker exec -it kolaboree-backend bash

# Check Tailscale status
tailscale status

# Check your Tailscale IP
tailscale ip -4
```

### Test Connectivity to LXD Server

```bash
# Ping the LXD server via Tailscale
docker exec kolaboree-backend ping -c 3 100.94.245.27

# Test HTTPS connection to LXD
docker exec kolaboree-backend curl -k https://100.94.245.27:8443
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Tailscale Network                        │
│                    (100.x.x.x IP range)                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐           ┌───────────────────┐      │
│  │ Kolaboree Backend│◄─────────►│  LXD Server       │      │
│  │ (Docker)         │  Secure   │  100.94.245.27    │      │
│  │ Tailscale Client │  Tunnel   │  Port 8443        │      │
│  └──────────────────┘           └───────────────────┘      │
│                                                              │
│  ┌──────────────────┐           ┌───────────────────┐      │
│  │ Your Workstation │◄─────────►│  Other Clouds     │      │
│  │ (Optional)       │           │  (Future)         │      │
│  └──────────────────┘           └───────────────────┘      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Configuration Details

### Docker Container Requirements

The backend container needs special capabilities to run Tailscale:

```yaml
services:
  backend:
    cap_add:
      - NET_ADMIN  # Required for network configuration
      - NET_RAW    # Required for raw socket access
    devices:
      - /dev/net/tun:/dev/net/tun  # TUN device for VPN
    sysctls:
      - net.ipv4.ip_forward=1      # Enable IP forwarding
      - net.ipv6.conf.all.forwarding=1
```

### Persistent State

Tailscale state is persisted in a Docker volume:

```yaml
volumes:
  - tailscale_state:/var/lib/tailscale
```

This ensures the Tailscale connection persists across container restarts.

---

## 🔧 Troubleshooting

### Problem: Tailscale not starting

**Symptoms:**
```
Error: tailscaled not running
```

**Solutions:**

1. Check that the container has the required capabilities:
   ```bash
   docker inspect kolaboree-backend | grep -A 10 CapAdd
   ```

2. Verify `/dev/net/tun` device exists:
   ```bash
   docker exec kolaboree-backend ls -la /dev/net/tun
   ```

3. Check container logs:
   ```bash
   docker logs kolaboree-backend
   ```

### Problem: Authentication failed

**Symptoms:**
```
Error: authentication failed
```

**Solutions:**

1. Verify the auth key is correct in `.env`
2. Generate a new auth key from [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
3. Make sure the key is marked as **Reusable**
4. Restart the backend:
   ```bash
   docker compose restart backend
   ```

### Problem: Cannot reach LXD server

**Symptoms:**
```
Connection refused to 100.94.245.27:8443
```

**Solutions:**

1. Check Tailscale is connected:
   ```bash
   docker exec kolaboree-backend tailscale status
   ```

2. Verify the LXD server is in your Tailscale network:
   ```bash
   docker exec kolaboree-backend tailscale ping 100.94.245.27
   ```

3. Check LXD server is running and accessible:
   ```bash
   docker exec kolaboree-backend curl -k https://100.94.245.27:8443
   ```

4. Verify the LXD server is accepting connections on the Tailscale interface

### Problem: Tailscale connects but loses connection

**Symptoms:**
- Tailscale shows connected but cannot reach resources
- Intermittent connectivity

**Solutions:**

1. Check if `--accept-routes` flag is set in the entrypoint script
2. Verify subnet routes are advertised by the LXD server in Tailscale admin
3. Restart Tailscale:
   ```bash
   docker exec kolaboree-backend tailscale down
   docker exec kolaboree-backend tailscale up --authkey="$TAILSCALE_AUTH_KEY"
   ```

---

## 🔐 Security Best Practices

### Auth Key Management

- ✅ **Use reusable keys** for production deployments
- ✅ **Set expiration dates** on auth keys (90 days recommended)
- ✅ **Store keys securely** - Never commit to git
- ✅ **Rotate keys regularly** - Generate new keys periodically
- ❌ **Don't share keys** - Each deployment should have its own key

### Network Security

- ✅ **Use ACLs** in Tailscale to restrict which devices can communicate
- ✅ **Enable MagicDNS** for easier service discovery
- ✅ **Monitor connections** in Tailscale admin console
- ✅ **Use subnet routing** for accessing specific networks

---

## 📚 Additional Resources

### Tailscale Documentation
- [Getting Started](https://tailscale.com/kb/1017/install/)
- [Auth Keys](https://tailscale.com/kb/1085/auth-keys/)
- [Docker Guide](https://tailscale.com/kb/1282/docker/)
- [ACLs](https://tailscale.com/kb/1018/acls/)

### Kolaboree Documentation
- [CLOUD_SETUP.md](./CLOUD_SETUP.md) - Cloud provider configuration
- [QUICK_START_LXD.md](./QUICK_START_LXD.md) - LXD quick start guide
- [API_TESTING.md](./API_TESTING.md) - API testing guide

---

## ✅ Checklist

Before connecting to remote clouds:

- [ ] Tailscale account created
- [ ] Auth key generated and added to `.env`
- [ ] Backend container started with Tailscale
- [ ] Tailscale shows "connected" status
- [ ] Can ping LXD server (100.94.245.27)
- [ ] Can curl LXD API endpoint
- [ ] LXD connection works in Kolaboree UI

---

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review container logs: `docker logs kolaboree-backend`
3. Check Tailscale admin console: https://login.tailscale.com/admin/machines
4. Verify network connectivity inside container
5. Check this project's issues on GitHub

---

**Remember:** This project requires Tailscale to be running for communication with remote cloud providers. Always ensure Tailscale is connected before attempting to manage cloud resources.

**Recuerda:** Este proyecto requiere que Tailscale esté ejecutándose para la comunicación con proveedores de nube remotos. Siempre asegúrate de que Tailscale esté conectado antes de intentar gestionar recursos en la nube.
