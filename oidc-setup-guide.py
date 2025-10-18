#!/usr/bin/env python3
"""
Guía paso a paso para configurar OIDC Provider en Authentik manualmente
"""

def show_manual_configuration():
    print("🔐 GUÍA PASO A PASO: CONFIGURAR OIDC PROVIDER EN AUTHENTIK")
    print("="*65)
    
    print("\n📋 INFORMACIÓN NECESARIA:")
    print("▶️ Authentik Admin: https://34.68.124.46:9443/if/admin/")
    print("▶️ Usuario: akadmin")
    print("▶️ Contraseña: Kolaboree2024!Admin")
    
    print("\n🔧 PASO 1: CREAR OAUTH2/OPENID PROVIDER")
    print("-" * 45)
    print("1. Acceder a: https://34.68.124.46:9443/if/admin/")
    print("2. Login con: akadmin / Kolaboree2024!Admin")
    print("3. En el menú lateral, ir a: Applications > Providers")
    print("4. Hacer clic en: [Create] (botón azul)")
    print("5. Seleccionar: OAuth2/OpenID Provider")
    print("6. Configurar estos campos EXACTOS:")
    print()
    print("   📝 DATOS DEL PROVIDER:")
    print("   ├── Name: Guacamole OIDC Provider")
    print("   ├── Authorization flow: default-provider-authorization-explicit-consent (o similar)")
    print("   ├── Client type: Confidential")
    print("   ├── Client ID: guacamole-rac-client")
    print("   ├── Client Secret: guacamole-rac-secret-2024")
    print("   ├── Redirect URIs/Origins (IMPORTANTE):")
    print("   │   https://34.68.124.46:8080/guacamole/")
    print("   │   https://34.68.124.46:8080/guacamole")
    print("   ├── Signing Key: (dejar por defecto)")
    print("   ├── Advanced protocol settings:")
    print("   │   ├── Scopes: openid profile email")
    print("   │   ├── Subject mode: Based on the User's ID")
    print("   │   ├── Include claims in id_token: ✅ ACTIVADO")
    print("   │   └── Issuer mode: Each provider has a different issuer")
    print("   └── Machine-to-machine authentication: (desactivado)")
    print()
    print("7. Hacer clic en: [Create]")
    
    print("\n🔗 PASO 2: CREAR APPLICATION")
    print("-" * 35)
    print("1. En el menú lateral, ir a: Applications > Applications")
    print("2. Hacer clic en: [Create] (botón azul)")
    print("3. Configurar estos campos:")
    print()
    print("   📝 DATOS DE LA APPLICATION:")
    print("   ├── Name: Apache Guacamole")
    print("   ├── Slug: guacamole")
    print("   ├── Provider: Guacamole OIDC Provider (seleccionar el creado arriba)")
    print("   ├── Launch URL: https://34.68.124.46:8080/guacamole/")
    print("   ├── Open in new tab: ❌ NO")
    print("   ├── Icon: (opcional - puede subir logo de Guacamole)")
    print("   ├── Publisher: Kolaboree")
    print("   ├── Description: Remote Desktop Gateway")
    print("   └── Policy engine mode: ANY")
    print()
    print("4. Hacer clic en: [Create]")
    
    print("\n✅ PASO 3: VERIFICACIÓN")
    print("-" * 25)
    print("1. En Applications > Providers, debería aparecer:")
    print("   ▶️ Guacamole OIDC Provider (OAuth2/OpenID Provider)")
    print()
    print("2. En Applications > Applications, debería aparecer:")
    print("   ▶️ Apache Guacamole (con slug: guacamole)")
    print()
    print("3. Hacer clic en la aplicación 'Apache Guacamole'")
    print("4. Verificar que en la pestaña 'Provider Info' aparezcan los endpoints:")
    print("   ├── Authorization URL: https://34.68.124.46:9443/application/o/authorize/")
    print("   ├── Token URL: https://34.68.124.46:9443/application/o/token/")
    print("   ├── Userinfo URL: https://34.68.124.46:9443/application/o/userinfo/")
    print("   ├── Logout URL: https://34.68.124.46:9443/application/o/guacamole/end-session/")
    print("   └── JWKS URL: https://34.68.124.46:9443/application/o/guacamole/jwks/")
    
    print("\n🚀 PASO 4: PROBAR LA INTEGRACIÓN")
    print("-" * 35)
    print("1. Acceder a Guacamole: https://34.68.124.46:8080/guacamole/")
    print("2. Debería aparecer:")
    print("   ▶️ Botón 'Login with OIDC' o")
    print("   ▶️ Redirect automático a Authentik")
    print("3. Login en Authentik con cualquier usuario creado")
    print("4. Debería redirigir de vuelta a Guacamole autenticado")
    
    print("\n🔧 CONFIGURACIÓN ACTUAL DE GUACAMOLE:")
    print("-" * 45)
    print("✅ docker-compose.yml ya configurado con:")
    print("├── OPENID_AUTHORIZATION_ENDPOINT: https://34.68.124.46:9443/application/o/authorize/")
    print("├── OPENID_JWKS_ENDPOINT: https://34.68.124.46:9443/application/o/guacamole/jwks/")
    print("├── OPENID_ISSUER: https://34.68.124.46:9443/application/o/guacamole/")
    print("├── OPENID_CLIENT_ID: guacamole-rac-client")
    print("├── OPENID_REDIRECT_URI: https://34.68.124.46:8080/guacamole/")
    print("├── OPENID_USERNAME_CLAIM_TYPE: preferred_username")
    print("├── OPENID_ENABLED: true")
    print("└── EXTENSION_PRIORITY: *,openid")
    
    print("\n⚠️  SOLUCIÓN DE PROBLEMAS:")
    print("-" * 30)
    print("❌ Si no aparece el botón OIDC:")
    print("   1. Verificar que el provider esté configurado correctamente")
    print("   2. Revisar logs de Guacamole: docker-compose logs guacamole")
    print("   3. Verificar que las URLs en docker-compose.yml coincidan con Authentik")
    print()
    print("❌ Si hay error de redirect_uri:")
    print("   1. Verificar que las URLs en Authentik Redirect URIs incluyan:")
    print("      - https://34.68.124.46:8080/guacamole/")
    print("      - https://34.68.124.46:8080/guacamole")
    print()
    print("❌ Si hay errores SSL:")
    print("   1. Verificar que todas las URLs usen https://")
    print("   2. Verificar certificados SSL de Authentik")
    
    print("\n🎯 DESPUÉS DE LA CONFIGURACIÓN:")
    print("-" * 35)
    print("1. Los usuarios podrán acceder a Guacamole directamente desde:")
    print("   ▶️ https://34.68.124.46:8080/guacamole/ (con OIDC)")
    print("   ▶️ El launcher de Authentik en https://34.68.124.46:9443/")
    print()
    print("2. SSO funcionará automáticamente entre Authentik y Guacamole")
    print()
    print("3. Los usuarios solo necesitarán hacer login una vez en Authentik")

