#!/bin/bash

# Script para configurar logos y aplicación TSplus en Authentik
echo "🎨 Configurando logos y aplicación TSplus..."

# 1. Crear Provider RAC para TSplus (Windows remoto)
echo "🖥️ Creando provider RAC para TSplus Windows..."
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.providers.rac.models import RacProvider

# Crear Provider RAC para TSplus Windows
tsplus_provider = RacProvider.objects.create(
    name="TSplus Windows Remote",
    slug="tsplus-windows-remote",
    connection_expiry="hours=8",
    endpoint="https://tsplus.kolaboree.local:3443"  # URL del TSplus en Windows LXD
)

print(f"✅ Provider RAC TSplus creado: {tsplus_provider.name}")
EOF

# 2. Crear Application para TSplus
echo "💻 Creando aplicación TSplus..."
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.core.models import Application
from authentik.providers.rac.models import RacProvider

# Obtener el provider
tsplus_provider = RacProvider.objects.get(slug="tsplus-windows-remote")

# Crear Application para TSplus
tsplus_app = Application.objects.create(
    name="Windows Remote Desktop (TSplus)",
    slug="tsplus-windows",
    provider=tsplus_provider,
    meta_launch_url="https://tsplus.kolaboree.local:3443",
    meta_description="Acceso remoto a escritorio Windows mediante TSplus",
    meta_icon="https://cdn-icons-png.flaticon.com/512/888/888882.png"
)

print(f"✅ Aplicación TSplus creada: {tsplus_app.name}")
EOF

# 3. Crear política de acceso para TSplus (solo admins)
echo "🔐 Creando política de acceso para TSplus..."
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.policies.expression.models import ExpressionPolicy
from authentik.core.models import PolicyBinding, Application

# Crear política para TSplus (solo admins)
tsplus_policy = ExpressionPolicy.objects.create(
    name="TSplus Admin Access Policy",
    expression='return "globaladmin" in [group.name for group in request.user.ak_groups.all()] or "admintecnico" in [group.name for group in request.user.ak_groups.all()]'
)

# Obtener la aplicación TSplus
tsplus_app = Application.objects.get(slug="tsplus-windows")

# Crear binding para la aplicación TSplus
PolicyBinding.objects.create(
    target=tsplus_app,
    policy=tsplus_policy,
    enabled=True,
    order=10
)

print(f"✅ Política TSplus creada: {tsplus_policy.name}")
EOF

# 4. Copiar logos a directorio compartido de Authentik
echo "🏷️ Configurando logos..."

# Crear directorio para logos en el volumen de Authentik
docker exec kolaboree-authentik-server mkdir -p /authentik/media/public/logos

# Copiar logos seleccionados
echo "📁 Copiando logos a Authentik..."
docker cp logos/Logo_Neo25_Workspace.png kolaboree-authentik-server:/authentik/media/public/logos/
docker cp logos/logo_horizontal_sinfondo.png kolaboree-authentik-server:/authentik/media/public/logos/
docker cp logos/Logo_positivo-100.jpg kolaboree-authentik-server:/authentik/media/public/logos/

# 5. Actualizar iconos de las aplicaciones con logos locales
echo "🎯 Actualizando iconos de aplicaciones..."
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.core.models import Application

# Actualizar iconos con logos locales
try:
    user_app = Application.objects.get(slug="kolaboree-user")
    user_app.meta_icon = "/authentik/media/public/logos/logo_horizontal_sinfondo.png"
    user_app.save()
    print(f"✅ Icono actualizado para: {user_app.name}")

    admin_app = Application.objects.get(slug="kolaboree-admin")
    admin_app.meta_icon = "/authentik/media/public/logos/Logo_Neo25_Workspace.png"
    admin_app.save()
    print(f"✅ Icono actualizado para: {admin_app.name}")

    tsplus_app = Application.objects.get(slug="tsplus-windows")
    tsplus_app.meta_icon = "/authentik/media/public/logos/Logo_positivo-100.jpg"
    tsplus_app.save()
    print(f"✅ Icono actualizado para: {tsplus_app.name}")

except Exception as e:
    print(f"❌ Error actualizando iconos: {e}")
EOF

echo ""
echo "🎉 ¡Configuración completada!"
echo ""
echo "📱 Aplicaciones creadas:"
echo "   👥 Kolaboree User Dashboard - http://34.68.124.46/user"
echo "   👨‍💼 Kolaboree Admin Dashboard - http://34.68.124.46/admin"  
echo "   💻 Windows Remote Desktop (TSplus) - https://tsplus.kolaboree.local:3443"
echo ""
echo "🔐 Políticas de acceso:"
echo "   • Users: Solo panel de usuario"
echo "   • Admintecnico: Panel usuario + admin + TSplus"
echo "   • Globaladmin: Acceso completo a todo"
echo ""
echo "🌐 Ve a Authentik: http://localhost:9000"
echo "🎯 Prueba con: infra@neogenesys.com / Password123"