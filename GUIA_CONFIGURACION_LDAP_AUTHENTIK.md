# 🔧 Guía de Configuración Manual - LDAP Source en Authentik

## ✅ Estado Actual
- **✅ RAC Provider funcionando** (Application authorized exitosamente)  
- **✅ Usuario akadmin autenticado** en Authentik
- **✅ Windows Remote Desktop (TSplus) autorizado**

---

## 📋 **PASO 1: Configurar LDAP Source**

### En tu interfaz de Authentik Admin:

1. **Navegar a:** `Directory` → `LDAP Sources`
2. **Hacer clic en:** `Create`
3. **Completar los siguientes campos:**

```yaml
# Configuración Básica
Name: Neogenesys LDAP
Slug: neogenesys-ldap

# Configuración del Servidor
Server URI: ldap://kolaboree-ldap:389
Bind CN: cn=admin,dc=kolaboree,dc=local
Bind Password: zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01

# Configuración de Base
Base DN: dc=kolaboree,dc=local
Additional User DN: ou=users
Additional Group DN: ou=groups

# Filtros de Objetos
User Object Filter: (objectClass=inetOrgPerson)
Group Object Filter: (objectClass=groupOfNames)
Group membership field: member
Object uniqueness field: uid

# Opciones de Sincronización
☑️ Sync users
☑️ Sync users password  
☑️ Sync groups
```

4. **Hacer clic en:** `Create`

---

## 📋 **PASO 2: Configurar Property Mappings**

### Después de crear la fuente LDAP:

1. **Ir a:** `Directory` → `LDAP Sources` → `Neogenesys LDAP`
2. **Hacer clic en:** `Edit`
3. **En la sección Property Mappings, verificar:**

```yaml
# User Property Mappings requeridos:
- authentik default LDAP Mapping: Name
- authentik default LDAP Mapping: Email  
- authentik default LDAP Mapping: Username

# Group Property Mappings:
- authentik default LDAP Mapping: Name
```

4. **Si faltan mappings, crearlos:**
   - `Customization` → `Property Mappings` → `Create`
   - **Tipo:** `LDAP Property Mapping`

### Mappings críticos:
```python
# Username Mapping
return ldap.get('uid')

# Email Mapping  
return ldap.get('mail')

# Name Mapping
return ldap.get('cn')
```

---

## 📋 **PASO 3: Sincronización Inicial**

1. **En LDAP Source:** `Neogenesys LDAP`
2. **Hacer clic en:** `Sync`
3. **Esperar a que complete la sincronización**
4. **Verificar en:** `Directory` → `Users`

### Usuarios esperados:
- **✅ akadmin** (infra@neogenesys.com)
- **✅ usuario1** (usuario1@neogenesys.com)  
- **✅ usuario2** (usuario2@neogenesys.com)
- **✅ tecnico1** (tecnico1@neogenesys.com)
- **✅ tecnico2** (tecnico2@neogenesys.com)
- **✅ infra** (infra@neogenesys.com)

---

## 📋 **PASO 4: Crear OAuth2 Provider para Guacamole**

1. **Ir a:** `Applications` → `Providers` → `Create`
2. **Seleccionar:** `OAuth2/OpenID Provider`
3. **Configurar:**

```yaml
# Configuración Básica
Name: Guacamole OIDC Provider
Authorization flow: default-authorization-flow
Invalidation flow: default-invalidation-flow

# OAuth2/OIDC Settings
Client type: Confidential
Client ID: guacamole-rac-client
Client Secret: guacamole-rac-secret-2024

# Redirect URIs (uno por línea):
http://34.68.124.46:8080/guacamole/
http://34.68.124.46:8080/guacamole/api/ext/oidc/callback

# Scopes:
openid
profile  
email
groups
```

4. **Hacer clic en:** `Create`

---

## 📋 **PASO 5: Crear Aplicación Guacamole**

1. **Ir a:** `Applications` → `Applications` → `Create`
2. **Configurar:**

```yaml
Name: Guacamole RAC
Slug: guacamole-rac
Provider: Guacamole OIDC Provider (seleccionar el creado arriba)
Meta Launch URL: http://34.68.124.46:8080/guacamole/
```

3. **Hacer clic en:** `Create`

---

## 🧪 **PASO 6: Prueba del Flujo Completo**

### Test 1: Login LDAP en Authentik
1. **Cerrar sesión** de Authentik
2. **Ir a:** https://34.68.124.46:9443/if/flow/default-authentication-flow/
3. **Probar login con:**
   - **Usuario:** `usuario1@neogenesys.com`
   - **Password:** (password del usuario en LDAP)

### Test 2: Acceso a Guacamole via Authentik
1. **Una vez logueado en Authentik**
2. **Ir a:** https://34.68.124.46:9443/if/user/#/library
3. **Hacer clic en:** `Guacamole RAC`
4. **Debería redirigir a Guacamole autenticado**

### Test 3: RAC Dashboard  
1. **Ir a:** http://34.68.124.46:3000/user/rac
2. **Verificar que muestra conexiones disponibles**

---

## 🎯 **Resultados Esperados**

✅ **LDAP Source sincronizado** con usuarios de OpenLDAP  
✅ **OAuth2 Provider** configurado para Guacamole  
✅ **Aplicación Guacamole** disponible en Authentik Library  
✅ **Flujo completo:** LDAP → Authentik → Guacamole → RAC  

---

## 🚨 **Solución de Problemas**

### Si la sincronización LDAP falla:
```bash
# Verificar conectividad LDAP desde contenedor Authentik
docker exec kolaboree-authentik-server ldapsearch -x -H ldap://kolaboree-ldap:389 -D "cn=admin,dc=kolaboree,dc=local" -w "zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01" -b "dc=kolaboree,dc=local" "(uid=*)"
```

### Si OAuth2 no funciona:
- Verificar que las **Redirect URIs** coincidan exactamente
- Confirmar que **Client ID** y **Client Secret** estén en `docker-compose.yml`
- Revisar logs: `docker logs kolaboree-guacamole`

---

## 📞 **Soporte Técnico**

Si necesitas ayuda, proporciona:
1. **Screenshots** de la configuración LDAP Source
2. **Logs** de sincronización en Authentik
3. **Mensaje de error** específico si aparece alguno

**¡Ahora tienes todo listo para configurar el flujo completo!** 🚀