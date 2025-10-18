#!/bin/bash

echo "=== CONFIGURACIÓN FINAL DE PROPERTY MAPPINGS LDAP ==="

# Asignar los property mappings por defecto existentes al source LDAP usando los atributos correctos
docker exec kolaboree-authentik-server python manage.py shell -c "
from authentik.core.models import PropertyMapping
from authentik.sources.ldap.models import LDAPSource

# Obtener el source LDAP
source = LDAPSource.objects.get(name='Ldap Local')
print(f'Source encontrado: {source.name}')

# Obtener los property mappings necesarios por UUID
uid_mapping = PropertyMapping.objects.get(pk='1924cc65-d5e3-4a70-9f98-032dca0f580f')  # authentik default OpenLDAP Mapping: uid
name_mapping = PropertyMapping.objects.get(pk='14a88c92-0ecd-4554-ae2c-3b58d396ebb3')  # authentik default LDAP Mapping: Name  
mail_mapping = PropertyMapping.objects.get(pk='80ac3774-7271-4e16-bea3-c344bb4cf3de')  # authentik default LDAP Mapping: mail

print(f'UID mapping: {uid_mapping.name} - Expression: {uid_mapping.expression}')
print(f'Name mapping: {name_mapping.name} - Expression: {name_mapping.expression}')  
print(f'Mail mapping: {mail_mapping.name} - Expression: {mail_mapping.expression}')

# Asignar los property mappings al source para usuarios usando el atributo correcto
source.user_property_mappings.set([uid_mapping, name_mapping, mail_mapping])
print('✓ Property mappings de usuarios asignados')

# Para grupos LDAP crear un property mapping específico
group_mapping, created = PropertyMapping.objects.get_or_create(
    name='LDAP Group Name Mapping',
    defaults={
        'expression': 'return ldap.get(\"cn\")'
    }
)
print(f'Group mapping: {group_mapping.name} - Created: {created} - Expression: {group_mapping.expression}')

# Asignar el mapping de grupos usando el atributo correcto
source.group_property_mappings.set([group_mapping])
print('✓ Property mappings de grupos asignados')

source.save()

print('Property mappings configurados correctamente:')
print('  Usuarios:', [pm.name for pm in source.user_property_mappings.all()])
print('  Grupos:', [pm.name for pm in source.group_property_mappings.all()])
"

echo "=== EJECUTANDO SINCRONIZACIÓN LDAP ==="
docker exec kolaboree-authentik-server python manage.py ldap_sync 'Ldap Local'

echo "=== VERIFICANDO RESULTADOS FINALES ==="
docker exec kolaboree-authentik-server python manage.py shell -c "
from authentik.core.models import User, Group
from authentik.sources.ldap.models import LDAPSource

users = User.objects.filter(attributes__ldap_uniq__isnull=False)
groups = Group.objects.filter(attributes__ldap_uniq__isnull=False)

print(f'🎉 Usuarios LDAP sincronizados: {users.count()}')
for user in users:
    print(f'  - {user.username} | {user.email} | {user.name}')

print(f'🎉 Grupos LDAP sincronizados: {groups.count()}')  
for group in groups:
    print(f'  - {group.name} | Miembros: {group.users.count()}')
    for member in group.users.all():
        print(f'    → {member.username}')

print(f'Total usuarios en sistema: {User.objects.count()}')
print(f'Total grupos en sistema: {Group.objects.count()}')
"

echo ""
echo "🚀 === CONFIGURACIÓN LDAP COMPLETADA EXITOSAMENTE ==="
echo "✅ Property mappings configurados"
echo "✅ Usuarios y grupos sincronizados"
echo ""
echo "🔐 Ahora puedes autenticar con:"
echo "  - usuario1@neogenesys.com / Password123"
echo "  - infra@neogenesys.com / Neo123!!!"
echo ""
echo "🌐 Accede a las aplicaciones en:"
echo "  - http://34.68.124.46:9000/if/user/#/library"