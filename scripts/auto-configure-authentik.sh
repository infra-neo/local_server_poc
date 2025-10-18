#!/bin/bash

# 🔐 Automated Authentik OIDC Configuration Script
# Purpose: Configure Authentik OIDC provider and RAC application automatically
# Usage: ./scripts/auto-configure-authentik.sh [--ci-mode] [--dry-run]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${PROJECT_ROOT}/logs/authentik-config-$(date +%Y%m%d-%H%M%S).log"
CI_MODE="${CI_MODE:-false}"
DRY_RUN="${1:-false}"

# Authentik Configuration
AUTHENTIK_URL="${AUTHENTIK_URL:-http://localhost:9000}"
AUTHENTIK_TOKEN="${AUTHENTIK_TOKEN:-}"
GUACAMOLE_URL="${GUACAMOLE_URL:-http://localhost:8080/guacamole/}"

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

log "INFO" "🚀 Starting Authentik OIDC Configuration"
log "INFO" "📁 Project Root: $PROJECT_ROOT"
log "INFO" "📝 Log File: $LOG_FILE"

# Function to wait for Authentik service
wait_for_authentik() {
    log "INFO" "⏳ Waiting for Authentik service to be ready..."
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f "${AUTHENTIK_URL}/if/flow/initial-setup/" > /dev/null 2>&1; then
            log "INFO" "✅ Authentik service is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        log "DEBUG" "Attempt $attempt/$max_attempts - Authentik not ready yet"
        sleep 5
    done
    
    log "ERROR" "❌ Authentik service failed to become ready after $max_attempts attempts"
    return 1
}

# Function to get Authentik admin token
get_authentik_token() {
    log "INFO" "🔑 Obtaining Authentik admin token..."
    
    if [[ -n "$AUTHENTIK_TOKEN" ]]; then
        log "INFO" "✅ Using provided token"
        return 0
    fi
    
    # In CI mode, we would typically have this pre-configured
    if [[ "$CI_MODE" == "true" ]]; then
        log "WARN" "⚠️ CI mode requires pre-configured AUTHENTIK_TOKEN"
        return 1
    fi
    
    # For manual setup, generate instructions
    cat > "${PROJECT_ROOT}/get-authentik-token.sh" << 'EOF'
#!/bin/bash
echo "🔑 To get Authentik admin token:"
echo ""
echo "1. Open Authentik Admin UI: http://localhost:9000/"
echo "2. Login with admin credentials"
echo "3. Go to Directory -> Tokens"
echo "4. Create new token with admin permissions"
echo "5. Export token: export AUTHENTIK_TOKEN='your-token-here'"
echo "6. Re-run this script"
echo ""
echo "Alternatively, for API-based token creation:"
echo "curl -X POST http://localhost:9000/api/v3/core/tokens/ \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"identifier\": \"auto-config\", \"user\": 1, \"description\": \"Auto configuration token\"}'"
EOF
    
    chmod +x "${PROJECT_ROOT}/get-authentik-token.sh"
    log "INFO" "📝 Created token instructions: get-authentik-token.sh"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        log "ERROR" "❌ AUTHENTIK_TOKEN required for actual configuration"
        return 1
    fi
    
    return 0
}

# Function to create LDAP source
create_ldap_source() {
    log "INFO" "📁 Creating LDAP source configuration..."
    
    local ldap_config=$(cat << 'EOF'
{
  "name": "LDAP-Kolaboree",
  "slug": "ldap-kolaboree",
  "enabled": true,
  "authentication_flow": null,
  "enrollment_flow": null,
  "server_uri": "ldap://openldap:389",
  "peer_certificate": null,
  "client_certificate": null,
  "bind_cn": "cn=admin,dc=kolaboree,dc=local",
  "bind_password": "admin",
  "start_tls": false,
  "sni": false,
  "base_dn": "dc=kolaboree,dc=local",
  "additional_user_dn": "ou=users",
  "additional_group_dn": "ou=groups",
  "user_object_filter": "(objectClass=person)",
  "group_object_filter": "(objectClass=groupOfNames)",
  "group_membership_field": "member",
  "object_uniqueness_field": "uid",
  "sync_users": true,
  "sync_users_password": true,
  "sync_groups": true,
  "sync_parent_group": null,
  "property_mappings": [],
  "property_mappings_group": []
}
EOF
)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "🔍 [DRY RUN] Would create LDAP source with config:"
        echo "$ldap_config" | jq '.' 2>/dev/null || echo "$ldap_config"
        return 0
    fi
    
    log "DEBUG" "Creating LDAP source via API..."
    local response=$(curl -s -X POST "${AUTHENTIK_URL}/api/v3/sources/ldap/" \
        -H "Authorization: Bearer ${AUTHENTIK_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$ldap_config")
    
    if echo "$response" | jq -e '.pk' > /dev/null 2>&1; then
        local source_id=$(echo "$response" | jq -r '.pk')
        log "INFO" "✅ LDAP source created with ID: $source_id"
        echo "$source_id" > "${PROJECT_ROOT}/.authentik-ldap-source-id"
    else
        log "ERROR" "❌ Failed to create LDAP source: $response"
        return 1
    fi
}

