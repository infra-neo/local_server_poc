#!/bin/bash

################################################################################
# Bootstrap Script para Servidor Bare Metal Ubuntu 22.04
# Prepara el host para Juju Controller sobre LXD
################################################################################

set -e  # Salir inmediatamente si un comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================================================="
echo "  Bootstrap de Servidor Bare Metal - Juju sobre LXD"
echo "=========================================================================="
echo ""

################################################################################
# 1. VALIDACIÓN INICIAL
################################################################################
echo -e "${BLUE}[1/7] Validando permisos y capacidades del sistema...${NC}"

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✗ ERROR: Este script debe ejecutarse como superusuario (root)${NC}"
    echo "Por favor ejecuta: sudo bash bootstrap.sh"
    exit 1
fi
echo -e "${GREEN}✓${NC} Script ejecutándose como superusuario"

# Verificar virtualización por hardware (KVM)
if ! command -v kvm-ok &> /dev/null; then
    echo "  Instalando cpu-checker para verificar KVM..."
    apt-get update -qq
    apt-get install -y cpu-checker > /dev/null 2>&1
fi

if ! kvm-ok > /dev/null 2>&1; then
    echo -e "${RED}✗ ERROR: La virtualización por hardware NO está habilitada${NC}"
    echo ""
    echo "La virtualización KVM no está disponible en este sistema."
    echo "Por favor:"
    echo "  1. Accede a la BIOS/UEFI de tu servidor"
    echo "  2. Habilita Intel VT-x o AMD-V"
    echo "  3. Reinicia el servidor"
    echo "  4. Vuelve a ejecutar este script"
    exit 1
fi
echo -e "${GREEN}✓${NC} Virtualización por hardware (KVM) está habilitada"
echo ""

################################################################################
# 2. ACTUALIZACIÓN Y DEPENDENCIAS CLAVE
################################################################################
echo -e "${BLUE}[2/7] Actualizando sistema e instalando dependencias...${NC}"

# Actualizar sistema
echo "  Actualizando lista de paquetes..."
apt-get update -qq

echo "  Actualizando paquetes del sistema (esto puede tomar varios minutos)..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1

# Instalar paquetes esenciales
echo "  Instalando paquetes esenciales para virtualización y seguridad..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    qemu-kvm \
    libvirt-daemon-system \
    bridge-utils \
    lvm2 \
    git \
    ufw \
    fail2ban \
    cpu-checker \
    > /dev/null 2>&1

echo -e "${GREEN}✓${NC} Sistema actualizado y dependencias instaladas"
echo ""

################################################################################
# 3. CONFIGURACIÓN DE SEGURIDAD BASE (HARDENING)
################################################################################
echo -e "${BLUE}[3/7] Configurando seguridad base del sistema (UFW Firewall)...${NC}"

# Configurar UFW con políticas restrictivas
echo "  Configurando políticas por defecto del firewall..."
ufw --force default deny incoming > /dev/null 2>&1
ufw --force default allow outgoing > /dev/null 2>&1

# Permitir SSH
echo "  Habilitando acceso SSH (puerto 22/tcp)..."
ufw --force allow 22/tcp > /dev/null 2>&1

# Activar firewall
echo "  Activando firewall..."
ufw --force enable > /dev/null 2>&1

echo -e "${GREEN}✓${NC} Firewall UFW configurado y activado"
echo "  • Política de entrada: DENY"
echo "  • Política de salida: ALLOW"
echo "  • Puerto SSH (22/tcp): PERMITIDO"
echo ""

################################################################################
# 4. OPTIMIZACIÓN DEL KERNEL
################################################################################
echo -e "${BLUE}[4/7] Aplicando optimizaciones del kernel...${NC}"

# Verificar si las configuraciones ya existen
if ! grep -q "^vm.swappiness=10" /etc/sysctl.conf 2>/dev/null; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "  ✓ Añadida configuración vm.swappiness=10"
fi

if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "  ✓ Añadida configuración net.ipv4.ip_forward=1"
fi

# Aplicar configuración sin reiniciar
sysctl -p > /dev/null 2>&1

echo -e "${GREEN}✓${NC} Optimizaciones del kernel aplicadas"
echo ""

################################################################################
# 5. INSTALACIÓN DE SNAPS DE CANONICAL
################################################################################
echo -e "${BLUE}[5/7] Instalando LXD y Juju desde Snap...${NC}"

