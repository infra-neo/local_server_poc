# Plan de Validación - Authentik + RAC HTML5 + WebSockets

## 🔍 DIAGNÓSTICO DE PROBLEMAS IDENTIFICADOS

### Problemas Críticos Encontrados:

1. **❌ NGINX sin configuración HTTPS/SSL**
   - Solo puerto 80 configurado
   - No hay reverse proxy para puerto 443
   - Authentik expuesto directamente en puertos 9000/9443

2. **❌ Variables de entorno de Authentik incompletas**
   - Falta `AUTHENTIK_HOST` y `AUTHENTIK_PUBLIC_URL`
   - No hay configuración de CORS
   - Faltan variables específicas para RAC

3. **❌ Configuración WebSocket inadecuada**
   - No hay soporte específico para `/ws/` en NGINX
   - Falta configuración de upgrade de conexión
   - Timeouts inadecuados para sesiones largas

4. **❌ Headers CORS insuficientes**
   - No hay headers específicos para RAC HTML5
   - Falta configuración para WebSockets cross-origin

## 🛠️ PASOS DE CORRECCIÓN

### Paso 1: Aplicar configuración de NGINX corregida

```bash
# Respaldar configuración actual
cp /home/infra/local_server_poc/nginx/conf.d/default.conf /home/infra/local_server_poc/nginx/conf.d/default.conf.backup

# Aplicar nueva configuración
cp /home/infra/local_server_poc/nginx_corrected.conf /home/infra/local_server_poc/nginx/conf.d/default.conf

# Verificar sintaxis
docker exec kolaboree-nginx nginx -t

# Recargar configuración
docker exec kolaboree-nginx nginx -s reload
```

### Paso 2: Configurar certificados SSL

```bash
# Crear directorio para certificados
mkdir -p /home/infra/local_server_poc/nginx/ssl

# Opción A: Certificados Let's Encrypt (producción)
certbot --nginx -d gate.kappa4.com

# Opción B: Certificado autofirmado (testing)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /home/infra/local_server_poc/nginx/ssl/privkey.pem \
  -out /home/infra/local_server_poc/nginx/ssl/fullchain.pem \
  -subj "/CN=gate.kappa4.com"
```

### Paso 3: Actualizar docker-compose con variables de entorno

```bash
# Respaldar docker-compose actual
cp /home/infra/local_server_poc/docker-compose.yml /home/infra/local_server_poc/docker-compose.yml.backup

# Aplicar configuración corregida (manualmente editar docker-compose.yml)
# Añadir las variables de entorno del archivo authentik_env_corrected.conf
```

### Paso 4: Reiniciar servicios

```bash
# Recrear contenedores Authentik con nueva configuración
docker-compose down authentik-server authentik-worker
docker-compose up -d authentik-server authentik-worker

# Verificar logs
docker logs kolaboree-authentik-server --tail 50
docker logs kolaboree-nginx --tail 50
```

## 🧪 TESTS DE VALIDACIÓN

### Test 1: Verificar HTTPS y redirección

```bash
# Debe redirigir HTTP → HTTPS
curl -I http://gate.kappa4.com
# Esperado: 301 Moved Permanently, Location: https://gate.kappa4.com/

# Verificar HTTPS funcional
curl -I https://gate.kappa4.com
# Esperado: 200 OK
```

### Test 2: Verificar WebSocket con wscat

```bash
# Instalar wscat si no está disponible
npm install -g wscat

# Test WebSocket connection
wscat -c wss://gate.kappa4.com/ws/
# Esperado: Conexión exitosa, sin errores CORS

# Test con headers específicos
wscat -c wss://gate.kappa4.com/ws/ -H "Origin: https://gate.kappa4.com"
```

### Test 3: Verificar headers CORS en navegador

```javascript
// Ejecutar en console del navegador en https://gate.kappa4.com
fetch('https://gate.kappa4.com/api/v3/core/users/me/', {
  method: 'GET',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json'
  }
}).then(response => {
  console.log('Status:', response.status);
  console.log('Headers:', response.headers);
}).catch(error => {
  console.error('Error:', error);
});
```

### Test 4: Verificar RAC HTML5 en navegador

1. **Acceder a Authentik:**
   - URL: `https://gate.kappa4.com`
   - Login con credenciales admin

2. **Configurar RAC Provider:**
   - Applications → Providers
   - Create RAC Provider
   - Settings:
     - Name: `Windows RAC Provider`
     - Connection expiry: `hours=8`
     - Delete on disconnect: `true`

3. **Configurar Application:**
   - Applications → Applications
   - Create Application
   - Provider: Seleccionar RAC Provider creado
   - Launch URL: `blank://blank`

4. **Test de conexión RAC:**
   - Abrir aplicación configurada
   - Verificar que no aparezcan errores de CORS
   - Verificar que WebSocket se conecte a `wss://gate.kappa4.com/ws/`

## 🔧 COMANDOS DE DEBUGGING

### Verificar configuración NGINX

```bash
# Ver configuración activa
docker exec kolaboree-nginx cat /etc/nginx/conf.d/default.conf

# Verificar sintaxis
docker exec kolaboree-nginx nginx -t

# Ver logs de error
docker logs kolaboree-nginx --tail 100
```

### Verificar variables Authentik

```bash
# Ver todas las variables de entorno
docker exec kolaboree-authentik-server env | grep AUTHENTIK | sort

# Verificar logs específicos de RAC
docker logs kolaboree-authentik-server --tail 100 | grep -i "rac\|websocket\|cors"
```

### Verificar conectividad WebSocket

```bash
# Test básico de conectividad
curl -I -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: test" \
  https://gate.kappa4.com/ws/
```

## 📋 CHECKLIST DE VALIDACIÓN

- [ ] NGINX responde en puerto 443 con SSL
- [ ] Redirección HTTP → HTTPS funcional
- [ ] Headers CORS presentes en respuestas
- [ ] WebSocket /ws/ accesible vía wss://
- [ ] Authentik carga sin errores CORS
- [ ] Variables de entorno Authentik correctas
- [ ] RAC Provider configurable en admin
- [ ] Conexiones RAC HTML5 sin errores WebSocket
- [ ] Logs sin errores de CORS o WebSocket
- [ ] Timeouts de sesión adecuados

## 🚨 SOLUCIÓN DE PROBLEMAS COMUNES

### Error: "WebSocket connection failed"
- Verificar configuración de upgrade en NGINX
- Revisar headers Upgrade y Connection
- Comprobar timeouts de proxy

### Error: "CORS policy blocks request"
- Verificar Access-Control-Allow-Origin headers
- Confirmar que Origin sea https://gate.kappa4.com
- Revisar configuración AUTHENTIK_WEB__ALLOWED_ORIGINS

### Error: "Mixed content" (HTTP/HTTPS)
- Asegurar que todas las URLs usen https://
- Verificar X-Forwarded-Proto headers
- Confirmar SSL termination en NGINX

---
**Estado**: 🔄 PENDIENTE APLICACIÓN
**Prioridad**: 🔴 CRÍTICO
**Próximo paso**: Aplicar configuración NGINX corregida