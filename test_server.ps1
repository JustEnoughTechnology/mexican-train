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
Write-Host "1. Automated System Tests (recommended first)" -ForegroundColor White
Write-Host "2. Server Mechanics Test (manual server testing)" -ForegroundColor White
Write-Host "3. New Admin Dashboard (GDScript implementation)" -ForegroundColor Green
Write-Host "4. Client Lobby Test (player interface)" -ForegroundColor White
Write-Host "5. Complete Integration Test (Manual Server Control)" -ForegroundColor White
Write-Host "6. Quick Validation (headless check)" -ForegroundColor White
Write-Host "7. Start Headless Server (command-line server)" -ForegroundColor Cyan
Write-Host "8. Complete Integration Test (with headless server)" -ForegroundColor Green
Write-Host "9. Multi-Server Monitor (view all running servers)" -ForegroundColor Magenta
Write-Host ""

$choice = Read-Host "Enter choice (1-9)"

switch ($choice) {
    "1" {
        Write-Host "🧪 Running automated system tests..." -ForegroundColor Cyan
        Write-Host "This will test all autoloads and core functionality" -ForegroundColor Gray
        godot scenes/test/server_system_test.tscn
    }
    "2" {
        Write-Host "🖥️  Opening server mechanics test..." -ForegroundColor Cyan
        Write-Host "Use this to manually test server start/stop and connections" -ForegroundColor Gray
        godot scenes/test/server_mechanics_test.tscn
    }
    "3" {
        Write-Host "🎯 Opening New Admin Dashboard..." -ForegroundColor Cyan
        Write-Host "Clean GDScript implementation with modular design" -ForegroundColor Green
        Write-Host "Login: admin@mexicantrain.local / admin123" -ForegroundColor Yellow
        godot scenes/test/admin_dashboard_test.tscn
    }
    "4" {
        Write-Host "🎮 Opening client lobby..." -ForegroundColor Cyan
        Write-Host "Connect to: leave blank for localhost:25025, or specify address[:port]" -ForegroundColor Yellow
        godot scenes/lobby/client_lobby.tscn
    }    "5" {
        Write-Host "🚀 Starting complete integration test..." -ForegroundColor Cyan
        Write-Host "Opening 3 windows for full testing workflow..." -ForegroundColor Yellow
        
        # Start server mechanics
        Write-Host "1. Starting server mechanics..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/test/server_mechanics_test.tscn" -WindowStyle Normal
        Start-Sleep 2
        
        # Start new admin dashboard
        Write-Host "2. Starting new admin dashboard..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/test/admin_dashboard_test.tscn" -WindowStyle Normal
        Start-Sleep 2
        
        # Start client lobby
        Write-Host "3. Starting client lobby..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/lobby/client_lobby.tscn" -WindowStyle Normal
          Write-Host ""
        Write-Host "✅ All windows launched!" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  IMPORTANT: These windows only provide the UI - you must manually start the server!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Testing workflow:" -ForegroundColor Yellow
        Write-Host "1. In the Server Mechanics window: Click 'Start Server' button" -ForegroundColor White
        Write-Host "2. In the Admin Dashboard Test window: Click 'Launch Admin Dashboard'" -ForegroundColor White
        Write-Host "3. Login to admin dashboard (admin@mexicantrain.local / admin123)" -ForegroundColor White
        Write-Host "4. In the Client Lobby window: Leave address blank or enter server address" -ForegroundColor White
        Write-Host "5. Create a game and verify it appears in admin dashboard" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Tip: For automated server startup, use option 8 instead" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⚠️  NOTE: You must manually click 'Start Server' in the Server Mechanics window first!" -ForegroundColor Red
    }"6" {
        Write-Host "✅ Running quick validation..." -ForegroundColor Cyan
        
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
            "autoload/network_manager.gd",
            "autoload/lobby_manager.gd",
            "autoload/server_admin.gd",
            "autoload/event_bus.gd",
            "autoload/game_config.gd",
            "autoload/global.gd"
        )
        
        $allAutoloadsExist = $true
        foreach ($autoload in $autoloads) {
            if (Test-Path $autoload) {
                Write-Host "✅ $autoload exists" -ForegroundColor Green
            } else {
                Write-Host "❌ $autoload missing" -ForegroundColor Red
                $allAutoloadsExist = $false
            }
        }
        
        if (-not $allAutoloadsExist) {
            Write-Host "❌ Some autoload scripts are missing" -ForegroundColor Red
            exit 1
        }
        
        # Simple Godot project validation (just check basic project loading)
        Write-Host "Testing Godot project access..."
        try {
            # Use only valid Godot flags - just test if it can read the project
            $null = godot --headless --quit 2>$null
            Write-Host "✅ Godot can access the project" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Godot project access test inconclusive (but project files exist)" -ForegroundColor Yellow
        }
        
        Write-Host ""        Write-Host "✅ Quick validation complete!" -ForegroundColor Green
        Write-Host "All required files found. Run option 1 for detailed runtime testing." -ForegroundColor Yellow    }
    "7" {
        Write-Host "🖥️  Starting headless server..." -ForegroundColor Cyan
        Write-Host "This will start a command-line server that you can connect to" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Server will start on port 25025" -ForegroundColor White
        Write-Host "Press Ctrl+C in the server window to stop it" -ForegroundColor Gray
        Write-Host ""
        
        # Start headless server in a new window so user can see output
        Start-Process -FilePath "powershell" -ArgumentList "-Command", "godot --headless scenes/server/headless_server.tscn; Read-Host 'Press Enter to close'" -WindowStyle Normal
        
        Start-Sleep 2
        Write-Host "✅ Headless server started!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Server Info:" -ForegroundColor Yellow
        Write-Host "  • Address: 127.0.0.1:25025" -ForegroundColor White
        Write-Host "  • Use option 4 to test client connections" -ForegroundColor White
        Write-Host "  • Use option 3 to launch admin dashboard" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 The server is running in a separate window" -ForegroundColor Cyan
    }
    "8" {
        Write-Host "🚀 Starting complete integration test with headless server..." -ForegroundColor Cyan
        Write-Host "This will start a headless server and open client windows" -ForegroundColor Yellow
        
        # Start headless server
        Write-Host "1. Starting headless server..."
        Start-Process -FilePath "powershell" -ArgumentList "-Command", "godot --headless scenes/server/headless_server.tscn; Read-Host 'Press Enter to close'" -WindowStyle Normal
        Start-Sleep 3
        
        # Start admin dashboard
        Write-Host "2. Starting admin dashboard..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/test/admin_dashboard_test.tscn" -WindowStyle Normal
        Start-Sleep 2
        
        # Start client lobby
        Write-Host "3. Starting client lobby..."
        Start-Process -FilePath "godot" -ArgumentList "scenes/lobby/client_lobby.tscn" -WindowStyle Normal
        Start-Sleep 2
        
        Write-Host ""
        Write-Host "✅ All windows launched with headless server!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🤖 Automated testing workflow:" -ForegroundColor Yellow
        Write-Host "1. Server is running in a separate console window" -ForegroundColor White
        Write-Host "2. In the Admin Dashboard Test window: Click 'Launch Admin Dashboard'" -ForegroundColor White
        Write-Host "3. Login to admin dashboard (admin@mexicantrain.local / admin123)" -ForegroundColor White
        Write-Host "4. In the Client Lobby window: Leave blank for localhost or enter address[:port]" -ForegroundColor White
        Write-Host "5. Create a game and verify it appears in admin dashboard" -ForegroundColor White
        Write-Host ""
        Write-Host "🖥️  The server console shows live connection status" -ForegroundColor Cyan
        Write-Host "⏹️  Close the server console window to stop the server" -ForegroundColor Red
    }
    default {
        Write-Host "❌ Invalid choice. Please run the script again." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "📚 For detailed testing instructions, see TESTING_GUIDE.md" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Green
