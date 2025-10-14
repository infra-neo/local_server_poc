# 🔐 Configuración de Proveedores Cloud - Kolaboree

Este documento explica cómo configurar las conexiones a **LXD** y **GCP** para Kolaboree.

## 📁 Archivos Generados

```
/workspaces/local_server_poc/
├── credentials/
│   ├── lxd-client.crt          # Certificado cliente LXD
│   ├── lxd-client.key          # Clave privada cliente LXD
│   └── gcp-service-account.json # Service Account de GCP
├── setup-lxd-trust.sh          # Script para el servidor LXD
└── test-cloud-connections.py   # Script de prueba
```

---

## 🖥️  CONFIGURACIÓN LXD

### Paso 1: Agregar certificado en el servidor LXD

Ejecuta UNO de estos métodos:

#### Método A: SSH Manual (Recomendado)

```bash
# 1. Conéctate al servidor LXD
ssh neo@100.94.245.27

# 2. Ejecuta estos comandos en el servidor:
cat > /tmp/kolaboree-client.crt <<'EOF'
-----BEGIN CERTIFICATE-----
MIIByTCCAU6gAwIBAgIUTeZwZRNXdXOQa7vOTcvjcH2B2+owCgYIKoZIzj0EAwMw
GzEZMBcGA1UEAwwQa29sYWJvcmVlLWNsaWVudDAeFw0yNTEwMTQwOTM5MDVaFw0z
NTEwMTIwOTM5MDVaMBsxGTAXBgNVBAMMEGtvbGFib3JlZS1jbGllbnQwdjAQBgcq
hkjOPQIBBgUrgQQAIgNiAATKol0kLfyI1F/RpSq2atD+zoZzSw+XNeELv3XIeF7H
Uv+yaGKyJ/C0zOCDW2OGEFjHOm9Gu02G0tikFlcVuGpRZVR4avRg7N3h2tjDkv2b
vXoVEONGH/BEoRCqWPtq0oijUzBRMB0GA1UdDgQWBBQYEcnc448XsIEkuC3tIuKk
fxBzcTAfBgNVHSMEGDAWgBQYEcnc448XsIEkuC3tIuKkfxBzcTAPBgNVHRMBAf8E
BTADAQH/MAoGCCqGSM49BAMDA2kAMGYCMQDQVa1KFxqaqFbWKYtPoHO8b6Wgzy5n
ccDtIsf5zUUpNfYs5yWk8keED3nv44F/0q8CMQDp9MK4JPIQtR8Mf5qNX5HejHDk
8idFSJcOPcD7ENlPAAyuGc8DQT4tNrNpC+kPdcQ=
-----END CERTIFICATE-----
EOF

lxc config trust add /tmp/kolaboree-client.crt --name kolaboree-client

# 3. Verifica que se agregó
lxc config trust list
```

#### Método B: Usar el script automatizado

```bash
# Desde tu máquina local
scp setup-lxd-trust.sh neo@100.94.245.27:~/
ssh neo@100.94.245.27 'bash setup-lxd-trust.sh'
```

### Configuración en Kolaboree

Una vez agregado el certificado en el servidor, usa estos datos en la interfaz web:

- **Connection Name**: `LXC microcloud`
- **LXD Endpoint**: `https://100.94.245.27:8443`
- **Client Certificate**: Contenido de `credentials/lxd-client.crt`
- **Client Key**: Contenido de `credentials/lxd-client.key`

---

## ☁️  CONFIGURACIÓN GCP

### Información del Service Account

- **Project ID**: `fine-web-382122`
- **Service Account Email**: `fine-web-382122@appspot.gserviceaccount.com`
- **Archivo de credenciales**: `credentials/gcp-service-account.json`

### Configuración en Kolaboree

- **Connection Name**: `GCP fine-web`
- **Provider**: `Google Cloud Platform (GCP)`
- **Service Account JSON**: Contenido completo del archivo `credentials/gcp-service-account.json`
- **Region**: `us-central1-a` (o la que prefieras)

