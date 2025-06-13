# Mexican Train Server Testing Script
# Run this to quickly test all server functionality

Write-Host "=== Mexican Train Server Test Launcher ===" -ForegroundColor Green
Write-Host ""

# Check if Godot is available
try {
    $godotVersion = godot --version 2>$null
    Write-Host "✅ Godot found: $godotVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Godot not found in PATH. Please install Godot 4.4+ and add to PATH." -ForegroundColor Red
    exit 1
}

# Change to project directory
Set-Location "c:\development\mexican-train"

Write-Host ""
Write-Host "Select test to run:" -ForegroundColor Yellow
Write-Host "1. Automated System Tests (recommended first)"
Write-Host "2. Server Mechanics (manual server testing)"
Write-Host "3. Admin Dashboard (server administration)"
Write-Host "4. Client Lobby (player interface)"
Write-Host "5. Complete Integration Test (all windows)"
Write-Host "6. Multi-Client Game Test (server + 2 clients + admin)"
Write-Host "7. Quick Validation (headless check)"
Write-Host ""

$choice = Read-Host "Enter choice (1-7)"

switch ($choice) {
    "1" {
        Write-Host "🧪 Running automated system tests..." -ForegroundColor Cyan
        godot scenes/test/server_system_test.tscn
    }
    "2" {
        Write-Host "🖥️  Opening server mechanics test..." -ForegroundColor Cyan
        godot scenes/test/server_mechanics_test.tscn
    }
    "3" {
        Write-Host "👤 Opening admin dashboard..." -ForegroundColor Cyan
        Write-Host "Login: admin@mexicantrain.local / admin123" -ForegroundColor Yellow
        godot scenes/test/server_admin_dashboard_test.tscn
    }
    "4" {
        Write-Host "🎮 Opening client lobby..." -ForegroundColor Cyan
        Write-Host "Connect to: 127.0.0.1" -ForegroundColor Yellow        godot scenes/lobby/client_lobby.tscn
    }
    "5" {
        Write-Host "🚀 Starting complete integration test..." -ForegroundColor Cyan
        Write-Host "Opening multiple windows for full testing..." -ForegroundColor Yellow
        
        # Start server mechanics
        Write-Host "1. Starting server mechanics..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/test/server_mechanics_test.tscn" -WindowStyle Normal
        Start-Sleep 2
        
        # Start admin dashboard
        Write-Host "2. Starting admin dashboard..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/test/server_admin_dashboard_test.tscn" -WindowStyle Normal
        Start-Sleep 2
        
        # Start client lobby
        Write-Host "3. Starting client lobby..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/lobby/client_lobby.tscn" -WindowStyle Normal
        
        Write-Host ""
        Write-Host "✅ All windows launched!" -ForegroundColor Green
        Write-Host "Follow the testing guide to verify functionality:" -ForegroundColor Yellow
        Write-Host "1. Start server in Server Mechanics window"
        Write-Host "2. Login to Admin Dashboard (admin@mexicantrain.local / admin123)"
        Write-Host "3. Connect to server in Client Lobby (127.0.0.1)"        Write-Host "4. Create a game and verify it appears in admin dashboard"
    }
    "6" {
        Write-Host "🎯 Starting multi-client game test..." -ForegroundColor Cyan
        Write-Host "Opening 4 windows for complete network testing..." -ForegroundColor Yellow
          # Start server mechanics
        Write-Host "1. Starting server mechanics..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/test/server_mechanics_test.tscn" -WindowStyle Normal
        Start-Sleep 2
        
        # Start admin dashboard
        Write-Host "2. Starting admin dashboard..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/test/server_admin_dashboard_test.tscn" -WindowStyle Normal
        Start-Sleep 2
        
        # Start first client (host)
        Write-Host "3. Starting host client..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/lobby/client_lobby.tscn" -WindowStyle Normal
        Start-Sleep 1
        
        # Start second client (joining)
        Write-Host "4. Starting joining client..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/lobby/client_lobby.tscn" -WindowStyle Normal
        
        Write-Host ""
        Write-Host "✅ All 4 windows launched!" -ForegroundColor Green
        Write-Host "Testing workflow:" -ForegroundColor Yellow
        Write-Host "1. Start server in Server Mechanics window"
        Write-Host "2. Login to Admin Dashboard (admin@mexicantrain.local / admin123)"
        Write-Host "3. Connect BOTH clients to server (127.0.0.1)"
        Write-Host "4. Host creates game in first client"
        Write-Host "5. Second client joins the game"
        Write-Host "6. Monitor statistics in admin dashboard"
    }
    "7" {
        Write-Host "✅ Running quick validation..." -ForegroundColor Cyan
        
        # Check if project loads properly by trying to get version info
        Write-Host "Checking project loading..."
        $projectTest = godot --headless --quit --script-expr "print('Project loads successfully')" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Project loads successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Project loading issues found:" -ForegroundColor Red
            Write-Host "Error details:" -ForegroundColor Yellow
            $projectTest | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            Write-Host ""
            Write-Host "Try opening the project in Godot editor to see detailed errors." -ForegroundColor Yellow
            exit 1
        }
          # Check autoloads using existing test system
        Write-Host "Checking autoloads using automated test system..."
        $result = godot --headless scenes/test/server_system_test.tscn 2>&1
        if ($result -match "All autoloads loaded correctly" -or $result -match "8/8 PASSED") {
            Write-Host "✅ All autoloads loaded successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Some autoloads may have issues. Run option 1 for detailed testing." -ForegroundColor Yellow
            Write-Host "Output: $result" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "✅ Quick validation complete!" -ForegroundColor Green
        Write-Host "Run option 1 for detailed automated testing." -ForegroundColor Yellow
    }
    default {
        Write-Host "❌ Invalid choice. Please run the script again." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "📚 For detailed testing instructions, see TESTING_GUIDE.md" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Green
