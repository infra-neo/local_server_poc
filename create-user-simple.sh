#!/bin/bash
# Script simplificado para crear usuario LDAP

echo "🔐 CREANDO USUARIO SOPORTE EN LDAP"
echo "=================================="

# Crear LDIF para el usuario
cat > /tmp/create-user-soporte.ldif << 'EOF'
# Crear OU para usuarios si no existe
dn: ou=users,dc=kolaboree,dc=local
objectClass: organizationalUnit
ou: users

# Crear usuario soporte
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

# Crear OU para grupos si no existe
dn: ou=groups,dc=kolaboree,dc=local
objectClass: organizationalUnit
ou: groups

# Crear grupo usuarios
dn: cn=usuarios,ou=groups,dc=kolaboree,dc=local
objectClass: groupOfNames
cn: usuarios
description: Grupo de usuarios del sistema
member: uid=soporte,ou=users,dc=kolaboree,dc=local
EOF

echo "📝 Archivo LDIF creado"

# Copiar LDIF al contenedor
docker cp /tmp/create-user-soporte.ldif kolaboree-ldap:/tmp/

echo "🔄 Aplicando configuración LDAP..."

# Aplicar LDIF (usar contraseña por defecto)
docker exec kolaboree-ldap ldapadd -x -D "cn=admin,dc=kolaboree,dc=local" -w "CHANGEME_LDAP_PASSWORD" -f /tmp/create-user-soporte.ldif

if [ $? -eq 0 ]; then
    echo "✅ Usuario creado exitosamente"
else
    echo "⚠️ Puede que el usuario ya exista, intentando actualizar..."
    
    # Crear LDIF de actualización
    cat > /tmp/update-user-soporte.ldif << 'EOF'
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
    
    docker cp /tmp/update-user-soporte.ldif kolaboree-ldap:/tmp/
    docker exec kolaboree-ldap ldapmodify -x -D "cn=admin,dc=kolaboree,dc=local" -w "CHANGEME_LDAP_PASSWORD" -f /tmp/update-user-soporte.ldif
fi

echo ""
echo "🔍 VERIFICANDO USUARIO CREADO"
echo "=============================="

# Buscar el usuario
docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "CHANGEME_LDAP_PASSWORD" -b "dc=kolaboree,dc=local" "(uid=soporte)" uid mail cn displayName

echo ""
echo "🧪 PROBANDO AUTENTICACIÓN"
echo "========================="

# Probar autenticación del usuario
docker exec kolaboree-ldap ldapwhoami -x -D "uid=soporte,ou=users,dc=kolaboree,dc=local" -w "Neo123!!!"

if [ $? -eq 0 ]; then
    echo "✅ ¡Autenticación exitosa!"
    echo ""
    echo "📋 DATOS DEL USUARIO:"
    echo "├── UID: soporte"
    echo "├── Email: soporte@kolaboree.local"  
    echo "├── Nombre: Usuario Soporte"
    echo "├── Contraseña: Neo123!!!"
    echo "└── DN: uid=soporte,ou=users,dc=kolaboree,dc=local"
    echo ""
    echo "🚀 PRÓXIMO PASO:"
    echo "Probar login en: https://34.68.124.46:9443/"
    echo "Usuario: soporte@kolaboree.local"
    echo "Contraseña: Neo123!!!"
else
    echo "❌ Error en autenticación"
fi

# Limpiar archivos temporales
rm -f /tmp/create-user-soporte.ldif /tmp/update-user-soporte.ldif