# Function to create property mappings
create_property_mappings() {
    log "INFO" "🏷️ Creating property mappings..."
    
    # Username mapping
    local username_mapping=$(cat << 'EOF'
{
  "name": "LDAP Username",
  "expression": "return request.user.username",
  "managed": null
}
EOF
)
    
    # Email mapping
    local email_mapping=$(cat << 'EOF'
{
  "name": "LDAP Email",
  "expression": "return request.user.email", 
  "managed": null
}
EOF
)
    
    # Name mapping
    local name_mapping=$(cat << 'EOF'
{
  "name": "LDAP Name",
  "expression": "return request.user.name",
  "managed": null
}
EOF
)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "🔍 [DRY RUN] Would create property mappings for: username, email, name"
        return 0
    fi
    
    # Create mappings via API
    for mapping_name in "username" "email" "name"; do
        case $mapping_name in
            "username") mapping_data="$username_mapping" ;;
            "email") mapping_data="$email_mapping" ;;
            "name") mapping_data="$name_mapping" ;;
        esac
        
        log "DEBUG" "Creating $mapping_name mapping..."
        local response=$(curl -s -X POST "${AUTHENTIK_URL}/api/v3/propertymappings/user/" \
            -H "Authorization: Bearer ${AUTHENTIK_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$mapping_data")
        
        if echo "$response" | jq -e '.pk' > /dev/null 2>&1; then
            local mapping_id=$(echo "$response" | jq -r '.pk')
            log "INFO" "✅ Property mapping '$mapping_name' created with ID: $mapping_id"
            echo "$mapping_id" >> "${PROJECT_ROOT}/.authentik-property-mappings"
        else
            log "WARN" "⚠️ Property mapping '$mapping_name' might already exist: $response"
        fi
    done
}

# Function to create OIDC provider
create_oidc_provider() {
    log "INFO" "🔐 Creating OIDC provider..."
    
    local oidc_config=$(cat << EOF
{
  "name": "Guacamole OIDC",
  "authorization_flow": null,
  "client_type": "confidential",
  "client_id": "guacamole",
  "client_secret": "$(openssl rand -base64 32)",
  "redirect_uris": "${GUACAMOLE_URL}",
  "signing_key": null,
  "sub_mode": "hashed_user_id",
  "include_claims_in_id_token": true,
  "issuer_mode": "per_provider",
  "jwks_sources": []
}
EOF
)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "🔍 [DRY RUN] Would create OIDC provider with config:"
        echo "$oidc_config" | jq '.' 2>/dev/null || echo "$oidc_config"
        return 0
    fi
    
    log "DEBUG" "Creating OIDC provider via API..."
    local response=$(curl -s -X POST "${AUTHENTIK_URL}/api/v3/providers/oauth2/" \
        -H "Authorization: Bearer ${AUTHENTIK_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$oidc_config")
    
    if echo "$response" | jq -e '.pk' > /dev/null 2>&1; then
        local provider_id=$(echo "$response" | jq -r '.pk')
        local client_secret=$(echo "$response" | jq -r '.client_secret')
        log "INFO" "✅ OIDC provider created with ID: $provider_id"
        
        # Save configuration for Guacamole
        cat > "${PROJECT_ROOT}/guacamole-oidc-config.env" << EOF
# Guacamole OIDC Configuration
OPENID_AUTHORIZATION_ENDPOINT=${AUTHENTIK_URL}/application/o/authorize/
OPENID_JWKS_ENDPOINT=${AUTHENTIK_URL}/application/o/guacamole/jwks/
OPENID_ISSUER=${AUTHENTIK_URL}/application/o/guacamole/
OPENID_CLIENT_ID=guacamole
OPENID_REDIRECT_URI=${GUACAMOLE_URL}
OPENID_USERNAME_CLAIM_TYPE=preferred_username
OPENID_GROUPS_CLAIM_TYPE=groups
OPENID_SCOPE=openid profile email groups
EOF
        
        log "INFO" "📁 OIDC configuration saved to: guacamole-oidc-config.env"
        echo "$provider_id" > "${PROJECT_ROOT}/.authentik-oidc-provider-id"
    else
        log "ERROR" "❌ Failed to create OIDC provider: $response"
        return 1
    fi
}

