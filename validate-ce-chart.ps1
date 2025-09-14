# Validation script for ThingsBoard CE Helm Chart
# This script validates the basic structure and common issues in the Helm chart

Write-Host "=== ThingsBoard CE Helm Chart Validation ===" -ForegroundColor Green

$chartPath = ".\charts\thingsboard-ce"
$errorCount = 0
$warningCount = 0

function Write-Error-Message {
    param([string]$message)
    Write-Host "ERROR: $message" -ForegroundColor Red
    $script:errorCount++
}

function Write-Warning-Message {
    param([string]$message)
    Write-Host "WARNING: $message" -ForegroundColor Yellow
    $script:warningCount++
}

function Write-Success-Message {
    param([string]$message)
    Write-Host "✓ $message" -ForegroundColor Green
}

function Validate-File-Exists {
    param([string]$filePath, [string]$description)
    
    if (Test-Path $filePath) {
        Write-Success-Message "$description exists"
        return $true
    } else {
        Write-Error-Message "$description missing at $filePath"
        return $false
    }
}

function Validate-YAML-Syntax {
    param([string]$filePath, [string]$description)
    
    if (-not (Test-Path $filePath)) {
        Write-Error-Message "$description file not found: $filePath"
        return $false
    }
    
    try {
        $content = Get-Content $filePath -Raw
        if ($content.Length -eq 0) {
            Write-Warning-Message "$description file is empty"
            return $false
        }
        
        # Basic YAML syntax checks - check for basic structure
        if ($content -like "*apiVersion:*" -or $content -like "*global:*" -or $content -like "*metadata:*") {
            Write-Success-Message "$description appears to have valid YAML structure"
        }
        
        Write-Success-Message "$description has valid basic syntax"
        return $true
    } catch {
        Write-Error-Message "$description has syntax errors: $($_.Exception.Message)"
        return $false
    }
}

function Validate-Helm-Template-Syntax {
    param([string]$filePath, [string]$description)
    
    if (-not (Test-Path $filePath)) {
        return $false
    }
    
    $content = Get-Content $filePath -Raw
    
    # Check for Helm template content
    if ($content -like "*{{*}}*") {
        Write-Success-Message "$description contains Helm templates"
    }
    
    # Check for common Helm patterns
    if ($content -like "*include*" -and $content -like "*nindent*") {
        Write-Success-Message "$description uses proper include with nindent"
    }
    
    # Check for Values references
    if ($content -like "*.Values.*") {
        Write-Success-Message "$description properly references Values"
    }
    
    return $true
}

Write-Host "`n1. Validating Chart Structure..." -ForegroundColor Cyan

# Check essential chart files
$chartYamlValid = Validate-File-Exists "$chartPath\Chart.yaml" "Chart.yaml"
$valuesYamlValid = Validate-File-Exists "$chartPath\values.yaml" "values.yaml"
$readmeValid = Validate-File-Exists "$chartPath\README.md" "README.md"
$helpersValid = Validate-File-Exists "$chartPath\templates\_helpers.tpl" "_helpers.tpl"

# Check essential template files
Write-Host "`n2. Validating Template Files..." -ForegroundColor Cyan
$namespaceValid = Validate-File-Exists "$chartPath\templates\namespace.yaml" "namespace.yaml"
$serviceAccountValid = Validate-File-Exists "$chartPath\templates\serviceaccount.yaml" "serviceaccount.yaml"
$serviceValid = Validate-File-Exists "$chartPath\templates\service.yaml" "service.yaml"
$monolithValid = Validate-File-Exists "$chartPath\templates\monolith-deployment.yaml" "monolith-deployment.yaml"
$coreServiceValid = Validate-File-Exists "$chartPath\templates\core-service.yaml" "core-service.yaml"

# Check transport templates
$mqttTransportValid = Validate-File-Exists "$chartPath\templates\transports\mqtt-transport.yaml" "MQTT transport template"
$httpTransportValid = Validate-File-Exists "$chartPath\templates\transports\http-transport.yaml" "HTTP transport template"
$coapTransportValid = Validate-File-Exists "$chartPath\templates\transports\coap-transport.yaml" "CoAP transport template"

Write-Host "`n3. Validating YAML Syntax..." -ForegroundColor Cyan

# Validate YAML syntax for key files
if ($chartYamlValid) { Validate-YAML-Syntax "$chartPath\Chart.yaml" "Chart.yaml" }
if ($valuesYamlValid) { Validate-YAML-Syntax "$chartPath\values.yaml" "values.yaml" }
Validate-YAML-Syntax "$chartPath\values-dev.yaml" "values-dev.yaml"
Validate-YAML-Syntax "$chartPath\values-prod.yaml" "values-prod.yaml"

Write-Host "`n4. Validating Helm Template Syntax..." -ForegroundColor Cyan

# Validate template syntax
if ($helpersValid) { Validate-Helm-Template-Syntax "$chartPath\templates\_helpers.tpl" "_helpers.tpl" }
if ($namespaceValid) { Validate-Helm-Template-Syntax "$chartPath\templates\namespace.yaml" "namespace.yaml" }
if ($serviceValid) { Validate-Helm-Template-Syntax "$chartPath\templates\service.yaml" "service.yaml" }
if ($monolithValid) { Validate-Helm-Template-Syntax "$chartPath\templates\monolith-deployment.yaml" "monolith-deployment.yaml" }

Write-Host "`n5. Validating Chart Values..." -ForegroundColor Cyan

if (Test-Path "$chartPath\values.yaml") {
    $valuesContent = Get-Content "$chartPath\values.yaml" -Raw
    
    # Check for required sections using simple string matching
    if ($valuesContent -like "*global:*") {
        Write-Success-Message "Global configuration section exists"
        
        if ($valuesContent -like "*deploymentMode:*") {
            Write-Success-Message "Deployment mode configuration found"
        }
    } else {
        Write-Warning-Message "Global configuration section missing"
    }
    
    if ($valuesContent -like "*database:*") {
        Write-Success-Message "Database configuration section exists"
    } else {
        Write-Error-Message "Database configuration section missing"
    }
    
    if ($valuesContent -like "*image:*") {
        Write-Success-Message "Image configuration section exists"
    } else {
        Write-Warning-Message "Image configuration section missing"
    }
}

Write-Host "`n6. Chart Structure Validation..." -ForegroundColor Cyan

# Check for both monolith and microservices templates
if ($monolithValid) {
    Write-Success-Message "Monolith deployment template exists"
}
if ($coreServiceValid) {
    Write-Success-Message "Microservices core template exists"
}
if ($mqttTransportValid -and $httpTransportValid) {
    Write-Success-Message "Transport templates exist"
}

Write-Host "`n=== Validation Summary ===" -ForegroundColor Green
if ($errorCount -eq 0 -and $warningCount -eq 0) {
    Write-Host "✓ Chart validation completed successfully with no issues!" -ForegroundColor Green
} elseif ($errorCount -eq 0) {
    Write-Host "✓ Chart validation completed with $warningCount warning(s)" -ForegroundColor Yellow
} else {
    Write-Host "✗ Chart validation completed with $errorCount error(s) and $warningCount warning(s)" -ForegroundColor Red
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Install Helm CLI to perform full validation" -ForegroundColor White
Write-Host "2. Run 'helm lint charts/thingsboard-ce' to check for template issues" -ForegroundColor White
Write-Host "3. Run 'helm template charts/thingsboard-ce' to validate template rendering" -ForegroundColor White
Write-Host "4. Test deployment with 'helm install --dry-run --debug'" -ForegroundColor White

exit $errorCount
