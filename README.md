# Mexican Train Dominoes Game

A complete implementation of the Mexican Train dominoes game built in
Godot 4, featuring realistic game mechanics, drag-and-drop functionality,
and proper domino orientation behavior.

## 🎮 Features

### Core Game Components

- **BoneYard**: Complete domino set with drag-and-drop functionality
- **Hand**: Player's personal domino collection with automatic sizing
- **Station**: Central engine placement area with validation
- **Train**: Extendable domino train with connection logic

### Advanced Game Mechanics

- **Domino Orientation**: Automatic orientation based on connection requirements
- **Drag-Drop Restrictions**: Realistic movement rules between game areas
- **Player Identification**: OS username detection with fallback system
- **Engine Validation**: Proper double-domino engine placement

### Technical Features

- **Source-Based Drag Rules**: Prevents invalid domino movements
- **Connection Validation**: Ensures dominoes match properly
- **Dynamic Sizing**: Responsive layouts for all game components
- **Debug Overlays**: Visual orientation indicators for testing
- **Professional Logging**: RFC 5424 syslog-compatible logging system with configurable levels and areas

## 🚀 Quick Start

### Prerequisites

- Godot 4.x
- Windows, macOS, or Linux

### Running the Game

1. Open the project in Godot Editor
2. Run the main test scene: `scenes/test/test_complete_mexican_train.tscn`
3. Follow the on-screen instructions to play

### Game Rules

1. **Setup**: Drag dominoes from the boneyard to your hand
2. **Engine**: Place any double domino (0-0, 1-1, etc.) in the station to start
3. **Building**: Extend the train by matching domino values
4. **Goal**: Build the longest possible train

## 🎯 Drag-and-Drop Rules

The game enforces realistic domino movement restrictions:

| Source → Target | Allowed | Description |
|----------------|---------|-------------|
| Boneyard → Hand | ✅ | Collect dominoes |
| Hand → Train | ✅ | Build your train |
| Hand → Station | ✅ | Place engine domino |
| Train → Anywhere | ❌ | Cannot move placed dominoes |
| Station → Anywhere | ❌ | Engine stays in place |
| Boneyard → Train/Station | ❌ | Must go through hand first |

## 🎛️ Controls

- **Mouse Drag**: Move dominoes between areas
- **Right-Click**: Flip dominoes face up/down
- **Spacebar**: Toggle orientation overlays (for debugging)
- **Enter**: Toggle debug warnings

## 🏗️ Architecture

### Core Classes

- `Domino`: Individual domino piece with orientation logic
- `BoneYard`: Domino storage and distribution
- `Hand`: Player's domino collection
- `Train`: Extendable domino sequence
- `Station`: Engine domino placement area

### Utility Classes

- `PlayerNameUtil`: OS username detection and player identification
- `DominoData`: Data model for domino state
- `GameConfig`: Global game configuration constants and settings

### Key Features Implementation

#### Domino Orientation System

```gdscript
# Automatically orients dominoes for proper connections
func _orient_domino_for_connection(domino: Domino) -> void:
    # First domino: engine-matching side on left
    # Subsequent dominoes: connecting side matches previous
```

#### Drag-Drop Restriction System

```gdscript
# Source detection prevents invalid moves
func _get_source_type() -> String:
    # Returns: "boneyard", "hand", "train", or "station"
```

#### Player Identification System

```gdscript
# OS username detection with fallback
PlayerNameUtil.get_player_name()  # Returns OS username or "Player123"
```

## 🧪 Testing

### Test Scenes

- `scenes/test/test_complete_mexican_train.tscn`: Full game integration test
- `scenes/test/test_boneyard_hand_drag_drop.tscn`: Drag-drop mechanics test
- `scenes/test/test_train_orientation.tscn`: Domino orientation test
- `scenes/test/test_domino_basic.tscn`: Individual domino testing

### Running Tests

```powershell
# Run specific test scenes from Godot editor
# Available test scenes:
# - scenes/test/test_server_system.tscn (automated server tests)
# - scenes/test/test_server_mechanics.tscn (server control)
# - scenes/test/test_server_admin_dashboard.tscn (admin interface)
```

## 🖥️ Server Testing & Administration

### Quick Server Testing

```powershell
# Run the automated test launcher
./test_server.ps1
```

### Manual Testing Options

#### 1. Automated System Tests

```powershell
godot scenes/test/test_server_system.tscn
```

- Comprehensive automated testing of all server components
- Tests autoloads, authentication, networking, and statistics
- **Recommended first step** for verifying system integrity

#### 2. Server Mechanics

```powershell
godot scenes/test/test_server_mechanics.tscn
```

- Start/stop central server
- Monitor active games and connections
- Basic server management interface

#### 3. Admin Dashboard

```powershell
godot scenes/test/test_server_admin_dashboard.tscn
```

- **Login**: `admin@mexicantrain.local` / `admin123`
- Real-time server metrics and monitoring
- Statistics tracking and server control
- Administrative functions

#### 4. Client Lobby

```powershell
godot scenes/lobby/client_lobby.tscn
```

- Connect to server at `127.0.0.1`
- Create and join games
- Test multiplayer lobby functionality

