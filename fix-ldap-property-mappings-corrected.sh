#!/bin/bash

echo "=== CONFIGURANDO PROPERTY MAPPINGS CORRECTOS PARA LDAP ==="

# Crear los property mappings necesarios usando la clase correcta
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.sources.ldap.models import LDAPSource
from authentik.core.models import PropertyMapping

print('=== CONFIGURANDO PROPERTY MAPPINGS ===')

# Obtener la fuente LDAP
source = LDAPSource.objects.get(slug='ldap-local')
print(f'Configurando mappings para: {source.name}')

# Crear o actualizar property mappings para usuarios
user_mappings = [
    {
        'name': 'authentik default LDAP Mapping: Name',
        'object_field': 'name',
        'expression': 'return ldap.get(\"cn\")[0]'
    },
    {
        'name': 'authentik default LDAP Mapping: mail',
        'object_field': 'email', 
        'expression': 'return ldap.get(\"mail\")[0] if ldap.get(\"mail\") else \"\"'
    },
    {
        'name': 'authentik default LDAP Mapping: Username',
        'object_field': 'username',
        'expression': 'return ldap.get(\"uid\")[0]'
    }
]

# Crear property mappings para usuarios
for mapping_data in user_mappings:
    mapping, created = PropertyMapping.objects.get_or_create(
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
        'name': 'authentik default LDAP Mapping: cn',
        'object_field': 'name',
        'expression': 'return ldap.get(\"cn\")[0]'
    }
]

for mapping_data in group_mappings:
    mapping, created = PropertyMapping.objects.get_or_create(
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
user_mappings_objs = PropertyMapping.objects.filter(
    name__in=['authentik default LDAP Mapping: Name', 'authentik default LDAP Mapping: mail', 'authentik default LDAP Mapping: Username']
)
group_mappings_objs = PropertyMapping.objects.filter(
    name__in=['authentik default LDAP Mapping: cn']
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
all_users = User.objects.all()
for user in all_users:
    if any(keyword in user.path.lower() for keyword in ['ldap', 'usuario', 'tecnico', 'infra']):
        print(f'Usuario: {user.username} | Email: {user.email} | Name: {user.name} | Path: {user.path}')

print(f'Total usuarios en sistema: {all_users.count()}')

print('\n=== GRUPOS SINCRONIZADOS ===')
all_groups = Group.objects.all()
for group in all_groups:
    print(f'Grupo: {group.name} | Miembros: {group.users.count()}')
    if group.users.count() > 0:
        members = [u.username for u in group.users.all()]
        print(f'  Miembros: {members}')

print(f'Total grupos: {all_groups.count()}')
"

echo ""
echo "=== CONFIGURACIÓN DE PROPERTY MAPPINGS CORREGIDA ==="
echo ""
echo "Ahora los usuarios y grupos deberían estar sincronizados correctamente."
echo "Puedes probar login con:"
echo "- usuario1@neogenesys.com / Password123" 
echo "- infra@neogenesys.com / Neo123!!!"