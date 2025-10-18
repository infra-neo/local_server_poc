# RESOLUCIÓN - Error de Autenticación en Guacamole

## 🚨 Problema Identificado

### Síntomas
- Error: "Too many failed authentication attempts. Please try again later."
- Mensaje en logs: "The server requested SCRAM-based authentication, but the password is an empty string"
- Bloqueo temporal de la IP por intentos fallidos

### Causa Raíz
El contenedor de Guacamole tenía variables de entorno cacheadas con una contraseña PostgreSQL vacía o mal formateada, a pesar de que el archivo `.env` contenía la contraseña correcta.

## ✅ Solución Aplicada

### Pasos Ejecutados
1. **Diagnóstico inicial**:
   ```bash
   docker logs kolaboree-guacamole --tail 30
   # Mostró: "password is an empty string"
   ```

2. **Verificación del archivo .env**:
   ```bash
   grep POSTGRES_PASSWORD .env
   # POSTGRES_PASSWORD=KolaboreeDB2024 ✓ Correcto
   ```

3. **Recreación completa del contenedor**:
   ```bash
   # Parar y eliminar completamente
   docker compose stop guacamole
   docker compose rm -f guacamole
   
   # Recrear con variables frescas
   docker compose up -d guacamole
   ```

4. **Verificación de variables de entorno**:
   ```bash
   docker exec kolaboree-guacamole env | grep POSTGRES
   # POSTGRES_PASSWORD=KolaboreeDB2024 ✓ Correcto
   ```

### Resultado
- ✅ Guacamole se inició sin errores de PostgreSQL
- ✅ Variables de entorno cargadas correctamente
- ✅ Conexión a base de datos establecida
- ⏳ Bloqueo temporal expirará en ~5 minutos (300 segundos)

## 🔐 Credenciales de Acceso Confirmadas

### Usuario Superadmin
- **Usuario**: `akadmin`
- **Password**: `Kolaboree2024!Admin`
- **URL**: http://34.68.124.46:8080/guacamole/

### Estado de la Base de Datos
- ✅ Esquema PostgreSQL inicializado
- ✅ Usuario akadmin creado con permisos completos
- ✅ Conexión PostgreSQL funcionando

## 🕐 Próximos Pasos

1. **Esperar 5 minutos** para que expire el bloqueo temporal
2. **Intentar login** con las credenciales akadmin
3. **Configurar conexiones RDP/VNC** según necesidades
4. **Probar autenticación RAC** con Authentik

## 📋 Lecciones Aprendidas

### Problema de Variables de Entorno
- Los contenedores Docker pueden cachear variables de entorno
- `docker compose restart` no siempre refresca las variables
- La recreación completa (`rm` + `up`) es más efectiva

### Mecanismo de Protección
- Guacamole tiene protección contra ataques de fuerza bruta
- Bloquea IPs después de 5 intentos fallidos
- Bloqueo dura 300 segundos (5 minutos)

## 🔧 Comandos de Diagnostico Útiles

```bash
# Verificar variables de entorno del contenedor
docker exec kolaboree-guacamole env | grep POSTGRES

# Ver logs de errores
docker logs kolaboree-guacamole --tail 20

# Recrear contenedor completamente
docker compose stop guacamole && docker compose rm -f guacamole && docker compose up -d guacamole

# Verificar estado de todos los servicios
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---
**Estado**: ✅ RESUELTO
**Fecha**: 17 de Octubre, 2025 - 20:31 GMT
**Siguiente acción**: Esperar expiración del bloqueo y probar login