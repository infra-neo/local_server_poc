#!/bin/bash
# Script para agregar usuario soporte con la contraseña LDAP correcta

echo "👤 AGREGANDO USUARIO SOPORTE AL LDAP"
echo "===================================="

# Contraseña LDAP correcta del .env
LDAP_PASSWORD="zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01"

echo "🔍 Verificando conexión LDAP..."

# Probar conexión con la contraseña correcta
docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "$LDAP_PASSWORD" -b "dc=kolaboree,dc=local" -s base > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Conexión LDAP exitosa"
else
    echo "❌ Error de conexión LDAP"
    exit 1
fi

# Crear LDIF para el usuario soporte
cat > /tmp/add-user-soporte.ldif << 'EOF'
dn: uid=soporte,ou=users,dc=kolaboree,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: soporte
sn: Soporte
givenName: Usuario
cn: Usuario Soporte
displayName: Usuario Soporte
mail: soporte@kolaboree.local
userPassword: Neo123!!!
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/soporte
loginShell: /bin/bash
description: Usuario de prueba para SSO
EOF

echo "📝 Agregando usuario soporte..."

# Copiar LDIF al contenedor
docker cp /tmp/add-user-soporte.ldif kolaboree-ldap:/tmp/

# Agregar usuario
docker exec kolaboree-ldap ldapadd -x -D "cn=admin,dc=kolaboree,dc=local" -w "$LDAP_PASSWORD" -f /tmp/add-user-soporte.ldif

if [ $? -eq 0 ]; then
    echo "✅ Usuario soporte creado exitosamente"
else
    echo "⚠️ El usuario puede que ya exista, intentando actualizar..."
    
    # Crear LDIF de actualización
    cat > /tmp/update-soporte.ldif << 'EOF'
dn: uid=soporte,ou=users,dc=kolaboree,dc=local
changetype: modify
replace: userPassword
userPassword: Neo123!!!
-
replace: mail
mail: soporte@kolaboree.local
-
replace: displayName
displayName: Usuario Soporte
EOF
    
    docker cp /tmp/update-soporte.ldif kolaboree-ldap:/tmp/
    docker exec kolaboree-ldap ldapmodify -x -D "cn=admin,dc=kolaboree,dc=local" -w "$LDAP_PASSWORD" -f /tmp/update-soporte.ldif
    
    if [ $? -eq 0 ]; then
        echo "✅ Usuario actualizado exitosamente"
    fi
fi

echo ""
echo "🔍 VERIFICANDO USUARIO CREADO"
echo "============================="

# Buscar el usuario
docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "$LDAP_PASSWORD" -b "dc=kolaboree,dc=local" "(uid=soporte)" uid mail cn displayName

echo ""
echo "🧪 PROBANDO AUTENTICACIÓN"
echo "========================="

# Probar autenticación del usuario
docker exec kolaboree-ldap ldapwhoami -x -D "uid=soporte,ou=users,dc=kolaboree,dc=local" -w "Neo123!!!"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 ¡USUARIO SOPORTE CONFIGURADO CORRECTAMENTE!"
    echo ""
    echo "📋 DATOS PARA PROBAR EN AUTHENTIK:"
    echo "├── URL: https://34.68.124.46:9443/"
    echo "├── Usuario: soporte@kolaboree.local"
    echo "├── Contraseña: Neo123!!!"
    echo "└── Debería autenticar via LDAP"
    echo ""
    echo "✅ LISTO PARA CONTINUAR CON:"
    echo "├── 1. Provider OIDC en Authentik"
    echo "├── 2. Application en Authentik"
    echo "└── 3. Probar flujo SSO completo"
else
    echo "❌ Error en la autenticación del usuario"
fi

# Limpiar archivos temporales
rm -f /tmp/add-user-soporte.ldif /tmp/update-soporte.ldif

echo ""
echo "🎯 SIGUIENTE PASO: Configurar Provider OIDC en Authentik"
echo "https://34.68.124.46:9443/if/admin/"