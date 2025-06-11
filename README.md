# Mexican Train Dominoes Game

A complete implementation of the Mexican Train dominoes game built in Godot 4, featuring realistic game mechanics, drag-and-drop functionality, and proper domino orientation behavior.

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

## 🚀 Quick Start

### Prerequisites
- Godot 4.x
- Windows, macOS, or Linux

### Running the Game
1. Open the project in Godot Editor
2. Run the main test scene: `tests/test_complete_mexican_train.tscn`
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
- `test_complete_mexican_train.tscn`: Full game integration test
- `test_boneyard_hand_drag_drop.tscn`: Drag-drop mechanics test
- `test_train_orientation.tscn`: Domino orientation test
- `test_domino_basic.tscn`: Individual domino testing

### Running Tests
```bash
# Run specific test scenes from Godot editor
# Or use the project's test runner
```

## 🖥️ Server Testing & Administration

### Quick Server Testing
```bash
# Run the automated test launcher
./test_server.ps1
```

### Manual Testing Options

#### 1. Automated System Tests
```bash
godot scenes/test/test_server_system.tscn
```
- Comprehensive automated testing of all server components
- Tests autoloads, authentication, networking, and statistics
- **Recommended first step** for verifying system integrity

#### 2. Server Mechanics
```bash
godot scenes/test/test_server_mechanics.tscn
```
- Start/stop central server
- Monitor active games and connections
- Basic server management interface

#### 3. Admin Dashboard
```bash
godot scenes/test/test_server_admin_dashboard.tscn
```
- **Login**: `admin@mexicantrain.local` / `admin123`
- Real-time server metrics and monitoring
- Statistics tracking and server control
- Administrative functions

#### 4. Client Lobby
```bash
godot scenes/lobby/client_lobby.tscn
```
- Connect to server at `127.0.0.1`
- Create and join games
- Test multiplayer lobby functionality

#### 5. Complete Integration Test
Run all components simultaneously to test full system:
```bash
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

```
mexican-train/
├── scenes/          # Godot scene files
│   ├── domino/     # Domino component
│   ├── bone_yard/  # BoneYard component  
│   ├── hand/       # Hand component
│   ├── train/      # Train component
│   └── station/    # Station component
├── scripts/         # GDScript files
│   └── util/       # Utility classes
├── tests/          # Test scenes and scripts
├── docs/           # Documentation
└── assets/         # Game assets
```

## 🔧 Configuration

### Game Settings
Adjust game parameters in `autoload/game_state.gd`:
```gdscript
@export var MAX_DOTS: int = 6          # Maximum dots per domino side
@export var DEBUG_SHOW_WARNINGS: bool = false  # Debug output
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

### v0.6.0 (Current)
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
- [ ] Multiplayer support
- [ ] AI opponents
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