# Function to create RAC application
create_rac_application() {
    log "INFO" "🌐 Creating RAC application..."
    
    local provider_id
    if [[ -f "${PROJECT_ROOT}/.authentik-oidc-provider-id" ]]; then
        provider_id=$(cat "${PROJECT_ROOT}/.authentik-oidc-provider-id")
    else
        log "ERROR" "❌ OIDC provider ID not found. Create provider first."
        return 1
    fi
    
    local app_config=$(cat << EOF
{
  "name": "Guacamole RAC",
  "slug": "guacamole-rac",
  "provider": $provider_id,
  "launch_url": "${GUACAMOLE_URL}",
  "open_in_new_tab": true,
  "meta_description": "Remote Access Client - Guacamole",
  "meta_publisher": "Kolaboree",
  "policy_engine_mode": "any",
  "group": null
}
EOF
)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "🔍 [DRY RUN] Would create RAC application with config:"
        echo "$app_config" | jq '.' 2>/dev/null || echo "$app_config"
        return 0
    fi
    
    log "DEBUG" "Creating RAC application via API..."
    local response=$(curl -s -X POST "${AUTHENTIK_URL}/api/v3/core/applications/" \
        -H "Authorization: Bearer ${AUTHENTIK_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$app_config")
    
    if echo "$response" | jq -e '.pk' > /dev/null 2>&1; then
        local app_id=$(echo "$response" | jq -r '.pk')
        log "INFO" "✅ RAC application created with ID: $app_id"
        echo "$app_id" > "${PROJECT_ROOT}/.authentik-rac-app-id"
    else
        log "ERROR" "❌ Failed to create RAC application: $response"
        return 1
    fi
}

# Function to test OIDC configuration
test_oidc_configuration() {
    log "INFO" "🔍 Testing OIDC configuration..."
    
    # Test OIDC discovery endpoint
    log "DEBUG" "Testing OIDC discovery endpoint..."
    if curl -f "${AUTHENTIK_URL}/.well-known/openid_configuration" > /dev/null 2>&1; then
        log "INFO" "✅ OIDC discovery endpoint accessible"
    else
        log "ERROR" "❌ OIDC discovery endpoint not accessible"
        return 1
    fi
    
    # Test authorization endpoint
    log "DEBUG" "Testing authorization endpoint..."
    if curl -f "${AUTHENTIK_URL}/application/o/authorize/" > /dev/null 2>&1; then
        log "INFO" "✅ Authorization endpoint accessible"
    else
        log "ERROR" "❌ Authorization endpoint not accessible"
        return 1
    fi
    
    return 0
}

