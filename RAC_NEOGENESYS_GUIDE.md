# 🚀 Neogenesys RAC HTML5 - Guía Completa

## 📋 Resumen del Sistema

El sistema **Neogenesys RAC HTML5** está completamente configurado y operativo con las siguientes características:

### ✅ Estado Actual
- **NGINX**: Configurado con HTTPS, WebSocket y CORS ✅
- **Authentik 2025.2.4**: Identity provider configurado ✅
- **RAC Provider**: "Windows-Remote-Desktop" operativo ✅
- **Outpost RAC**: Desplegado con imagen `ghcr.io/goauthentik/rac:latest` ✅
- **Branding Neogenesys**: Aplicado completamente ✅
- **Footer personalizado**: "Desarrollado por authentik" oculto ✅
- **Logos corporativos**: Múltiples variantes disponibles ✅
- **Favicon personalizado**: Logo negativo configurado ✅
- **Menú de opciones RAC**: Implementado estilo Citrix/Kasm ✅

---

## 🎨 Logos y Branding

### Logos Disponibles en `/authentik/branding/logos/`:
- **genesys-25-anos.svg**: Logo conmemorativo 25 años
- **neogenesys-horizontal.svg**: Logo horizontal estándar  
- **neogenesys-negative.svg**: Logo con fondo (usado para favicon)
- **neogenesys-favicon.svg**: Favicon 32x32 optimizado
- **neogenesys-logo.svg**: Logo principal
- **neo-genesys-logo.svg**: Variante alternativa
- **neogenesys-oficial.svg**: Logo oficial corporativo

### Configuración de Branding
```
Portal: https://gate.kappa4.com
Favicon: neogenesys-favicon.svg (logo negativo)
CSS: neogenesys.css (estilo corporativo)
Footer: Ocultado con hide-footer.js
```

---

## 🎮 Menú de Opciones RAC

### Características Implementadas
El menú RAC incluye funcionalidades profesionales similares a **Citrix** y **Kasm**:

#### 🔘 Botón Flotante
- Posición: Esquina superior derecha
- Ícono: ⚙️ (engranaje)
- Estilo: Corporativo Neogenesys (azul)

#### 🚪 Opciones Disponibles
1. **Cerrar Sesión** 
   - Función: Desconecta del escritorio remoto
   - Atajo: `Ctrl+Alt+D`
   - Confirmación: Sí

2. **Pantalla Completa**
   - Función: Alterna modo pantalla completa
   - Atajo: `F11`
   - Estados: Normal ↔ Completa

3. **Captura de Pantalla**
   - Función: Toma screenshot del escritorio remoto
   - Formato: PNG
   - Descarga: Automática

4. **Gestión de Portapapeles**
   - Función: Sincroniza portapapeles local ↔ remoto
   - Tipos: Texto, imágenes
   - Estados: Activo/Inactivo

5. **Panel de Configuración**
   - Calidad de video: Baja/Media/Alta
   - Audio: Activar/Desactivar
   - Compresión: Ajustable
   - Teclado: Layout personalizable

#### ⌨️ Atajos de Teclado
- `Ctrl+Alt+M`: Abrir/cerrar menú
- `Ctrl+Alt+D`: Cerrar sesión
- `F11`: Pantalla completa
- `Ctrl+Shift+V`: Pegar desde portapapeles

#### 📊 Información de Sesión
- Timer de sesión activa
- Estado de conexión (indicador verde/rojo)
- Calidad de red (latencia)
- Uso de recursos

---

## 🌐 URLs y Acceso

### Puntos de Acceso
```
🏠 Portal Principal: https://gate.kappa4.com
🔐 Admin Authentik: https://gate.kappa4.com/if/admin/
💻 RAC Directo: https://gate.kappa4.com/if/rac/
📱 Health Check: https://gate.kappa4.com/outpost.goauthentik.io/ping
```

### Credenciales de Administración
```
Usuario: admin
Password: [Configurado durante setup]
```

---

## 🎯 Instrucciones de Uso

### Para Usuarios Finales

1. **Acceder al Portal**
   ```
   URL: https://gate.kappa4.com
   Navegador: Chrome, Firefox, Edge, Safari
   ```

2. **Autenticación**
   - Introducir usuario y contraseña
   - Proceso automático via Authentik

3. **Seleccionar RAC**
   - Buscar "Windows Remote Desktop" 
   - Click en el botón de conexión

