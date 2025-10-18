#!/bin/bash

echo "=== CONFIGURANDO PROPERTY MAPPINGS PARA LDAP ==="

# Crear los property mappings necesarios para LDAP
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.sources.ldap.models import LDAPSource, LDAPPropertyMapping

print('=== CONFIGURANDO PROPERTY MAPPINGS ===')

# Obtener la fuente LDAP
source = LDAPSource.objects.get(slug='ldap-local')
print(f'Configurando mappings para: {source.name}')

# Crear o actualizar property mappings para usuarios
user_mappings = [
    {
        'name': 'LDAP Username',
        'object_field': 'username',
        'expression': 'return ldap.get(\"uid\")[0]'
    },
    {
        'name': 'LDAP Email',
        'object_field': 'email', 
        'expression': 'return ldap.get(\"mail\")[0] if ldap.get(\"mail\") else \"\"'
    },
    {
        'name': 'LDAP First Name',
        'object_field': 'name',
        'expression': 'return ldap.get(\"givenName\")[0] if ldap.get(\"givenName\") else ldap.get(\"cn\")[0]'
    },
    {
        'name': 'LDAP Path',
        'object_field': 'path',
        'expression': 'return \"goauthentik.io/sources/ldap-local\"'
    }
]

# Crear property mappings para usuarios
for mapping_data in user_mappings:
    mapping, created = LDAPPropertyMapping.objects.get_or_create(
        name=mapping_data['name'],
        defaults={
            'object_field': mapping_data['object_field'],
            'expression': mapping_data['expression']
        }
    )
    if created:
        print(f'✓ Creado mapping: {mapping.name}')
    else:
        print(f'→ Actualizando mapping: {mapping.name}')
        mapping.object_field = mapping_data['object_field']
        mapping.expression = mapping_data['expression']
        mapping.save()

# Crear property mappings para grupos
group_mappings = [
    {
        'name': 'LDAP Group Name',
        'object_field': 'name',
        'expression': 'return ldap.get(\"cn\")[0]'
    }
]

for mapping_data in group_mappings:
    mapping, created = LDAPPropertyMapping.objects.get_or_create(
        name=mapping_data['name'],
        defaults={
            'object_field': mapping_data['object_field'],
            'expression': mapping_data['expression']
        }
    )
    if created:
        print(f'✓ Creado group mapping: {mapping.name}')
    else:
        print(f'→ Actualizando group mapping: {mapping.name}')
        mapping.object_field = mapping_data['object_field']
        mapping.expression = mapping_data['expression']
        mapping.save()

print('\n=== ASIGNANDO MAPPINGS A LA FUENTE LDAP ===')

# Asignar los property mappings a la fuente LDAP
user_mappings_objs = LDAPPropertyMapping.objects.filter(
    name__in=['LDAP Username', 'LDAP Email', 'LDAP First Name', 'LDAP Path']
)
group_mappings_objs = LDAPPropertyMapping.objects.filter(
    name__in=['LDAP Group Name']
)

# Limpiar mappings existentes y asignar los nuevos
source.property_mappings.set(user_mappings_objs)
source.property_mappings_group.set(group_mappings_objs)
source.save()

print(f'✓ Asignados {user_mappings_objs.count()} user mappings')
print(f'✓ Asignados {group_mappings_objs.count()} group mappings')

print('\n=== CONFIGURACIÓN DE MAPPINGS COMPLETADA ===')
"

echo "--- Ejecutando nueva sincronización LDAP ---"
docker exec kolaboree-authentik-server python -m manage ldap_sync ldap-local

echo "--- Verificando usuarios y grupos sincronizados ---"
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.core.models import User, Group

print('\n=== USUARIOS SINCRONIZADOS ===')
ldap_users = User.objects.filter(path__contains='ldap')
for user in ldap_users:
    print(f'Usuario: {user.username} | Email: {user.email} | Name: {user.name}')

print(f'Total usuarios LDAP: {ldap_users.count()}')

print('\n=== GRUPOS SINCRONIZADOS ===')
all_groups = Group.objects.all()
for group in all_groups:
    if group.name in ['users', 'admintecnico', 'globaladmin']:
        print(f'Grupo: {group.name} | Miembros: {group.users.count()}')
        members = [u.username for u in group.users.all()]
        print(f'  Miembros: {members}')

print(f'Total grupos: {all_groups.count()}')
"

echo ""
echo "=== CONFIGURACIÓN DE PROPERTY MAPPINGS COMPLETADA ==="
echo ""
echo "Ahora los usuarios y groups deberían estar sincronizados correctamente."
echo "Puedes probar login con:"
echo "- usuario1@neogenesys.com / Password123"
echo "- infra@neogenesys.com / Neo123!!!"