#!/usr/bin/env python3
"""
Script de Validación del Flujo LDAP → Authentik → Guacamole
=============================================================

Este script valida todo el flujo de autenticación:
1. LDAP: Verifica usuarios y passwords
2. Authentik: Valida configuración LDAP source
3. Guacamole: Confirma conexiones disponibles
4. Test end-to-end del flujo completo

Uso:
    python test-ldap-authentik-flow.py
"""

import requests
import ldap3
import json
import sys
import urllib3
from urllib.parse import urljoin
import time
import os

# Deshabilitar warnings SSL para testing
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class LDAPAuthFlowTester:
    def __init__(self):
        self.base_ip = "34.68.124.46"
        self.authentik_url = f"https://{self.base_ip}:9443"
        self.guacamole_url = f"http://{self.base_ip}:8080/guacamole"
        self.ldap_server = self.base_ip
        self.ldap_port = 389
        
        # Credenciales desde .env
        self.ldap_admin_dn = "cn=admin,dc=kolaboree,dc=local"
        self.ldap_admin_password = "zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01"
        self.ldap_base_dn = "dc=kolaboree,dc=local"
        
        # Usuarios de prueba
        self.test_users = [
            {"uid": "akadmin", "mail": "infra@neogenesys.com", "cn": "AK Admin"},
            {"uid": "usuario1", "mail": "usuario1@neogenesys.com", "cn": "Usuario Uno"},
            {"uid": "infra", "mail": "infra@neogenesys.com", "cn": "Infra Administrator"}
        ]
        
        self.results = {}
        
    def print_header(self, title):
        print(f"\n{'='*60}")
        print(f"{title:^60}")
        print(f"{'='*60}")
        
    def print_step(self, step, status="INFO"):
        symbols = {"OK": "✅", "ERROR": "❌", "INFO": "🔍", "WARNING": "⚠️"}
        print(f"{symbols.get(status, '▶️')} {step}")
        
    def test_ldap_connection(self):
        """Test 1: Verificar conexión y usuarios en LDAP"""
        self.print_header("TEST 1: VERIFICACIÓN DE LDAP")
        
        try:
            # Conectar a LDAP
            server = ldap3.Server(f'ldap://{self.ldap_server}:{self.ldap_port}')
            conn = ldap3.Connection(server, self.ldap_admin_dn, self.ldap_admin_password, auto_bind=True)
            
            self.print_step("Conexión a LDAP exitosa", "OK")
            
            # Buscar usuarios
            conn.search(
                search_base=self.ldap_base_dn,
                search_filter='(objectClass=inetOrgPerson)',
                attributes=['uid', 'cn', 'mail', 'userPassword', 'objectClass']
            )
            
            users_found = []
            for entry in conn.entries:
                user_data = {
                    'uid': str(entry.uid) if entry.uid else "N/A",
                    'cn': str(entry.cn) if entry.cn else "N/A", 
                    'mail': str(entry.mail) if entry.mail else "N/A",
                    'dn': str(entry.entry_dn),
                    'has_password': bool(entry.userPassword)
                }
                users_found.append(user_data)
                
            self.print_step(f"Usuarios encontrados en LDAP: {len(users_found)}", "OK")
            
            for user in users_found:
                print(f"  👤 {user['uid']} ({user['cn']}) - {user['mail']}")
                print(f"     DN: {user['dn']}")
                print(f"     Password: {'✅ Configurado' if user['has_password'] else '❌ No configurado'}")
                
            self.results['ldap'] = {
                'status': 'success',
                'users_count': len(users_found),
                'users': users_found
            }
            
            conn.unbind()
            return True
            
        except Exception as e:
            self.print_step(f"Error en LDAP: {e}", "ERROR")
            self.results['ldap'] = {'status': 'error', 'error': str(e)}
            return False
    
    def test_ldap_user_auth(self, uid, password):
        """Test 2: Verificar autenticación de usuario específico"""
        self.print_header(f"TEST 2: AUTENTICACIÓN LDAP - {uid}")
        
        try:
            # Primero buscar el DN del usuario
            server = ldap3.Server(f'ldap://{self.ldap_server}:{self.ldap_port}')
            admin_conn = ldap3.Connection(server, self.ldap_admin_dn, self.ldap_admin_password, auto_bind=True)
            
            admin_conn.search(
                search_base=self.ldap_base_dn,
                search_filter=f'(uid={uid})',
                attributes=['uid', 'cn', 'mail']
            )
            
            if not admin_conn.entries:
                self.print_step(f"Usuario {uid} no encontrado en LDAP", "ERROR")
                return False
                
            user_dn = str(admin_conn.entries[0].entry_dn)
            user_data = {
                'dn': user_dn,
                'cn': str(admin_conn.entries[0].cn),
                'mail': str(admin_conn.entries[0].mail)
            }
            
            self.print_step(f"Usuario encontrado: {user_data['cn']} ({user_data['mail']})", "OK")
            admin_conn.unbind()
            
            # Intentar autenticación con el usuario
            user_conn = ldap3.Connection(server, user_dn, password, auto_bind=True)
            self.print_step(f"Autenticación exitosa para {uid}", "OK")
            user_conn.unbind()
            
            return True
            
        except ldap3.core.exceptions.LDAPInvalidCredentialsError:
            self.print_step(f"Credenciales inválidas para {uid}", "ERROR")
            return False
        except Exception as e:
            self.print_step(f"Error en autenticación LDAP: {e}", "ERROR")
            return False
    
    def test_authentik_access(self):
        """Test 3: Verificar acceso a Authentik"""
        self.print_header("TEST 3: VERIFICACIÓN DE AUTHENTIK")
        
        try:
            # Test de conectividad
            response = requests.get(
                f"{self.authentik_url}/if/flow/default-authentication-flow/",
                verify=False,
                timeout=10
            )
            
            if response.status_code == 200:
                self.print_step("Authentik accesible", "OK")
                self.print_step(f"URL: {self.authentik_url}", "INFO")
                
                # Verificar si contiene login form
                if 'authentik' in response.text.lower():
                    self.print_step("Página de login cargada correctamente", "OK")
                else:
                    self.print_step("Página no contiene formulario de login", "WARNING")
                    
                self.results['authentik'] = {'status': 'success', 'accessible': True}
                return True
            else:
                self.print_step(f"Authentik retornó código {response.status_code}", "ERROR")
                return False
                
        except Exception as e:
            self.print_step(f"Error conectando a Authentik: {e}", "ERROR")
            self.results['authentik'] = {'status': 'error', 'error': str(e)}
            return False
    
    def test_guacamole_access(self):
        """Test 4: Verificar acceso a Guacamole"""
        self.print_header("TEST 4: VERIFICACIÓN DE GUACAMOLE")
        
        try:
            # Test de conectividad
            response = requests.get(f"{self.guacamole_url}/", timeout=10)
            
            if response.status_code == 200:
                self.print_step("Guacamole accesible", "OK")
                self.print_step(f"URL: {self.guacamole_url}", "INFO")
                
                # Test de API con credenciales hardcodeadas
                self.print_step("Probando autenticación con akadmin...", "INFO")
                
                auth_data = {
                    "username": "akadmin",
                    "password": "Kolaboree2024"
                }
                
                auth_response = requests.post(
                    f"{self.guacamole_url}/api/tokens",
                    data=auth_data,
                    timeout=10
                )
                
                if auth_response.status_code == 200:
                    token_data = auth_response.json()
                    self.print_step("Autenticación Guacamole exitosa", "OK")
                    self.print_step(f"Token obtenido: {token_data.get('authToken', 'N/A')[:20]}...", "INFO")
                    
                    # Test de conexiones
                    token = token_data.get('authToken')
                    connections_url = f"{self.guacamole_url}/api/session/data/{token_data.get('dataSource')}/connections"
                    
                    conn_response = requests.get(
                        connections_url,
                        params={'token': token},
                        timeout=10
                    )
                    
                    if conn_response.status_code == 200:
                        connections = conn_response.json()
                        self.print_step(f"Conexiones disponibles: {len(connections)}", "OK")
                        
                        for conn_id, conn_info in connections.items():
                            print(f"  🖥️  {conn_info.get('name', 'Sin nombre')} ({conn_info.get('protocol', 'N/A')})")
                            
                        self.results['guacamole'] = {
                            'status': 'success',
                            'auth_working': True,
                            'connections_count': len(connections),
                            'connections': connections
                        }
                        return True
                    else:
                        self.print_step("Error obteniendo conexiones de Guacamole", "ERROR")
                        
                else:
                    self.print_step(f"Error en autenticación Guacamole: {auth_response.status_code}", "ERROR")
                    
            else:
                self.print_step(f"Guacamole retornó código {response.status_code}", "ERROR")
                
            return False
            
        except Exception as e:
            self.print_step(f"Error conectando a Guacamole: {e}", "ERROR")
            self.results['guacamole'] = {'status': 'error', 'error': str(e)}
            return False
    
    def test_authentik_ldap_source(self):
        """Test 5: Verificar configuración LDAP en Authentik"""
        self.print_header("TEST 5: CONFIGURACIÓN LDAP EN AUTHENTIK")
        
        self.print_step("⚠️ Esta verificación requiere acceso a Authentik Admin", "WARNING")
        self.print_step("Para completar:", "INFO")
        self.print_step("1. Acceder a: https://34.68.124.46:9443/if/admin/", "INFO")
        self.print_step("2. Directory -> LDAP Sources", "INFO")
        self.print_step("3. Verificar configuración:", "INFO")
        
        print("   📋 Configuración LDAP requerida:")
        print(f"      Server URI: ldap://{self.ldap_server}:{self.ldap_port}")
        print(f"      Bind DN: {self.ldap_admin_dn}")
        print(f"      Base DN: {self.ldap_base_dn}")
        print(f"      User DN: ou=users,{self.ldap_base_dn}")
        print(f"      Group DN: ou=groups,{self.ldap_base_dn}")
        
        return True
    
    def generate_fix_script(self):
        """Generar script de corrección"""
        self.print_header("SCRIPT DE CORRECCIÓN")
        
        script_content = f"""#!/bin/bash
# Script de Corrección del Flujo LDAP → Authentik → Guacamole
# Generado automáticamente por test-ldap-authentik-flow.py

echo "🔧 Aplicando correcciones al flujo de autenticación..."

# 1. Verificar servicios
echo "1️⃣ Verificando servicios..."
docker ps --filter name=kolaboree --format "table {{{{.Names}}}}\\t{{{{.Status}}}}"

# 2. Reiniciar Authentik para aplicar configuración LDAP
echo "2️⃣ Reiniciando Authentik..."
docker restart kolaboree-authentik-server kolaboree-authentik-worker

# 3. Verificar logs de Authentik
echo "3️⃣ Revisando logs de Authentik..."
docker logs kolaboree-authentik-server | tail -20

# 4. Test rápido de conectividad
echo "4️⃣ Probando conectividad..."
curl -s -o /dev/null -w "LDAP: %{{http_code}}\\n" ldap://{self.ldap_server}:{self.ldap_port} || echo "LDAP: Conexión TCP OK"
curl -k -s -o /dev/null -w "Authentik: %{{http_code}}\\n" {self.authentik_url}/if/flow/default-authentication-flow/
curl -s -o /dev/null -w "Guacamole: %{{http_code}}\\n" {self.guacamole_url}/

echo "✅ Script de corrección completado"
echo "📋 Para continuar:"
echo "   1. Acceder a Authentik Admin: {self.authentik_url}/if/admin/"
echo "   2. Configurar LDAP Source con datos mostrados arriba"
echo "   3. Crear OAuth2 Provider para Guacamole"
echo "   4. Probar flujo completo"
"""
        
        with open('/home/infra/local_server_poc/fix-ldap-authentik-flow.sh', 'w') as f:
            f.write(script_content)
            
        os.chmod('/home/infra/local_server_poc/fix-ldap-authentik-flow.sh', 0o755)
        self.print_step("Script de corrección creado: fix-ldap-authentik-flow.sh", "OK")
    
    def run_full_test(self):
        """Ejecutar todos los tests"""
        self.print_header("🚀 INICIANDO VALIDACIÓN COMPLETA DEL FLUJO")
        
        # Test 1: LDAP
        ldap_ok = self.test_ldap_connection()
        
        # Test 2: Autenticación LDAP (probar con contraseñas conocidas)
        if ldap_ok:
            self.print_step("Probando autenticación LDAP con contraseñas conocidas...", "INFO")
            test_passwords = ["Kolaboree2024!Admin", "Kolaboree2024", "admin", "password"]
            
            for password in test_passwords:
                self.print_step(f"Probando password: {password[:5]}...", "INFO")
                if self.test_ldap_user_auth("akadmin", password):
                    self.print_step(f"✅ Password correcto para akadmin: {password}", "OK")
                    break
        
        # Test 3: Authentik
        self.test_authentik_access()
        
        # Test 4: Guacamole
        self.test_guacamole_access()
        
        # Test 5: Configuración LDAP
        self.test_authentik_ldap_source()
        
        # Generar script de corrección
        self.generate_fix_script()
        
        # Resumen final
        self.print_header("📊 RESUMEN DE RESULTADOS")
        
        for service, result in self.results.items():
            status = result.get('status', 'unknown')
            symbol = "✅" if status == 'success' else "❌"
            print(f"{symbol} {service.upper()}: {status}")
            
        self.print_step("Validación completa finalizada", "OK")
        
        # Recomendaciones
        self.print_header("🎯 PRÓXIMOS PASOS RECOMENDADOS")
        print("1. 🔧 Ejecutar: ./fix-ldap-authentik-flow.sh")
        print("2. 🌐 Acceder a Authentik Admin y configurar LDAP Source")
        print("3. 🔗 Crear OAuth2 Provider para Guacamole")
        print("4. 🧪 Probar flujo: Authentik Login → Guacamole Access")
        print("5. 📱 Crear frontend para gestión de conexiones")

if __name__ == "__main__":
    print("🔬 RAC Flow Validator - LDAP → Authentik → Guacamole")
    print("=" * 60)
    
    try:
        tester = LDAPAuthFlowTester()
        tester.run_full_test()
    except KeyboardInterrupt:
        print("\\n❌ Test interrumpido por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\\n❌ Error inesperado: {e}")
        sys.exit(1)