#!/usr/bin/env python3
"""
Script de prueba para conexiones cloud
Prueba LXD y GCP usando las credenciales configuradas
"""
import json
import sys
import os

# Agregar el backend al path
sys.path.insert(0, '/workspaces/local_server_poc/backend')

from app.core.cloud_manager import CloudManager

def test_lxd_connection():
    """Prueba la conexión a LXD"""
    print("\n" + "="*60)
    print("🔌 PROBANDO CONEXIÓN LXD")
    print("="*60)
    
    manager = CloudManager()
    
    # Leer certificados
    try:
        with open('credentials/lxd-client.crt', 'r') as f:
            cert_content = f.read()
        with open('credentials/lxd-client.key', 'r') as f:
            key_content = f.read()
    except FileNotFoundError:
        print("❌ Error: Archivos de certificado no encontrados")
        print("   Asegúrate de que existan:")
        print("   - credentials/lxd-client.crt")
        print("   - credentials/lxd-client.key")
        return False
    
    # Guardar certificados en archivos temporales
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.crt', delete=False) as cert_file:
        cert_file.write(cert_content)
        cert_path = cert_file.name
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.key', delete=False) as key_file:
        key_file.write(key_content)
        key_path = key_file.name
    
    credentials = {
        "endpoint": "https://100.94.245.27:8443",
        "cert": cert_path,
        "key": key_path,
        "verify": False
    }
    
    print(f"📡 Endpoint: {credentials['endpoint']}")
    print(f"🔐 Certificado: {cert_path}")
    print(f"🔑 Clave: {key_path}")
    print("\n⏳ Intentando conectar...")
    
    success = manager.connect_lxd("test-lxd", credentials)
    
    if success:
        print("✅ Conexión exitosa a LXD!")
        print("\n📋 Listando instancias...")
        nodes = manager.list_lxd_nodes("test-lxd")
        if nodes:
            print(f"\n✅ Encontradas {len(nodes)} instancia(s):")
            for node in nodes:
                print(f"  - {node.name} ({node.state}) - IPs: {', '.join(node.ip_addresses) if node.ip_addresses else 'N/A'}")
        else:
            print("ℹ️  No hay instancias en el servidor LXD")
        
        # Limpiar archivos temporales
        os.unlink(cert_path)
        os.unlink(key_path)
        return True
    else:
        print("❌ Error al conectar a LXD")
        print("\n💡 Solución:")
        print("   1. Copia el script setup-lxd-trust.sh al servidor:")
        print("      scp setup-lxd-trust.sh neo@100.94.245.27:~/")
        print("   2. Ejecuta en el servidor:")
        print("      ssh neo@100.94.245.27 'bash setup-lxd-trust.sh'")
        print("   3. Vuelve a ejecutar este script de prueba")
        
        # Limpiar archivos temporales
        os.unlink(cert_path)
        os.unlink(key_path)
        return False


def test_gcp_connection():
    """Prueba la conexión a GCP"""
    print("\n" + "="*60)
    print("☁️  PROBANDO CONEXIÓN GCP")
    print("="*60)
    
    manager = CloudManager()
    
    # Leer service account
    try:
        with open('credentials/gcp-service-account.json', 'r') as f:
            sa_json = f.read()
    except FileNotFoundError:
        print("❌ Error: Archivo de service account no encontrado")
        print("   Asegúrate de que exista: credentials/gcp-service-account.json")
        return False
    
    credentials = {
        "service_account_json": sa_json
    }
    
    sa_data = json.loads(sa_json)
    print(f"📧 Service Account: {sa_data.get('client_email')}")
    print(f"🆔 Project ID: {sa_data.get('project_id')}")
    print(f"🌍 Región: us-central1-a")
    print("\n⏳ Intentando conectar...")
    
    success = manager.connect_gcp("test-gcp", credentials, region="us-central1-a")
    
    if success:
        print("✅ Conexión exitosa a GCP!")
        print("\n📋 Listando instancias...")
        nodes = manager.list_gcp_nodes("test-gcp")
        if nodes:
            print(f"\n✅ Encontradas {len(nodes)} instancia(s):")
            for node in nodes:
                print(f"  - {node.name} ({node.state}) - IPs: {', '.join(node.ip_addresses) if node.ip_addresses else 'N/A'}")
        else:
            print("ℹ️  No hay instancias activas en GCP")
        return True
    else:
        print("❌ Error al conectar a GCP")
        print("\n💡 Verifica:")
        print("   - Que el service account tenga permisos de Compute Engine")
        print("   - Que la API de Compute Engine esté habilitada")
        print("   - Que las credenciales sean válidas")
        return False


def main():
    """Ejecuta todas las pruebas"""
    print("\n" + "="*60)
    print("🧪 PRUEBA DE CONEXIONES CLOUD - KOLABOREE")
    print("="*60)
    
    results = {}
    
    # Probar LXD
    results['lxd'] = test_lxd_connection()
    
    # Probar GCP
    results['gcp'] = test_gcp_connection()
    
    # Resumen
    print("\n" + "="*60)
    print("📊 RESUMEN DE PRUEBAS")
    print("="*60)
    print(f"LXD:  {'✅ OK' if results['lxd'] else '❌ FALLO'}")
    print(f"GCP:  {'✅ OK' if results['gcp'] else '❌ FALLO'}")
    print("="*60)
    
    if all(results.values()):
        print("\n🎉 ¡Todas las conexiones funcionan correctamente!")
        print("\n📝 Siguiente paso:")
        print("   Usa estos proveedores en tu aplicación web Kolaboree")
        return 0
    else:
        print("\n⚠️  Algunas conexiones fallaron. Revisa los mensajes arriba.")
        return 1


if __name__ == "__main__":
    exit(main())
