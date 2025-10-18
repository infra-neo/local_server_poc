#!/usr/bin/env python3
"""
Script para configurar RAC (Remote Access Control) en Authentik
"""
import requests
import json
import time
import sys

# Configuración
AUTHENTIK_URL = "http://34.68.124.46:9000"
USERNAME = "akadmin"
PASSWORD = "KolaboreeAdmin2024"

def get_auth_token():
    """Obtener token de autenticación"""
    url = f"{AUTHENTIK_URL}/api/v3/flows/executor/default-authentication-flow/"
    
    # Obtener el formulario de login
    response = requests.get(url)
    if response.status_code != 200:
        print(f"Error al obtener formulario de login: {response.status_code}")
        return None
    
    # Extraer CSRF token
    csrf_token = None
    for line in response.text.split('\n'):
        if 'csrfmiddlewaretoken' in line and 'value=' in line:
            csrf_token = line.split('value="')[1].split('"')[0]
            break
    
    if not csrf_token:
        print("No se pudo obtener CSRF token")
        return None
    
    # Hacer login
    session = requests.Session()
    login_data = {
        'csrfmiddlewaretoken': csrf_token,
        'uid_field': USERNAME,
        'password': PASSWORD,
    }
    
    response = session.post(url, data=login_data)
    if response.status_code == 200 and 'successfully authenticated' in response.text.lower():
        print("Login exitoso")
        return session
    
    print(f"Error en login: {response.status_code}")
    return None

def create_rac_provider(session):
    """Crear proveedor RAC"""
    url = f"{AUTHENTIK_URL}/api/v3/providers/rac/"
    
    data = {
        "name": "Kolaboree Guacamole RAC",
        "authorization_flow": "default-provider-authorization-implicit-consent",
        "settings": {
            "guacamole_url": "http://kolaboree-guacamole:8080/guacamole/",
            "guacamole_admin_user": "akadmin",
            "guacamole_admin_password": "KolaboreeAdmin2024"
        },
        "connection_expiry": "hours=8",
        "delete_token_on_disconnect": True
    }
    
    response = session.post(url, json=data)
    if response.status_code in [200, 201]:
        print("Proveedor RAC creado exitosamente")
        return response.json()
    else:
        print(f"Error creando proveedor RAC: {response.status_code} - {response.text}")
        return None

def create_rac_application(session, provider_pk):
    """Crear aplicación RAC"""
    url = f"{AUTHENTIK_URL}/api/v3/core/applications/"
    
    data = {
        "name": "Remote Desktop Access",
        "slug": "remote-desktop",
        "provider": provider_pk,
        "meta_description": "Access remote desktops through Kolaboree platform",
        "meta_publisher": "Kolaboree",
        "policy_engine_mode": "any",
        "open_in_new_tab": True
    }
    
    response = session.post(url, json=data)
    if response.status_code in [200, 201]:
        print("Aplicación RAC creada exitosamente")
        return response.json()
    else:
        print(f"Error creando aplicación RAC: {response.status_code} - {response.text}")
        return None

def main():
    print("=== Configurando RAC en Authentik ===")
    
    # Esperar a que Authentik esté listo
    print("Esperando a que Authentik esté disponible...")
    time.sleep(10)
    
    # Obtener sesión autenticada
    session = get_auth_token()
    if not session:
        print("No se pudo autenticar")
        sys.exit(1)
    
    # Crear proveedor RAC
    provider = create_rac_provider(session)
    if not provider:
        print("No se pudo crear el proveedor RAC")
        sys.exit(1)
    
    # Crear aplicación RAC
    application = create_rac_application(session, provider['pk'])
    if not application:
        print("No se pudo crear la aplicación RAC")
        sys.exit(1)
    
    print("=== Configuración RAC completada ===")
    print(f"Proveedor ID: {provider['pk']}")
    print(f"Aplicación ID: {application['pk']}")

if __name__ == "__main__":
    main()
