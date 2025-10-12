# GitOps Repository - Juju Controller sobre LXD

<div align="center">

**Infraestructura como Código para Bare Metal Ubuntu 22.04**

Automatización completa del despliegue de Juju Controller sobre LXD con configuración declarativa

[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-orange)](https://ubuntu.com/)
[![LXD](https://img.shields.io/badge/LXD-Snap-green)](https://ubuntu.com/lxd)
[![Juju](https://img.shields.io/badge/Juju-Controller-blue)](https://juju.is/)
[![GitOps](https://img.shields.io/badge/GitOps-IaC-purple)](https://www.gitops.tech/)

</div>

---

## 📋 Tabla de Contenidos

- [Descripción General](#-descripción-general)
- [Estructura del Repositorio](#-estructura-del-repositorio)
- [Prerrequisitos](#-prerrequisitos)
- [Guía de Uso](#-guía-de-uso)
  - [Fase 1: Bootstrap del Host](#fase-1-bootstrap-del-host)
  - [Fase 2: Aplicar Configuración IaC](#fase-2-aplicar-configuración-iac)
- [Manifiestos de Infraestructura](#-manifiestos-de-infraestructura)
- [Verificación y Troubleshooting](#-verificación-y-troubleshooting)
- [Arquitectura](#-arquitectura)
- [Mejores Prácticas](#-mejores-prácticas)

---

## 🌟 Descripción General

Este repositorio GitOps proporciona una solución completa y automatizada para preparar un servidor bare metal con Ubuntu 22.04 LTS y desplegar un **Juju Controller** sobre **LXD**, siguiendo las mejores prácticas de Infraestructura como Código (IaC).

### Objetivos

1. **Automatización Completa**: Un script de bootstrap que prepara el host desde cero
2. **Configuración Declarativa**: Manifiestos YAML que definen el estado deseado de la infraestructura LXD
3. **Idempotencia**: Scripts que pueden ejecutarse múltiples veces sin efectos secundarios
4. **Seguridad por Defecto**: Hardening básico del sistema con firewall restrictivo
5. **Reproducibilidad**: Garantía de que cualquier servidor se configura de manera idéntica

### Componentes Principales

- **bootstrap.sh**: Preparación inicial del host bare metal
- **converge.sh**: Aplicación de la configuración declarativa LXD
- **iac/**: Directorio con manifiestos YAML de infraestructura

---

## 📁 Estructura del Repositorio

```
.
├── bootstrap.sh              # Script de bootstrap del host (ejecutar UNA VEZ)
├── converge.sh               # Script de convergencia IaC (idempotente)
├── GITOPS_README.md          # Esta documentación
└── iac/                      # Infraestructura como Código
    ├── 00-storage-pools/     # Pools de almacenamiento
    │   └── lvm-thin-pool.yaml
    ├── 01-networks/          # Redes bridge
    │   ├── segbr0.yaml
    │   └── winbr0.yaml
    └── 02-profiles/          # Perfiles LXD
        ├── docker-host.yaml
        └── windows-vm.yaml
```

Los nombres de los directorios incluyen prefijos numéricos (`00-`, `01-`, `02-`) para garantizar el orden correcto de aplicación, respetando las dependencias entre recursos.

---

## 🔧 Prerrequisitos

### Hardware

- **CPU**: Procesador con soporte para virtualización (Intel VT-x o AMD-V)
- **RAM**: Mínimo 8GB recomendado (4GB para el controlador Juju + 4GB para workloads)
- **Disco**: Mínimo 50GB de espacio libre
- **Volume Group LVM**: Un VG llamado `ubuntu-vg` existente (para el storage pool LVM)

### Software

- **Sistema Operativo**: Ubuntu 22.04 LTS Server (instalación limpia)
- **Acceso**: Permisos de superusuario (root/sudo)
- **Conectividad**: Acceso a internet para descargar paquetes y snaps

### Configuración de BIOS/UEFI

⚠️ **IMPORTANTE**: Antes de ejecutar el bootstrap, verifica que la virtualización por hardware esté habilitada en la BIOS/UEFI:

- **Intel**: Habilitar **VT-x** (Intel Virtualization Technology)
- **AMD**: Habilitar **AMD-V** (AMD Virtualization)

---

## 🚀 Guía de Uso

### Fase 1: Bootstrap del Host

Este paso se ejecuta **una única vez** en cada servidor bare metal nuevo.

#### 1. Clonar el Repositorio

```bash
git clone <url-de-este-repositorio-gitops>
cd <nombre-del-repositorio>
```

#### 2. Ejecutar Bootstrap

```bash
sudo bash bootstrap.sh
```

#### ¿Qué hace el script bootstrap.sh?

El script realiza las siguientes acciones automáticamente:

1. **Validación Inicial**
   - ✅ Verifica ejecución como root
   - ✅ Confirma que KVM está habilitado (detiene si falla)

2. **Actualización del Sistema**
   - 📦 `apt update && apt upgrade -y`
   - 📦 Instala: `qemu-kvm`, `libvirt-daemon-system`, `bridge-utils`, `lvm2`, `git`, `ufw`, `fail2ban`

3. **Hardening de Seguridad**
   - 🔒 Configura UFW: `default deny incoming`, `default allow outgoing`
   - 🔒 Permite solo SSH: `ufw allow 22/tcp`
   - 🔒 Activa el firewall

4. **Optimizaciones del Kernel**
   - ⚙️ Añade `vm.swappiness=10` a `/etc/sysctl.conf`
   - ⚙️ Añade `net.ipv4.ip_forward=1` a `/etc/sysctl.conf`
   - ⚙️ Aplica cambios: `sysctl -p`

5. **Instalación de Snaps**
   - 📥 `snap install lxd --channel=stable`
   - 📥 `snap install juju --channel=stable`
   - 🔧 Inicializa LXD con `lxd init --auto`

6. **Bootstrap de Juju**
   - ☁️ Añade LXD local como cloud `qa-baremetal`
   - 🎮 Crea controlador `qa-controller` en LXD
   - 🖥️ Habilita el Juju Dashboard

7. **Información de Acceso**
   - 📋 Muestra la URL del Juju Dashboard
   - 🔑 Proporciona comandos para obtener credenciales

#### Salida Esperada

Al finalizar, verás un mensaje similar a:

```
==========================================================================
✓ BOOTSTRAP FINALIZADO EXITOSAMENTE
==========================================================================

Acceso al Juju Dashboard:

  URL del Dashboard: https://10.x.x.x:17070/dashboard

Para obtener las credenciales de acceso, ejecuta:
  juju dashboard

==========================================================================
PRÓXIMOS PASOS:
==========================================================================

1. Clona este repositorio GitOps en el servidor
2. Ejecuta el script de convergencia: sudo bash converge.sh
3. Verifica el estado: juju status
```

---

### Fase 2: Aplicar Configuración IaC

Una vez completado el bootstrap, aplica la configuración declarativa de LXD.

#### Prerrequisitos Adicionales

Antes de ejecutar `converge.sh`, asegúrate de tener:

1. **Volume Group LVM**: Debe existir un VG llamado `ubuntu-vg`

   ```bash
   # Verificar VGs existentes
   sudo vgs
   
   # Si no existe, crear uno (ejemplo con disco /dev/sdb)
   sudo pvcreate /dev/sdb
   sudo vgcreate ubuntu-vg /dev/sdb
   ```

#### Ejecutar Convergencia

```bash
sudo bash converge.sh
```

#### ¿Qué hace el script converge.sh?

El script aplica los manifiestos YAML en orden de dependencias:

1. **Storage Pools** (`iac/00-storage-pools/`)
   - Crea pool LVM `windows-vms` para VMs de Windows
   - Usa el VG `ubuntu-vg` y thin pool `LXDThinPool`

2. **Networks** (`iac/01-networks/`)
   - Crea bridge `segbr0` (10.50.0.1/24) con NAT para hosts Docker
   - Crea bridge `winbr0` (10.60.0.1/24) con NAT para VMs Windows

3. **Profiles** (`iac/02-profiles/`)
   - Crea perfil `docker-host` con security.nesting activado
   - Crea perfil `win-profile` optimizado para Windows 11 (4 vCPUs, 12GB RAM, TPM virtual)

**Característica clave**: El script es **idempotente**, puedes ejecutarlo múltiples veces sin problemas.

#### Salida Esperada

```
==========================================================================
  Convergencia de Infraestructura LXD - Aplicando IaC
==========================================================================

[1/3] Aplicando Storage Pools...
  → Creando pool 'windows-vms'...
  ✓ Pool 'windows-vms' creado

[2/3] Aplicando Networks...
  → Creando red 'segbr0'...
  ✓ Red 'segbr0' creada
  → Creando red 'winbr0'...
  ✓ Red 'winbr0' creada

[3/3] Aplicando Profiles...
  → Creando perfil 'docker-host'...
  ✓ Perfil 'docker-host' configurado
  → Creando perfil 'win-profile'...
  ✓ Perfil 'win-profile' configurado

==========================================================================
✓ CONVERGENCIA COMPLETADA EXITOSAMENTE
==========================================================================
```

---

## 📄 Manifiestos de Infraestructura

### Storage Pools

#### `iac/00-storage-pools/lvm-thin-pool.yaml`

```yaml
config:
  lvm.thinpool_name: LXDThinPool
  lvm.vg_name: ubuntu-vg
  source: ubuntu-vg
description: Storage pool LVM para VMs de Windows
name: windows-vms
driver: lvm
```

**Propósito**: Pool de almacenamiento LVM optimizado para VMs Windows con thin provisioning.

---

### Networks

#### `iac/01-networks/segbr0.yaml`

```yaml
config:
  ipv4.address: 10.50.0.1/24
  ipv4.nat: "true"
  ipv6.address: none
description: Red bridge para hosts Docker
name: segbr0
type: bridge
```

**Propósito**: Red aislada para contenedores Docker con NAT habilitado.

#### `iac/01-networks/winbr0.yaml`

```yaml
config:
  ipv4.address: 10.60.0.1/24
  ipv4.nat: "true"
  ipv6.address: none
description: Red bridge para VMs Windows
name: winbr0
type: bridge
```

**Propósito**: Red aislada para VMs Windows con NAT habilitado.

---

### Profiles

#### `iac/02-profiles/docker-host.yaml`

```yaml
config:
  security.nesting: "true"
description: Perfil para contenedores que ejecutan Docker
devices:
  eth0:
    name: eth0
    network: segbr0
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: docker-host
```

**Propósito**: Perfil para contenedores LXD que ejecutarán Docker (requiere nesting).

**Uso**:
```bash
lxc launch ubuntu:22.04 mi-docker-host --profile docker-host
```

#### `iac/02-profiles/windows-vm.yaml`

```yaml
config:
  limits.cpu: "4"
  limits.memory: 12GiB
  security.secureboot: "false"
  security.hyperv: "true"
description: Perfil optimizado para VMs Windows 11
devices:
  eth0:
    name: eth0
    network: winbr0
    type: nic
  root:
    path: /
    pool: windows-vms
    type: disk
  vtpm:
    type: tpm
name: win-profile
```

**Propósito**: Perfil optimizado para Windows 11 con TPM virtual y Hyper-V.

**Uso**:
```bash
lxc init windows/11 mi-windows-vm --vm --profile win-profile
lxc start mi-windows-vm
```

---

## 🔍 Verificación y Troubleshooting

### Verificar Estado de Juju

```bash
# Ver controladores
juju controllers

# Ver estado del controlador
juju status --controller qa-controller

# Acceder al dashboard
juju dashboard
```

### Verificar Infraestructura LXD

```bash
# Listar storage pools
lxc storage list

# Listar redes
lxc network list

# Listar perfiles
lxc profile list

# Ver detalle de un perfil
lxc profile show docker-host
```

### Verificar Volume Group LVM

```bash
# Listar VGs
sudo vgs

# Listar LVs del VG
sudo lvs ubuntu-vg

# Ver uso del thin pool
sudo lvs -a ubuntu-vg
```

### Problemas Comunes

#### Error: "KVM not available"

**Causa**: Virtualización no habilitada en BIOS/UEFI

**Solución**:
1. Reinicia el servidor
2. Accede a BIOS/UEFI (F2, DEL, F12, etc.)
3. Busca "Virtualization Technology", "VT-x" o "AMD-V"
4. Habilita la opción
5. Guarda y reinicia

#### Error: "Volume group ubuntu-vg not found"

**Causa**: No existe el VG necesario para el storage pool LVM

**Solución**:
```bash
# Crear VG (ejemplo con disco /dev/sdb)
sudo pvcreate /dev/sdb
sudo vgcreate ubuntu-vg /dev/sdb
```

#### Error: "LXD not ready"

**Causa**: LXD no fue inicializado correctamente

**Solución**:
```bash
sudo lxd init --auto
lxd waitready -t 30
```

#### El firewall bloquea Juju Dashboard

**Solución**: Abre el puerto 17070 en UFW (opcional, solo si necesitas acceso remoto)
```bash
sudo ufw allow 17070/tcp
```

---

## 🏗️ Arquitectura

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                    Bare Metal Server                            │
│                    Ubuntu 22.04 LTS                             │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    LXD Daemon                             │ │
│  │                                                           │ │
│  │  ┌─────────────────┐  ┌─────────────────┐               │ │
│  │  │ Juju Controller │  │  Storage Pools  │               │ │
│  │  │  qa-controller  │  │  - windows-vms  │               │ │
│  │  │  (Container)    │  │    (LVM thin)   │               │ │
│  │  └─────────────────┘  └─────────────────┘               │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │            Networks                                  │ │ │
│  │  │  - segbr0 (10.50.0.1/24) → Docker hosts            │ │ │
│  │  │  - winbr0 (10.60.0.1/24) → Windows VMs             │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │            Profiles                                  │ │ │
│  │  │  - docker-host  (nesting enabled)                   │ │ │
│  │  │  - win-profile  (4vCPU, 12GB, TPM)                  │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Security Layer                         │ │
│  │  - UFW Firewall (deny incoming by default)               │ │
│  │  - Fail2ban (brute force protection)                     │ │
│  │  - Kernel hardening (swappiness, ip_forward)             │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Flujo de Trabajo GitOps

```
Developer              Git Repository              Bare Metal Server
    │                        │                            │
    │  1. Commit YAML        │                            │
    │ ──────────────────────>│                            │
    │                        │                            │
    │                        │  2. Pull repository        │
    │                        │<───────────────────────────│
    │                        │                            │
    │                        │  3. Run converge.sh        │
    │                        │                            │
    │                        │  4. Apply state            │
    │                        │ ──────────────────────────>│
    │                        │                            │
    │                        │  5. Verify convergence     │
    │                        │<───────────────────────────│
```

---

## 💡 Mejores Prácticas

### 1. Versionado de Infraestructura

- ✅ Todos los cambios a la infraestructura deben pasar por Git
- ✅ Usa commits semánticos: `feat:`, `fix:`, `docs:`
- ✅ Crea branches para cambios experimentales
- ✅ Usa Pull Requests para revisión de cambios

### 2. Idempotencia

- ✅ El script `converge.sh` puede ejecutarse múltiples veces
- ✅ Detecta recursos existentes y los omite
- ✅ Solo aplica cambios cuando es necesario

### 3. Seguridad

- ✅ Firewall restrictivo por defecto (UFW)
- ✅ Solo puerto 22 (SSH) abierto inicialmente
- ✅ Fail2ban para protección contra fuerza bruta
- ✅ Actualización regular del sistema

### 4. Documentación

- ✅ Comenta tus cambios en los YAML
- ✅ Documenta razones de configuraciones personalizadas
- ✅ Mantén este README actualizado

### 5. Backup

Antes de cambios importantes:

```bash
# Backup de configuración LXD
lxc config show > /root/lxd-config-backup.yaml

# Backup de perfiles
lxc profile list --format=yaml > /root/lxd-profiles-backup.yaml

# Backup de redes
lxc network list --format=yaml > /root/lxd-networks-backup.yaml
```

### 6. Testing

- ✅ Prueba cambios en un entorno de desarrollo primero
- ✅ Usa máquinas virtuales para validar bootstrap
- ✅ Verifica convergencia después de cada cambio

---

## 📚 Referencias

- **Juju**: https://juju.is/docs
- **LXD**: https://ubuntu.com/lxd/docs
- **Ubuntu Server**: https://ubuntu.com/server/docs
- **GitOps**: https://www.gitops.tech/
- **LVM**: https://ubuntu.com/server/docs/lvm

---

## 🤝 Contribución

Para contribuir a este repositorio:

1. Fork el repositorio
2. Crea un branch: `git checkout -b feature/nueva-funcionalidad`
3. Realiza tus cambios en los manifiestos YAML
4. Prueba con `converge.sh`
5. Commit: `git commit -m 'feat: añadir nuevo perfil XYZ'`
6. Push: `git push origin feature/nueva-funcionalidad`
7. Crea un Pull Request

---

## 📝 Licencia

Este proyecto GitOps está disponible bajo los mismos términos del proyecto principal.

---

<div align="center">

**Infraestructura Automatizada, Reproducible y Versionada** 🚀

*Hecho con ❤️ para la comunidad de DevOps e IaC*

</div>
