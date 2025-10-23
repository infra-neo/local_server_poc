#!/bin/bash

# Script para revisar el estatus del último commit y detectar errores en el proceso
# Script to review the status of the last commit and detect errors in the process

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_FILE="${PROJECT_ROOT}/commit-status-report.md"
ERROR_COUNT=0
WARNING_COUNT=0
SUCCESS_COUNT=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*"
    WARNING_COUNT=$((WARNING_COUNT + 1))
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
    ERROR_COUNT=$((ERROR_COUNT + 1))
}

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║           VALIDACIÓN DEL ESTADO DEL ÚLTIMO COMMIT                           ║
║           LAST COMMIT STATUS AND ERROR VALIDATION                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Initialize report
cat > "$REPORT_FILE" << 'EOF'
# 📊 Reporte de Estado del Último Commit / Last Commit Status Report

**Fecha / Date:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')

---

## 📝 Información del Último Commit / Last Commit Information

EOF

# Section 1: Git Status and Last Commit
echo ""
log_info "Sección 1: Revisando estado de Git y último commit..."
log_info "Section 1: Checking Git status and last commit..."
echo ""

# Get last commit details
LAST_COMMIT_HASH=$(git log -1 --format="%H")
LAST_COMMIT_AUTHOR=$(git log -1 --format="%an")
LAST_COMMIT_DATE=$(git log -1 --format="%ai")
LAST_COMMIT_MESSAGE=$(git log -1 --format="%s")
CURRENT_BRANCH=$(git branch --show-current)

echo "Rama actual / Current branch: $CURRENT_BRANCH"
echo "Último commit / Last commit: $LAST_COMMIT_HASH"
echo "Autor / Author: $LAST_COMMIT_AUTHOR"
echo "Fecha / Date: $LAST_COMMIT_DATE"
echo "Mensaje / Message: $LAST_COMMIT_MESSAGE"

# Add to report
cat >> "$REPORT_FILE" << EOF

