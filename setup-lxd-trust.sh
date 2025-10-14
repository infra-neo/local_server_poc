#!/bin/bash
# Script para ejecutar EN EL SERVIDOR LXD (100.94.245.27)
# Usuario: neo
# Ejecutar: bash setup-lxd-trust.sh

echo "=========================================="
echo "🔐 Configuración de Trust LXD"
echo "=========================================="
echo ""

# Crear certificado del cliente
cat > /tmp/kolaboree-client.crt <<'EOF'
-----BEGIN CERTIFICATE-----
MIIByTCCAU6gAwIBAgIUTeZwZRNXdXOQa7vOTcvjcH2B2+owCgYIKoZIzj0EAwMw
GzEZMBcGA1UEAwwQa29sYWJvcmVlLWNsaWVudDAeFw0yNTEwMTQwOTM5MDVaFw0z
NTEwMTIwOTM5MDVaMBsxGTAXBgNVBAMMEGtvbGFib3JlZS1jbGllbnQwdjAQBgcq
hkjOPQIBBgUrgQQAIgNiAATKol0kLfyI1F/RpSq2atD+zoZzSw+XNeELv3XIeF7H
Uv+yaGKyJ/C0zOCDW2OGEFjHOm9Gu02G0tikFlcVuGpRZVR4avRg7N3h2tjDkv2b
vXoVEONGH/BEoRCqWPtq0oijUzBRMB0GA1UdDgQWBBQYEcnc448XsIEkuC3tIuKk
fxBzcTAfBgNVHSMEGDAWgBQYEcnc448XsIEkuC3tIuKkfxBzcTAPBgNVHRMBAf8E
BTADAQH/MAoGCCqGSM49BAMDA2kAMGYCMQDQVa1KFxqaqFbWKYtPoHO8b6Wgzy5n
ccDtIsf5zUUpNfYs5yWk8keED3nv44F/0q8CMQDp9MK4JPIQtR8Mf5qNX5HejHDk
8idFSJcOPcD7ENlPAAyuGc8DQT4tNrNpC+kPdcQ=
-----END CERTIFICATE-----
EOF

echo "✅ Certificado creado en /tmp/kolaboree-client.crt"
echo ""

# Agregar al trust de LXD
echo "📋 Agregando certificado al trust de LXD..."
lxc config trust add /tmp/kolaboree-client.crt --name kolaboree-client

echo ""
echo "📊 Lista de certificados de confianza:"
lxc config trust list

echo ""
echo "=========================================="
echo "✅ Configuración completada"
echo "=========================================="
echo ""
echo "Ahora puedes conectar desde Kolaboree usando:"
echo "  - Endpoint: https://100.94.245.27:8443"
echo "  - Certificado y clave generados"
echo ""
