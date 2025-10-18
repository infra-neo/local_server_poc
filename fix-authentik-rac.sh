#!/bin/bash

echo "🔧 Reparando configuración de Authentik RAC..."

# Primero, limpiar las aplicaciones existentes que puedan tener problemas
echo "🧹 Limpiando configuración previa..."
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.core.models import Application
from authentik.providers.rac.models import RACProvider
from authentik.policies.expression.models import ExpressionPolicy

# Eliminar aplicaciones con providers RAC
apps = Application.objects.filter(provider__isnull=False)
for app in apps:
    if hasattr(app.provider, 'racprovider'):
        print(f'Eliminando aplicación: {app.name}')
        app.delete()

# Eliminar providers RAC
providers = RACProvider.objects.all()
for prov in providers:
    print(f'Eliminando provider: {prov.name}')
    prov.delete()

print('Limpieza completada')
"

echo "🖥️ Creando provider RAC para Panel de Usuario..."
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.providers.rac.models import RACProvider
from authentik.core.models import Application

# Crear provider para Panel de Usuario
user_provider = RACProvider.objects.create(
    name='Kolaboree User Provider',
    settings={
        'url': 'http://34.68.124.46/user',
        'ignore_server_certificate': True
    }
)
user_provider.save()

# Crear aplicación para Panel de Usuario
user_app = Application.objects.create(
    name='Kolaboree User Panel',
    slug='kolaboree-user-panel',
    provider=user_provider
)
user_app.save()

print(f'✅ Panel de Usuario creado - ID: {user_app.pk}')
"

echo "👨‍💼 Creando provider RAC para Panel de Administrador..."
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.providers.rac.models import RACProvider
from authentik.core.models import Application

# Crear provider para Panel de Admin
admin_provider = RACProvider.objects.create(
    name='Kolaboree Admin Provider',
    settings={
        'url': 'http://34.68.124.46/admin',
        'ignore_server_certificate': True
    }
)
admin_provider.save()

# Crear aplicación para Panel de Admin
admin_app = Application.objects.create(
    name='Kolaboree Admin Panel',
    slug='kolaboree-admin-panel',
    provider=admin_provider
)
admin_app.save()

print(f'✅ Panel de Admin creado - ID: {admin_app.pk}')
"

echo "💻 Creando provider RAC para TSplus..."
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.providers.rac.models import RACProvider
from authentik.core.models import Application

# Crear provider para TSplus
tsplus_provider = RACProvider.objects.create(
    name='TSplus Windows Provider',
    settings={
        'url': 'https://tsplus.kolaboree.local:3443',
        'ignore_server_certificate': True
    }
)
tsplus_provider.save()

# Crear aplicación para TSplus
tsplus_app = Application.objects.create(
    name='Windows Remote Desktop (TSplus)',
    slug='windows-remote-desktop',
    provider=tsplus_provider
)
tsplus_app.save()

print(f'✅ TSplus creado - ID: {tsplus_app.pk}')
"

echo "🔐 Creando políticas de acceso basadas en grupos..."
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.policies.expression.models import ExpressionPolicy
from authentik.core.models import Application

# Obtener las aplicaciones
user_app = Application.objects.get(slug='kolaboree-user-panel')
admin_app = Application.objects.get(slug='kolaboree-admin-panel')
tsplus_app = Application.objects.get(slug='windows-remote-desktop')

# Política para usuarios regulares (solo panel de usuario)
users_policy = ExpressionPolicy.objects.create(
    name='Users Group Policy',
    expression='return \"users\" in [group.name for group in user.ak_groups.all()]'
)
users_policy.save()

# Política para administradores técnicos (panel usuario + admin + tsplus)
admin_tech_policy = ExpressionPolicy.objects.create(
    name='Tech Admin Group Policy',
    expression='return \"admintecnico\" in [group.name for group in user.ak_groups.all()]'
)
admin_tech_policy.save()

# Política para administradores globales (acceso a todo)
global_admin_policy = ExpressionPolicy.objects.create(
    name='Global Admin Policy',
    expression='return \"globaladmin\" in [group.name for group in user.ak_groups.all()]'
)
global_admin_policy.save()

# Asignar políticas a aplicaciones
# Panel de Usuario: usuarios, admintecnico, globaladmin
user_app.policies.add(users_policy)
user_app.policies.add(admin_tech_policy)
user_app.policies.add(global_admin_policy)

# Panel de Admin: admintecnico, globaladmin
admin_app.policies.add(admin_tech_policy)
admin_app.policies.add(global_admin_policy)

# TSplus: admintecnico, globaladmin
tsplus_app.policies.add(admin_tech_policy)
tsplus_app.policies.add(global_admin_policy)

print('✅ Políticas creadas y asignadas')
"

echo "📊 Verificando configuración..."
docker exec kolaboree-authentik-server python -m manage shell -c "
from authentik.core.models import Application
from authentik.providers.rac.models import RACProvider

print('=== APLICACIONES RAC ===')
apps = Application.objects.filter(provider__isnull=False)
for app in apps:
    print(f'📱 {app.name} | Slug: {app.slug}')
    policies = app.policies.all()
    print(f'   Políticas: {[p.name for p in policies]}')
    print()

print(f'Total aplicaciones: {apps.count()}')
"

echo "🎉 ¡Configuración RAC reparada y completada!"
echo ""
echo "📱 Aplicaciones disponibles en: http://34.68.124.46:9000/if/user/#/library"
echo "🔐 Usuario de prueba: infra@neogenesys.com / Neo123!!!"