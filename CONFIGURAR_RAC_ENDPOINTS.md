# Configuración RAC Endpoints - Windows VMs

## 🎯 Estado Actual
- ✅ Outpost conectado y funcionando
- ✅ Network_mode: host habilitado
- ✅ Conectividad a Tailscale confirmada (100.95.223.18:3389)

## 📋 Pasos para Configurar RAC

### 1. Acceder a Authentik Admin
```
https://gate.kappa4.com/if/admin/
Usuario: akadmin
Password: [tu password]
```

### 2. Crear RAC Provider
1. Ir a **Applications > Providers**
2. Crear nuevo **RAC Provider**
3. Configurar:
   - **Name**: `Windows-VMs-RAC`
   - **Outpost**: Seleccionar el outpost existente
   - **Settings**: Default

### 3. Crear Endpoints RAC
Para cada VM Windows, crear un endpoint:

#### VM Principal (100.95.223.18)
```
Name: Windows-VM-1
Protocol: RDP
Host: 100.95.223.18
Port: 3389
Username: soporte
Password: Neo123!!!
```

#### Otras VMs disponibles en Tailscale
```
- 100.82.13.37 (Windows 11 Pro)
- 100.127.86.122 (DESKTOP-windows)
- 100.96.137.70 (Windows-VM-otro)
```

### 4. Crear Aplicación RAC
1. Ir a **Applications > Applications**
2. Crear nueva aplicación:
   - **Name**: `Remote Desktop`
   - **Slug**: `remote-desktop`
   - **Provider**: Seleccionar el RAC Provider creado
   - **UI Settings**: Configurar icono y descripción

### 5. Asignar Permisos
1. Ir a **Applications > Applications**
2. Seleccionar la aplicación creada
3. En **Policy Bindings**, asignar grupos/usuarios

## 🌐 URL de Acceso
Una vez configurado:
```
https://gate.kappa4.com/application/o/remote-desktop/
```

## 🔧 Credenciales para Testing
```
Usuario Windows: soporte
Password: Neo123!!!
```

## 📝 Notas
- El Outpost está usando host networking para acceder a Tailscale
- Todas las VMs están en la red 100.x.x.x de Tailscale
- RDP port 3389 confirmado como accesible