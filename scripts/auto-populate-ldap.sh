#!/bin/bash

# 🔐 Automated LDAP Population and Validation Script
# Purpose: Populate LDAP with test users and validate synchronization
# Usage: ./scripts/auto-populate-ldap.sh [--ci-mode] [--validate-only]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${PROJECT_ROOT}/logs/ldap-population-$(date +%Y%m%d-%H%M%S).log"
CI_MODE="${CI_MODE:-false}"
VALIDATE_ONLY="${1:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac
}

# Create logs directory
mkdir -p "${PROJECT_ROOT}/logs"

log "INFO" "🚀 Starting LDAP Population and Validation"
log "INFO" "📁 Project Root: $PROJECT_ROOT"
log "INFO" "📝 Log File: $LOG_FILE"

# Function to wait for LDAP service
wait_for_ldap() {
    log "INFO" "⏳ Waiting for LDAP service to be ready..."
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose exec -T openldap ldapsearch -x -H ldap://localhost -b "" -s base > /dev/null 2>&1; then
            log "INFO" "✅ LDAP service is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        log "DEBUG" "Attempt $attempt/$max_attempts - LDAP not ready yet"
        sleep 2
    done
    
    log "ERROR" "❌ LDAP service failed to become ready after $max_attempts attempts"
    return 1
}

# Function to create LDAP test data
create_test_data() {
    log "INFO" "📝 Creating LDAP test data..."
    
    # Create temporary LDIF file
    local ldif_file="/tmp/auto-test-data.ldif"
    
    cat > "$ldif_file" << 'EOF'
# Base organizational units
dn: ou=users,dc=kolaboree,dc=local
objectClass: organizationalUnit
ou: users

dn: ou=groups,dc=kolaboree,dc=local
objectClass: organizationalUnit
ou: groups

# Test users
dn: uid=soporte,ou=users,dc=kolaboree,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: soporte
cn: Soporte Técnico
sn: Técnico
givenName: Soporte
mail: soporte@kolaboree.local
userPassword: {PLAIN}Neo123!!!
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/soporte
description: Technical Support User

dn: uid=admin.test,ou=users,dc=kolaboree,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: admin.test
cn: Administrator Test
sn: Test
givenName: Administrator
mail: admin.test@kolaboree.local
userPassword: {PLAIN}AdminTest123!
uidNumber: 1002
gidNumber: 1002
homeDirectory: /home/admin.test
description: Test Administrator User

dn: uid=user.demo,ou=users,dc=kolaboree,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: user.demo
cn: Demo User
sn: User
givenName: Demo
mail: user.demo@kolaboree.local
userPassword: {PLAIN}DemoUser123!
uidNumber: 1003
gidNumber: 1003
homeDirectory: /home/user.demo
description: Demo User for Testing

# Groups
dn: cn=administrators,ou=groups,dc=kolaboree,dc=local
objectClass: groupOfNames
cn: administrators
description: System Administrators
member: uid=soporte,ou=users,dc=kolaboree,dc=local
member: uid=admin.test,ou=users,dc=kolaboree,dc=local

dn: cn=users,ou=groups,dc=kolaboree,dc=local
objectClass: groupOfNames
cn: users
description: Regular Users
member: uid=user.demo,ou=users,dc=kolaboree,dc=local
member: uid=soporte,ou=users,dc=kolaboree,dc=local

dn: cn=support,ou=groups,dc=kolaboree,dc=local
objectClass: groupOfNames
cn: support
description: Support Team
member: uid=soporte,ou=users,dc=kolaboree,dc=local
EOF

    # Apply LDIF to LDAP
    log "INFO" "📤 Applying test data to LDAP..."
    if docker-compose exec -T openldap ldapadd -x -D "cn=admin,dc=kolaboree,dc=local" -w "admin" -f <(cat "$ldif_file") 2>/dev/null; then
        log "INFO" "✅ Test data added successfully"
    else
        log "WARN" "⚠️ Some entries may already exist, attempting modifications..."
        # Try to modify existing entries
        docker-compose exec -T openldap ldapmodify -x -D "cn=admin,dc=kolaboree,dc=local" -w "admin" -f <(cat "$ldif_file") 2>/dev/null || true
    fi
    
    # Cleanup
    rm -f "$ldif_file"
}

# Function to validate LDAP data
validate_ldap_data() {
    log "INFO" "🔍 Validating LDAP data..."
    
    # Test users exist
    local test_users=("soporte" "admin.test" "user.demo")
    for user in "${test_users[@]}"; do
        log "DEBUG" "Checking user: $user"
        if docker-compose exec -T openldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "admin" -b "ou=users,dc=kolaboree,dc=local" "uid=$user" | grep -q "dn: uid=$user"; then
            log "INFO" "✅ User $user exists"
        else
            log "ERROR" "❌ User $user not found"
            return 1
        fi
    done
    
    # Test groups exist
    local test_groups=("administrators" "users" "support")
    for group in "${test_groups[@]}"; do
        log "DEBUG" "Checking group: $group"
        if docker-compose exec -T openldap ldapsearch -x -D "cn=admin,dc=kolaboree,dc=local" -w "admin" -b "ou=groups,dc=kolaboree,dc=local" "cn=$group" | grep -q "dn: cn=$group"; then
            log "INFO" "✅ Group $group exists"
        else
            log "ERROR" "❌ Group $group not found"
            return 1
        fi
    done
    
    # Test authentication
    log "DEBUG" "Testing user authentication..."
    if docker-compose exec -T openldap ldapwhoami -x -D "uid=soporte,ou=users,dc=kolaboree,dc=local" -w "Neo123!!!" > /dev/null 2>&1; then
        log "INFO" "✅ User authentication test passed"
    else
        log "ERROR" "❌ User authentication test failed"
        return 1
    fi
    
    return 0
}