- **Rama / Branch:** \`$CURRENT_BRANCH\`
- **Commit Hash:** \`$LAST_COMMIT_HASH\`
- **Autor / Author:** $LAST_COMMIT_AUTHOR
- **Fecha / Date:** $LAST_COMMIT_DATE
- **Mensaje / Message:** $LAST_COMMIT_MESSAGE

### 📂 Archivos Modificados / Modified Files

\`\`\`
$(git show --stat --oneline $LAST_COMMIT_HASH | tail -n +2)
\`\`\`

---

## 🔍 Validación de Sintaxis / Syntax Validation

EOF

# Check git status
GIT_STATUS=$(git status --porcelain)
if [ -z "$GIT_STATUS" ]; then
    log_success "Directorio de trabajo limpio / Working directory clean"
else
    log_warning "Hay cambios sin confirmar / Uncommitted changes found:"
    echo "$GIT_STATUS"
fi

# Section 2: Shell Scripts Validation
echo ""
log_info "Sección 2: Validando scripts de shell..."
log_info "Section 2: Validating shell scripts..."
echo ""

SHELL_ERROR_COUNT=0
SHELL_CHECK_OUTPUT=$(mktemp)

while IFS= read -r script; do
    if bash -n "$script" 2>"$SHELL_CHECK_OUTPUT"; then
        log_success "Sintaxis OK: $script"
    else
        log_error "Error de sintaxis en / Syntax error in: $script"
        cat "$SHELL_CHECK_OUTPUT"
        SHELL_ERROR_COUNT=$((SHELL_ERROR_COUNT + 1))
    fi
done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -not -path "*/\.*" 2>/dev/null || true)

rm -f "$SHELL_CHECK_OUTPUT"

if [ $SHELL_ERROR_COUNT -eq 0 ]; then
    cat >> "$REPORT_FILE" << EOF
### ✅ Shell Scripts

- **Estado / Status:** Todos los scripts tienen sintaxis válida / All scripts have valid syntax
- **Scripts verificados / Scripts checked:** $(find "$PROJECT_ROOT" -name "*.sh" -type f -not -path "*/\.*" 2>/dev/null | wc -l)

EOF
else
    cat >> "$REPORT_FILE" << EOF
### ❌ Shell Scripts

- **Estado / Status:** $SHELL_ERROR_COUNT script(s) con errores / script(s) with errors
- **Acción requerida / Action required:** Revisar y corregir errores de sintaxis / Review and fix syntax errors

EOF
fi

# Section 3: Python Files Validation
echo ""
log_info "Sección 3: Validando archivos Python..."
log_info "Section 3: Validating Python files..."
echo ""

PYTHON_ERROR_COUNT=0
PYTHON_CHECK_OUTPUT=$(mktemp)

if [ -d "$PROJECT_ROOT/backend" ]; then
    while IFS= read -r pyfile; do
        if python3 -m py_compile "$pyfile" 2>"$PYTHON_CHECK_OUTPUT"; then
            log_success "Sintaxis OK: $pyfile"
        else
            log_error "Error de sintaxis en / Syntax error in: $pyfile"
            cat "$PYTHON_CHECK_OUTPUT"
            PYTHON_ERROR_COUNT=$((PYTHON_ERROR_COUNT + 1))
        fi
    done < <(find "$PROJECT_ROOT/backend" -name "*.py" -type f 2>/dev/null || true)
fi

# Also check Python scripts in root
while IFS= read -r pyfile; do
    if python3 -m py_compile "$pyfile" 2>"$PYTHON_CHECK_OUTPUT"; then
        log_success "Sintaxis OK: $pyfile"
    else
        log_error "Error de sintaxis en / Syntax error in: $pyfile"
        cat "$PYTHON_CHECK_OUTPUT"
        PYTHON_ERROR_COUNT=$((PYTHON_ERROR_COUNT + 1))
    fi
done < <(find "$PROJECT_ROOT" -maxdepth 1 -name "*.py" -type f 2>/dev/null || true)

rm -f "$PYTHON_CHECK_OUTPUT"

if [ $PYTHON_ERROR_COUNT -eq 0 ]; then
    cat >> "$REPORT_FILE" << EOF
### ✅ Python Files

- **Estado / Status:** Todos los archivos Python tienen sintaxis válida / All Python files have valid syntax
- **Archivos verificados / Files checked:** $(find "$PROJECT_ROOT/backend" "$PROJECT_ROOT" -maxdepth 1 -name "*.py" -type f 2>/dev/null | wc -l)

EOF
else
    cat >> "$REPORT_FILE" << EOF
### ❌ Python Files

- **Estado / Status:** $PYTHON_ERROR_COUNT archivo(s) con errores / file(s) with errors
- **Acción requerida / Action required:** Revisar y corregir errores de sintaxis / Review and fix syntax errors

EOF
fi

# Section 4: Docker Compose Validation
echo ""
log_info "Sección 4: Validando configuración de Docker Compose..."
log_info "Section 4: Validating Docker Compose configuration..."
echo ""

DOCKER_CHECK_OUTPUT=$(mktemp)

if docker compose config --quiet 2>"$DOCKER_CHECK_OUTPUT"; then
    log_success "Configuración de Docker Compose es válida / Docker Compose configuration is valid"
    cat >> "$REPORT_FILE" << EOF
### ✅ Docker Compose

- **Estado / Status:** Configuración válida / Valid configuration
- **Advertencias / Warnings:** $(grep -i "warn" "$DOCKER_CHECK_OUTPUT" | wc -l)

EOF
    
    if grep -i "warn" "$DOCKER_CHECK_OUTPUT" > /dev/null; then
        log_warning "Advertencias encontradas / Warnings found:"
        grep -i "warn" "$DOCKER_CHECK_OUTPUT"
        cat >> "$REPORT_FILE" << EOF

#### ⚠️ Advertencias / Warnings:
\`\`\`
$(grep -i "warn" "$DOCKER_CHECK_OUTPUT")
\`\`\`

EOF
    fi
else
    log_error "Error en configuración de Docker Compose / Docker Compose configuration error"
    cat "$DOCKER_CHECK_OUTPUT"
    cat >> "$REPORT_FILE" << EOF
### ❌ Docker Compose

- **Estado / Status:** Error en configuración / Configuration error
- **Detalles / Details:**

\`\`\`
$(cat "$DOCKER_CHECK_OUTPUT")
\`\`\`

EOF
fi

rm -f "$DOCKER_CHECK_OUTPUT"

# Section 5: Frontend Configuration Validation
echo ""
log_info "Sección 5: Validando configuración del Frontend..."
log_info "Section 5: Validating Frontend configuration..."
echo ""

if [ -f "$PROJECT_ROOT/frontend/package.json" ]; then
    if python3 -c "import json; json.load(open('$PROJECT_ROOT/frontend/package.json'))" 2>/dev/null; then
        log_success "package.json es válido / package.json is valid"
        cat >> "$REPORT_FILE" << EOF
### ✅ Frontend (package.json)

- **Estado / Status:** Configuración válida / Valid configuration
- **Ubicación / Location:** \`frontend/package.json\`

EOF
    else
        log_error "package.json tiene errores / package.json has errors"
        cat >> "$REPORT_FILE" << EOF
### ❌ Frontend (package.json)

- **Estado / Status:** JSON inválido / Invalid JSON
- **Acción requerida / Action required:** Corregir formato JSON / Fix JSON format

EOF
    fi
else
    log_warning "package.json no encontrado / package.json not found"
    cat >> "$REPORT_FILE" << EOF
### ⚠️ Frontend

- **Estado / Status:** No se encontró package.json / package.json not found

EOF
fi

# Section 6: CI/CD Pipeline Files Validation
echo ""
log_info "Sección 6: Validando archivos de CI/CD..."
log_info "Section 6: Validating CI/CD pipeline files..."
echo ""

cat >> "$REPORT_FILE" << EOF

---

## 🔄 CI/CD Pipelines

EOF

CI_FILES_FOUND=0

# Check GitHub Actions workflows
if [ -d "$PROJECT_ROOT/.github/workflows" ]; then
    log_info "Encontrados archivos de GitHub Actions / Found GitHub Actions workflows"
    for workflow in "$PROJECT_ROOT"/.github/workflows/*.yml "$PROJECT_ROOT"/.github/workflows/*.yaml; do
        if [ -f "$workflow" ]; then
            CI_FILES_FOUND=$((CI_FILES_FOUND + 1))
            WORKFLOW_NAME=$(basename "$workflow")
            log_success "Workflow encontrado / Workflow found: $WORKFLOW_NAME"
            
            # Try to validate YAML syntax with Python
            if python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>/dev/null; then
                log_success "  ✓ Sintaxis YAML válida / Valid YAML syntax"
            else
                log_error "  ✗ Error de sintaxis YAML / YAML syntax error"
            fi
        fi
    done
fi

# Check Jenkins files
if [ -d "$PROJECT_ROOT/pipelines" ]; then
    log_info "Encontrados archivos de Jenkins / Found Jenkins files"
    for jenkinsfile in "$PROJECT_ROOT"/pipelines/Jenkinsfile*; do
        if [ -f "$jenkinsfile" ]; then
            CI_FILES_FOUND=$((CI_FILES_FOUND + 1))
            JENKINS_NAME=$(basename "$jenkinsfile")
            log_success "Jenkinsfile encontrado / Jenkinsfile found: $JENKINS_NAME"
        fi
    done
fi

cat >> "$REPORT_FILE" << EOF
- **GitHub Actions workflows:** $(find "$PROJECT_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
- **Jenkins pipelines:** $(find "$PROJECT_ROOT/pipelines" -name "Jenkinsfile*" 2>/dev/null | wc -l)
- **Total archivos CI/CD / Total CI/CD files:** $CI_FILES_FOUND

EOF

# Section 7: Additional Checks
echo ""
log_info "Sección 7: Verificaciones adicionales..."
log_info "Section 7: Additional checks..."
echo ""

cat >> "$REPORT_FILE" << EOF

---

## 🔧 Verificaciones Adicionales / Additional Checks

EOF

# Check for .env file
if [ -f "$PROJECT_ROOT/.env" ]; then
    log_success "Archivo .env encontrado / .env file found"
    cat >> "$REPORT_FILE" << EOF
### ✅ Variables de Entorno / Environment Variables

- **.env:** Presente / Present
- **Advertencia / Warning:** Asegúrese de que no contenga información sensible en el repositorio / Ensure it doesn't contain sensitive information in the repository

EOF
else
    log_warning "Archivo .env no encontrado (se espera .env.example) / .env file not found (expected .env.example)"
    cat >> "$REPORT_FILE" << EOF
### ⚠️ Variables de Entorno / Environment Variables

- **.env:** No encontrado / Not found
- **Nota / Note:** Copiar .env.example a .env según sea necesario / Copy .env.example to .env as needed

EOF
fi

# Check for requirements.txt
if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    log_success "requirements.txt encontrado / requirements.txt found"
    REQ_COUNT=$(wc -l < "$PROJECT_ROOT/requirements.txt")
    cat >> "$REPORT_FILE" << EOF
### ✅ Dependencias Python / Python Dependencies

- **requirements.txt:** Presente / Present ($REQ_COUNT líneas / lines)

EOF
else
    log_info "requirements.txt no encontrado / requirements.txt not found"
fi

# Check for README.md
if [ -f "$PROJECT_ROOT/README.md" ]; then
    log_success "README.md encontrado / README.md found"
else
    log_warning "README.md no encontrado / README.md not found"
fi

# Final Summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
log_info "RESUMEN FINAL / FINAL SUMMARY"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Verificaciones exitosas / Successful checks: $SUCCESS_COUNT${NC}"
echo -e "${YELLOW}Advertencias / Warnings: $WARNING_COUNT${NC}"
echo -e "${RED}Errores / Errors: $ERROR_COUNT${NC}"
echo ""

cat >> "$REPORT_FILE" << EOF

---

## 📊 Resumen Final / Final Summary

| Métrica / Metric | Valor / Value |
|------------------|---------------|
| ✅ Verificaciones exitosas / Successful checks | $SUCCESS_COUNT |
| ⚠️ Advertencias / Warnings | $WARNING_COUNT |
| ❌ Errores / Errors | $ERROR_COUNT |

### 🎯 Estado General / Overall Status

EOF

if [ $ERROR_COUNT -eq 0 ]; then
    log_success "✅ No se encontraron errores críticos / No critical errors found"
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                     ✅ VALIDACIÓN EXITOSA / VALIDATION SUCCESSFUL            ║
║                                                                              ║
║  El último commit está en buen estado y no se encontraron errores críticos  ║
║  The last commit is in good state and no critical errors were found         ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    cat >> "$REPORT_FILE" << EOF
**✅ EXITOSO / SUCCESSFUL**

El último commit está en buen estado. No se encontraron errores críticos en:
- Scripts de shell
- Archivos Python
- Configuración de Docker Compose
- Configuración del frontend

The last commit is in good state. No critical errors found in:
- Shell scripts
- Python files
- Docker Compose configuration
- Frontend configuration

EOF
    
    if [ $WARNING_COUNT -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF

**Nota:** Se encontraron $WARNING_COUNT advertencia(s) que deben revisarse pero no bloquean el despliegue.

**Note:** Found $WARNING_COUNT warning(s) that should be reviewed but don't block deployment.

EOF
    fi
    
    EXIT_CODE=0
else
    log_error "❌ Se encontraron $ERROR_COUNT error(es) / Found $ERROR_COUNT error(s)"
    echo -e "${RED}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    ❌ SE ENCONTRARON ERRORES / ERRORS FOUND                  ║
║                                                                              ║
║     Por favor revise los errores arriba antes de continuar                  ║
║     Please review the errors above before continuing                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    cat >> "$REPORT_FILE" << EOF
**❌ ERRORES ENCONTRADOS / ERRORS FOUND**

Se encontraron $ERROR_COUNT error(es) que deben corregirse:

Found $ERROR_COUNT error(s) that must be fixed:

1. Revise la sección de validación de sintaxis arriba / Review the syntax validation section above
2. Corrija los errores identificados / Fix the identified errors
3. Ejecute este script nuevamente para verificar / Run this script again to verify

EOF
    
    EXIT_CODE=1
fi

cat >> "$REPORT_FILE" << EOF

---

## 🔗 Enlaces Útiles / Useful Links

- [Documentación del Proyecto / Project Documentation](./README.md)
- [Guía de Configuración / Configuration Guide](./QUICK_REFERENCE.md)
- [Arquitectura del Sistema / System Architecture](./ARCHITECTURE.md)

---

*Reporte generado automáticamente / Report generated automatically*  
*Fecha / Date:* $(date -u '+%Y-%m-%d %H:%M:%S UTC')

EOF

echo ""
log_info "Reporte completo guardado en / Full report saved to: $REPORT_FILE"
echo ""

exit $EXIT_CODE
