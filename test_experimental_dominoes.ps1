# Test Experimental Domino System
# This script helps test the new shader-based domino system

Write-Host "Testing Experimental Shader-Based Domino System" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Gray

$projectPath = "c:\development\mexican-train"

# Check if required files exist
Write-Host "`nChecking system files..." -ForegroundColor Cyan

$requiredFiles = @(
    "assets\experimental\dominos_white\white_domino-1-1_top.svg",
    "shaders\domino_dot_color.gdshader",
    "scenes\experimental\experimental_domino.tscn",
    "scenes\experimental\simple_experimental_test.tscn",
    "scripts\experimental\experimental_domino.gd"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $projectPath $file
    if (Test-Path $fullPath) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file (MISSING)" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host "`nSome required files are missing. Please run the creation script first." -ForegroundColor Red
    exit 1
}

# Count converted SVG files
$whiteDotsPath = Join-Path $projectPath "assets\experimental\dominos_white"
if (Test-Path $whiteDotsPath) {
    $svgCount = (Get-ChildItem $whiteDotsPath -Filter "*.svg").Count
    Write-Host "`n✓ Found $svgCount white-dot SVG files" -ForegroundColor Green
} else {
    Write-Host "`n✗ White-dot SVG directory not found" -ForegroundColor Red
}

Write-Host "`nRunning tests..." -ForegroundColor Cyan

try {
    Push-Location $projectPath
    
    Write-Host "1. Running simple validation test..." -ForegroundColor Yellow
    $result1 = Start-Process "godot" -ArgumentList "scenes/experimental/simple_experimental_test.tscn" -Wait -PassThru -WindowStyle Normal
    
    Write-Host "2. Running full experimental test suite..." -ForegroundColor Yellow
    $result2 = Start-Process "godot" -ArgumentList "scenes/experimental/experimental_domino_test.tscn" -Wait -PassThru -WindowStyle Normal
    
    Write-Host "`nTest Results:" -ForegroundColor Green
    Write-Host "- Simple test exit code: $($result1.ExitCode)" -ForegroundColor Gray
    Write-Host "- Full test exit code: $($result2.ExitCode)" -ForegroundColor Gray
    
} catch {
    Write-Host "`nError running tests: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Pop-Location
}

Write-Host "`nTesting complete!" -ForegroundColor Green
Write-Host "Check the Godot console output for detailed validation results." -ForegroundColor Gray
Write-Host "`nDocumentation: docs\experimental_domino_system.md" -ForegroundColor Cyan
