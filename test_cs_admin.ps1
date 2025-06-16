# Test C# Server Admin Dashboard
# This script launches the new C#-based admin dashboard for testing

Write-Host "=== Mexican Train C# Admin Dashboard Test ===" -ForegroundColor Cyan
Write-Host ""

# Check if Godot is available
$godotPath = Get-Command godot -ErrorAction SilentlyContinue
if (-not $godotPath) {
    Write-Host "❌ Godot not found in PATH" -ForegroundColor Red
    Write-Host "Please ensure Godot is installed and accessible via command line" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Godot found: $($godotPath.Source)" -ForegroundColor Green

# Get project path
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scenePath = Join-Path $projectPath "scenes\test\cs_admin_dashboard_test.tscn"

if (-not (Test-Path $scenePath)) {
    Write-Host "❌ C# Admin Dashboard test scene not found: $scenePath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Test scene found: $scenePath" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Launching C# Server Admin Dashboard..." -ForegroundColor Yellow
Write-Host "Expected behavior:" -ForegroundColor Cyan
Write-Host "  1. Login panel should appear with pre-filled admin credentials" -ForegroundColor White
Write-Host "  2. Click 'Login as Admin' to authenticate" -ForegroundColor White
Write-Host "  3. Dashboard should show server information and controls" -ForegroundColor White
Write-Host "  4. Test server start/stop functionality" -ForegroundColor White
Write-Host "  5. Use F5 to refresh data, ESC to logout" -ForegroundColor White
Write-Host ""

# Launch the C# admin dashboard
try {
    Start-Process -FilePath "godot" -ArgumentList "--path", "`"$projectPath`"", "`"$scenePath`"" -Wait
    Write-Host "✅ C# Admin Dashboard test completed" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to launch C# Admin Dashboard: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "  - If the dashboard worked correctly, we can proceed with creating additional C# test components" -ForegroundColor White
Write-Host "  - Consider creating C# versions of server mechanics and client lobby tests" -ForegroundColor White
Write-Host "  - The programmatic UI approach eliminates scene file corruption issues" -ForegroundColor White
