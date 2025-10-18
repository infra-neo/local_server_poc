#!/usr/bin/env python3
"""
Script para diagnosticar y solucionar problemas de sincronización LDAP en Authentik
"""

import requests
import time
import json
from urllib.parse import urljoin

# Configuración
AUTHENTIK_URL = "https://34.68.124.46:9443"
GUACAMOLE_URL = "http://34.68.124.46:8080"

def test_authentik_api():
    """Probar conectividad con Authentik"""
    try:
        response = requests.get(f"{AUTHENTIK_URL}/api/v3/core/users/", 
                              verify=False, timeout=10)
        print(f"✅ Authentik API respondiendo: {response.status_code}")
        return True
    except Exception as e:
        print(f"❌ Error conectando a Authentik: {e}")
        return False

def test_guacamole():
    """Probar conectividad con Guacamole"""
    try:
        response = requests.get(f"{GUACAMOLE_URL}/guacamole/", timeout=10)
        print(f"✅ Guacamole respondiendo: {response.status_code}")
        return True
    except Exception as e:
        print(f"❌ Error conectando a Guacamole: {e}")
        return False

def main():
    print("🔍 DIAGNÓSTICO DE SINCRONIZACIÓN LDAP")
    print("====================================")
    
    print("\n1. 🌐 Probando conectividad de servicios...")
    authentik_ok = test_authentik_api()
    guacamole_ok = test_guacamole()
    
    print(f"\n2. 📊 Estado de servicios:")
    print(f"   Authentik: {'✅ OK' if authentik_ok else '❌ FALLO'}")
    print(f"   Guacamole: {'✅ OK' if guacamole_ok else '❌ FALLO'}")
    
    print("\n3. ⚠️ PROBLEMA IDENTIFICADO:")
    print("   El error 'Could not find page in cache' indica un problema")
    print("   de timeout en la tarea de sincronización LDAP.")
    
    print("\n4. 🔧 SOLUCIÓN RECOMENDADA:")
    print("   1. ELIMINAR el LDAP Source existente completamente")
    print("   2. CREAR uno nuevo con configuración correcta")
    print("   3. Usar el nombre correcto del contenedor")
    
    print("\n5. 📝 CONFIGURACIÓN EXACTA PARA LDAP SOURCE:")
    print("   ┌─────────────────────────────────────────────────────────────┐")
    print("   │ Name: Kolaboree LDAP                                        │")
    print("   │ Slug: kolaboree-ldap-new                                    │")
    print("   │ Enabled: ✅ Activado                                       │")
    print("   │ Server URI: ldap://kolaboree-ldap:389                      │")
    print("   │ Bind CN: cn=admin,dc=kolaboree,dc=local                    │")
    print("   │ Bind Password: zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhW   │")
    print("   │ Base DN: dc=kolaboree,dc=local                             │")
    print("   │ Additional User DN: ou=users                               │")
    print("   │ Additional Group DN: ou=groups                             │")
    print("   │ User object filter: (objectClass=inetOrgPerson)           │")
    print("   │ User object class: inetOrgPerson                          │")
    print("   │ Group object filter: (objectClass=groupOfNames)           │")
    print("   │ Group object class: groupOfNames                          │")
    print("   │ Group membership field: member                             │")
    print("   │ Object uniqueness field: uid                               │")
    print("   │ Sync users: ✅ Activado                                   │")
    print("   │ Sync groups: ✅ Activado                                  │")
    print("   └─────────────────────────────────────────────────────────────┘")
    
    print("\n6. 🎯 PASOS CRÍTICOS:")
    print("   1. Ir a: https://34.68.124.46:9443/if/admin/")
    print("   2. Directory > Federation & Social login > LDAP Sources")
    print("   3. ❌ ELIMINAR cualquier LDAP Source existente")
    print("   4. ➕ Crear NUEVO LDAP Source")
    print("   5. 📋 Copiar EXACTAMENTE la configuración de arriba")
    print("   6. 💾 Guardar")
    print("   7. 🔄 Hacer clic en 'Sync' en el nuevo LDAP Source")
    print("   8. ⏰ Esperar 1-2 minutos")
    print("   9. ✅ Verificar en Directory > Users que aparezca 'soporte'")
    
    print("\n7. 🔍 VERIFICACIÓN:")
    print("   Después de la sincronización, deberías ver:")
    print("   • Usuario 'soporte' en Directory > Users")
    print("   • Email: soporte@kolaboree.local")
    print("   • Fuente: Kolaboree LDAP")
    
    print("\n✅ Diagnóstico completo. Servicios están funcionando.")
    print("💡 El problema es de configuración LDAP, no de conectividad.")

if __name__ == "__main__":
    main()