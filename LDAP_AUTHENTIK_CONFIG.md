# Configuración LDAP para Authentik

## Estructura LDAP Poblada

El OpenLDAP ha sido poblado con la siguiente estructura organizacional:

### Configuración Base
- **Base DN**: `dc=kolaboree,dc=local`
- **Admin DN**: `cn=admin,dc=kolaboree,dc=local`
- **Admin Password**: `zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01`

### Unidades Organizacionales
- `ou=users,dc=kolaboree,dc=local` - Contiene todos los usuarios
- `ou=groups,dc=kolaboree,dc=local` - Contiene todos los grupos

### Usuarios Creados
| Usuario | Email | Nombre Completo | Contraseña | Grupos |
|---------|-------|-----------------|------------|---------|
| `infra` | infra@neogenesys.com | Infra Administrator | Neo123!!! | globaladmin |
| `usuario1` | usuario1@neogenesys.com | Usuario Uno | Password123 | users |
| `usuario2` | usuario2@neogenesys.com | Usuario Dos | Password123 | users |
| `tecnico1` | tecnico1@neogenesys.com | Técnico Uno | Password123 | admintecnico |
| `tecnico2` | tecnico2@neogenesys.com | Técnico Dos | Password123 | admintecnico |

### Grupos Creados
| Grupo | Descripción | Miembros |
|-------|-------------|----------|
| `users` | Usuarios regulares | usuario1, usuario2 |
| `admintecnico` | Administradores técnicos | tecnico1, tecnico2 |
| `globaladmin` | Administrador global | infra |

### Configuración para Authentik

Para configurar Authentik con este LDAP:

1. **LDAP Source Configuration**:
   - Server URI: `ldap://kolaboree-ldap:389`
   - Bind CN: `cn=admin,dc=kolaboree,dc=local`
   - Bind Password: `zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01`
   - Base DN: `dc=kolaboree,dc=local`
   - **DN de usuario adicional**: `ou=users`
   - **DN de grupo adicional**: `ou=groups`

2. **Filtros de Objetos**:
   - **Filtro de objetos de usuario**: `(objectClass=inetOrgPerson)`
   - **Filtro de objetos de grupo**: `(objectClass=groupOfNames)`

3. **Configuración de Grupos**:
   - **Campo pertenencia a grupos**: `member`
   - **Campo de unicidad de objetos**: `entryUUID`

### Valores Exactos para Authentik UI

Copia estos valores directamente en la interfaz de Authentik:

| Campo | Valor |
|-------|-------|
| **Server URI** | `ldap://kolaboree-ldap:389` |
| **Bind CN** | `cn=admin,dc=kolaboree,dc=local` |
| **Bind Password** | `zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01` |
| **Base DN** | `dc=kolaboree,dc=local` |
| **DN de usuario adicional** | `ou=users` |
| **DN de grupo adicional** | `ou=groups` |
| **Filtro de objetos de usuario** | `(objectClass=inetOrgPerson)` |
| **Filtro de objetos de grupo** | `(objectClass=groupOfNames)` |
| **Campo pertenencia a grupos** | `member` |
| **Campo de unicidad de objetos** | `entryUUID` |

4. **User Attribute Mappings**:
   - Username: `uid`
   - Email: `mail`
   - First Name: `givenName`
   - Last Name: `sn`
   - Display Name: `displayName`

### Pruebas de Autenticación

Los usuarios pueden autenticarse usando:
- **Usuario**: `uid=<username>,ou=users,dc=kolaboree,dc=local`
- **Contraseña**: 
  - `infra`: `Neo123!!!`
  - Otros usuarios: `Password123`

Ejemplo para el usuario infra:
```bash
docker exec kolaboree-ldap ldapwhoami -x -D "uid=infra,ou=users,dc=kolaboree,dc=local" -w "Neo123!!!"
```

### Aplicaciones RAC Configuradas

El sistema está configurado con las siguientes aplicaciones de acceso remoto:

| Aplicación | URL | Acceso por Grupo |
|------------|-----|------------------|
| **Panel de Usuario** | http://34.68.124.46/user | users, admintecnico, globaladmin |
| **Panel de Administrador** | http://34.68.124.46/admin | admintecnico, globaladmin |
| **Windows Remote Desktop (TSplus)** | https://tsplus.kolaboree.local:3443 | admintecnico, globaladmin |

### Acceso a Authentik

- **URL de acceso**: http://34.68.124.46:9000/if/user/#/library
- **Usuario de prueba**: infra@neogenesys.com
- **Contraseña**: Neo123!!!

### Notas Importantes

1. **Parent Group**: Puedes crear un grupo padre en Authentik para organizar todos los grupos LDAP importados.

2. **Ruta de usuario**: El template por defecto `goauthentik.io/sources/%(slug)s` funciona bien.

3. **Campo de unicidad**: Hemos verificado que `entryUUID` está disponible y es único para cada entrada LDAP.

4. **Membresía de grupos**: Nuestros grupos usan el campo `member` con DNs completos, no `memberUid`.

### Servicios Disponibles

- **LDAP**: http://localhost:389 (dentro del contenedor)
- **Authentik**: http://localhost:9000
- **Kolaboree Frontend**: http://localhost

### Verificación de Conexión

Para probar la conexión desde Authentik, usa el botón "Test" después de configurar los valores.

¡La estructura LDAP está lista para ser integrada con Authentik!