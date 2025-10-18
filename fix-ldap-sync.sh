#!/bin/bash

echo "=== CONFIGURANDO SINCRONIZACIÓN LDAP Y FLUJOS DE AUTENTICACIÓN ==="

# 1. Primero, configurar correctamente la fuente LDAP con sincronización automática
echo "--- Configurando fuente LDAP con sync automático ---"
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.sources.ldap.models import LDAPSource
from authentik.flows.models import Flow
from authentik.core.models import User, Group

# Actualizar la fuente LDAP para incluir en flow de autenticación
print('Configurando fuente LDAP...')
source = LDAPSource.objects.get(slug='ldap-local')
print(f'Fuente encontrada: {source.name}')

# Asegurar que esté habilitada
source.enabled = True
source.sync_users = True
source.sync_groups = True
source.sync_users_password = True
source.user_matching_mode = 'email'  # Usar email para match
source.user_path_template = 'goauthentik.io/sources/%(slug)s'
source.group_matching_mode = 'name_link'
source.save()

print(f'Fuente LDAP configurada:')
print(f'  - Enabled: {source.enabled}')
print(f'  - Sync Users: {source.sync_users}')
print(f'  - Sync Groups: {source.sync_groups}')
print(f'  - User Matching: {source.user_matching_mode}')
print(f'  - Group Matching: {source.group_matching_mode}')
"

# 2. Ejecutar sync usando el comando manage
echo "--- Ejecutando sincronización LDAP ---"
docker exec kolaboree-authentik-server python -m manage ldap_sync --source ldap-local

# 3. Configurar el flow de autenticación para incluir LDAP
echo "--- Configurando flow de autenticación ---"
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.flows.models import Flow, FlowStageBinding
from authentik.stages.identification.models import IdentificationStage
from authentik.sources.ldap.models import LDAPSource

# Obtener el flow de autenticación por defecto
auth_flow = Flow.objects.filter(slug='default-authentication-flow').first()
if not auth_flow:
    print('Flow de autenticación no encontrado')
else:
    print(f'Flow encontrado: {auth_flow.title}')
    
    # Obtener la fuente LDAP
    ldap_source = LDAPSource.objects.get(slug='ldap-local')
    
    # Buscar el stage de identificación
    ident_stages = IdentificationStage.objects.filter(
        flowstage_set__flow=auth_flow
    )
    
    for stage in ident_stages:
        print(f'Agregando fuente LDAP al stage: {stage.name}')
        stage.sources.add(ldap_source)
        stage.save()
        
        # Verificar las fuentes configuradas
        sources = stage.sources.all()
        print(f'Fuentes en el stage:')
        for src in sources:
            print(f'  - {src.name} ({src.__class__.__name__})')
"

# 4. Verificar usuarios y grupos sincronizados
echo "--- Verificando sincronización ---"
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.core.models import User, Group
from authentik.sources.ldap.models import LDAPSource

print('=== RESULTADOS DE SINCRONIZACIÓN ===')

print('\n--- Usuarios sincronizados ---')
ldap_users = User.objects.filter(path__contains='ldap-local')
for user in ldap_users:
    print(f'Usuario: {user.username} | Email: {user.email} | Path: {user.path}')
    
    # Mostrar grupos del usuario
    groups = user.groups.all()
    group_names = [g.name for g in groups]
    print(f'  Grupos: {group_names}')

print(f'Total usuarios LDAP: {ldap_users.count()}')

print('\n--- Grupos sincronizados ---')  
ldap_groups = Group.objects.filter(parent__name__icontains='ldap')
for group in ldap_groups:
    print(f'Grupo: {group.name} | Parent: {group.parent} | Miembros: {group.users.count()}')
    
    # Mostrar miembros
    members = group.users.all()
    member_names = [u.username for u in members]
    print(f'  Miembros: {member_names}')

print(f'Total grupos LDAP: {ldap_groups.count()}')

# Verificar grupos por nombre específico
specific_groups = Group.objects.filter(name__in=['users', 'admintecnico', 'globaladmin'])
print(f'\n--- Grupos específicos ---')
for group in specific_groups:
    print(f'Grupo: {group.name} | Miembros: {group.users.count()}')
    members = [u.username for u in group.users.all()]
    print(f'  Miembros: {members}')
"

echo "=== CONFIGURACIÓN COMPLETADA ==="
echo ""
echo "Ahora deberías poder:"
echo "1. Ver un botón/opción para LDAP en la página de login"
echo "2. Autenticarte con: usuario1@neogenesys.com / Password123"
echo "3. Ver las aplicaciones según tu grupo"
echo ""
echo "Si no ves el botón LDAP, revisa:"
echo "- http://34.68.124.46:9000/if/admin/#/core/sources"
echo "- http://34.68.124.46:9000/if/admin/#/flow/flows"