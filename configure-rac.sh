#!/bin/bash

# Script para configurar conexiones RDP automáticas en Guacamole
# Este script ayuda a automatizar el proceso de conexión RDP

echo "🖥️  Configurador de Conexiones RDP - Kolaboree NG"
echo "=================================================="

# Función para mostrar ayuda de uso
show_usage() {
    echo "Este script ayuda con las conexiones RDP a través de Guacamole."
    echo ""
    echo "Para configurar conexiones RDP automáticas en Windows:"
    echo "1. En la máquina Windows, abrir 'Configuración del sistema'"
    echo "2. Ir a 'Remoto' -> 'Escritorio remoto'"
    echo "3. Habilitar 'Habilitar Escritorio remoto'"
    echo "4. Agregar usuarios que pueden conectarse remotamente"
    echo ""
    echo "Para evitar los mensajes de confirmación:"
    echo "1. Abrir 'gpedit.msc' (Editor de directivas de grupo local)"
    echo "2. Ir a: Configuración del equipo -> Plantillas administrativas"
    echo "   -> Componentes de Windows -> Servicios de Escritorio remoto"
    echo "   -> Host de sesión de Escritorio remoto -> Conexiones"
    echo "3. Habilitar 'Permitir que los usuarios se conecten remotamente'"
    echo "4. Configurar 'Nivel de autenticación': Permitir conexiones desde cualquier versión"
    echo ""
}

# Función para verificar el estado de Guacamole
check_guacamole() {
    echo "🔍 Verificando estado de Guacamole..."
    
    # Verificar si Guacamole está ejecutándose
    if curl -s -f http://localhost:8080/guacamole/ > /dev/null; then
        echo "✅ Guacamole está funcionando correctamente"
        
        # Obtener conexiones disponibles
        echo "📋 Conexiones disponibles:"
        curl -s http://localhost:8000/api/v1/rac/connections | jq -r '.[] | "  - \(.name) (\(.protocol)): \(.description)"'
        
    else
        echo "❌ Guacamole no está respondiendo"
        echo "   Ejecutar: docker-compose up -d guacamole"
    fi
}

# Función para mostrar información de conexión
show_connection_info() {
    echo ""
    echo "🔗 Información de Acceso:"
    echo "========================"
    echo "Frontend (RAC Dashboard): http://localhost:3000/user/rac"
    echo "Backend API:              http://localhost:8000/api/v1/rac/connections"
    echo "Guacamole directo:        http://localhost:8080/guacamole/"
    echo ""
    echo "Credenciales Guacamole:"
    echo "  Usuario: guacadmin"
    echo "  Contraseña: guacadmin"
    echo ""
}

# Función para configurar permisos automáticos
configure_rdp_permissions() {
    echo ""
    echo "⚙️  Configuración recomendada para RDP sin confirmaciones:"
    echo "========================================================="
    echo ""
    echo "En la máquina Windows (100.95.223.18):"
    echo ""
    echo "1. Abrir PowerShell como Administrador y ejecutar:"
    echo '   Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0'
    echo '   Enable-NetFirewallRule -DisplayGroup "Remote Desktop"'
    echo ""
    echo "2. Para evitar mensajes de confirmación, ejecutar:"
    echo '   Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 0'
    echo ""
    echo "3. Para permitir múltiples sesiones simultáneas:"
    echo '   Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fSingleSessionPerUser" -Value 0'
    echo ""
    echo "4. Reiniciar el servicio de Terminal Services:"
    echo '   Restart-Service TermService -Force'
    echo ""
}

# Función principal
main() {
    case "${1:-help}" in
        "check")
            check_guacamole
            ;;
        "info")
            show_connection_info
            ;;
        "rdp-config")
            configure_rdp_permissions
            ;;
        "help"|*)
            show_usage
            echo ""
            echo "Comandos disponibles:"
            echo "  $0 check      - Verificar estado de Guacamole y conexiones"
            echo "  $0 info       - Mostrar información de acceso"
            echo "  $0 rdp-config - Mostrar comandos para configurar RDP automático"
            echo "  $0 help       - Mostrar esta ayuda"
            ;;
    esac
}

# Ejecutar función principal con argumentos
main "$@"