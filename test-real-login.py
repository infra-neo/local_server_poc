#!/usr/bin/env python3
"""
Test REAL del login de Authentik simulando navegador
"""

import requests
import json
import sys
from urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

def test_real_login():
    """Test real del login simulando exactamente el comportamiento del navegador"""
    
    print("🌐 TEST REAL DE LOGIN AUTHENTIK")
    print("=" * 50)
    
    session = requests.Session()
    session.verify = False
    
    base_url = "https://34.68.124.46:9443"
    
    # Paso 1: Obtener la página inicial de login
    print("1️⃣ Obteniendo página inicial...")
    
    try:
        response = session.get(f"{base_url}/if/flow/default-authentication-flow/")
        print(f"   Status: {response.status_code}")
        
        if response.status_code != 200:
            print("❌ No se puede acceder a la página de login")
            return False
            
    except Exception as e:
        print(f"❌ Error accediendo: {e}")
        return False
    
    # Paso 2: Obtener el flow de autenticación
    print("2️⃣ Obteniendo flow de autenticación...")
    
    try:
        response = session.get(f"{base_url}/api/v3/flows/executor/default-authentication-flow/")
        print(f"   Status: {response.status_code}")
        
        if response.status_code != 200:
            print("❌ No se puede obtener el flow")
            return False
            
        flow_data = response.json()
        print(f"   Component: {flow_data.get('component', 'unknown')}")
        
        if flow_data.get('component') != 'ak-stage-identification':
            print("❌ Flow no está en el stage de identificación")
            return False
            
    except Exception as e:
        print(f"❌ Error obteniendo flow: {e}")
        return False
    
    # Paso 3: Enviar usuario (identificación)
    print("3️⃣ Enviando usuario...")
    
    try:
        identification_data = {
            'uid_field': 'akadmin'
        }
        
        response = session.post(
            f"{base_url}/api/v3/flows/executor/default-authentication-flow/",
            json=identification_data,
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        )
        
        print(f"   Status: {response.status_code}")
        
        if response.status_code != 200:
            print("❌ Error enviando usuario")
            return False
            
        flow_data = response.json()
        print(f"   Next Component: {flow_data.get('component', 'unknown')}")
        
        if flow_data.get('component') != 'ak-stage-password':
            print("❌ No pasó al stage de password")
            return False
            
        pending_user = flow_data.get('pending_user')
        print(f"   Pending User: {pending_user}")
        
        if pending_user != 'akadmin':
            print("❌ Usuario pendiente no es akadmin")
            return False
            
    except Exception as e:
        print(f"❌ Error enviando usuario: {e}")
        return False
    
    # Paso 4: Enviar password
    print("4️⃣ Enviando password...")
    
    try:
        password_data = {
            'password': 'Kolaboree2024!Admin'
        }
        
        response = session.post(
            f"{base_url}/api/v3/flows/executor/default-authentication-flow/",
            json=password_data,
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        )
        
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            flow_data = response.json()
            
            # Verificar si el login fue exitoso
            if 'successful' in flow_data and flow_data['successful']:
                print("✅ ¡LOGIN EXITOSO!")
                return True
            elif 'component' in flow_data:
                next_component = flow_data.get('component')
                print(f"   Next Component: {next_component}")
                
                if next_component == 'ak-stage-password':
                    print("❌ Aún en password stage - password incorrecta")
                    return False
                else:
                    print(f"✅ Login exitoso - siguiente step: {next_component}")
                    return True
            else:
                print("ℹ️ Respuesta inesperada:")
                print(json.dumps(flow_data, indent=2)[:500])
                return False
                
        elif response.status_code == 302:
            print("✅ Login exitoso - redirect")
            return True
        else:
            print(f"❌ Status inesperado: {response.status_code}")
            print(f"Response: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"❌ Error enviando password: {e}")
        return False

def main():
    success = test_real_login()
    
    print("\n" + "=" * 50)
    
    if success:
        print("🎉 ¡LOGIN FUNCIONA CORRECTAMENTE!")
        print("\n📋 CREDENCIALES CONFIRMADAS:")
        print("🌐 URL: https://34.68.124.46:9443")
        print("👤 Usuario: akadmin")
        print("🔑 Password: Kolaboree2024!Admin")
    else:
        print("❌ LOGIN AÚN NO FUNCIONA")
        print("\nℹ️ Revisemos los logs de Authentik:")
        print("docker logs kolaboree-authentik-server | grep -i 'login\\|password\\|error' | tail -10")
    
    return success

if __name__ == "__main__":
    sys.exit(0 if main() else 1)