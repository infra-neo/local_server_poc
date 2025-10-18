#!/usr/bin/env python3
"""
Debug REAL del login de Authentik - Identifica el problema exacto
"""

import requests
import json
import sys
from urllib3.exceptions import InsecureRequestWarning
from urllib.parse import urljoin
from bs4 import BeautifulSoup
import re

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

class AuthentikLoginDebugger:
    def __init__(self):
        self.base_url = "https://34.68.124.46:9443"
        self.session = requests.Session()
        self.session.verify = False
        
    def log_step(self, step, status, details=""):
        status_icon = "✅" if status == "OK" else "❌" if status == "ERROR" else "ℹ️"
        print(f"{status_icon} {step}: {details}")
        
    def get_csrf_token(self, html_content):
        """Extraer CSRF token del HTML"""
        soup = BeautifulSoup(html_content, 'html.parser')
        
        # Buscar en meta tags
        csrf_meta = soup.find('meta', {'name': 'csrf-token'})
        if csrf_meta:
            return csrf_meta.get('content')
            
        # Buscar en inputs hidden
        csrf_input = soup.find('input', {'name': 'csrfmiddlewaretoken'})
        if csrf_input:
            return csrf_input.get('value')
            
        # Buscar en el contenido JavaScript
        csrf_pattern = r'csrfmiddlewaretoken["\']?\s*[:=]\s*["\']([^"\']+)["\']'
        match = re.search(csrf_pattern, html_content)
        if match:
            return match.group(1)
            
        return None
        
    def test_initial_access(self):
        """Test 1: Acceso inicial a la página de login"""
        try:
            response = self.session.get(f"{self.base_url}/if/flow/default-authentication-flow/")
            
            if response.status_code == 200:
                self.log_step("Acceso inicial", "OK", f"Status: {response.status_code}")
                
                # Buscar elementos de login en el HTML
                content = response.text.lower()
                login_elements = []
                
                if 'username' in content or 'user' in content:
                    login_elements.append("Campo usuario")
                if 'password' in content:
                    login_elements.append("Campo password")
                if 'login' in content or 'sign in' in content:
                    login_elements.append("Botón login")
                    
                if login_elements:
                    self.log_step("Elementos login", "OK", f"Encontrados: {', '.join(login_elements)}")
                else:
                    self.log_step("Elementos login", "ERROR", "No se encontraron elementos de login")
                    
                return response
            else:
                self.log_step("Acceso inicial", "ERROR", f"Status: {response.status_code}")
                return None
                
        except Exception as e:
            self.log_step("Acceso inicial", "ERROR", str(e))
            return None
    
    def test_api_flow(self):
        """Test 2: Probar API de flow de autenticación"""
        try:
            response = self.session.get(f"{self.base_url}/api/v3/flows/executor/default-authentication-flow/")
            
            if response.status_code == 200:
                self.log_step("API Flow", "OK", f"Status: {response.status_code}")
                
                try:
                    data = response.json()
                    if 'type' in data:
                        self.log_step("Flow Type", "INFO", data.get('type', 'Unknown'))
                    if 'component' in data:
                        self.log_step("Flow Component", "INFO", data.get('component', 'Unknown'))
                        
                    return data
                except:
                    self.log_step("API Flow", "ERROR", "Respuesta no es JSON válido")
                    return None
            else:
                self.log_step("API Flow", "ERROR", f"Status: {response.status_code}")
                return None
                
        except Exception as e:
            self.log_step("API Flow", "ERROR", str(e))
            return None
    
    def attempt_login(self, username="akadmin", password="Kolaboree2024!Admin"):
        """Test 3: Intentar login real"""
        self.log_step("Intento de Login", "INFO", f"Usuario: {username}")
        
        # Primero obtener el flow
        flow_data = self.test_api_flow()
        if not flow_data:
            return False
            
        # Intentar POST al flow
        try:
            login_data = {
                'uid_field': username,
                'password': password,
                'username': username  # Por si acaso usa este campo
            }
            
            response = self.session.post(
                f"{self.base_url}/api/v3/flows/executor/default-authentication-flow/",
                json=login_data,
                headers={
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                }
            )
            
            self.log_step("POST Login", "INFO", f"Status: {response.status_code}")
            
            if response.status_code == 200:
                try:
                    result = response.json()
                    if 'successful' in result and result['successful']:
                        self.log_step("Login Result", "OK", "Login exitoso")
                        return True
                    else:
                        self.log_step("Login Result", "ERROR", f"Login falló: {result}")
                        return False
                except:
                    self.log_step("Login Result", "ERROR", "Respuesta no es JSON válido")
                    
            elif response.status_code == 302:
                self.log_step("Login Result", "OK", "Redirect - posible login exitoso")
                return True
            else:
                self.log_step("Login Result", "ERROR", f"Status inesperado: {response.status_code}")
                print(f"Response content: {response.text[:500]}")
                
        except Exception as e:
            self.log_step("POST Login", "ERROR", str(e))
            
        return False
    
    def check_user_in_database(self):
        """Test 4: Verificar usuario en base de datos"""
        import subprocess
        
        try:
            cmd = [
                'docker', 'exec', '-i', 'kolaboree-postgres', 
                'psql', '-U', 'kolaboree', '-d', 'kolaboree', 
                '-c', "SELECT username, email, is_active, date_joined FROM authentik_core_user WHERE username = 'akadmin';"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                self.log_step("Usuario en BD", "OK", "Usuario encontrado")
                print(f"   Detalles: {result.stdout.strip()}")
                return True
            else:
                self.log_step("Usuario en BD", "ERROR", f"Error: {result.stderr}")
                return False
                
        except Exception as e:
            self.log_step("Usuario en BD", "ERROR", str(e))
            return False
    
    def check_logs_for_errors(self):
        """Test 5: Revisar logs recientes de Authentik"""
        import subprocess
        
        try:
            cmd = ['docker', 'logs', '--tail', '20', 'kolaboree-authentik-server']
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                logs = result.stdout
                
                # Buscar errores comunes
                error_patterns = [
                    'error', 'Error', 'ERROR',
                    'invalid credentials', 'Invalid credentials',
                    'login_failed', 'authentication failed',
                    'exception', 'Exception'
                ]
                
                found_errors = []
                for pattern in error_patterns:
                    if pattern in logs:
                        found_errors.append(pattern)
                
                if found_errors:
                    self.log_step("Logs Error", "ERROR", f"Encontrados: {', '.join(set(found_errors))}")
                    print("\n--- LOGS RECIENTES ---")
                    print(logs[-1000:])  # Últimos 1000 caracteres
                    print("--- FIN LOGS ---\n")
                else:
                    self.log_step("Logs Error", "OK", "No se encontraron errores evidentes")
                    
        except Exception as e:
            self.log_step("Logs Error", "ERROR", str(e))
    
    def run_complete_debug(self):
        """Ejecutar diagnóstico completo"""
        print("🔍 DIAGNÓSTICO COMPLETO DE LOGIN AUTHENTIK")
        print("=" * 60)
        
        # Test 1: Acceso inicial
        initial_response = self.test_initial_access()
        
        # Test 2: API Flow
        flow_data = self.test_api_flow()
        
        # Test 3: Verificar usuario en BD
        user_exists = self.check_user_in_database()
        
        # Test 4: Intentar login
        login_success = self.attempt_login()
        
        # Test 5: Revisar logs
        self.check_logs_for_errors()
        
        print("\n" + "=" * 60)
        
        if login_success:
            print("✅ LOGIN FUNCIONANDO - El problema puede estar en otro lado")
        else:
            print("❌ LOGIN NO FUNCIONA - Problemas identificados arriba")
            
            print("\n💡 PASOS SUGERIDOS:")
            if not user_exists:
                print("1. Recrear usuario akadmin")
            if not flow_data:
                print("2. Verificar configuración de flows")
            print("3. Revisar logs detallados")
            print("4. Resetear password nuevamente")
            
        return login_success

def main():
    debugger = AuthentikLoginDebugger()
    success = debugger.run_complete_debug()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