#### 5. Complete Integration Test

Run all components simultaneously to test full system:

```powershell
# Automated multi-window launch
./test_server.ps1
# Choose option 5 for complete integration test
```

### Testing Workflow

1. **Start Server**: Use server mechanics to start central server
2. **Admin Login**: Access admin dashboard with provided credentials
3. **Client Connect**: Join lobby from client interface
4. **Create Game**: Host a new game and verify it appears in admin dashboard
5. **Monitor**: Watch real-time statistics and server metrics

For detailed testing instructions, see `TESTING_GUIDE.md`.

## 📁 Project Structure

```text
mexican-train/
├── scenes/          # Godot scene files
│   ├── domino/     # Domino component
│   ├── bone_yard/  # BoneYard component  
│   ├── hand/       # Hand component
│   ├── train/      # Train component
│   ├── station/    # Station component
│   ├── test/       # Test scenes
│   └── lobby/      # Multiplayer lobby
├── scripts/         # GDScript files
│   ├── util/       # Utility classes
│   ├── test/       # Test scripts
│   └── lobby/      # Lobby scripts
├── autoload/       # Global autoload scripts
├── docs/           # Documentation
└── assets/         # Game assets
```

## 🔧 Configuration

### Game Settings

Adjust game parameters in `autoload/game_config.gd`:

```gdscript
const MAX_DOTS: int = 6          # Maximum dots per domino side
const DEBUG_SHOW_WARNINGS: bool = false  # Debug output
```

### Layout Settings

Customize component sizing in individual scripts:

```gdscript
@export var max_width_percent: float = 0.5   # Hand width
@export var max_height_percent: float = 0.25 # Hand height
```

## 🐛 Debugging

### Debug Features

- **Orientation Overlays**: Visual indicators for domino orientation
- **Debug Warnings**: Detailed console output for troubleshooting
- **Connection Validation**: Step-by-step domino placement logging

### Common Issues

1. **Domino won't drop**: Check source restrictions and connection validation
2. **Wrong orientation**: Verify engine domino is placed correctly
3. **Layout issues**: Adjust size percentages in component scripts

## 🔍 Logging System

The game includes a professional logging system for debugging and monitoring:

### Usage

```gdscript
# Basic logging
Logger.log_info(Logger.LogArea.GAME, "Player action completed")
Logger.log_error(Logger.LogArea.NETWORK, "Connection failed")
Logger.log_debug(Logger.LogArea.AI, "AI evaluating move")

# Available areas: ADMIN, MULTIPLAYER, AI, GAME, LOBBY, NETWORK, SYSTEM, UI, GENERAL
```

### Configuration

Configure in `autoload/global.gd`:

```gdscript
func get_logging_config() -> Dictionary:
    return {
        "global_level": Logger.LogLevel.INFO,
        "areas": {
            Logger.LogArea.NETWORK: Logger.LogLevel.DEBUG,  # Debug network issues
            Logger.LogArea.AI: Logger.LogLevel.WARNING,     # Less verbose AI
        }
    }
```

### Documentation

See `docs/LOGGING_SYSTEM.md` for complete documentation and examples.

## 🤝 Contributing

### Development Setup

1. Clone the repository
2. Open in Godot 4.x
3. Run test scenes to verify functionality
4. Follow the existing code structure for new features

### Code Style

- Use clear, descriptive variable names
- Add debug logging for complex operations
- Include comprehensive comments for game logic
- Follow GDScript naming conventions

## 📝 License

This project is open source. See LICENSE file for details.

## 🏷️ Version History

### v0.6.1 (Current)

- ✅ Professional RFC 5424 syslog-compatible logging system
- ✅ Comprehensive logging conversion across all core game files
- ✅ Configurable log levels and application areas
- ✅ Runtime logging configuration and control
- ✅ Enhanced debugging and monitoring capabilities

### v0.6.0

- ✅ GameState → GameConfig refactoring
- ✅ Multiplayer networking infrastructure
- ✅ AI player foundation
- ✅ Enhanced player management with unique naming
- ✅ Color theme management system
- ✅ Comprehensive test suite restructuring
- ✅ 8-player layout support
- ✅ Lobby system for multiplayer games
- ✅ Advanced drag-and-drop improvements

### Previous Versions

- v0.5.0 - Complete domino orientation system, drag-drop restrictions, player identification
- Development builds with individual component testing

## 🎯 Roadmap

### Planned Features

- [x] Multiplayer support (✅ Completed in v0.6.0)
- [ ] AI opponents (🚧 Foundation implemented)
- [ ] Score tracking
- [ ] Game save/load
- [ ] Custom domino sets
- [ ] Sound effects
- [ ] Enhanced UI/UX

### Technical Improvements

- [ ] Performance optimization
- [ ] Unit test coverage
- [ ] Continuous integration
- [ ] Cross-platform testing

## 📞 Support

For questions, issues, or contributions:

1. Check the documentation in the `docs/` folder
2. Run the test scenes to verify functionality
3. Review the code comments for implementation details
4. Create issues for bugs or feature requests

---

**Enjoy playing Mexican Train Dominoes!** 🚂🎲
