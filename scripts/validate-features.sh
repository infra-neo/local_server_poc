#!/bin/bash

# Quick Validation Script for Kolaboree NG
# Tests all new features and endpoints

set -e

echo "=================================================="
echo "Kolaboree NG - Feature Validation"
echo "=================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="${API_URL:-http://localhost:8000}"
PASSED=0
FAILED=0

# Test function
test_endpoint() {
    local name=$1
    local url=$2
    local method=${3:-GET}
    
    echo -n "Testing $name... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL$url")
    fi
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAIL (HTTP $response)${NC}"
        FAILED=$((FAILED + 1))
    fi
}

echo "1. Backend API Tests"
echo "--------------------"

# Basic endpoints
test_endpoint "Root endpoint" "/"
test_endpoint "Health check" "/health"
test_endpoint "API docs" "/docs"

echo ""
echo "2. Admin Endpoints"
echo "------------------"

# Admin endpoints
test_endpoint "List cloud connections" "/api/v1/admin/cloud_connections"
test_endpoint "List users" "/api/v1/admin/users"

echo ""
echo "3. File Structure Validation"
echo "-----------------------------"

# Check for new files
check_file() {
    local file=$1
    echo -n "Checking $file... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ EXISTS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ MISSING${NC}"
        FAILED=$((FAILED + 1))
    fi
}

check_file "DRAG_DROP_GUIDE.md"
check_file "PACKAGE_MANAGEMENT.md"
check_file "FEATURES.md"
check_file "frontend/src/components/admin/VMCreationWizard.js"
check_file "frontend/src/pages/UsersManagement.js"
check_file "frontend/src/pages/RemoteConnectionView.js"

echo ""
echo "4. Docker Compose Configuration"
echo "-------------------------------"

echo -n "Checking Guacamole services... "
if grep -q "guacamole:" docker-compose.yml && grep -q "guacd:" docker-compose.yml; then
    echo -e "${GREEN}✓ CONFIGURED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ NOT FOUND${NC}"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "5. Environment Variables"
echo "-----------------------"

echo -n "Checking GUACAMOLE_PORT in .env.example... "
if grep -q "GUACAMOLE_PORT" .env.example; then
    echo -e "${GREEN}✓ PRESENT${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ MISSING${NC}"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "=================================================="
echo "Summary"
echo "=================================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validations passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: docker-compose up -d"
    echo "2. Access admin panel: http://localhost:80"
    echo "3. Access Guacamole: http://localhost:8080/guacamole"
    echo "4. Check API docs: http://localhost:8000/docs"
    exit 0
else
    echo -e "${RED}✗ Some validations failed${NC}"
    echo "Please review the errors above"
    exit 1
fi
