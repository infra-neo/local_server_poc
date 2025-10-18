#!/usr/bin/env python3
"""
Script para configurar LDAP Source en Authentik
Sincroniza usuarios desde OpenLDAP
"""

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class AuthentikLDAPConfigurator:
    def __init__(self):
        self.base_url = "https://34.68.124.46:9443"
        self.session = requests.Session()
        self.session.verify = False
        
        # Configuración LDAP desde el análisis anterior
        self.ldap_config = {
            "name": "Neogenesys LDAP",
            "slug": "neogenesys-ldap",
            "server_uri": "ldap://kolaboree-ldap:389",
            "bind_cn": "cn=admin,dc=kolaboree,dc=local",
            "bind_password": "zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01",
            "base_dn": "dc=kolaboree,dc=local",
            "additional_user_dn": "ou=users",
            "additional_group_dn": "ou=groups",
            "user_object_filter": "(objectClass=inetOrgPerson)",
            "group_object_filter": "(objectClass=groupOfNames)",
            "group_membership_field": "member",
            "object_uniqueness_field": "uid",
            "sync_users": True,
            "sync_users_password": True,
            "sync_groups": True,
            "sync_parent_group": None
        }
        
    def get_auth_token(self, username, password):
        """Obtener token de autenticación"""
        print("🔐 Obteniendo token de autenticación...")
        
        login_page = self.session.get(f"{self.base_url}/if/flow/default-authentication-flow/")
        
        # Buscar token CSRF
        csrf_token = None
        for line in login_page.text.split('\n'):
            if 'csrfmiddlewaretoken' in line and 'value=' in line:
                csrf_token = line.split('value="')[1].split('"')[0]
                break
        
        if not csrf_token:
            print("❌ No se pudo obtener token CSRF")
            return False
            
        # Realizar login
        login_data = {
            'uid_field': username,
            'password': password,
            'csrfmiddlewaretoken': csrf_token
        }
        
        response = self.session.post(
            f"{self.base_url}/if/flow/default-authentication-flow/",
            data=login_data,
            allow_redirects=False
        )
        
        if response.status_code in [302, 200]:
            print("✅ Autenticación exitosa")
            return True
        else:
            print(f"❌ Error en autenticación: {response.status_code}")
            return False
    
    def check_existing_ldap_sources(self):
        """Verificar fuentes LDAP existentes"""
        print("🔍 Verificando fuentes LDAP existentes...")
        
        response = self.session.get(f"{self.base_url}/api/v3/sources/ldap/")
        
        if response.status_code == 200:
            sources = response.json()['results']
            print(f"✅ Encontradas {len(sources)} fuentes LDAP")
            
            for source in sources:
                print(f"  📂 {source['name']} (slug: {source['slug']})")
                print(f"     Server: {source['server_uri']}")
                print(f"     Base DN: {source['base_dn']}")
                
            return sources
        else:
            print(f"❌ Error obteniendo fuentes LDAP: {response.status_code}")
            return []
    
    def create_ldap_source(self):
        """Crear nueva fuente LDAP"""
        print("🔧 Creando fuente LDAP...")
        
        response = self.session.post(
            f"{self.base_url}/api/v3/sources/ldap/",
            json=self.ldap_config,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 201:
            source = response.json()
            print("✅ Fuente LDAP creada exitosamente")
            print(f"  📂 Nombre: {source['name']}")
            print(f"  🔗 Slug: {source['slug']}")
            print(f"  🌐 Server: {source['server_uri']}")
            return source
        else:
            print(f"❌ Error creando fuente LDAP: {response.status_code}")
            print(f"Response: {response.text}")
            return None
    
    def sync_ldap_users(self, source_slug):
        """Sincronizar usuarios desde LDAP"""
        print(f"🔄 Sincronizando usuarios desde LDAP ({source_slug})...")
        
        # Trigger sync
        response = self.session.post(
            f"{self.base_url}/api/v3/sources/ldap/{source_slug}/sync/",
            json={}
        )
        
        if response.status_code in [200, 202]:
            print("✅ Sincronización iniciada")
            return True
        else:
            print(f"❌ Error iniciando sincronización: {response.status_code}")
            return False
    
    def check_users(self):
        """Verificar usuarios sincronizados"""
        print("👥 Verificando usuarios sincronizados...")
        
        response = self.session.get(f"{self.base_url}/api/v3/core/users/")
        
        if response.status_code == 200:
            users = response.json()['results']
            print(f"✅ Encontrados {len(users)} usuarios")
            
            ldap_users = [u for u in users if 'ldap' in str(u.get('source', '')).lower()]
            print(f"📂 Usuarios LDAP: {len(ldap_users)}")
            
            for user in users:
                source_name = user.get('source_name', 'Local')
                print(f"  👤 {user['username']} ({user['email']}) - Fuente: {source_name}")
                
            return users
        else:
            print(f"❌ Error obteniendo usuarios: {response.status_code}")
            return []
    
    def run_ldap_setup(self):
        """Ejecutar configuración completa de LDAP"""
        print("🚀 Configurando LDAP Source en Authentik")
        print("=" * 50)
        
        # Autenticación
        if not self.get_auth_token("akadmin", "Kolaboree2024!Admin"):
            return False
        
        # Verificar fuentes existentes
        existing_sources = self.check_existing_ldap_sources()
        
        # Crear fuente LDAP si no existe
        neogenesys_source = None
        for source in existing_sources:
            if 'neogenesys' in source['name'].lower():
                neogenesys_source = source
                print(f"✅ Fuente LDAP existente encontrada: {source['name']}")
                break
        
        if not neogenesys_source:
            neogenesys_source = self.create_ldap_source()
            if not neogenesys_source:
                return False
        
        # Sincronizar usuarios
        source_slug = neogenesys_source['slug']
        self.sync_ldap_users(source_slug)
        
        # Verificar usuarios
        import time
        print("⏳ Esperando sincronización...")
        time.sleep(5)
        self.check_users()
        
        print("\n✅ Configuración LDAP completada")
        print("🎯 Próximos pasos:")
        print("   1. Verificar sincronización en Authentik Admin")
        print("   2. Configurar Property Mappings si es necesario")
        print("   3. Crear OAuth2 Provider para Guacamole")
        print("   4. Probar flujo completo de autenticación")
        
        return True

if __name__ == "__main__":
    print("🔧 LDAP Source Configurator - Authentik")
    print("Configurando sincronización con OpenLDAP")
    print("=" * 60)
    
    try:
        configurator = AuthentikLDAPConfigurator()
        success = configurator.run_ldap_setup()
        
        if success:
            print("\n✅ Configuración LDAP exitosa")
        else:
            print("\n❌ Error en configuración LDAP")
            
    except Exception as e:
        print(f"\n❌ Error inesperado: {e}")
        import traceback
        traceback.print_exc()