# Function to test property mappings
test_property_mappings() {
    log "INFO" "🔧 Testing property mappings configuration..."
    
    # This would normally test Authentik API
    # For now, we'll create a validation script that can be run manually
    
    cat > "${PROJECT_ROOT}/validate-property-mappings.sh" << 'EOF'
#!/bin/bash
# Manual validation script for Authentik property mappings
echo "🔍 Property Mappings Validation Checklist:"
echo ""
echo "1. Username Mapping:"
echo "   Expression: return request.user.username"
echo "   Expected: Maps to 'uid' attribute from LDAP"
echo ""
echo "2. Email Mapping:"
echo "   Expression: return request.user.email"
echo "   Expected: Maps to 'mail' attribute from LDAP"
echo ""
echo "3. Name Mapping:"
echo "   Expression: return request.user.name"
echo "   Expected: Maps to 'cn' attribute from LDAP"
echo ""
echo "4. Group Mapping:"
echo "   Expression: return [group.name for group in request.user.ak_groups.all()]"
echo "   Expected: Maps user groups from LDAP"
echo ""
echo "✅ Run this validation in Authentik Admin UI -> Directory -> Property Mappings"
EOF
    
    chmod +x "${PROJECT_ROOT}/validate-property-mappings.sh"
    log "INFO" "📝 Created property mappings validation script"
}

# Function to generate validation report
generate_validation_report() {
    log "INFO" "📊 Generating LDAP validation report..."
    
    local report_file="${PROJECT_ROOT}/ldap-validation-report.md"
    
    cat > "$report_file" << EOF
# 🔐 LDAP Population and Validation Report

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Script:** auto-populate-ldap.sh
**CI Mode:** $CI_MODE

## 📋 Summary

- ✅ LDAP service connectivity verified
- ✅ Test users created and validated
- ✅ Test groups created and validated
- ✅ User authentication tested
- ✅ Property mappings validation script generated

## 👥 Test Users Created

| Username | Email | Groups | Password | Status |
|----------|-------|--------|----------|--------|
| soporte | soporte@kolaboree.local | administrators, users, support | Neo123!!! | ✅ Active |
| admin.test | admin.test@kolaboree.local | administrators | AdminTest123! | ✅ Active |
| user.demo | user.demo@kolaboree.local | users | DemoUser123! | ✅ Active |

## 🏷️ Test Groups Created

| Group Name | Description | Members |
|------------|-------------|---------|
| administrators | System Administrators | soporte, admin.test |
| users | Regular Users | user.demo, soporte |
| support | Support Team | soporte |

## 🔧 Next Steps

1. **Configure Authentik LDAP Source:**
   - Server URI: ldap://openldap:389
   - Bind DN: cn=admin,dc=kolaboree,dc=local
   - Bind Password: admin
   - Base DN: dc=kolaboree,dc=local
   - User DN: ou=users,dc=kolaboree,dc=local
   - Group DN: ou=groups,dc=kolaboree,dc=local

2. **Setup Property Mappings:**
   - Run: \`./validate-property-mappings.sh\`
   - Configure mappings in Authentik Admin UI

3. **Test Synchronization:**
   - Force sync in Authentik LDAP Source
   - Verify users appear in Authentik Admin

## 📝 Logs

Full logs available at: \`$LOG_FILE\`

---
*Report generated by automated LDAP population script*
EOF

    log "INFO" "📊 Report generated: $report_file"
}

# Main execution
main() {
    # Parse arguments
    if [[ "${1:-}" == "--validate-only" ]]; then
        VALIDATE_ONLY=true
        log "INFO" "🔍 Running in validation-only mode"
    fi
    
    # Wait for LDAP service
    if ! wait_for_ldap; then
        log "ERROR" "❌ LDAP service not available"
        exit 1
    fi
    
    # Create test data (unless validation-only)
    if [[ "$VALIDATE_ONLY" != "true" ]]; then
        create_test_data
    fi
    
    # Always validate
    if validate_ldap_data; then
        log "INFO" "✅ LDAP validation successful"
    else
        log "ERROR" "❌ LDAP validation failed"
        exit 1
    fi
    
    # Generate additional resources
    test_property_mappings
    generate_validation_report
    
    log "INFO" "🎉 LDAP population and validation completed successfully!"
    
    if [[ "$CI_MODE" != "true" ]]; then
        echo ""
        echo "📋 Next steps:"
        echo "1. Review the validation report: ldap-validation-report.md"
        echo "2. Configure Authentik LDAP source with the provided settings"
        echo "3. Run property mappings validation: ./validate-property-mappings.sh"
        echo "4. Test user synchronization in Authentik Admin UI"
    fi
}

# Run main function
main "$@"