4. **Usar el Menú RAC**
   - **Abrir menú**: Click en ⚙️ o `Ctrl+Alt+M`
   - **Pantalla completa**: `F11`
   - **Cerrar sesión**: Click en "Logout" o `Ctrl+Alt+D`
   - **Captura**: Click en "Screenshot"
   - **Configurar**: Click en "Settings"

### Para Administradores

1. **Gestión de Usuarios**
   ```bash
   # Acceder al admin
   URL: https://gate.kappa4.com/if/admin/
   
   # Crear usuario
   Directory → Users → Create
   ```

2. **Configuración RAC**
   ```bash
   # Ver configuración
   Applications → Providers → Windows-Remote-Desktop
   
   # Modificar endpoint
   Applications → Providers → Endpoints
   ```

3. **Monitoreo**
   ```bash
   # Ver logs
   docker logs kolaboree-authentik-outpost
   
   # Estado servicios
   docker ps
   ```

---

## 🔧 Configuración Técnica

### Arquitectura
```
Internet → NGINX (443) → Authentik (9000) → RAC Outpost → Windows VM
         ↳ SSL/TLS    ↳ Identity      ↳ HTML5 Client   ↳ 100.95.223.18:3389
```

### Puertos y Servicios
```
443/tcp  - NGINX HTTPS
9000/tcp - Authentik Server (interno)
3389/tcp - Windows RDP (Tailscale: 100.95.223.18)
80/tcp   - HTTP Redirect
```

### Variables de Entorno RAC
```bash
AUTHENTIK_HOST=gate.kappa4.com
AUTHENTIK_TOKEN=FJVTBKwhy66m0ZTRqhWZCnOfczGHPlz3gCHABYNYcNa55q5r8fxf6sSCvCQF
AUTHENTIK_INSECURE=false
```

### Archivos Importantes
```
📁 /home/infra/local_server_poc/
├── 📁 authentik/branding/
│   ├── 📁 logos/           # Todos los logos SVG
│   ├── 📁 static/          # CSS, JS, favicon
│   └── 📁 templates/       # Templates HTML personalizados
├── 📁 nginx/
│   └── 📄 nginx.conf       # Configuración HTTPS/WebSocket
├── 📁 scripts/
│   └── 📄 deploy-rac-menu.sh  # Script de despliegue
└── 📄 docker-compose.yml  # Stack completo
```

---

## 🛠️ Troubleshooting

### Problemas Comunes

#### 🔴 No se conecta RAC
```bash
# Verificar outpost
docker logs kolaboree-authentik-outpost

# Verificar conectividad
ping 100.95.223.18
telnet 100.95.223.18 3389
```

#### 🔴 Menú no aparece
```bash
# Verificar script
docker exec kolaboree-authentik-server ls -la /web/dist/assets/rac-options-menu.js

# Recargar página con Ctrl+F5
# Verificar consola de desarrollador
```

#### 🔴 Favicon no se muestra
```bash
# Limpiar caché del navegador
# Verificar favicon
docker exec kolaboree-authentik-server ls -la /web/dist/assets/icons/neogenesys-favicon.svg
```

#### 🔴 SSL/Certificado
```bash
# Verificar certificado
openssl s_client -connect gate.kappa4.com:443 -servername gate.kappa4.com

# Renovar si es necesario
docker exec kolaboree-nginx nginx -s reload
```

### Comandos de Diagnóstico
```bash
# Estado general
./scripts/deploy-rac-menu.sh

# Logs en tiempo real
docker logs -f kolaboree-authentik-outpost
docker logs -f kolaboree-authentik-server

# Verificar configuración
docker exec kolaboree-authentik-server ak config
```

---

## 📈 Mejoras Futuras

### Funcionalidades Planeadas
- [ ] Grabación de sesiones
- [ ] Transferencia de archivos mejorada
- [ ] Multi-monitor support
- [ ] Audio bidireccional
- [ ] Impresión virtual
- [ ] Dashboard de administración avanzado

### Optimizaciones
- [ ] Compresión de video H.264
- [ ] Load balancing RAC
- [ ] Caché de assets estáticos
- [ ] Métricas y analytics

---

## 👥 Soporte

### Contacto Técnico
```
Empresa: Neogenesys
Implementación: Asistente IA
Fecha: Octubre 2025
Versión: 1.0.0 (25 Años)
```

### Recursos Adicionales
- [Documentación Authentik](https://docs.goauthentik.io/)
- [Guacamole RAC](https://guacamole.apache.org/)
- [NGINX Configuration](https://nginx.org/en/docs/)

---

**🎉 ¡El sistema Neogenesys RAC HTML5 está completamente operativo!**

*Celebrando 25 años de innovación tecnológica (1999-2024)*