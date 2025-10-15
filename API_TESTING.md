# 🔌 API Testing - Kolaboree Cloud Connections

## ⚠️ PREREQUISITO - TAILSCALE

**Este proyecto requiere Tailscale para comunicarse con proveedores cloud remotos.**

Antes de probar las conexiones:
1. ✅ Configura Tailscale (ver **[TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md)**)
2. ✅ Verifica que esté conectado:
   ```bash
   docker exec kolaboree-backend tailscale status
   ```

---

## ✅ Todo está listo para probar

### Método 1: Script Python Automatizado (RECOMENDADO)

```bash
python3 test-api-connections.py
```

Este script probará automáticamente LXD y GCP.

---

### Método 2: Interfaz Web

1. Abre: **http://localhost:3000**
2. Ve a "Add Cloud Connection"
3. Sigue la guía en: `QUICK_START_LXD.md`

---

### Método 3: curl + jq

#### Crear conexión LXD:

```bash
python3 <<'EOF'
import json

# Leer certificados
with open('credentials/lxd-client.crt') as f:
    cert = f.read()
with open('credentials/lxd-client.key') as f:
    key = f.read()

# Crear payload
payload = {
    "name": "LXC microcloud",
    "provider_type": "lxd",
    "credentials": {
        "endpoint": "https://100.94.245.27:8443",
        "cert": cert,
        "key": key,
        "verify": False
    }
}

# Guardar
with open('/tmp/lxd_payload.json', 'w') as f:
    json.dump(payload, f)
    
print("Payload creado en /tmp/lxd_payload.json")
EOF

# Enviar petición
curl -X POST http://localhost:8000/api/v1/admin/cloud_connections \
  -H "Content-Type: application/json" \
  -d @/tmp/lxd_payload.json | python3 -m json.tool
```

#### Listar conexiones:

```bash
curl http://localhost:8000/api/v1/admin/cloud_connections | python3 -m json.tool
```

#### Listar instancias (reemplaza CONNECTION_ID):

```bash
curl http://localhost:8000/api/v1/admin/cloud_connections/CONNECTION_ID/nodes \
  | python3 -m json.tool
```

---

## 📊 Ver Logs del Backend

```bash
docker logs -f kolaboree-backend
```

Busca estas líneas:
- `Connecting to LXD at https://100.94.245.27:8443 with certificates`
- `Testing LXD connection by listing instances...`
- `LXD connection successful!`

---

## 🔍 Troubleshooting

### Error: Connection refused
```bash
# Verifica que el backend esté corriendo
docker ps | grep kolaboree-backend

# Reinicia si es necesario
docker restart kolaboree-backend
```

### Error: Failed to connect to LXD
```bash
# PRIMERO: Verifica que Tailscale esté conectado en el backend
docker exec kolaboree-backend tailscale status

# Debe mostrar "connected" y listar dispositivos

# Verifica conectividad al servidor LXD via Tailscale
docker exec kolaboree-backend ping -c 3 100.94.245.27

# Verifica conectividad HTTPS
docker exec kolaboree-backend curl -k https://100.94.245.27:8443

# Si Tailscale no está conectado, ver TAILSCALE_SETUP.md
```

### Ver documentación interactiva
```bash
# Abre en el navegador
xdg-open http://localhost:8000/docs
# o
firefox http://localhost:8000/docs
```

---

## ✅ Respuesta Exitosa

```json
{
  "id": "abc-123-uuid",
  "name": "LXC microcloud",
  "provider_type": "lxd",
  "status": "connected",
  "created_at": "2025-10-14T...",
  "last_checked": "2025-10-14T..."
}
```

¡Ahora puedes ver tus instancias en la interfaz web!
