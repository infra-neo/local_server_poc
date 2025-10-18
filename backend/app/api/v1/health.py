"""
Health check endpoints for system monitoring
"""
from fastapi import APIRouter, HTTPException
from typing import Dict, Any
import asyncio
import aiohttp
import socket
import ldap3
import os

router = APIRouter(prefix="/health", tags=["health"])

@router.get("/")
async def health_check():
    """Basic health check"""
    return {"status": "healthy", "service": "RAC Backend API"}

@router.get("/ldap")
async def check_ldap():
    """Check LDAP connectivity and users"""
    try:
        # LDAP configuration from environment
        ldap_server = "kolaboree-ldap"
        ldap_port = 389
        bind_dn = "cn=admin,dc=kolaboree,dc=local"
        bind_password = "zEYgBeGPqNdqXSUF2IajtezHrjSE8tXgE8dx6ClhWiMiqD35+tMtVZIndUzaMW01"
        base_dn = "dc=kolaboree,dc=local"
        
        # Test connection
        server = ldap3.Server(f'ldap://{ldap_server}:{ldap_port}', connect_timeout=10)
        conn = ldap3.Connection(server, bind_dn, bind_password, auto_bind=True)
        
        # Search for users
        conn.search(
            search_base=base_dn,
            search_filter='(objectClass=inetOrgPerson)',
            attributes=['uid', 'cn', 'mail']
        )
        
        users = []
        for entry in conn.entries:
            users.append({
                'uid': str(entry.uid) if entry.uid else "N/A",
                'cn': str(entry.cn) if entry.cn else "N/A",
                'mail': str(entry.mail) if entry.mail else "N/A"
            })
        
        conn.unbind()
        
        return {
            "status": "healthy",
            "server": f"ldap://{ldap_server}:{ldap_port}",
            "base_dn": base_dn,
            "users_count": len(users),
            "users": users[:5]  # Return first 5 users
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "error": str(e),
                "service": "LDAP"
            }
        )

@router.get("/authentik")
async def check_authentik():
    """Check Authentik connectivity"""
    try:
        authentik_url = "https://34.68.124.46:9443/if/flow/default-authentication-flow/"
        
        async with aiohttp.ClientSession(
            connector=aiohttp.TCPConnector(ssl=False),
            timeout=aiohttp.ClientTimeout(total=10)
        ) as session:
            async with session.get(authentik_url) as response:
                content = await response.text()
                
                return {
                    "status": "healthy",
                    "url": authentik_url,
                    "http_status": response.status,
                    "has_login_form": "authentik" in content.lower(),
                    "response_size": len(content)
                }
                
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "error": str(e),
                "service": "Authentik"
            }
        )

@router.get("/guacamole")
async def check_guacamole():
    """Check Guacamole connectivity and try authentication"""
    try:
        guacamole_url = "http://34.68.124.46:8080/guacamole/"
        
        async with aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=10)
        ) as session:
            # Test basic connectivity
            async with session.get(guacamole_url) as response:
                basic_status = response.status
                
            # Try to get token (test authentication)
            auth_url = "http://34.68.124.46:8080/guacamole/api/tokens"
            auth_data = aiohttp.FormData()
            auth_data.add_field('username', 'akadmin')
            auth_data.add_field('password', 'Kolaboree2024')
            
            try:
                async with session.post(auth_url, data=auth_data) as auth_response:
                    if auth_response.status == 200:
                        token_data = await auth_response.json()
                        auth_status = "success"
                        token_preview = token_data.get('authToken', '')[:20] + '...' if token_data.get('authToken') else 'N/A'
                    else:
                        auth_status = f"failed_{auth_response.status}"
                        token_preview = "N/A"
            except:
                auth_status = "error"
                token_preview = "N/A"
                
            return {
                "status": "healthy",
                "url": guacamole_url,
                "http_status": basic_status,
                "auth_status": auth_status,
                "token_preview": token_preview
            }
                
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "error": str(e),
                "service": "Guacamole"
            }
        )

@router.get("/system")
async def check_system():
    """Complete system health check"""
    results = {}
    
    # Check each service
    services = ['ldap', 'authentik', 'guacamole']
    
    for service in services:
        try:
            if service == 'ldap':
                result = await check_ldap()
            elif service == 'authentik':
                result = await check_authentik()
            elif service == 'guacamole':
                result = await check_guacamole()
                
            results[service] = {
                "status": "healthy",
                "details": result
            }
        except HTTPException as e:
            results[service] = {
                "status": "unhealthy",
                "error": e.detail
            }
        except Exception as e:
            results[service] = {
                "status": "error",
                "error": str(e)
            }
    
    # Overall health
    healthy_services = sum(1 for r in results.values() if r["status"] == "healthy")
    total_services = len(results)
    
    return {
        "overall_status": "healthy" if healthy_services == total_services else "degraded",
        "healthy_services": healthy_services,
        "total_services": total_services,
        "services": results,
        "timestamp": "2025-10-18T00:00:00Z"
    }