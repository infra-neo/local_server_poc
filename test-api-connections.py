#!/usr/bin/env python3
"""
Script para probar las conexiones cloud vía API REST
Prueba tanto LXD como GCP
"""
import requests
import json
import time

BASE_URL = "http://localhost:8000/api/v1"

def test_lxd_connection():
    """Prueba conexión LXD vía API"""
    print("\n" + "="*70)
    print("🔌 PROBANDO CONEXIÓN LXD VÍA API")
    print("="*70)
    
    # Leer certificados
    with open('credentials/lxd-client.crt', 'r') as f:
        cert = f.read()
    
    with open('credentials/lxd-client.key', 'r') as f:
        key = f.read()
    
    # Crear payload
    payload = {
        "name": "LXC microcloud",
        "provider_type": "lxd",
        "credentials": {
            "endpoint": "https://100.94.245.27:8443",
            "cert": cert,
            "key": key,
            "verify": False
        }
    }
    
    print(f"📡 Endpoint: {payload['credentials']['endpoint']}")
    print(f"🔐 Certificado: {len(cert)} caracteres")
    print(f"🔑 Clave: {len(key)} caracteres")
    print("\n⏳ Enviando petición POST a la API...")
    
    try:
        response = requests.post(
            f"{BASE_URL}/admin/cloud_connections",
            json=payload,
            timeout=30
        )
        
        print(f"\n📊 Status Code: {response.status_code}")
        
        if response.status_code == 201:
            data = response.json()
            connection_id = data.get('id')
            print(f"✅ Conexión creada exitosamente!")
            print(f"🆔 Connection ID: {connection_id}")
            print(f"📛 Nombre: {data.get('name')}")
            print(f"🔌 Provider: {data.get('provider_type')}")
            print(f"✓ Estado: {data.get('status')}")
            
            # Listar instancias
            print("\n⏳ Listando instancias LXD...")
            time.sleep(1)
            
            nodes_response = requests.get(
                f"{BASE_URL}/admin/cloud_connections/{connection_id}/nodes",
                timeout=10
            )
            
            if nodes_response.status_code == 200:
                nodes = nodes_response.json()
                if nodes:
                    print(f"\n✅ Encontradas {len(nodes)} instancia(s):")
                    for node in nodes:
                        ips = ', '.join(node.get('ip_addresses', [])) if node.get('ip_addresses') else 'N/A'
                        print(f"  - {node['name']} ({node['state']}) - IPs: {ips}")
                else:
                    print("ℹ️  No hay instancias en el servidor LXD")
            else:
                print(f"⚠️  Error al listar instancias: {nodes_response.status_code}")
                print(nodes_response.text)
            
            return True, connection_id
        else:
            print(f"❌ Error al crear conexión")
            print(f"Respuesta: {response.text}")
            return False, None
            
    except requests.exceptions.Timeout:
        print("❌ Timeout - El servidor no respondió a tiempo")
        print("💡 Verifica que el servidor LXD esté accesible")
        return False, None
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False, None


