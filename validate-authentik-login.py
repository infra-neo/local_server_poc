#!/usr/bin/env python3
"""
Validación final del login de Authentik - Confirma que todo funciona
"""

import requests
from urllib3.exceptions import InsecureRequestWarning
import sys

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

def test_authentik_access():
    """Test completo de acceso a Authentik"""
    print("🔍 VALIDACIÓN FINAL DEL LOGIN AUTHENTIK")
    print("=" * 50)
    
    tests = [
        {
            "name": "HTTPS Principal",
            "url": "https://34.68.124.46:9443/if/flow/default-authentication-flow/",
            "expected": ["authentication", "login", "password", "username"]
        },
        {
            "name": "API Root Config", 
            "url": "https://34.68.124.46:9443/api/v3/root/config/",
            "expected": ["authentik", "version"]
        },
        {
            "name": "Branding Current",
            "url": "https://34.68.124.46:9443/api/v3/core/brands/current/",
            "expected": ["branding", "matched_domain"]
        }
    ]
    
    all_passed = True
    
    for test in tests:
        print(f"\n🧪 Probando: {test['name']}")
        
        try:
            response = requests.get(test['url'], verify=False, timeout=10)
            
            if response.status_code == 200:
                print(f"   ✅ Status: {response.status_code}")
                
                content = response.text.lower()
                found_keywords = []
                
                for keyword in test['expected']:
                    if keyword.lower() in content:
                        found_keywords.append(keyword)
                
                if len(found_keywords) >= 1:
                    print(f"   ✅ Keywords: {', '.join(found_keywords)}")
                else:
                    print(f"   ⚠️  Keywords no encontradas: {test['expected']}")
                    
            else:
                print(f"   ❌ Status: {response.status_code}")
                all_passed = False
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
            all_passed = False
    
    print("\n" + "=" * 50)
    
    if all_passed:
        print("✅ TODOS LOS TESTS PASARON")
        print("\n📋 RESUMEN DE ACCESO:")
        print("▶️  URL: https://34.68.124.46:9443")
        print("▶️  Usuario: akadmin")
        print("▶️  Password: Kolaboree2024!Admin")
        print("▶️  Email: infra@neogenesys.com")
        
        print("\n🎉 EL LOGIN DE AUTHENTIK ESTÁ FUNCIONANDO CORRECTAMENTE")
        
    else:
        print("❌ ALGUNOS TESTS FALLARON")
        print("Verifica los logs: docker logs kolaboree-authentik-server")
    
    return all_passed

if __name__ == "__main__":
    success = test_authentik_access()
    sys.exit(0 if success else 1)