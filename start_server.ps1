# Mexican Train Server Launcher
# Simple PowerShell script to start the headless server

param(
    [int]$Port = 25025,
    [int]$MaxPlayers = 32,
    [switch]$Help
)

if ($Help) {
    Write-Host "Mexican Train Server Launcher" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\start_server.ps1 [-Port <number>] [-MaxPlayers <number>] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Port        Server port (default: 25025)"
    Write-Host "  -MaxPlayers  Maximum players (default: 32)"
    Write-Host "  -Help        Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\start_server.ps1"
    Write-Host "  .\start_server.ps1 -Port 9000"
    Write-Host "  .\start_server.ps1 -Port 25025 -MaxPlayers 16"
    Write-Host ""
    exit 0
}

Write-Host "=== Mexican Train Server Launcher ===" -ForegroundColor Green
Write-Host ""

# Check if Godot is available
try {
    $godotVersion = godot --version 2>$null
    Write-Host "✅ Godot found: $godotVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Godot not found in PATH. Please install Godot 4.4+ and add to PATH." -ForegroundColor Red
    exit 1
}

# Change to project directory (assumes script is in project root)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "Starting server..." -ForegroundColor Cyan
Write-Host "Port: $Port" -ForegroundColor Yellow
Write-Host "Max Players: $MaxPlayers" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""

# Start the headless server
$arguments = @("--headless", "scenes/server/headless_server.tscn", "--port", $Port, "--max-players", $MaxPlayers)
& godot $arguments