# Instalar LXD
if ! command -v lxd &> /dev/null; then
    echo "  Instalando LXD (stable channel)..."
    snap install lxd --channel=stable 2>&1 | grep -v "^$" || true
    echo -e "${GREEN}✓${NC} LXD instalado"
else
    echo -e "${GREEN}✓${NC} LXD ya está instalado"
fi

# Instalar Juju
if ! command -v juju &> /dev/null; then
    echo "  Instalando Juju (stable channel)..."
    snap install juju --channel=stable 2>&1 | grep -v "^$" || true
    echo -e "${GREEN}✓${NC} Juju instalado"
else
    echo -e "${GREEN}✓${NC} Juju ya está instalado"
fi

# Inicializar LXD (sin interacción)
echo "  Inicializando LXD con configuración por defecto..."
if ! lxd waitready -t 30 2>/dev/null; then
    lxd init --auto 2>&1 | grep -v "^$" || true
    sleep 5
fi

echo -e "${GREEN}✓${NC} LXD y Juju instalados y configurados"
echo ""

################################################################################
# 6. INICIALIZACIÓN DEL CONTROLADOR JUJU
################################################################################
echo -e "${BLUE}[6/7] Inicializando Juju Controller sobre LXD...${NC}"

# Añadir LXD como cloud para Juju
echo "  Registrando LXD local como proveedor de nube 'qa-baremetal'..."
if ! juju clouds 2>/dev/null | grep -q "qa-baremetal"; then
    juju add-cloud qa-baremetal localhost --controller localhost 2>&1 | grep -v "^$" || true
    echo "  ✓ Nube 'qa-baremetal' añadida"
else
    echo "  ✓ Nube 'qa-baremetal' ya existe"
fi

# Bootstrap del controlador Juju
echo "  Realizando bootstrap del controlador 'qa-controller' (esto puede tomar varios minutos)..."
if ! juju controllers 2>/dev/null | grep -q "qa-controller"; then
    juju bootstrap localhost qa-controller \
        --bootstrap-constraints="mem=4G cores=2" \
        --config agent-stream=released 2>&1 | tail -5 || true
    echo -e "${GREEN}✓${NC} Controlador 'qa-controller' creado exitosamente"
else
    echo -e "${GREEN}✓${NC} Controlador 'qa-controller' ya existe"
fi

# Habilitar Juju Dashboard
echo "  Habilitando Juju Dashboard..."
juju dashboard --no-browser 2>&1 || true

echo -e "${GREEN}✓${NC} Controlador Juju inicializado y Dashboard habilitado"
echo ""

################################################################################
# 7. INSTRUCCIONES FINALES
################################################################################
echo -e "${BLUE}[7/7] Bootstrap completado - Acceso al Juju Dashboard${NC}"
echo ""
echo "=========================================================================="
echo -e "${GREEN}✓ BOOTSTRAP FINALIZADO EXITOSAMENTE${NC}"
echo "=========================================================================="
echo ""
echo -e "${YELLOW}Acceso al Juju Dashboard:${NC}"
echo ""

# Obtener URL del dashboard
DASHBOARD_URL=$(juju dashboard 2>&1 | grep -oP 'https://[^\s]+' | head -1 || echo "https://localhost:17070/dashboard")
echo -e "  URL del Dashboard: ${GREEN}${DASHBOARD_URL}${NC}"
echo ""

# Obtener credenciales
echo "Para obtener las credenciales de acceso, ejecuta:"
echo -e "  ${BLUE}juju dashboard${NC}"
echo ""
echo "Para crear un usuario adicional, ejecuta:"
echo -e "  ${BLUE}juju add-user <nombre-usuario>${NC}"
echo -e "  ${BLUE}juju change-user-password <nombre-usuario>${NC}"
echo ""

echo "=========================================================================="
echo -e "${YELLOW}PRÓXIMOS PASOS:${NC}"
echo "=========================================================================="
echo ""
echo "1. Clona este repositorio GitOps en el servidor:"
echo -e "   ${BLUE}git clone <url-repositorio-gitops>${NC}"
echo -e "   ${BLUE}cd <nombre-repositorio>${NC}"
echo ""
echo "2. Ejecuta el script de convergencia para aplicar la configuración IaC:"
echo -e "   ${BLUE}sudo bash converge.sh${NC}"
echo ""
echo "3. Verifica el estado del controlador:"
echo -e "   ${BLUE}juju status${NC}"
echo -e "   ${BLUE}juju controllers${NC}"
echo ""
echo "=========================================================================="
echo ""
echo -e "${GREEN}El servidor está ahora preparado para gestión declarativa con LXD.${NC}"
echo ""