def check_current_status():
    print("\n📊 ESTADO ACTUAL DEL SISTEMA:")
    print("-" * 35)
    
    import subprocess
    import json
    
    try:
        # Verificar estado de contenedores
        result = subprocess.run(
            ['docker-compose', 'ps', '--format', 'json'],
            capture_output=True,
            text=True,
            cwd='/home/infra/local_server_poc'
        )
        
        if result.returncode == 0:
            containers = result.stdout.strip().split('\n')
            for container_line in containers:
                if container_line.strip():
                    container = json.loads(container_line)
                    name = container.get('Name', 'Unknown')
                    state = container.get('State', 'Unknown')
                    health = container.get('Health', 'N/A')
                    
                    if 'guacamole' in name.lower() or 'authentik' in name.lower():
                        status_icon = "✅" if state == "running" else "❌"
                        print(f"{status_icon} {name}: {state} (Health: {health})")
        
    except Exception as e:
        print(f"⚠️ No se pudo verificar el estado de los contenedores: {e}")
    
    print("\n🔗 URLs DE ACCESO:")
    print("├── Authentik Admin: https://34.68.124.46:9443/if/admin/")
    print("├── Authentik User: https://34.68.124.46:9443/")
    print("└── Guacamole: https://34.68.124.46:8080/guacamole/")

if __name__ == "__main__":
    show_manual_configuration()
    check_current_status()
    
    print("\n" + "="*65)
    print("💡 RESUMEN: El archivo docker-compose.yml ya está configurado.")
    print("   Solo falta crear el Provider y Application en Authentik UI.")
    print("="*65)