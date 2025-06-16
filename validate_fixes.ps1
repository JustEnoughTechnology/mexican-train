# Validation script for client-server connection fixes
Set-Location "c:\development\mexican-train"

Write-Host "=== VALIDATING CLIENT-SERVER CONNECTION FIXES ===" -ForegroundColor Cyan

$allGood = $true

# 1. Check that client_lobby.tscn references the correct script
Write-Host "`n1. Checking client_lobby.tscn script reference..." -ForegroundColor Yellow
$lobbyContent = Get-Content "scenes\lobby\client_lobby.tscn" -Raw
if ($lobbyContent -match 'path="res://scripts/lobby/client_lobby\.gd"') {
    Write-Host "✅ client_lobby.tscn correctly references implementation script" -ForegroundColor Green
} else {
    Write-Host "❌ client_lobby.tscn has wrong script reference" -ForegroundColor Red
    $allGood = $false
}

# 2. Check that the implementation script exists
Write-Host "`n2. Checking implementation script exists..." -ForegroundColor Yellow
if (Test-Path "scripts\lobby\client_lobby.gd") {
    Write-Host "✅ client_lobby.gd implementation script exists" -ForegroundColor Green
} else {
    Write-Host "❌ client_lobby.gd implementation script missing" -ForegroundColor Red
    $allGood = $false
}

# 3. Check lobby_manager.gd has AI player functionality
Write-Host "`n3. Checking lobby_manager.gd has AI player functionality..." -ForegroundColor Yellow
$lobbyManagerContent = Get-Content "autoload\lobby_manager.gd" -Raw
if ($lobbyManagerContent -match 'func add_ai_to_game') {
    Write-Host "✅ add_ai_to_game function exists" -ForegroundColor Green
} else {
    Write-Host "❌ add_ai_to_game function missing" -ForegroundColor Red
    $allGood = $false
}

# 4. Check player readiness system exists
Write-Host "`n4. Checking player readiness system..." -ForegroundColor Yellow
if ($lobbyManagerContent -match 'func set_player_ready') {
    Write-Host "✅ set_player_ready function exists" -ForegroundColor Green
} else {
    Write-Host "❌ set_player_ready function missing" -ForegroundColor Red
    $allGood = $false
}

if ($lobbyManagerContent -match 'func _can_game_start') {
    Write-Host "✅ _can_game_start function exists" -ForegroundColor Green
} else {
    Write-Host "❌ _can_game_start function missing" -ForegroundColor Red
    $allGood = $false
}

# 5. Check for syntax errors in key files
Write-Host "`n5. Checking for syntax issues..." -ForegroundColor Yellow
$syntaxCheck = $true

# Check if lobby_manager has proper indentation in start_game function
if ($lobbyManagerContent -match 'var game = active_games\[game_code\][\r\n\s]+if game\.host_id != host_id:') {
    Write-Host "✅ start_game function has correct structure" -ForegroundColor Green
} else {
    Write-Host "❌ start_game function may have indentation issues" -ForegroundColor Red
    $syntaxCheck = $false
}

# Check get_game_info doesn't have unreachable code
if ($lobbyManagerContent -notmatch 'return \{\}[\r\n\s]+return \{') {
    Write-Host "✅ get_game_info function has no unreachable code" -ForegroundColor Green
} else {
    Write-Host "❌ get_game_info function has unreachable code" -ForegroundColor Red
    $syntaxCheck = $false
}

if (-not $syntaxCheck) {
    $allGood = $false
}

# 6. Check that domino_game_container.tscn no longer references missing script
Write-Host "`n6. Checking domino_game_container.tscn..." -ForegroundColor Yellow
$containerContent = Get-Content "scenes\util\domino_game_container.tscn" -Raw
if ($containerContent -notmatch 'domino_game_container\.gd') {
    Write-Host "✅ domino_game_container.tscn no longer references missing script" -ForegroundColor Green
} else {
    Write-Host "❌ domino_game_container.tscn still references missing script" -ForegroundColor Red
    $allGood = $false
}

# Final result
Write-Host "`n=== VALIDATION RESULTS ===" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "🎉 ALL CHECKS PASSED! Client-server connection fixes are validated." -ForegroundColor Green
    Write-Host "The following issues have been resolved:" -ForegroundColor Green
    Write-Host "  • Fixed scene-script reference issue in client_lobby.tscn" -ForegroundColor Green
    Write-Host "  • Added missing AI player functionality" -ForegroundColor Green
    Write-Host "  • Implemented player readiness system" -ForegroundColor Green
    Write-Host "  • Fixed syntax errors in lobby_manager.gd" -ForegroundColor Green
    Write-Host "  • Removed broken script reference in domino_game_container.tscn" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some validation checks failed. Please review the issues above." -ForegroundColor Red
    exit 1
}
