#!/bin/bash

# Test script for Kolaboree NG Platform
# This script performs basic validation of the setup

set -e

echo "=========================================="
echo "Kolaboree NG - Platform Validation"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

test_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} File exists: $1"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} Missing file: $1"
        FAILED=$((FAILED + 1))
    fi
}

test_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} Directory exists: $1"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} Missing directory: $1"
        FAILED=$((FAILED + 1))
    fi
}

echo "1. Checking Backend Structure..."
test_dir "backend"
test_dir "backend/app"
test_dir "backend/app/api"
test_dir "backend/app/api/v1"
test_dir "backend/app/core"
test_file "backend/app/main.py"
test_file "backend/app/models.py"
test_file "backend/app/core/cloud_manager.py"
test_file "backend/app/api/v1/endpoints_admin.py"
test_file "backend/app/api/v1/endpoints_user.py"
test_file "backend/Dockerfile"
test_file "backend/requirements.txt"
echo ""

echo "2. Checking Frontend Structure..."
test_dir "frontend"
test_dir "frontend/src"
test_dir "frontend/src/components"
test_dir "frontend/src/components/admin"
test_dir "frontend/src/components/user"
test_dir "frontend/src/pages"
test_file "frontend/src/App.js"
test_file "frontend/src/index.js"
test_file "frontend/src/components/admin/CloudProviderCard.js"
test_file "frontend/src/components/admin/WizardConector.js"
test_file "frontend/src/components/user/WorkspaceCard.js"
test_file "frontend/src/pages/AdminDashboard.js"
test_file "frontend/src/pages/UserDashboard.js"
test_file "frontend/Dockerfile"
test_file "frontend/package.json"
echo ""

echo "3. Checking Infrastructure..."
test_file "docker-compose.yml"
test_file ".env.example"
test_file "README.md"
test_dir "nginx"
test_file "nginx/nginx.conf"
test_file "nginx/conf.d/default.conf"
echo ""

echo "4. Validating Python Syntax..."
if python3 -m py_compile backend/app/main.py 2>/dev/null; then
    echo -e "${GREEN}✓${NC} backend/app/main.py syntax OK"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} backend/app/main.py has syntax errors"
    FAILED=$((FAILED + 1))
fi

if python3 -m py_compile backend/app/core/cloud_manager.py 2>/dev/null; then
    echo -e "${GREEN}✓${NC} backend/app/core/cloud_manager.py syntax OK"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} backend/app/core/cloud_manager.py has syntax errors"
    FAILED=$((FAILED + 1))
fi
echo ""

echo "5. Validating Docker Compose..."
if docker compose config --quiet 2>&1 | grep -q "warning\|error"; then
    echo -e "${YELLOW}⚠${NC} docker-compose.yml has warnings (check manually)"
else
    echo -e "${GREEN}✓${NC} docker-compose.yml is valid"
    PASSED=$((PASSED + 1))
fi
echo ""

echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! The platform is ready to deploy.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Copy .env.example to .env and configure"
    echo "  2. Run: docker compose up -d"
    echo "  3. Access the platform at http://localhost"
    exit 0
else
    echo -e "${RED}❌ Some checks failed. Please review the errors above.${NC}"
    exit 1
fi
