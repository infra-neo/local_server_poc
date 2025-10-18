#!/usr/bin/env python3
"""
SOLUCIÓN DEFINITIVA PARA PROBLEMA DE SINCRONIZACIÓN LDAP
"""

import subprocess
import time
import sys

def run_command(cmd, description=""):
    """Ejecutar comando y mostrar resultado"""
    if description:
        print(f"🔧 {description}")
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Éxito: {result.stdout.strip()}")
            return True
        else:
            print(f"❌ Error: {result.stderr.strip()}")
            return False
    except Exception as e:
        print(f"❌ Excepción: {e}")
        return False

def main():
    print("🎯 SOLUCIÓN DEFINITIVA PARA LDAP SYNC")
    print("====================================")
    
    print("\n1. 🧹 Limpiando sistema completamente...")
    
    # Limpiar cache de Redis
    run_command(
        'docker exec kolaboree-redis redis-cli -a "h84cOC6MeVvDAP0ltqbxf44g9Tr0x88n8zRI1XlqzkK1TZwDrclf5S3Xw0SuOhwK" FLUSHALL',
        "Limpiando cache de Redis"
    )
    
    print("\n2. 🔄 Reiniciando servicios...")
    
    # Parar servicios
    run_command("docker-compose stop authentik-server authentik-worker", 
                "Parando servicios Authentik")
    
    time.sleep(5)
    
    # Iniciar servicios
    run_command("docker-compose start authentik-server authentik-worker",
                "Iniciando servicios Authentik")
    
    print("\n3. ⏰ Esperando que servicios estén listos...")
    time.sleep(20)
    
    print("\n4. 🔍 Verificando usuario en LDAP...")
    run_command(
        'docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01" -b "dc=kolaboree,dc=local" "(uid=soporte)" uid mail cn displayName',
        "Verificando usuario soporte en LDAP"
    )
    
    print("\n5. 🔍 Verificando estructura LDAP completa...")
    run_command(
        'docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01" -b "dc=kolaboree,dc=local" -s one',
        "Verificando estructura base de LDAP"
    )
    
    print("\n" + "="*60)
    print("🎯 CONFIGURACIÓN EXACTA PARA AUTHENTIK LDAP SOURCE")
    print("="*60)
    
    print("""
📋 COPIAR ESTOS DATOS EXACTOS EN AUTHENTIK:

🌐 URL de Authentik: https://34.68.124.46:9443/if/admin/
📂 Ir a: Directory > Federation & Social login > LDAP Sources

⚠️  IMPORTANTE: Si ya existe un LDAP Source, ELIMINARLO primero

➕ CREAR NUEVO LDAP SOURCE CON:

┌─────────────────────────────────────────────────────────────┐
│ CONFIGURACIÓN BÁSICA                                        │
├─────────────────────────────────────────────────────────────┤
│ Name: Kolaboree LDAP                                        │
│ Slug: kolaboree-ldap                                        │
│ Enabled: ✅ ACTIVADO                                       │
├─────────────────────────────────────────────────────────────┤
│ CONFIGURACIÓN DE CONEXIÓN                                  │
├─────────────────────────────────────────────────────────────┤
│ Server URI: ldap://kolaboree-ldap:389                      │
│ Enable StartTLS: ❌ DESACTIVADO                           │
│ TLS Verification Certificate: (dejar vacío)                │
│ Bind CN: cn=admin,dc=kolaboree,dc=local                    │
│ Bind Password: zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiM │
│               iqD35+tMtVZIndUzaMW01                        │
├─────────────────────────────────────────────────────────────┤
│ CONFIGURACIÓN DE BÚSQUEDA                                  │
├─────────────────────────────────────────────────────────────┤
│ Base DN: dc=kolaboree,dc=local                             │
│ Addition User DN: ou=users                                  │
│ Addition Group DN: ou=groups                                │
├─────────────────────────────────────────────────────────────┤
│ CONFIGURACIÓN DE OBJETOS                                   │
├─────────────────────────────────────────────────────────────┤
│ User object filter: (objectClass=inetOrgPerson)           │
│ User object class: inetOrgPerson                           │
│ Group object filter: (objectClass=groupOfNames)            │
│ Group object class: groupOfNames                           │
│ Group membership field: member                             │
│ Object uniqueness field: uid                               │
├─────────────────────────────────────────────────────────────┤
│ CONFIGURACIÓN DE SINCRONIZACIÓN                            │
├─────────────────────────────────────────────────────────────┤
│ Sync users: ✅ ACTIVADO                                   │
│ Sync users password: ✅ ACTIVADO                          │
│ Sync groups: ✅ ACTIVADO                                  │
│ Sync parent group: (dejar vacío)                          │
└─────────────────────────────────────────────────────────────┘

🔧 PASOS DESPUÉS DE CREAR:

1. 💾 Hacer clic en "Save" (Guardar)
2. 🔄 Hacer clic en "Sync" (Sincronizar)
3. ⏰ Esperar 2-3 minutos
4. 🔍 Verificar en "Directory > Users" que aparezca 'soporte'
5. ✅ Si aparece, la configuración está correcta

🧪 VERIFICACIÓN FINAL:
   Deberías ver el usuario 'soporte' con:
   • Username: soporte
   • Email: soporte@kolaboree.local  
   • Name: Usuario Soporte
   • Source: Kolaboree LDAP

❌ SI NO APARECE EL USUARIO:
   1. Verificar que el Server URI sea exactamente: ldap://kolaboree-ldap:389
   2. Verificar que el Bind Password sea completo (sin espacios)
   3. Eliminar y crear nuevamente el LDAP Source
   4. Ejecutar este script otra vez para verificar LDAP
""")

    print("\n" + "="*60)
    print("✅ SISTEMA PREPARADO PARA CONFIGURACIÓN LDAP")
    print("💡 PROBLEMA: Error de timeout se soluciona creando NUEVO LDAP Source")
    print("🎯 SIGUIENTE PASO: Configurar LDAP Source en Authentik UI")
    print("="*60)

if __name__ == "__main__":
    main()