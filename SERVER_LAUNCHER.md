# Mexican Train Server

## Quick Start

### Option 1: Use the Batch File (Windows)
```batch
start_server.bat
```

### Option 2: Use PowerShell Script
```powershell
.\start_server.ps1
```

### Option 3: Direct Godot Command
```bash
godot --headless scenes/server/headless_server.tscn
```

## Command Line Options

The headless server supports the following command line arguments:

- `--port <number>` - Set server port (default: 9957)
- `--max-players <number>` - Set maximum players (default: 32)
- `--help` - Show help message

### Examples

Start server on default port 9957:
```bash
godot --headless scenes/server/headless_server.tscn
```

Start server on custom port:
```bash
godot --headless scenes/server/headless_server.tscn --port 9000
```

Start server with custom port and player limit:
```bash
godot --headless scenes/server/headless_server.tscn --port 9957 --max-players 16
```

## PowerShell Script Options

The `start_server.ps1` script provides the same functionality with PowerShell parameters:

```powershell
# Default settings
.\start_server.ps1

# Custom port
.\start_server.ps1 -Port 9000

# Custom port and player limit
.\start_server.ps1 -Port 9957 -MaxPlayers 16

# Show help
.\start_server.ps1 -Help
```

## Server Management

- **Start**: Run any of the commands above
- **Stop**: Press `Ctrl+C` in the server console
- **Status**: The server prints connection status and player counts
- **Logs**: All server activity is logged to the console in real-time

## Client Connection

Once the server is running, clients can connect using flexible address formats:

### Address Input Options
1. **Blank** (default): Connects to `localhost:9957`
2. **Address only**: `192.168.1.100` connects to `192.168.1.100:9957` 
3. **Address with port**: `server.com:8000` connects to `server.com:8000`

### Examples
- Leave blank → `127.0.0.1:9957`
- `192.168.1.100` → `192.168.1.100:9957`
- `game.example.com` → `game.example.com:9957`
- `10.0.0.5:8000` → `10.0.0.5:8000`

## Testing

Use the test script for comprehensive testing:
```powershell
.\test_server.ps1
```

Select option 7 to start a headless server, or option 8 for complete integration testing.
