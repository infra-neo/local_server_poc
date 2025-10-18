#!/bin/bash

# Script para crear políticas de acceso basadas en grupos LDAP
echo "🛡️ Creando políticas de acceso por grupos..."

# 1. Crear política para usuarios regulares (grupo 'users')
echo "👥 Creando política para grupo 'users'..."
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.policies.expression.models import ExpressionPolicy
from authentik.core.models import PolicyBinding, Application
from authentik.providers.rac.models import RacProvider

# Crear política para usuarios regulares
user_policy = ExpressionPolicy.objects.create(
    name="Users Group Policy",
    expression='return "users" in [group.name for group in request.user.ak_groups.all()]'
)

# Obtener la aplicación de usuario
user_app = Application.objects.get(slug="kolaboree-user")

# Crear binding para la aplicación de usuario
PolicyBinding.objects.create(
    target=user_app,
    policy=user_policy,
    enabled=True,
    order=10
)

print(f"✅ Política creada para usuarios regulares: {user_policy.name}")
EOF

# 2. Crear política para administradores técnicos (grupo 'admintecnico')
echo "🔧 Creando política para grupo 'admintecnico'..."
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.policies.expression.models import ExpressionPolicy
from authentik.core.models import PolicyBinding, Application

# Crear política para administradores técnicos
tech_policy = ExpressionPolicy.objects.create(
    name="Tech Admin Group Policy",
    expression='return "admintecnico" in [group.name for group in request.user.ak_groups.all()]'
)

# Obtener las aplicaciones
user_app = Application.objects.get(slug="kolaboree-user")
admin_app = Application.objects.get(slug="kolaboree-admin")

# Los técnicos pueden acceder tanto al panel de usuario como al de admin
PolicyBinding.objects.create(
    target=user_app,
    policy=tech_policy,
    enabled=True,
    order=20
)

PolicyBinding.objects.create(
    target=admin_app,
    policy=tech_policy,
    enabled=True,
    order=20
)

print(f"✅ Política creada para administradores técnicos: {tech_policy.name}")
EOF

# 3. Crear política para administrador global (grupo 'globaladmin')
echo "👨‍💼 Creando política para grupo 'globaladmin'..."
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.policies.expression.models import ExpressionPolicy
from authentik.core.models import PolicyBinding, Application

# Crear política para administrador global
global_policy = ExpressionPolicy.objects.create(
    name="Global Admin Policy",
    expression='return "globaladmin" in [group.name for group in request.user.ak_groups.all()]'
)

# Obtener las aplicaciones
user_app = Application.objects.get(slug="kolaboree-user")
admin_app = Application.objects.get(slug="kolaboree-admin")

# El admin global puede acceder a todo
PolicyBinding.objects.create(
    target=user_app,
    policy=global_policy,
    enabled=True,
    order=5
)

PolicyBinding.objects.create(
    target=admin_app,
    policy=global_policy,
    enabled=True,
    order=5
)

print(f"✅ Política creada para administrador global: {global_policy.name}")
EOF

echo "🎯 Configurando redirecciones automáticas..."

# 4. Configurar flujo de autenticación personalizado
docker exec kolaboree-authentik-server python manage.py shell << 'EOF'
from authentik.flows.models import Flow, FlowStageBinding
from authentik.stages.user_login.models import UserLoginStage
from authentik.stages.identification.models import IdentificationStage
from authentik.policies.expression.models import ExpressionPolicy

# Buscar el flujo de autenticación por defecto
try:
    auth_flow = Flow.objects.get(slug="default-authentication-flow")
    print(f"✅ Flujo de autenticación encontrado: {auth_flow.name}")
    
    # Crear política de redirección basada en grupos
    redirect_policy = ExpressionPolicy.objects.create(
        name="Group Based Redirect Policy",
        expression='''
# Redirección basada en grupos
groups = [group.name for group in request.user.ak_groups.all()]

if "globaladmin" in groups:
    return {"redirect": "http://34.68.124.46/admin"}
elif "admintecnico" in groups:
    return {"redirect": "http://34.68.124.46/admin"}
elif "users" in groups:
    return {"redirect": "http://34.68.124.46/user"}
else:
    return {"redirect": "http://34.68.124.46/user"}
'''
    )
    print(f"✅ Política de redirección creada: {redirect_policy.name}")
    
except Exception as e:
    print(f"❌ Error configurando redirecciones: {e}")
EOF

echo ""
echo "🎉 ¡Configuración de políticas completada!"
echo ""
echo "📋 Resumen de políticas creadas:"
echo "   👥 Users Group Policy - Acceso al panel de usuario"
echo "   🔧 Tech Admin Group Policy - Acceso a ambos paneles"
echo "   👨‍💼 Global Admin Policy - Acceso completo"
echo ""
echo "🔄 Próximos pasos:"
echo "   1. Ve a Authentik en http://localhost:9000"
echo "   2. Verifica las aplicaciones en Applications"
echo "   3. Prueba el login con infra@neogenesys.com"
echo "   4. Verifica la redirección automática"