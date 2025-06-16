# MEXICAN TRAIN - LOGGING SYSTEM DOCUMENTATION

## Overview

The Mexican Train project now includes a professional logging system with syslog-standard levels and application-specific areas. This system provides granular control over what gets logged and how it's formatted.

## Features

- **RFC 5424 Syslog Levels**: Emergency, Alert, Critical, Error, Warning, Notice, Info, Debug
- **Application Areas**: Admin, Multiplayer, AI, Game, Lobby, Network, System, Database, UI, General
- **Configurable**: Set different log levels for different areas
- **Runtime Control**: Change logging levels during execution
- **Backward Compatible**: Existing `Global.debug_print()` calls still work
- **Timestamp Support**: Optional timestamps in log messages
- **Future Ready**: File logging support planned

## Quick Start

### Basic Usage

```gdscript
# Use the Logger autoload directly
Logger.log_info(Logger.LogArea.GAME, "Player joined the game")
Logger.log_error(Logger.LogArea.NETWORK, "Connection failed")
Logger.log_debug(Logger.LogArea.AI, "AI evaluating move options")

# Or use convenience functions
Logger.log_warning(Logger.LogArea.MULTIPLAYER, "High latency detected")
```

### Configuration in Global.gd

```gdscript
# Override default logging in Global.gd
var logging_config: Dictionary = {
    "global_level": Logger.LogLevel.INFO,
    "areas": {
        Logger.LogArea.NETWORK: Logger.LogLevel.DEBUG,  # Debug network issues
        Logger.LogArea.AI: Logger.LogLevel.WARNING,     # Less verbose AI logs
    },
    "console_output": true,
    "file_output": false
}
```

### Runtime Configuration

```gdscript
# Change log levels at runtime
Logger.set_global_log_level(Logger.LogLevel.DEBUG)
Logger.set_area_log_level(Logger.LogArea.ADMIN, Logger.LogLevel.ERROR)

# Enable/disable logging
Logger.set_logging_enabled(false)
```

## Log Levels (0-7)

| Level | Value | When to Use |
|-------|-------|-------------|
| EMERGENCY | 0 | System is unusable |
| ALERT | 1 | Action must be taken immediately |
| CRITICAL | 2 | Critical conditions |
| ERROR | 3 | Error conditions |
| WARNING | 4 | Warning conditions |
| NOTICE | 5 | Normal but significant events |
| INFO | 6 | Informational messages |
| DEBUG | 7 | Debug-level messages |

## Application Areas

| Area | Purpose |
|------|---------|
| ADMIN | Admin dashboard and authentication |
| MULTIPLAYER | Network multiplayer functionality |
| AI | AI player logic and decisions |
| GAME | Core game logic and rules |
| LOBBY | Lobby and game room management |
| NETWORK | Low-level networking |
| SYSTEM | System events, startup, shutdown |
| DATABASE | Future: database operations |
| UI | User interface events |
| GENERAL | General application events |

## Examples by Game Component

### Network Manager
```gdscript
Logger.log_info(Logger.LogArea.NETWORK, "Server started on port %d" % port)
Logger.log_error(Logger.LogArea.NETWORK, "Failed to connect: %s" % error)
Logger.log_debug(Logger.LogArea.MULTIPLAYER, "Player %d connected" % peer_id)
```

### Admin Dashboard
```gdscript
Logger.log_warning(Logger.LogArea.ADMIN, "Authentication failed for %s" % email)
Logger.log_info(Logger.LogArea.ADMIN, "Admin %s logged in successfully" % email)
Logger.log_error(Logger.LogArea.ADMIN, "Unauthorized access attempt from %s" % ip)
```

### Game Logic
```gdscript
Logger.log_info(Logger.LogArea.GAME, "Game started with %d players" % player_count)
Logger.log_debug(Logger.LogArea.GAME, "Turn changed to player %d" % player_id)
Logger.log_warning(Logger.LogArea.GAME, "Invalid move attempted by player %d" % player_id)
```

### AI System
```gdscript
Logger.log_debug(Logger.LogArea.AI, "AI evaluating %d possible moves" % move_count)
Logger.log_info(Logger.LogArea.AI, "AI player made move: %s" % move_description)
Logger.log_warning(Logger.LogArea.AI, "AI took longer than expected: %d ms" % time_ms)
```

### Lobby Management
```gdscript
Logger.log_info(Logger.LogArea.LOBBY, "Game %s created by player %d" % [game_code, player_id])
Logger.log_debug(Logger.LogArea.LOBBY, "Player %d joined game %s" % [player_id, game_code])
Logger.log_notice(Logger.LogArea.LOBBY, "Game %s started with %d players" % [game_code, count])
```

## Configuration Examples

### Development Mode (Verbose)
```gdscript
func enable_development_logging():
    var config = {
        "global_level": Logger.LogLevel.DEBUG,
        "areas": {
            Logger.LogArea.ADMIN: Logger.LogLevel.DEBUG,
            Logger.LogArea.MULTIPLAYER: Logger.LogLevel.DEBUG,
            Logger.LogArea.AI: Logger.LogLevel.DEBUG,
            Logger.LogArea.GAME: Logger.LogLevel.DEBUG,
            Logger.LogArea.LOBBY: Logger.LogLevel.DEBUG,
            Logger.LogArea.NETWORK: Logger.LogLevel.DEBUG
        }
    }
    Global.set_logging_config(config)
```

### Production Mode (Minimal)
```gdscript
func enable_production_logging():
    var config = {
        "global_level": Logger.LogLevel.WARNING,
        "areas": {
            Logger.LogArea.ADMIN: Logger.LogLevel.ERROR,
            Logger.LogArea.SYSTEM: Logger.LogLevel.ERROR
        },
        "console_output": false,
        "file_output": true
    }
    Global.set_logging_config(config)
```

### Network Debugging
```gdscript
func enable_network_debug():
    Logger.set_area_log_level(Logger.LogArea.NETWORK, Logger.LogLevel.DEBUG)
    Logger.set_area_log_level(Logger.LogArea.MULTIPLAYER, Logger.LogLevel.DEBUG)
```

## Utility Functions

```gdscript
# Display current configuration
Logger.print_config()

# Get configuration as dictionary
var config = Logger.get_config()

# Get available options
var levels = Logger.get_log_levels()
var areas = Logger.get_log_areas()

# Control output
Logger.set_console_output(true)
Logger.set_file_output(false)  # Future feature
```

## Backward Compatibility

Old code using `Global.debug_print()` still works and automatically maps to the new system:

```gdscript
Global.debug_print("Network message", "network")  # → Logger.LogArea.NETWORK
Global.debug_print("Admin message", "admin")      # → Logger.LogArea.ADMIN
Global.debug_print("General message")             # → Logger.LogArea.GENERAL
```

## Testing

Run the logging system test:
1. Open `scenes/test/logging_system_test.tscn`
2. Run the scene to see all logging features demonstrated

## Migration from Old System

Replace old print statements:

```gdscript
# Old
print("Server started on port %d" % port)
Global.debug_print("Player connected", "network")

# New
Logger.log_info(Logger.LogArea.NETWORK, "Server started on port %d" % port)
Logger.log_debug(Logger.LogArea.NETWORK, "Player connected")
```

## Future Enhancements

- File logging with rotation
- JSON structured logging
- Remote logging endpoints
- Performance metrics
- Log filtering by message content
