# 📊 Guía de Validación de Commits / Commit Validation Guide

## 🎯 Propósito / Purpose

Esta guía describe cómo usar el script de validación de commits para verificar el estado del último commit y detectar errores en el proceso de desarrollo.

This guide describes how to use the commit validation script to verify the status of the last commit and detect errors in the development process.

---

## 🚀 Uso Rápido / Quick Usage

### Ejecutar Validación Completa / Run Full Validation

```bash
./scripts/check-commit-status.sh
```

Este comando realizará todas las validaciones y generará un reporte completo.

This command will perform all validations and generate a comprehensive report.

---

## 📋 Validaciones Incluidas / Included Validations

El script verifica automáticamente / The script automatically checks:

### 1. 📝 Estado de Git / Git Status
- ✅ Último commit (hash, autor, fecha, mensaje)
- ✅ Estado del directorio de trabajo
- ✅ Archivos modificados en el último commit

### 2. 🔍 Sintaxis de Scripts de Shell / Shell Script Syntax
- ✅ Validación de sintaxis de todos los archivos `.sh`
- ✅ Detección de errores de sintaxis bash
- ✅ Reporte de scripts con problemas

### 3. 🐍 Sintaxis de Archivos Python / Python File Syntax
- ✅ Validación de sintaxis de todos los archivos `.py`
- ✅ Detección de errores de sintaxis Python
- ✅ Verificación de módulos importados

### 4. 🐳 Configuración de Docker Compose / Docker Compose Configuration
- ✅ Validación de sintaxis del archivo `docker-compose.yml`
- ✅ Detección de errores de configuración
- ✅ Identificación de advertencias

### 5. 📦 Configuración del Frontend / Frontend Configuration
- ✅ Validación del archivo `package.json`
- ✅ Verificación de sintaxis JSON
- ✅ Detección de dependencias

### 6. 🔄 Archivos de CI/CD / CI/CD Pipeline Files
- ✅ Validación de workflows de GitHub Actions
- ✅ Verificación de Jenkinsfiles
- ✅ Validación de sintaxis YAML

### 7. 🔧 Verificaciones Adicionales / Additional Checks
- ✅ Presencia de archivos de configuración (`.env`, `requirements.txt`)
- ✅ Verificación de documentación (`README.md`)
- ✅ Estado general del proyecto

---

## 📊 Interpretación del Reporte / Report Interpretation

El script genera un reporte en formato Markdown: `commit-status-report.md`

The script generates a report in Markdown format: `commit-status-report.md`

### Métricas / Metrics

```
✅ Verificaciones exitosas / Successful checks: 127
⚠️ Advertencias / Warnings: 1
❌ Errores / Errors: 0
```

### Estados Posibles / Possible States

| Estado / State | Significado / Meaning |
|----------------|----------------------|
| ✅ Exitoso / Successful | Todo está correcto, no hay errores críticos |
| ⚠️ Advertencia / Warning | Hay problemas menores que deben revisarse |
| ❌ Error / Error | Errores críticos que deben corregirse |

---

## 🔧 Solución de Problemas / Troubleshooting

### Errores de Sintaxis en Shell Scripts

Si encuentras errores en scripts de shell:

1. Revisa el archivo indicado en el error
2. Verifica la sintaxis bash con: `bash -n script.sh`
3. Corrige los errores identificados
4. Ejecuta nuevamente el script de validación

If you find errors in shell scripts:

1. Review the file indicated in the error
2. Verify bash syntax with: `bash -n script.sh`
3. Fix the identified errors
4. Run the validation script again

### Errores de Sintaxis en Python

Si encuentras errores en archivos Python:

1. Revisa el archivo indicado en el error
2. Verifica la sintaxis con: `python3 -m py_compile file.py`
3. Corrige los errores identificados
4. Ejecuta nuevamente el script de validación

If you find errors in Python files:

1. Review the file indicated in the error
2. Verify syntax with: `python3 -m py_compile file.py`
3. Fix the identified errors
4. Run the validation script again

### Errores en Docker Compose

Si encuentras errores en la configuración de Docker Compose:

1. Verifica la sintaxis con: `docker compose config --quiet`
2. Revisa las variables de entorno necesarias
3. Corrige los errores en `docker-compose.yml`
4. Ejecuta nuevamente el script de validación

If you find errors in Docker Compose configuration:

1. Verify syntax with: `docker compose config --quiet`
2. Review required environment variables
3. Fix errors in `docker-compose.yml`
4. Run the validation script again

---

## 🎯 Mejores Prácticas / Best Practices

### Antes de Hacer Commit / Before Committing

```bash
# 1. Ejecutar validación
./scripts/check-commit-status.sh

# 2. Revisar el reporte
cat commit-status-report.md

# 3. Corregir errores si es necesario

# 4. Hacer commit
git add .
git commit -m "Your commit message"
```

### En CI/CD

El script puede integrarse en pipelines de CI/CD:

The script can be integrated into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Validate Commit
  run: |
    chmod +x scripts/check-commit-status.sh
    ./scripts/check-commit-status.sh
```

### Automatización / Automation

Puedes agregar el script como pre-commit hook:

You can add the script as a pre-commit hook:

```bash
# .git/hooks/pre-commit
#!/bin/bash
./scripts/check-commit-status.sh
```

---

## 📈 Resultados Esperados / Expected Results

### Estado Exitoso / Successful State

```
✅ VALIDACIÓN EXITOSA / VALIDATION SUCCESSFUL

El último commit está en buen estado.
No se encontraron errores críticos.

The last commit is in good state.
No critical errors found.
```

### Con Advertencias / With Warnings

```
⚠️ ADVERTENCIAS ENCONTRADAS / WARNINGS FOUND

Se encontraron advertencias que deben revisarse.
Revise el reporte para más detalles.

Warnings found that should be reviewed.
Check the report for more details.
```

### Con Errores / With Errors

```
❌ SE ENCONTRARON ERRORES / ERRORS FOUND

Se encontraron errores que deben corregirse.
Por favor revise los errores arriba antes de continuar.

Errors found that must be fixed.
Please review the errors above before continuing.
```

---

## 🔗 Enlaces Relacionados / Related Links

- [README Principal / Main README](./README.md)
- [Guía de Configuración / Configuration Guide](./QUICK_REFERENCE.md)
- [Arquitectura del Sistema / System Architecture](./ARCHITECTURE.md)
- [Guía de CI/CD](./TESTING.md)

---

## 📝 Notas / Notes

- El script genera un nuevo reporte cada vez que se ejecuta
- Los reportes anteriores son sobrescritos
- El script sale con código 0 si no hay errores, 1 si hay errores
- Las advertencias no causan que el script falle

- The script generates a new report each time it runs
- Previous reports are overwritten
- The script exits with code 0 if no errors, 1 if errors
- Warnings don't cause the script to fail

---

*Última actualización / Last updated: 2025-10-23*
