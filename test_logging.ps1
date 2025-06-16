# Test the new logging system in Mexican Train
# This script runs the logging system test scene

Write-Host "Testing Mexican Train Logging System..." -ForegroundColor Green

# Set the path to the project
$projectPath = "c:\development\mexican-train"
$scenePath = "res://scenes/test/logging_system_test.tscn"

# Check if Godot is in PATH
$godot = Get-Command "godot" -ErrorAction SilentlyContinue

if (-not $godot) {
    Write-Host "Error: Godot not found in PATH. Please install Godot 4.x or add it to your PATH." -ForegroundColor Red
    Write-Host "You can also run the test manually by opening the scene: $scenePath" -ForegroundColor Yellow
    exit 1
}

try {
    Push-Location $projectPath
    
    Write-Host "Running logging system test scene..." -ForegroundColor Cyan
    Write-Host "Scene: $scenePath" -ForegroundColor Gray
    Write-Host ""
    
    # Run the test scene
    & godot --headless --path . $scenePath
    
    Write-Host ""
    Write-Host "Logging test complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run manually:" -ForegroundColor Yellow
    Write-Host "1. Open Godot with the Mexican Train project" -ForegroundColor Yellow
    Write-Host "2. Open scene: scenes/test/logging_system_test.tscn" -ForegroundColor Yellow
    Write-Host "3. Run the scene (F6)" -ForegroundColor Yellow
    
} catch {
    Write-Host "Error running test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Pop-Location
}
