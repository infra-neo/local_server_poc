# 🎯 Guía Rápida: Agregar Conexión LXD a Kolaboree

## ⚠️ REQUISITO PREVIO - TAILSCALE

**Este proyecto requiere Tailscale para comunicarse con servidores LXD remotos.**

Antes de continuar, asegúrate de:
1. ✅ Haber configurado Tailscale (ver **[TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md)**)
2. ✅ Verificar que Tailscale esté conectado:
   ```bash
   docker exec kolaboree-backend tailscale status
   ```
3. ✅ Poder hacer ping al servidor LXD:
   ```bash
   docker exec kolaboree-backend ping -c 3 100.94.245.27
   ```

---

## ✅ Estado Actual

- ✅ Certificado cliente generado
- ✅ Certificado agregado al servidor LXD (fingerprint: `7c8c6dce5f04`)
- ✅ Backend actualizado para manejar certificados PEM
- ✅ Servidor LXD accesible en: `https://100.94.245.27:8443`

---

## 📋 Pasos para Agregar la Conexión

### 1. Accede a la Interfaz Web

Abre tu navegador y ve a:
```
http://localhost/admin/cloud-connections
```

O directamente al frontend de desarrollo:
```
http://localhost:3000
```

### 2. Haz Click en "Add New Cloud Connection"

### 3. Selecciona el Proveedor

- **Provider**: Selecciona **"LXD"**
- Click en **"Next"**

### 4. Configura las Credenciales

Llena el formulario con estos datos:

#### Connection Name:
```
LXC microcloud
```

#### LXD Endpoint:
```
https://100.94.245.27:8443
```

#### Client Certificate:
Copia y pega **TODO** este contenido (incluye las líneas BEGIN/END):

```
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
```

#### Client Key:
Copia y pega **TODO** este contenido (incluye las líneas BEGIN/END):

```
-----BEGIN PRIVATE KEY-----
MIG2AgEAMBAGByqGSM49AgEGBSuBBAAiBIGeMIGbAgEBBDCcdY9W1tDtQ2VaWMGR
ncCIh8ifc8v19kEGF1+v0c0veXRe1PmEVe/Np6ByqHw+al6hZANiAATKol0kLfyI
1F/RpSq2atD+zoZzSw+XNeELv3XIeF7HUv+yaGKyJ/C0zOCDW2OGEFjHOm9Gu02G
0tikFlcVuGpRZVR4avRg7N3h2tjDkv2bvXoVEONGH/BEoRCqWPtq0og=
-----END PRIVATE KEY-----
```

### 5. Conecta

- Click en **"Next"**
- Click en **"Connect"**

---

## ✅ Verificación

Si todo funciona correctamente:

1. ✅ Verás un mensaje: **"Connection successful!"**
2. ✅ La conexión aparecerá en la lista de proveedores
3. ✅ Podrás ver las instancias LXD del servidor

---

## 🔧 Solución de Problemas

### Error: "Failed to connect"

**Posible causa 1**: El certificado no está bien copiado
- **Solución**: Asegúrate de copiar TODO el contenido, incluyendo las líneas `-----BEGIN...-----` y `-----END...-----`
- No debe haber espacios extras al inicio o final

**Posible causa 2**: Problema de red o Tailscale no conectado
- **Solución**: 
  ```bash
  # Verificar estado de Tailscale en el contenedor backend
  docker exec kolaboree-backend tailscale status
  
  # Si no está conectado, revisar la configuración
  # Ver TAILSCALE_SETUP.md para más detalles
  
  # Verificar conectividad al servidor LXD via Tailscale
  docker exec kolaboree-backend ping -c 3 100.94.245.27
  ```
- Si Tailscale no está configurado, ver **[TAILSCALE_SETUP.md](./TAILSCALE_SETUP.md)**
- Prueba conectividad HTTPS:
  ```bash
  docker exec kolaboree-backend curl -k https://100.94.245.27:8443
  ```

**Posible causa 3**: El backend necesita reiniciarse
- **Solución**: Reinicia el backend:
  ```bash
  docker restart kolaboree-backend
  ```

### Ver Logs del Backend

Para ver qué está pasando en el backend:

```bash
docker logs -f kolaboree-backend
```

Busca líneas que digan:
- `Connecting to LXD at https://100.94.245.27:8443 with certificates`
- `Testing LXD connection by listing instances...`
- `LXD connection successful!`

---

## 📊 Datos Alternativos

Si quieres copiar desde archivos locales:

```bash
# Mostrar certificado
cat credentials/lxd-client.crt

# Mostrar clave
cat credentials/lxd-client.key
```

---

## 🎉 Próximos Pasos

Una vez conectado:

1. **Ver instancias**: Deberías poder ver todas las instancias/contenedores LXD
2. **Gestionar**: Podrás iniciar, detener, y gestionar las instancias
3. **Agregar GCP**: También puedes agregar tu proveedor de GCP con el service account

---

## 📞 Ayuda Adicional

- **Documentación completa**: Ver `CLOUD_SETUP.md`
- **Script de prueba**: Ejecutar `python3 test-cloud-connections.py`
- **Logs en vivo**: `docker logs -f kolaboree-backend`

---

**Última actualización**: 2025-10-14  
**Fingerprint del certificado**: `7c8c6dce5f04`  
**Estado del servidor**: ✅ Certificado verificado en trust store
