# Test Organization

This document describes the organization of test files in the Mexican Train Dominoes project.

## Test Directory Structure

### `scripts/test/` - Test Scripts
Contains all GDScript and C# test scripts organized by category in subfolders:

#### Subdirectories (122 total files)
- `boneyard/` (8 files) - Boneyard functionality tests (drag/drop, basic operations)
- `dominos/` (39 files) - Domino system tests (rendering, orientation, colors, back display)
- `game/` (13 files) - Game logic tests (Mexican Train game mechanics, configurations)
- `infrastructure/` (10 files) - Infrastructure tests (logging, admin dashboard, fixes)
- `lobby/` (4 files) - Lobby system tests (validation, client connections)
- `player/` (8 files) - Player-specific tests (hands, naming, layout)
- `server/` (10 files) - Server functionality tests (mechanics, admin, auto-start)
- `station/` (10 files) - Train station tests (drag/drop, layout, debugging)
- `train/` (10 files) - Train functionality tests (orientation, drag/drop, station integration)
- `ui/` (0 files) - UI-specific test scripts (reserved for future use)
- `visual/` (10 files) - Visual and debug tests (texture, orientation, simple graphics)

### `scenes/test/` - Test Scenes
Contains all test scene files (.tscn) organized by category in subfolders:

#### Subdirectories (43 total files)
- `boneyard/` (5 files) - Boneyard test scenes (drag/drop debugging, basic functionality)
- `dominos/` (6 files) - Domino system test scenes (display, showcase, piece testing)
- `game/` (5 files) - Game logic test scenes (Mexican Train variations, comparisons)
- `infrastructure/` (3 files) - Infrastructure test scenes (logging, admin dashboards)
- `lobby/` (2 files) - Lobby test scenes (validation, client connections)
- `player/` (3 files) - Player test scenes (hands, naming, unique identifiers)
- `server/` (7 files) - Server test scenes (mechanics, admin dashboards, auto-start)
- `station/` (5 files) - Train station test scenes (layout, drag fixes, debugging)
- `train/` (5 files) - Train test scenes (drag/drop, orientation, station integration)
- `ui/` (0 files) - UI test scenes (reserved for future use)
- `visual/` (2 files) - Visual and debug test scenes (texture debugging, graphics)

### `tools/` - Test Tools
Contains utility scripts for testing:
- `test_generate.ps1` - PowerShell script for test generation
- `create_test_domino_scenes.py` - Python script for creating test domino scenes

## Test File Naming Convention

All test files follow these naming conventions:
- Test scripts: `{component}_{description}_test.gd`
- Test scenes: `{component}_{description}_test.tscn`
- Test UIDs: `{filename}.uid`

## Running Tests

### Individual Tests
Load specific test scenes in Godot editor and run them directly.

### Batch Testing
Use the tools in the `tools/` directory for automated test generation and execution.

### Performance Tests
Performance-related tests are documented in the `docs/` folder with detailed instructions.

---

## Summary

**Total Test Files Organized:** 165 files
- **Scripts:** 122 files across 10 subdirectories  
- **Scenes:** 43 files across 10 subdirectories

**Organization Benefits:**
- ✅ **Zero test files** remain in root test directories
- ✅ **Logical categorization** by game component and functionality
- ✅ **Consistent structure** between scripts and scenes directories
- ✅ **Easy navigation** and maintenance
- ✅ **Clear separation** of concerns (dominos, boneyard, trains, etc.)

**Key Improvements Made:**
- Moved 30+ files from root `scripts/test/` into appropriate subfolders
- Moved 20+ files from root `scenes/test/` into appropriate subfolders  
- Created new subfolders: `boneyard/`, `station/`, `visual/`
- Maintained existing subfolders: `dominos/`, `game/`, `infrastructure/`, `lobby/`, `player/`, `server/`, `train/`, `ui/`
- Updated documentation to reflect actual file counts and organization

*All test files have been organized from scattered locations throughout the project into these centralized, well-structured test directories for better maintainability and discoverability.*