### Requisitos previos en GCP

1. **Habilitar API de Compute Engine**:
   ```bash
   gcloud services enable compute.googleapis.com --project=fine-web-382122
   ```

2. **Verificar permisos del Service Account**:
   - Debe tener el rol `Compute Engine Admin` o `Compute Viewer` como mínimo

---

## 🧪 PROBAR CONEXIONES

### Ejecutar script de prueba

```bash
# Desde el directorio del proyecto
python3 test-cloud-connections.py
```

Este script probará ambas conexiones y mostrará:
- ✅ Si la conexión es exitosa
- 📋 Lista de instancias disponibles
- ❌ Errores detallados si falla

### Prueba manual con curl

```bash
# Probar LXD (después de agregar el certificado)
curl -k -X GET https://100.94.245.27:8443/1.0/instances \
  --cert credentials/lxd-client.crt \
  --key credentials/lxd-client.key
```

---

## 🔧 SOLUCIÓN DE PROBLEMAS

### LXD: Error 403 Forbidden

**Problema**: El certificado no está en el trust del servidor.

**Solución**:
1. Ejecuta el Paso 1 de configuración LXD
2. Verifica con: `lxc config trust list` en el servidor

### LXD: Connection refused

**Problema**: El servidor LXD no está escuchando en esa IP/puerto.

**Solución**:
```bash
# En el servidor LXD, verifica la configuración
lxc config get core.https_address
# Debería mostrar: [::]

# Si no, configúralo:
lxc config set core.https_address [::]:8443
```

### GCP: Authentication failed

**Problema**: Las credenciales del service account son inválidas o no tienen permisos.

**Solución**:
1. Verifica que el archivo JSON sea correcto
2. Verifica permisos: https://console.cloud.google.com/iam-admin/iam
3. Habilita la API de Compute Engine

### GCP: No instances found

**Problema**: No hay instancias en la región especificada.

**Solución**:
- Crea una instancia de prueba en GCP
- O cambia la región a una que tenga instancias

---

## 📝 SIGUIENTE PASO: USAR EN KOLABOREE

1. **Inicia el backend**:
   ```bash
   cd backend
   source venv/bin/activate
   uvicorn app.main:app --reload
   ```

2. **Accede a la interfaz web**: http://localhost:3000

3. **Agrega los proveedores**:
   - Ve al panel de administración
   - Click en "Add Cloud Provider"
   - Llena el formulario con los datos de arriba
   - Guarda y prueba la conexión

4. **Visualiza las instancias**:
   - Deberías ver las instancias de LXD y GCP en el dashboard

---

## 📋 CREDENCIALES DE ACCESO

### Servidor LXD
- **IP**: 100.94.245.27 (via Tailscale)
- **Usuario**: neo
- **Password**: C0mplicad0$
- **Puerto LXD**: 8443

### GCP
- **Project ID**: fine-web-382122
- **Service Account**: fine-web-382122@appspot.gserviceaccount.com
- **Credenciales**: `credentials/gcp-service-account.json`

---

## 🔒 SEGURIDAD

⚠️ **IMPORTANTE**: Los archivos en `credentials/` contienen información sensible.

```bash
# Asegúrate de que estén en .gitignore
echo "credentials/" >> .gitignore

# Protege los archivos
chmod 600 credentials/*
```

**NO** subas estos archivos a repositorios públicos.

---

## ✅ CHECKLIST

- [ ] Certificado LXD agregado al servidor
- [ ] Script de prueba ejecutado exitosamente
- [ ] LXD muestra instancias correctamente
- [ ] GCP muestra instancias correctamente
- [ ] Proveedores agregados en la interfaz web de Kolaboree
- [ ] Archivos de credenciales protegidos y en .gitignore

---

**¿Necesitas ayuda?** Revisa los logs del backend o ejecuta el script de prueba con más verbosidad.
