#!/bin/bash

echo "=== CREANDO PROPERTY MAPPINGS CORRECTOS PARA LDAP ==="

# Crear los property mappings usando la API de Django correcta
docker exec kolaboree-authentik-server python manage.py shell -c "
from authentik.core.models import PropertyMapping
from authentik.sources.ldap.models import LDAPSource

# Crear property mapping para el nombre de usuario (username)
username_mapping, created = PropertyMapping.objects.get_or_create(
    name='LDAP Username Mapping',
    defaults={
        'expression': 'ldap.get(\"uid\")',
        'component': 'ldap-user'
    }
)
print(f'Username mapping: {username_mapping.name} - Created: {created}')

# Crear property mapping para el email
email_mapping, created = PropertyMapping.objects.get_or_create(
    name='LDAP Email Mapping',
    defaults={
        'expression': 'ldap.get(\"mail\")',
        'component': 'ldap-user'
    }
)
print(f'Email mapping: {email_mapping.name} - Created: {created}')

# Crear property mapping para el nombre completo
name_mapping, created = PropertyMapping.objects.get_or_create(
    name='LDAP Name Mapping', 
    defaults={
        'expression': 'ldap.get(\"cn\")',
        'component': 'ldap-user'
    }
)
print(f'Name mapping: {name_mapping.name} - Created: {created}')

# Crear property mapping para grupos
group_mapping, created = PropertyMapping.objects.get_or_create(
    name='LDAP Group Mapping',
    defaults={
        'expression': 'ldap.get(\"cn\")', 
        'component': 'ldap-group'
    }
)
print(f'Group mapping: {group_mapping.name} - Created: {created}')

# Obtener el source LDAP
source = LDAPSource.objects.get(name='Ldap Local')
print(f'Source encontrado: {source.name}')

# Asignar los property mappings al source
source.property_mappings.set([username_mapping, email_mapping, name_mapping])
source.property_mappings_group.set([group_mapping])
source.save()

print('Property mappings asignados al source LDAP')
print('Configurados para users:', [pm.name for pm in source.property_mappings.all()])
print('Configurados para groups:', [pm.name for pm in source.property_mappings_group.all()])
"

echo "=== EJECUTANDO SINCRONIZACIÓN LDAP ==="
docker exec kolaboree-authentik-server python manage.py ldap_sync --source='Ldap Local'

echo "=== VERIFICANDO RESULTADOS ==="
docker exec kolaboree-authentik-server python manage.py shell -c "
from authentik.core.models import User, Group
from authentik.sources.ldap.models import LDAPSource

users = User.objects.filter(attributes__ldap_uniq__isnull=False)
groups = Group.objects.filter(attributes__ldap_uniq__isnull=False)

print(f'Usuarios LDAP sincronizados: {users.count()}')
for user in users:
    print(f'  - {user.username} ({user.email})')

print(f'Grupos LDAP sincronizados: {groups.count()}')
for group in groups:
    print(f'  - {group.name}')
"

echo "=== PROPERTY MAPPINGS CONFIGURADOS CORRECTAMENTE ==="
echo "Ahora deberías poder autenticar con usuarios LDAP"