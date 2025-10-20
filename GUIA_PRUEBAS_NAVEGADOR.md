# 🧪 GUÍA DE PRUEBAS EN NAVEGADOR - RAC HTML5

## ✅ SISTEMA CONFIGURADO EXITOSAMENTE

### Configuraciones Aplicadas:
- ✅ **NGINX**: HTTPS con SSL, WebSockets, CORS
- ✅ **Authentik**: Variables RAC configuradas
- ✅ **Outpost**: Configurado y conectado (RAC Provider)
- ✅ **Certificados SSL**: Temporales generados
- ✅ **Puertos**: Solo NGINX expuesto (80, 443)
- ✅ **Backup**: Creado en `backup-pre-rac-20251020_085604/`

🎉 **OUTPOST FUNCIONANDO**: Token configurado correctamente, WebSocket conectado con Authentik

## 🌐 PRUEBAS EN NAVEGADOR

### Paso 1: Verificar Acceso Principal
1. **Abrir navegador** y ir a: `https://gate.kappa4.com`
2. **Aceptar certificado** autofirmado (temporal)
3. **Verificar redirección** automática al login de Authentik
4. **Login** con credenciales: `akadmin` / `Kolaboree2024!Admin`

### Paso 2: Verificar Headers CORS (Console del Navegador)
```javascript
// Abrir Developer Tools (F12) y ejecutar en Console:
fetch('https://gate.kappa4.com/api/v3/core/users/me/', {
  method: 'GET',
  headers: { 'Content-Type': 'application/json' }
}).then(response => {
  console.log('✅ Status:', response.status);
  console.log('✅ Headers CORS:', response.headers.get('Access-Control-Allow-Origin'));
}).catch(error => {
  console.error('❌ Error CORS:', error);
});
```

### Paso 3: Configurar RAC Provider
1. **Ir al Admin Panel**: En Authentik, clic en "Admin Interface"
2. **Applications → Providers → Create Provider**
3. **Seleccionar**: "RAC Provider"
4. **Configurar**:
   - Name: `Windows RAC Provider`
   - Connection expiry: `hours=8`
   - Delete on disconnect: `true`
   - **IMPORTANTE**: Dejar WebSocket URL en blanco (usará automáticamente gate.kappa4.com)

### Paso 4: Crear Application RAC
1. **Applications → Applications → Create Application**
2. **Configurar**:
   - Name: `Remote Desktop Access`
   - Slug: `remote-desktop`
   - Provider: Seleccionar "Windows RAC Provider"
   - Launch URL: `blank://blank`

### Paso 5: Configurar Endpoint (Conexión a tus VMs)

⚠️ **IMPORTANTE**: Ahora que el Outpost está funcionando, puedes configurar endpoints para RAC.

1. **En RAC Provider → Endpoints → Create Endpoint**
2. **Configurar para VM Local**:
   - Name: `VM Local`
   - Host: `100.x.x.x` (Tu IP de Tailscale VM Local)
   - Protocol: `rdp`
   - Port: `3389`
   
3. **Configurar para VM LXC**:
   - Name: `VM LXC`
   - Host: `100.x.x.x` (Tu IP de Tailscale VM LXC)
   - Protocol: `rdp`
   - Port: `3389`

**Para obtener las IPs de Tailscale:**
```bash
# En cada VM, ejecutar:
tailscale ip -4
```

### Paso 6: Probar Conexión RAC HTML5
1. **Ir a "My applications"** en Authentik
2. **Clic en "Remote Desktop Access"**
3. **Seleccionar endpoint** (VM Local o VM LXC)
4. **Credenciales**: 
   - Usuario: `soporte`
   - Contraseña: `Neo123!!!`
5. **Verificar**:
   - ✅ No errores CORS en console
   - ✅ WebSocket se conecta a `wss://gate.kappa4.com/ws/`
   - ✅ Sesión RDP se abre en HTML5
   - ✅ Puedes controlar el escritorio remoto

## 🔍 VERIFICACIONES TÉCNICAS

### Test WebSocket Manual
```javascript
// En Console del navegador:
const ws = new WebSocket('wss://gate.kappa4.com/ws/');
ws.onopen = () => console.log('✅ WebSocket conectado');
ws.onerror = (e) => console.error('❌ WebSocket error:', e);
ws.onclose = (e) => console.log('WebSocket cerrado:', e.code, e.reason);
```

### Verificar Headers de Respuesta
```javascript
// Verificar headers específicos:
fetch('https://gate.kappa4.com/').then(response => {
  console.log('X-Frame-Options:', response.headers.get('x-frame-options'));
  console.log('Access-Control-Allow-Origin:', response.headers.get('access-control-allow-origin'));
  console.log('Content-Security-Policy:', response.headers.get('content-security-policy'));
});
```

## 🔧 CONFIGURACIÓN DE TUS VMs ESPECÍFICAS

### Para usar tus IPs de Tailscale:
1. **Obtener IPs**:
   ```bash
   # En VM local: tailscale ip -4
   # En VM LXC: tailscale ip -4
   ```

2. **Configurar en RAC Endpoints**:
   - VM Local: IP de Tailscale de tu VM local
   - VM LXC: IP de Tailscale de tu VM LXC
   - Usuario: `soporte`
   - Password: `Neo123!!!`
   - Puerto: `3389`

## 🐛 TROUBLESHOOTING

### Si hay errores CORS:
```bash
# Verificar configuración Authentik
docker exec kolaboree-authentik-server env | grep CORS
# Debe mostrar: AUTHENTIK_CORS__ALLOWED_ORIGINS=https://gate.kappa4.com
```

### Si WebSocket no conecta:
```bash
# Verificar logs nginx
docker logs kolaboree-nginx --tail 20

# Verificar logs Authentik
docker logs kolaboree-authentik-server --tail 20 | grep -i websocket
```

### Si RAC no abre:
1. Verificar que Tailscale esté funcionando en ambas VMs
2. Verificar que RDP esté habilitado en las VMs
3. Verificar firewall en las VMs (puerto 3389)

## 📊 RESULTADOS ESPERADOS

### ✅ Funcionamiento Correcto:
- Login en `https://gate.kappa4.com` sin errores
- Console del navegador sin errores CORS
- WebSocket conecta a `wss://gate.kappa4.com/ws/`
- RAC HTML5 abre sesión remota
- Control completo del escritorio remoto
- Sin necesidad de acceder a puertos 9000/9443

### ❌ Si hay problemas:
- Consultar logs: `docker logs kolaboree-nginx` y `docker logs kolaboree-authentik-server`
- Restaurar backup: Copiar archivos desde `backup-pre-rac-20251020_085604/`
- Verificar DNS: `gate.kappa4.com` debe apuntar a la IP de tu VM GCP

---
**Estado**: 🟢 **LISTO PARA PRUEBAS**
**Tiempo estimado**: 15-20 minutos de configuración
**Siguiente paso**: Abrir navegador y seguir Paso 1