def test_gcp_connection():
    """Prueba conexión GCP vía API"""
    print("\n" + "="*70)
    print("☁️  PROBANDO CONEXIÓN GCP VÍA API")
    print("="*70)
    
    # Leer service account
    with open('credentials/gcp-service-account.json', 'r') as f:
        sa_json = f.read()
    
    sa_data = json.loads(sa_json)
    
    # Crear payload
    payload = {
        "name": "GCP fine-web",
        "provider_type": "gcp",
        "region": "us-central1-a",
        "credentials": {
            "service_account_json": sa_json
        }
    }
    
    print(f"📧 Service Account: {sa_data.get('client_email')}")
    print(f"🆔 Project ID: {sa_data.get('project_id')}")
    print(f"🌍 Región: {payload['region']}")
    print("\n⏳ Enviando petición POST a la API...")
    
    try:
        response = requests.post(
            f"{BASE_URL}/admin/cloud_connections",
            json=payload,
            timeout=30
        )
        
        print(f"\n📊 Status Code: {response.status_code}")
        
        if response.status_code == 201:
            data = response.json()
            connection_id = data.get('id')
            print(f"✅ Conexión creada exitosamente!")
            print(f"🆔 Connection ID: {connection_id}")
            print(f"📛 Nombre: {data.get('name')}")
            print(f"🔌 Provider: {data.get('provider_type')}")
            print(f"✓ Estado: {data.get('status')}")
            
            # Listar instancias
            print("\n⏳ Listando instancias GCP...")
            time.sleep(1)
            
            nodes_response = requests.get(
                f"{BASE_URL}/admin/cloud_connections/{connection_id}/nodes",
                timeout=30
            )
            
            if nodes_response.status_code == 200:
                nodes = nodes_response.json()
                if nodes:
                    print(f"\n✅ Encontradas {len(nodes)} instancia(s):")
                    for node in nodes:
                        ips = ', '.join(node.get('ip_addresses', [])) if node.get('ip_addresses') else 'N/A'
                        print(f"  - {node['name']} ({node['state']}) - IPs: {ips}")
                else:
                    print("ℹ️  No hay instancias activas en GCP")
            else:
                print(f"⚠️  Error al listar instancias: {nodes_response.status_code}")
                print(nodes_response.text)
            
            return True, connection_id
        else:
            print(f"❌ Error al crear conexión")
            print(f"Respuesta: {response.text}")
            return False, None
            
    except requests.exceptions.Timeout:
        print("❌ Timeout - El servidor no respondió a tiempo")
        print("💡 Esto puede ser normal en la primera conexión a GCP")
        return False, None
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False, None


def list_all_connections():
    """Lista todas las conexiones creadas"""
    print("\n" + "="*70)
    print("📋 LISTANDO TODAS LAS CONEXIONES")
    print("="*70)
    
    try:
        response = requests.get(f"{BASE_URL}/admin/cloud_connections", timeout=10)
        
        if response.status_code == 200:
            connections = response.json()
            if connections:
                print(f"\n✅ Total: {len(connections)} conexión(es)")
                for conn in connections:
                    print(f"\n  🔌 {conn['name']}")
                    print(f"     ID: {conn['id']}")
                    print(f"     Provider: {conn['provider_type']}")
                    print(f"     Estado: {conn['status']}")
                    print(f"     Creado: {conn['created_at']}")
            else:
                print("ℹ️  No hay conexiones configuradas")
        else:
            print(f"❌ Error: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")


def main():
    """Ejecuta todas las pruebas"""
    print("\n" + "="*70)
    print("🧪 PRUEBA DE CONEXIONES CLOUD VÍA API - KOLABOREE")
    print("="*70)
    
    # Verificar que el backend esté disponible
    print("\n⏳ Verificando backend...")
    try:
        response = requests.get("http://localhost:8000/", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Backend disponible: {data.get('name')} v{data.get('version')}")
        else:
            print("❌ Backend no responde correctamente")
            return 1
    except:
        print("❌ No se puede conectar al backend")
        print("💡 Asegúrate de que el backend esté corriendo:")
        print("   docker ps | grep kolaboree-backend")
        return 1
    
    results = {}
    connection_ids = {}
    
    # Probar LXD
    success, conn_id = test_lxd_connection()
    results['lxd'] = success
    if conn_id:
        connection_ids['lxd'] = conn_id
    
    # Probar GCP
    success, conn_id = test_gcp_connection()
    results['gcp'] = success
    if conn_id:
        connection_ids['gcp'] = conn_id
    
    # Listar todas las conexiones
    list_all_connections()
    
    # Resumen
    print("\n" + "="*70)
    print("📊 RESUMEN DE PRUEBAS")
    print("="*70)
    print(f"LXD:  {'✅ OK' if results['lxd'] else '❌ FALLO'}")
    print(f"GCP:  {'✅ OK' if results['gcp'] else '❌ FALLO'}")
    print("="*70)
    
    if all(results.values()):
        print("\n🎉 ¡Todas las conexiones funcionan correctamente!")
        print("\n📝 Conexiones creadas:")
        for provider, conn_id in connection_ids.items():
            print(f"   {provider.upper()}: {conn_id}")
        print("\n💡 Ahora puedes verlas en la interfaz web:")
        print("   http://localhost:3000")
        return 0
    else:
        print("\n⚠️  Algunas conexiones fallaron. Revisa los mensajes arriba.")
        return 1


if __name__ == "__main__":
    exit(main())
