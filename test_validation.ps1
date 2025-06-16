# Quick test of validation logic
Set-Location "c:\development\mexican-train"

Write-Host "Testing validation logic..." -ForegroundColor Cyan

# Check if project file exists and is valid
Write-Host "Checking project structure..."
if (Test-Path "project.godot") {
    Write-Host "✅ Project file found" -ForegroundColor Green
} else {
    Write-Host "❌ Project file missing" -ForegroundColor Red
    exit 1
}

# Check if key scene files exist
Write-Host "Checking test scenes..."
$testScenes = @(
    "scenes/test/server_system_test.tscn",
    "scenes/test/server_mechanics_test.tscn", 
    "scenes/test/admin_dashboard_test.tscn"
)

$allScenesExist = $true
foreach ($scene in $testScenes) {
    if (Test-Path $scene) {
        Write-Host "✅ $scene exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $scene missing" -ForegroundColor Red
        $allScenesExist = $false
    }
}

if (-not $allScenesExist) {
    Write-Host "❌ Some test scenes are missing" -ForegroundColor Red
    exit 1
}

# Check autoload files exist
Write-Host "Checking autoload scripts..."
$autoloads = @(