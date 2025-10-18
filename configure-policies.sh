#!/bin/bash

echo "🔐 Configurando políticas de acceso para aplicaciones RAC..."

docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.policies.expression.models import ExpressionPolicy
from authentik.core.models import Application
from authentik.policies.models import PolicyBinding

# Obtener las aplicaciones
try:
    user_app = Application.objects.get(slug='kolaboree-user-panel')
    admin_app = Application.objects.get(slug='kolaboree-admin-panel')
    tsplus_app = Application.objects.get(slug='windows-remote-desktop')
    print('✅ Aplicaciones encontradas')
except Application.DoesNotExist:
    print('❌ No se encontraron algunas aplicaciones')
    exit(1)

# Crear políticas si no existen
users_policy, created = ExpressionPolicy.objects.get_or_create(
    name='Users Access Policy',
    defaults={'expression': 'return \"users\" in [group.name for group in user.ak_groups.all()]'}
)
if created:
    print('✅ Política de usuarios creada')

admin_tech_policy, created = ExpressionPolicy.objects.get_or_create(
    name='Admin Tech Access Policy',
    defaults={'expression': 'return \"admintecnico\" in [group.name for group in user.ak_groups.all()]'}
)
if created:
    print('✅ Política de admin técnico creada')

global_admin_policy, created = ExpressionPolicy.objects.get_or_create(
    name='Global Admin Access Policy',
    defaults={'expression': 'return \"globaladmin\" in [group.name for group in user.ak_groups.all()]'}
)
if created:
    print('✅ Política de admin global creada')

# Limpiar políticas existentes para evitar duplicados
PolicyBinding.objects.filter(target_id__in=[user_app.pk, admin_app.pk, tsplus_app.pk]).delete()

# Asignar políticas con orden específico
# Panel de Usuario: usuarios, admintecnico, globaladmin
PolicyBinding.objects.create(
    target=user_app,
    policy=users_policy,
    enabled=True,
    order=0
)
PolicyBinding.objects.create(
    target=user_app,
    policy=admin_tech_policy,
    enabled=True,
    order=1
)
PolicyBinding.objects.create(
    target=user_app,
    policy=global_admin_policy,
    enabled=True,
    order=2
)

# Panel de Admin: admintecnico, globaladmin
PolicyBinding.objects.create(
    target=admin_app,
    policy=admin_tech_policy,
    enabled=True,
    order=0
)
PolicyBinding.objects.create(
    target=admin_app,
    policy=global_admin_policy,
    enabled=True,
    order=1
)

# TSplus: admintecnico, globaladmin
PolicyBinding.objects.create(
    target=tsplus_app,
    policy=admin_tech_policy,
    enabled=True,
    order=0
)
PolicyBinding.objects.create(
    target=tsplus_app,
    policy=global_admin_policy,
    enabled=True,
    order=1
)

print('✅ Políticas asignadas correctamente')
"

echo "📊 Verificando configuración final..."
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.core.models import Application
from authentik.policies.models import PolicyBinding

print('=== CONFIGURACIÓN FINAL ===')
apps = Application.objects.filter(provider__isnull=False)
for app in apps:
    print(f'📱 {app.name}')
    bindings = PolicyBinding.objects.filter(target=app)
    for binding in bindings:
        print(f'   🔐 {binding.policy.name} (orden: {binding.order})')
    print()
"

echo "🎉 ¡Configuración de políticas completada!"
echo ""
echo "🌐 Accede a Authentik: http://34.68.124.46:9000/if/user/#/library"
echo "👤 Usuario: infra@neogenesys.com"
echo "🔑 Contraseña: Neo123!!!"