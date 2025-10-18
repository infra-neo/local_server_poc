#!/usr/bin/env python3
"""
Reset FINAL de password de Authentik - usando Django shell
"""

import subprocess
import sys

def reset_password_via_django():
    """Resetear password usando Django shell directamente"""
    
    # Script Python para ejecutar dentro del contenedor
    django_script = '''
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentik.root.settings')
django.setup()

from authentik.core.models import User
from django.contrib.auth.hashers import make_password

try:
    # Buscar usuario akadmin
    user = User.objects.get(username='akadmin')
    print(f"Usuario encontrado: {user.username} ({user.email})")
    
    # Resetear password
    new_password = "Kolaboree2024!Admin"
    user.set_password(new_password)
    user.save()
    
    print(f"✅ Password reseteada exitosamente para: {user.username}")
    print(f"Nueva password: {new_password}")
    
except User.DoesNotExist:
    print("❌ Usuario akadmin no encontrado")
except Exception as e:
    print(f"❌ Error: {e}")
'''
    
    print("🔧 Reseteando password usando Django shell...")
    
    try:
        # Escribir script a archivo temporal
        with open('/tmp/reset_password.py', 'w') as f:
            f.write(django_script)
        
        # Copiar script al contenedor
        subprocess.run([
            'docker', 'cp', '/tmp/reset_password.py', 
            'kolaboree-authentik-server:/tmp/reset_password.py'
        ], check=True)
        
        # Ejecutar script en el contenedor
        result = subprocess.run([
            'docker', 'exec', 'kolaboree-authentik-server',
            'python', '/tmp/reset_password.py'
        ], capture_output=True, text=True, timeout=30)
        
        print("Salida del reset:")
        print(result.stdout)
        
        if result.stderr:
            print("Errores:")
            print(result.stderr)
        
        return result.returncode == 0
        
    except Exception as e:
        print(f"❌ Error ejecutando reset: {e}")
        return False

def test_login_after_reset():
    """Probar login después del reset"""
    print("\n🧪 Probando login después del reset...")
    
    try:
        result = subprocess.run([
            'python3', 'debug-login-real.py'
        ], capture_output=True, text=True, timeout=60)
        
        if "✅ LOGIN FUNCIONANDO" in result.stdout:
            print("✅ Login funciona después del reset")
            return True
        else:
            print("❌ Login aún no funciona")
            print("Salida:")
            print(result.stdout[-500:])  # Últimas 500 caracteres
            return False
            
    except Exception as e:
        print(f"❌ Error probando login: {e}")
        return False

def main():
    print("🔥 RESET FINAL DE PASSWORD AUTHENTIK")
    print("=" * 50)
    
    # 1. Reset usando Django
    if reset_password_via_django():
        print("✅ Reset de password completado")
        
        # 2. Probar login
        if test_login_after_reset():
            print("\n🎉 ¡LOGIN FUNCIONANDO!")
            print("\n📋 CREDENCIALES FINALES:")
            print("🌐 URL: https://34.68.124.46:9443")
            print("👤 Usuario: akadmin")
            print("🔑 Password: Kolaboree2024!Admin")
            return True
        else:
            print("\n⚠️  Password reseteada pero login aún falla")
    else:
        print("❌ Error reseteando password")
    
    print("\n🛠️ Intentando método alternativo...")
    
    # Método alternativo: usar comando ak directamente
    print("Ejecutando changepassword interactivo...")
    subprocess.run([
        'docker', 'exec', '-it', 'kolaboree-authentik-server',
        'ak', 'changepassword', 'akadmin'
    ])
    
    return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)