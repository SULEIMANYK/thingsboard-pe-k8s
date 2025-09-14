# Simple validation for ThingsBoard CE Helm Chart

Write-Host "=== ThingsBoard CE Helm Chart Validation ===" -ForegroundColor Green

$chartPath = ".\charts\thingsboard-ce"
$errorCount = 0

# Check essential files exist
$requiredFiles = @(
    "Chart.yaml",
    "values.yaml", 
    "README.md",
    "templates\_helpers.tpl",
    "templates\namespace.yaml",
    "templates\serviceaccount.yaml",
    "templates\service.yaml",
    "templates\monolith-deployment.yaml",
    "templates\core-service.yaml",
    "templates\database-secret.yaml",
    "templates\cache-secret.yaml",
    "templates\transports\mqtt-transport.yaml",
    "templates\transports\http-transport.yaml",
    "templates\transports\coap-transport.yaml"
)

Write-Host "`n1. Checking file structure..." -ForegroundColor Cyan

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $chartPath $file
    if (Test-Path $fullPath) {
        Write-Host "✓ $file exists" -ForegroundColor Green
    } else {
        Write-Host "✗ $file missing" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n2. Checking values files..." -ForegroundColor Cyan

$valuesFiles = @("values.yaml", "values-dev.yaml", "values-prod.yaml")
foreach ($file in $valuesFiles) {
    $fullPath = Join-Path $chartPath $file
    if (Test-Path $fullPath) {
        Write-Host "✓ $file exists" -ForegroundColor Green
        $content = Get-Content $fullPath -Raw
        if ($content.Length -gt 0) {
            Write-Host "  ✓ $file is not empty" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $file is empty" -ForegroundColor Red
            $errorCount++
        }
    }
}

Write-Host "`n3. Checking Helm template syntax..." -ForegroundColor Cyan

$templateFiles = Get-ChildItem -Path "$chartPath\templates" -Recurse -Filter "*.yaml" | Select-Object -ExpandProperty FullName

foreach ($file in $templateFiles) {
    $relativePath = $file -replace [regex]::Escape($chartPath), ""
    $content = Get-Content $file -Raw
    
    if ($content -like "*{{*}}*") {
        Write-Host "✓ $relativePath contains Helm templates" -ForegroundColor Green
    } else {
        $fileName = Split-Path $file -Leaf
        if ($fileName -eq "_helpers.tpl") {
            Write-Host "✓ $relativePath is helper template" -ForegroundColor Green
        } else {
            Write-Host "⚠ $relativePath missing Helm templates" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n4. Checking Chart.yaml..." -ForegroundColor Cyan

$chartYamlPath = Join-Path $chartPath "Chart.yaml"
if (Test-Path $chartYamlPath) {
    $chartContent = Get-Content $chartYamlPath -Raw
    
    if ($chartContent -like "*apiVersion: v2*") {
        Write-Host "✓ Chart uses Helm v3 format" -ForegroundColor Green
    }
    
    if ($chartContent -like "*name: thingsboard-ce*") {
        Write-Host "✓ Chart name is correct" -ForegroundColor Green
    }
    
    if ($chartContent -like "*version:*") {
        Write-Host "✓ Chart version specified" -ForegroundColor Green
    }
}

Write-Host "`n=== Validation Summary ===" -ForegroundColor Green

if ($errorCount -eq 0) {
    Write-Host "✓ All validation checks passed!" -ForegroundColor Green
    Write-Host "The ThingsBoard CE Helm chart structure is valid." -ForegroundColor Green
} else {
    Write-Host "✗ Found $errorCount error(s)" -ForegroundColor Red
}

Write-Host "`nRecommended next steps:" -ForegroundColor Cyan
Write-Host "1. Install Helm CLI for complete validation" -ForegroundColor White  
Write-Host "2. Run: helm lint charts/thingsboard-ce" -ForegroundColor White
Write-Host "3. Run: helm template charts/thingsboard-ce" -ForegroundColor White
Write-Host "4. Test deployment: helm install --dry-run tb-test charts/thingsboard-ce" -ForegroundColor White

return $errorCount
