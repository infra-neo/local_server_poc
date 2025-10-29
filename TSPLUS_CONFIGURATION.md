# Configuración de TSPlus Endpoint

## Descripción

TSPlus es el endpoint de escritorio remoto al que se accede a través de la red Headscale. Puede ser:
- Un servidor Ubuntu bare metal
- Un servidor en IP pública: `201.151.150.226`

## Acceso via Headscale

### MagicDNS

Headscale proporciona resolución automática de nombres a través de MagicDNS:

```
tsplus.hs.kappa4.com → 201.151.150.226
```

Los contenedores pueden usar este nombre en lugar de la IP directa.

## Configuración en Guacamole

### 1. Crear Conexión RDP Manual

1. Acceder a Guacamole: `https://gate.kappa4.com/guacamole/`
2. Login con Authentik SSO
3. Ir a Settings → Connections → New Connection
4. Configurar:

```
Name: TSPlus Ubuntu Server
Location: ROOT
Protocol: RDP

Parameters:
  Network:
    - Hostname: tsplus.hs.kappa4.com (o 201.151.150.226)
    - Port: 3389
  
  Authentication:
    - Username: (usuario de TSPlus)
    - Password: (contraseña de TSPlus)
    - Domain: (si aplica)
  
  Display:
    - Color depth: True color (24-bit)
    - Resolution: 1920x1080
  
  Performance:
    - Enable wallpaper: false
    - Enable theming: false
    - Enable font smoothing: true
    - Enable full window drag: false
```

### 2. Crear Conexión via Authentik RAC

El Authentik RAC Outpost puede configurarse para proporcionar acceso proxy a TSPlus:

1. En Authentik Admin: Applications → Create Application
2. Crear Provider tipo RAC
3. Configurar:

```yaml
Name: TSPlus RAC Provider
Type: RAC
Protocol: RDP

Configuration:
  - Target: tsplus.hs.kappa4.com:3389 (o 201.151.150.226:3389)
  - Username Template: User's username
  - Enable connection sharing: Yes
```

4. Crear Application:

```yaml
Name: TSPlus Remote Desktop
Provider: TSPlus RAC Provider
Slug: tsplus
Launch URL: Auto-generated
```

5. Asignar permisos a usuarios/grupos que deben tener acceso

## Configuración del Outpost

El contenedor `authentik-outpost` ya está configurado con las variables de entorno necesarias:

```yaml
AUTHENTIK_HOST: http://authentik-server:9000
AUTHENTIK_HOST_BROWSER: https://gate.kappa4.com
AUTHENTIK_TOKEN: ${AUTHENTIK_OUTPOST_TOKEN}
TSPLUS_ENDPOINT: ${TSPLUS_ENDPOINT:-201.151.150.226}
TSPLUS_PORT: ${TSPLUS_PORT:-3389}
```

### Obtener el Token del Outpost

1. En Authentik Admin: System → Outposts
2. Click en el outpost RAC
3. Copiar el token mostrado
4. Agregar a `.env`:

```bash
AUTHENTIK_OUTPOST_TOKEN=tu_token_aqui
```

5. Reiniciar el outpost:

```bash
docker-compose -f docker-compose.preproduccion.yml restart authentik-outpost
```

## Verificación de Conectividad

### Desde un contenedor dentro de Headscale

```bash
# Test ping via MagicDNS
docker exec kolaboree-guacamole ping -c 3 tsplus.hs.kappa4.com

# Test RDP port
docker exec kolaboree-guacamole nc -zv tsplus.hs.kappa4.com 3389
```

### Desde el host (si tiene Headscale instalado)

```bash
# Ping
ping tsplus.hs.kappa4.com

# Test RDP
nc -zv 201.151.150.226 3389
```

## Troubleshooting

### No se puede conectar a TSPlus

1. Verificar que TSPlus esté en la red Headscale:
   ```bash
   docker exec headscale-server headscale nodes list
   ```

2. Verificar reglas de ACL en `headscale/acl.yaml`:
   ```yaml
   - action: accept
     src:
       - guacamole.hs.kappa4.com
     dst:
       - tsplus:3389
   ```

3. Verificar que el puerto 3389 esté abierto en TSPlus:
   ```bash
   # Desde el servidor TSPlus
   netstat -tuln | grep 3389
   ```

4. Revisar logs del outpost:
   ```bash
   docker-compose -f docker-compose.preproduccion.yml logs -f authentik-outpost
   ```

### Conexión lenta o intermitente

1. Verificar latencia de red:
   ```bash
   docker exec kolaboree-guacamole ping -c 10 tsplus.hs.kappa4.com
   ```

2. Verificar configuración de DERP en Headscale si hay NAT de por medio

3. Ajustar configuración de rendimiento en Guacamole:
   - Reducir color depth a 16-bit
   - Deshabilitar wallpaper y theming
   - Habilitar compresión

### Error de autenticación

1. Verificar credenciales en la configuración de Guacamole
2. Verificar que el usuario existe en el servidor TSPlus
3. Revisar logs de TSPlus para errores de autenticación

## Seguridad

### Recomendaciones

1. **Usar certificados SSL válidos** para todas las conexiones HTTPS
2. **Configurar firewall** en el servidor TSPlus para permitir solo conexiones desde Headscale
3. **Rotar credenciales** regularmente
4. **Habilitar MFA** en Authentik para acceso adicional
5. **Auditar logs** de acceso regularmente

### Firewall en TSPlus

Si TSPlus es un servidor Ubuntu, configurar UFW:

```bash
# Permitir solo desde la red Headscale
sudo ufw allow from 100.64.0.0/10 to any port 3389

# O permitir solo desde Guacamole
sudo ufw allow from 100.64.0.12 to any port 3389
```

### Registro de Conexiones

Habilitar logging en Guacamole para auditoría:

1. Settings → Connections → (Tu conexión TSPlus) → Edit
2. En "Recording" section:
   - Enable recording path
   - Set recording name pattern

Los recordings se guardan en el contenedor y pueden ser montados a un volumen.

## Referencias

- Documentación de Headscale: https://headscale.net/
- Documentación de Guacamole: https://guacamole.apache.org/doc/gug/
- Documentación de Authentik RAC: https://docs.goauthentik.io/docs/providers/rac/