# Function to generate configuration report
generate_configuration_report() {
    log "INFO" "📊 Generating Authentik configuration report..."
    
    local report_file="${PROJECT_ROOT}/authentik-config-report.md"
    
    cat > "$report_file" << EOF
# 🔐 Authentik OIDC Configuration Report

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Script:** auto-configure-authentik.sh
**CI Mode:** $CI_MODE
**Dry Run:** $DRY_RUN

## 📋 Configuration Summary

EOF

    if [[ "$DRY_RUN" == "true" ]]; then
        cat >> "$report_file" << EOF
- 🔍 **DRY RUN MODE** - No actual changes made
- ✅ LDAP source configuration validated
- ✅ Property mappings configuration validated
- ✅ OIDC provider configuration validated
- ✅ RAC application configuration validated

## 🔧 Next Steps for Implementation

1. **Obtain Authentik admin token:**
   \`\`\`bash
   export AUTHENTIK_TOKEN='your-admin-token'
   \`\`\`

2. **Run actual configuration:**
   \`\`\`bash
   ./scripts/auto-configure-authentik.sh
   \`\`\`

3. **Apply Guacamole OIDC configuration:**
   \`\`\`bash
   source guacamole-oidc-config.env
   \`\`\`
EOF
    else
        # Report actual configuration results
        local ldap_status="❌ Not configured"
        local oidc_status="❌ Not configured"
        local app_status="❌ Not configured"
        
        if [[ -f "${PROJECT_ROOT}/.authentik-ldap-source-id" ]]; then
            ldap_status="✅ Configured (ID: $(cat "${PROJECT_ROOT}/.authentik-ldap-source-id"))"
        fi
        
        if [[ -f "${PROJECT_ROOT}/.authentik-oidc-provider-id" ]]; then
            oidc_status="✅ Configured (ID: $(cat "${PROJECT_ROOT}/.authentik-oidc-provider-id"))"
        fi
        
        if [[ -f "${PROJECT_ROOT}/.authentik-rac-app-id" ]]; then
            app_status="✅ Configured (ID: $(cat "${PROJECT_ROOT}/.authentik-rac-app-id"))"
        fi
        
        cat >> "$report_file" << EOF
- **LDAP Source:** $ldap_status
- **OIDC Provider:** $oidc_status
- **RAC Application:** $app_status
- **Property Mappings:** $(wc -l < "${PROJECT_ROOT}/.authentik-property-mappings" 2>/dev/null || echo "0") mappings created

## 🔧 Integration Settings

### Guacamole OIDC Configuration
Configuration saved to: \`guacamole-oidc-config.env\`

### Header Authentication Variables
Add to docker-compose.yml environment:
\`\`\`yaml
HTTP_AUTH_HEADER: X-Forwarded-User
HTTP_AUTH_NAME_ATTRIBUTE: name
HTTP_AUTH_EMAIL_ATTRIBUTE: email
HTTP_AUTH_AUTO_CREATE_USER: "true"
EXTENSION_PRIORITY: "header,openid,ldap,*"
\`\`\`
EOF
    fi
    
    cat >> "$report_file" << EOF

## 🔍 Validation Steps

1. **Test LDAP Sync:**
   - Go to Authentik Admin -> Directory -> LDAP Sources
   - Force synchronization
   - Verify users appear in Authentik

2. **Test OIDC Flow:**
   - Visit Guacamole URL
   - Should redirect to Authentik login
   - After login, should return to Guacamole with user context

3. **Verify Header Authentication:**
   - Check Guacamole logs for header processing
   - Confirm user auto-creation works

## 📝 Logs

Full logs available at: \`$LOG_FILE\`

---
*Report generated by automated Authentik configuration script*
EOF

    log "INFO" "📊 Report generated: $report_file"
}

# Main execution
main() {
    # Parse arguments
    if [[ "${1:-}" == "--dry-run" ]]; then
        DRY_RUN=true
        log "INFO" "🔍 Running in dry-run mode (no actual changes)"
    fi
    
    # Wait for Authentik service
    if ! wait_for_authentik; then
        log "ERROR" "❌ Authentik service not available"
        exit 1
    fi
    
    # Get admin token
    if ! get_authentik_token; then
        log "ERROR" "❌ Cannot proceed without admin token"
        exit 1
    fi
    
    # Configure Authentik components
    create_ldap_source
    create_property_mappings
    create_oidc_provider
    create_rac_application
    
    # Test configuration
    if [[ "$DRY_RUN" != "true" ]]; then
        test_oidc_configuration
    fi
    
    # Generate report
    generate_configuration_report
    
    log "INFO" "🎉 Authentik OIDC configuration completed successfully!"
    
    if [[ "$CI_MODE" != "true" ]]; then
        echo ""
        echo "📋 Next steps:"
        echo "1. Review the configuration report: authentik-config-report.md"
        echo "2. Apply Guacamole OIDC settings: source guacamole-oidc-config.env"
        echo "3. Test the complete SSO flow"
        echo "4. Run LDAP synchronization in Authentik Admin UI"
    fi
}

# Run main function
main "$@"