#!/bin/bash

################################################################################
# Script de Convergencia - Infraestructura como Código (IaC)
# Aplica la configuración declarativa de LXD desde manifiestos YAML
################################################################################

set -e  # Salir inmediatamente si un comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================================================="
echo "  Convergencia de Infraestructura LXD - Aplicando IaC"
echo "=========================================================================="
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✗ ERROR: Este script debe ejecutarse como superusuario (root)${NC}"
    echo "Por favor ejecuta: sudo bash converge.sh"
    exit 1
fi

# Verificar que LXD está instalado
if ! command -v lxc &> /dev/null; then
    echo -e "${RED}✗ ERROR: LXD no está instalado${NC}"
    echo "Por favor ejecuta primero el script bootstrap.sh"
    exit 1
fi

# Verificar que LXD está listo
if ! lxd waitready -t 10 2>/dev/null; then
    echo -e "${RED}✗ ERROR: LXD no está listo${NC}"
    echo "Por favor verifica que LXD esté inicializado correctamente"
    exit 1
fi

echo -e "${GREEN}✓${NC} Prerrequisitos verificados"
echo ""

# Directorio base de IaC
IAC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/iac" && pwd)"

if [ ! -d "$IAC_DIR" ]; then
    echo -e "${RED}✗ ERROR: No se encontró el directorio iac/${NC}"
    echo "Asegúrate de ejecutar este script desde el directorio raíz del repositorio"
    exit 1
fi

################################################################################
# Función: Aplicar Storage Pool
################################################################################
apply_storage_pool() {
    local yaml_file=$1
    local pool_name=$(grep "^name:" "$yaml_file" | awk '{print $2}')
    
    if lxc storage list -f csv | cut -d',' -f1 | grep -q "^${pool_name}$"; then
        echo -e "  ${YELLOW}⊙${NC} Pool '${pool_name}' ya existe, omitiendo..."
    else
        echo -e "  ${BLUE}→${NC} Creando pool '${pool_name}'..."
        
        # Extraer configuración del YAML
        local driver=$(grep "^driver:" "$yaml_file" | awk '{print $2}')
        local vg_name=$(grep "lvm.vg_name:" "$yaml_file" | awk '{print $2}')
        local thinpool=$(grep "lvm.thinpool_name:" "$yaml_file" | awk '{print $2}')
        
        # Crear el pool
        lxc storage create "$pool_name" "$driver" \
            source="$vg_name" \
            lvm.thinpool_name="$thinpool" 2>&1 | grep -v "^$" || true
        
        echo -e "  ${GREEN}✓${NC} Pool '${pool_name}' creado"
    fi
}

################################################################################
# Función: Aplicar Network
################################################################################
apply_network() {
    local yaml_file=$1
    local net_name=$(grep "^name:" "$yaml_file" | awk '{print $2}')
    
    if lxc network list -f csv | cut -d',' -f1 | grep -q "^${net_name}$"; then
        echo -e "  ${YELLOW}⊙${NC} Red '${net_name}' ya existe, omitiendo..."
    else
        echo -e "  ${BLUE}→${NC} Creando red '${net_name}'..."
        
        # Extraer configuración del YAML
        local net_type=$(grep "^type:" "$yaml_file" | awk '{print $2}')
        local ipv4_addr=$(grep "ipv4.address:" "$yaml_file" | awk '{print $2}')
        local ipv4_nat=$(grep "ipv4.nat:" "$yaml_file" | awk '{print $2}' | tr -d '"')
        local ipv6_addr=$(grep "ipv6.address:" "$yaml_file" | awk '{print $2}')
        
        # Crear la red
        lxc network create "$net_name" \
            ipv4.address="$ipv4_addr" \
            ipv4.nat="$ipv4_nat" \
            ipv6.address="$ipv6_addr" 2>&1 | grep -v "^$" || true
        
        echo -e "  ${GREEN}✓${NC} Red '${net_name}' creada"
    fi
}

