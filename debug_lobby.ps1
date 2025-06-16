# Debug test for lobby issues
Set-Location "c:\development\mexican-train"

Write-Host "=== LOBBY DEBUGGING TEST ===" -ForegroundColor Cyan

# Check current lobby manager state
Write-Host "`n1. Testing current lobby behavior..." -ForegroundColor Yellow

# Look for test scripts that can help debug
Write-Host "`nLooking for test files..." -ForegroundColor Yellow
if (Test-Path "scripts\test\test_lobby_debug.gd") {
    Write-Host "Found lobby debug test" -ForegroundColor Green
} else {
    Write-Host "No lobby debug test found - will run basic validation" -ForegroundColor Orange
}

# Test basic lobby manager functionality
$lobby_test = @"
extends SceneTree

func _init():
    print("=== Lobby Debug Test ===")
    
    # Test game creation
    var game_code = LobbyManager.create_game(12345, "TestHost")
    print("Created game: " + game_code)
    
    # Check if game appears in lobby data
    var lobby_data = LobbyManager.get_lobby_data()
    print("Lobby data size: " + str(lobby_data.size()))
    for code in lobby_data:
        print("Game: " + code + " - Players: " + str(lobby_data[code].player_count))
    
    # Check game info
    var game_info = LobbyManager.get_game_info(game_code)
    print("Game info: " + str(game_info))
    
    # Test AI addition
    var ai_success = LobbyManager.add_ai_to_game(game_code, 12345)
    print("AI addition success: " + str(ai_success))
    
    # Check updated lobby data
    lobby_data = LobbyManager.get_lobby_data()
    print("Updated lobby data size: " + str(lobby_data.size()))
    for code in lobby_data:
        var info = lobby_data[code]
        print("Game: " + code + " - Players: " + str(info.player_count) + " - Can start: " + str(info.get("can_start", false)))
    
    # Test ready status
    var ready_success = LobbyManager.set_player_ready(12345, true)
    print("Ready status success: " + str(ready_success))
    
    # Test game start
    var start_success = LobbyManager.start_game(game_code, 12345)
    print("Game start success: " + str(start_success))
    
    quit()
"@

# Write test file
$lobby_test | Out-File -FilePath "lobby_debug_test.gd" -Encoding UTF8

Write-Host "`nRunning lobby debug test..." -ForegroundColor Yellow
try {
    $result = & godot --script lobby_debug_test.gd
    Write-Host $result -ForegroundColor White
} catch {
    Write-Host "Error running test: $($_.Exception.Message)" -ForegroundColor Red
}

# Clean up
Remove-Item "lobby_debug_test.gd" -ErrorAction SilentlyContinue

Write-Host "`n=== DEBUG TEST COMPLETE ===" -ForegroundColor Cyan
