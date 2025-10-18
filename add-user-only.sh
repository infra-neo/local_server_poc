#!/bin/bash
# Script simple para agregar SOLO el usuario soporte al LDAP existente

echo "👤 AGREGANDO USUARIO SOPORTE AL LDAP EXISTENTE"
echo "=============================================="

# Esperar a que LDAP esté listo
echo "⏳ Esperando que LDAP esté listo..."
sleep 5

# Probar diferentes contraseñas LDAP comunes
PASSWORDS=("CHANGEME_LDAP_PASSWORD" "kolaboree_password_2024" "admin" "ldapadmin")

for PASSWORD in "${PASSWORDS[@]}"; do
    echo "🔍 Probando contraseña LDAP: $PASSWORD"
    
    # Probar conexión
    docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "$PASSWORD" -b "dc=kolaboree,dc=local" -s base > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Contraseña correcta encontrada: $PASSWORD"
        LDAP_PASSWORD="$PASSWORD"
        break
    fi
done

if [ -z "$LDAP_PASSWORD" ]; then
    echo "❌ No se pudo encontrar la contraseña LDAP"
    echo "💡 Verifica manualmente con: docker exec -it kolaboree-ldap ldapsearch -x -D 'cn=admin,dc=kolaboree,dc=local' -w 'TU_PASSWORD' -b 'dc=kolaboree,dc=local'"
    exit 1
fi

# Crear LDIF simple para el usuario
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

echo "📝 Creando usuario soporte..."

# Copiar al contenedor
docker cp /tmp/add-user-soporte.ldif kolaboree-ldap:/tmp/

# Agregar usuario
docker exec kolaboree-ldap ldapadd -x -D "cn=admin,dc=kolaboree,dc=local" -w "$LDAP_PASSWORD" -f /tmp/add-user-soporte.ldif

if [ $? -eq 0 ]; then
    echo "✅ Usuario soporte creado exitosamente"
else
    echo "⚠️ El usuario puede que ya exista, intentando actualizar contraseña..."
    
    # Actualizar contraseña si el usuario ya existe
    cat > /tmp/update-soporte-password.ldif << 'EOF'
dn: uid=soporte,ou=users,dc=kolaboree,dc=local
changetype: modify
replace: userPassword
userPassword: Neo123!!!
EOF
    
    docker cp /tmp/update-soporte-password.ldif kolaboree-ldap:/tmp/
    docker exec kolaboree-ldap ldapmodify -x -D "cn=admin,dc=kolaboree,dc=local" -w "$LDAP_PASSWORD" -f /tmp/update-soporte-password.ldif
fi

echo ""
echo "🔍 VERIFICANDO USUARIO"
echo "====================="

# Verificar que el usuario existe
docker exec kolaboree-ldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "$LDAP_PASSWORD" -b "dc=kolaboree,dc=local" "(uid=soporte)" uid mail cn

echo ""
echo "🧪 PROBANDO AUTENTICACIÓN DEL USUARIO"
echo "===================================="

# Probar login del usuario
docker exec kolaboree-ldap ldapwhoami -x -D "uid=soporte,ou=users,dc=kolaboree,dc=local" -w "Neo123!!!"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 ¡Usuario soporte configurado correctamente!"
    echo ""
    echo "📋 DATOS PARA PROBAR EN AUTHENTIK:"
    echo "├── URL: https://34.68.124.46:9443/"
    echo "├── Usuario: soporte@kolaboree.local"
    echo "├── Contraseña: Neo123!!!"
    echo "└── Debería autenticar via LDAP"
    echo ""
    echo "✅ ¡Listo para continuar con el Provider OIDC!"
else
    echo "❌ Error en la autenticación del usuario"
fi

# Limpiar archivos temporales
rm -f /tmp/add-user-soporte.ldif /tmp/update-soporte-password.ldif