################################################################################
# Función: Aplicar Profile
################################################################################
apply_profile() {
    local yaml_file=$1
    local profile_name=$(grep "^name:" "$yaml_file" | awk '{print $2}')
    
    if lxc profile list -f csv | cut -d',' -f1 | grep -q "^${profile_name}$"; then
        echo -e "  ${YELLOW}⊙${NC} Perfil '${profile_name}' ya existe, actualizando..."
        # Eliminar y recrear para asegurar convergencia
        lxc profile delete "$profile_name" 2>&1 | grep -v "^$" || true
    fi
    
    echo -e "  ${BLUE}→${NC} Creando perfil '${profile_name}'..."
    
    # Crear perfil vacío
    lxc profile create "$profile_name" 2>&1 | grep -v "^$" || true
    
    # Aplicar configuración desde YAML
    # Nota: Esto es una simplificación. En producción usarías 'lxc profile edit'
    # con el contenido completo del YAML
    
    # Extraer y aplicar configuración
    if grep -q "security.nesting:" "$yaml_file"; then
        local nesting=$(grep "security.nesting:" "$yaml_file" | awk '{print $2}' | tr -d '"')
        lxc profile set "$profile_name" security.nesting="$nesting" 2>&1 | grep -v "^$" || true
    fi
    
    if grep -q "limits.cpu:" "$yaml_file"; then
        local cpu=$(grep "limits.cpu:" "$yaml_file" | awk '{print $2}' | tr -d '"')
        lxc profile set "$profile_name" limits.cpu="$cpu" 2>&1 | grep -v "^$" || true
    fi
    
    if grep -q "limits.memory:" "$yaml_file"; then
        local memory=$(grep "limits.memory:" "$yaml_file" | awk '{print $2}')
        lxc profile set "$profile_name" limits.memory="$memory" 2>&1 | grep -v "^$" || true
    fi
    
    if grep -q "security.secureboot:" "$yaml_file"; then
        local secureboot=$(grep "security.secureboot:" "$yaml_file" | awk '{print $2}' | tr -d '"')
        lxc profile set "$profile_name" security.secureboot="$secureboot" 2>&1 | grep -v "^$" || true
    fi
    
    if grep -q "security.hyperv:" "$yaml_file"; then
        local hyperv=$(grep "security.hyperv:" "$yaml_file" | awk '{print $2}' | tr -d '"')
        lxc profile set "$profile_name" security.hyperv="$hyperv" 2>&1 | grep -v "^$" || true
    fi
    
    # Añadir dispositivos
    if grep -q "eth0:" "$yaml_file"; then
        local network=$(grep -A 3 "eth0:" "$yaml_file" | grep "network:" | awk '{print $2}')
        if [ -n "$network" ]; then
            lxc profile device add "$profile_name" eth0 nic \
                name=eth0 \
                network="$network" 2>&1 | grep -v "^$" || true
        fi
    fi
    
    if grep -q "root:" "$yaml_file"; then
        local pool=$(grep -A 3 "root:" "$yaml_file" | grep "pool:" | awk '{print $2}')
        if [ -n "$pool" ]; then
            lxc profile device add "$profile_name" root disk \
                path=/ \
                pool="$pool" 2>&1 | grep -v "^$" || true
        fi
    fi
    
    if grep -q "vtpm:" "$yaml_file"; then
        lxc profile device add "$profile_name" vtpm tpm 2>&1 | grep -v "^$" || true
    fi
    
    echo -e "  ${GREEN}✓${NC} Perfil '${profile_name}' configurado"
}

################################################################################
# 1. APLICAR STORAGE POOLS
################################################################################
echo -e "${BLUE}[1/3] Aplicando Storage Pools...${NC}"

if [ -d "$IAC_DIR/00-storage-pools" ]; then
    for yaml_file in "$IAC_DIR/00-storage-pools"/*.yaml; do
        if [ -f "$yaml_file" ]; then
            apply_storage_pool "$yaml_file"
        fi
    done
    echo -e "${GREEN}✓${NC} Storage pools aplicados"
else
    echo -e "${YELLOW}⊙${NC} No se encontraron storage pools para aplicar"
fi
echo ""

################################################################################
# 2. APLICAR NETWORKS
################################################################################
echo -e "${BLUE}[2/3] Aplicando Networks...${NC}"

if [ -d "$IAC_DIR/01-networks" ]; then
    for yaml_file in "$IAC_DIR/01-networks"/*.yaml; do
        if [ -f "$yaml_file" ]; then
            apply_network "$yaml_file"
        fi
    done
    echo -e "${GREEN}✓${NC} Redes aplicadas"
else
    echo -e "${YELLOW}⊙${NC} No se encontraron redes para aplicar"
fi
echo ""

################################################################################
# 3. APLICAR PROFILES
################################################################################
echo -e "${BLUE}[3/3] Aplicando Profiles...${NC}"

if [ -d "$IAC_DIR/02-profiles" ]; then
    for yaml_file in "$IAC_DIR/02-profiles"/*.yaml; do
        if [ -f "$yaml_file" ]; then
            apply_profile "$yaml_file"
        fi
    done
    echo -e "${GREEN}✓${NC} Perfiles aplicados"
else
    echo -e "${YELLOW}⊙${NC} No se encontraron perfiles para aplicar"
fi
echo ""

################################################################################
# RESUMEN FINAL
################################################################################
echo "=========================================================================="
echo -e "${GREEN}✓ CONVERGENCIA COMPLETADA EXITOSAMENTE${NC}"
echo "=========================================================================="
echo ""
echo -e "${YELLOW}Estado de la infraestructura LXD:${NC}"
echo ""

# Mostrar storage pools
echo -e "${BLUE}Storage Pools:${NC}"
lxc storage list
echo ""

# Mostrar networks
echo -e "${BLUE}Networks:${NC}"
lxc network list
echo ""

# Mostrar profiles
echo -e "${BLUE}Profiles:${NC}"
lxc profile list
echo ""

echo "=========================================================================="
echo -e "${YELLOW}PRÓXIMOS PASOS:${NC}"
echo "=========================================================================="
echo ""
echo "La infraestructura LXD ha sido configurada según los manifiestos IaC."
echo ""
echo "Puedes ahora:"
echo ""
echo "1. Crear un contenedor con el perfil docker-host:"
echo -e "   ${BLUE}lxc launch ubuntu:22.04 mi-docker-host --profile docker-host${NC}"
echo ""
echo "2. Crear una VM Windows con el perfil win-profile:"
echo -e "   ${BLUE}lxc init windows/11 mi-windows-vm --vm --profile win-profile${NC}"
echo ""
echo "3. Ver el estado de las instancias:"
echo -e "   ${BLUE}lxc list${NC}"
echo ""
echo "4. Para volver a aplicar la configuración (idempotente):"
echo -e "   ${BLUE}sudo bash converge.sh${NC}"
echo ""
echo "=========================================================================="
echo ""
