#!/usr/bin/env python3
"""
Generar hash de password válido para Django/Authentik
"""

import hashlib
import secrets
import base64

def generate_django_password_hash(password, iterations=600000):
    """Generar hash de password compatible con Django"""
    
    # Generar salt aleatorio
    salt = secrets.token_urlsafe(16)
    
    # Crear hash PBKDF2
    dk = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), iterations)
    hash_b64 = base64.b64encode(dk).decode('ascii')
    
    # Formato Django: algorithm$iterations$salt$hash
    django_hash = f"pbkdf2_sha256${iterations}${salt}${hash_b64}"
    
    return django_hash

def main():
    password = "Kolaboree2024!Admin"
    
    print("🔐 Generando hash de password para Authentik...")
    print(f"Password: {password}")
    
    # Generar hash
    password_hash = generate_django_password_hash(password)
    
    print(f"\nHash generado:")
    print(password_hash)
    
    # Crear comando SQL
    sql_command = f"""UPDATE authentik_core_user SET password = '{password_hash}' WHERE username = 'akadmin';"""
    
    print(f"\n📝 Comando SQL:")
    print(sql_command)
    
    return password_hash

if __name__ == "__main__":
    main()