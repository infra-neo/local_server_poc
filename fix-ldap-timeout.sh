#!/bin/bash
# Script para solucionar el problema de timeout LDAP en Authentik

echo "🔧 SOLUCIONANDO PROBLEMA DE TIMEOUT LDAP"
echo "========================================"

echo "1. 🔍 Verificando contenedores..."
echo "Contenedores de Authentik y LDAP:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(authentik|ldap)"

echo ""
echo "2. 🧹 Limpiando cache de Authentik..."
docker exec kolaboree-redis redis-cli -a "h84cOC6MeVvDAP0ltqbxf44g9Tr0x88n8zRI1XlqzkK1TZwDrclf5S3Xw0SuOhwK" FLUSHALL 2>/dev/null
echo "✅ Cache limpiado"

echo ""
echo "3. 🔄 Reiniciando servicios Authentik..."
docker-compose restart authentik-server authentik-worker
echo "✅ Servicios reiniciados"

echo ""
echo "4. ⏰ Esperando que servicios estén listos..."
sleep 15

echo ""
echo "5. 🔍 Verificando conectividad LDAP..."

# Verificar conectividad desde Authentik a LDAP
echo "Probando conexión desde authentik-server..."
docker exec kolaboree-authentik-server sh -c "nc -zv kolaboree-ldap 389 2>&1 || echo 'Probando con openldap...'"
docker exec kolaboree-authentik-server sh -c "nc -zv openldap 389 2>&1 || echo 'No hay conectividad'"

echo ""
echo "6. 🧪 Verificando usuario en LDAP..."
docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01" -b "dc=kolaboree,dc=local" "(uid=soporte)" uid mail cn

echo ""
echo "🎯 CONFIGURACIÓN CORREGIDA PARA LDAP SOURCE"
echo "=========================================="

echo ""
echo "📝 DATOS EXACTOS PARA NUEVA CONFIGURACIÓN:"
echo "├── Name: Kolaboree LDAP"
echo "├── Slug: kolaboree-ldap" 
echo "├── Enabled: ✅ SÍ"
echo "├── Server URI: ldap://kolaboree-ldap:389"
echo "├── Bind CN: cn=admin,dc=kolaboree,dc=local"
echo "├── Bind Password: zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01"
echo "├── Base DN: dc=kolaboree,dc=local"
echo "├── Addition User DN: ou=users"
echo "├── Addition Group DN: ou=groups"
echo "├── User object filter: (objectClass=inetOrgPerson)"
echo "├── User object class: inetOrgPerson"
echo "├── Group object filter: (objectClass=groupOfNames)"
echo "├── Group object class: groupOfNames"
echo "├── Group membership field: member"
echo "├── Object uniqueness field: uid"
echo "├── Sync users: ✅ SÍ"
echo "└── Sync groups: ✅ SÍ"

echo ""
echo "⚠️ IMPORTANTE:"
echo "1. Si ya existe un LDAP Source, ELIMINARLO primero"
echo "2. Crear uno NUEVO con los datos de arriba"
echo "3. Server URI DEBE ser: ldap://kolaboree-ldap:389"
echo "   (no usar 'openldap')"

echo ""
echo "🔧 PASOS:"
echo "1. Ir a: https://34.68.124.46:9443/if/admin/"
echo "2. Directory > Federation & Social login > LDAP Sources"
echo "3. Si existe LDAP Source anterior, eliminarlo"
echo "4. Crear nuevo LDAP Source con datos exactos de arriba"
echo "5. Guardar"
echo "6. Hacer clic en 'Sync' en el LDAP Source creado"
echo "7. Esperar y verificar en Directory > Users"

echo ""
echo "✅ Sistema preparado para nueva configuración LDAP"