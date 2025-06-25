# Test Organization Structure

This directory contains organized subdirectories for better test management. **IMPORTANT**: Existing test files remain in the root `test/` folder and should NOT be moved to avoid confusion.

## Directory Structure

### 📦 **dominos/** 
- Domino piece tests (creation, display, combinations)
- Boneyard functionality tests
- Domino visual/legibility tests
- **Examples**: `test_half_dominos_display.tscn`, future domino generation tests

### 🖥️ **server/**
- Server mechanics and admin functionality
- Multiplayer coordination tests
- Server infrastructure tests
- **Future examples**: Server performance tests, admin dashboard variations

### 👤 **player/**
- Player hand management tests
- Player naming and identification tests
- Player layout and positioning tests
- **Future examples**: Hand validation tests, player interaction tests

### 🚂 **train/**
- Train mechanics and movement tests
- Station interaction tests
- Drag & drop functionality for trains
- **Future examples**: Train routing tests, station validation tests

### 🎨 **ui/**
- Visual display tests
- Texture and rendering tests
- UI component tests
- **Future examples**: UI responsiveness tests, theme tests

### 🌐 **lobby/**
- Lobby creation and management tests
- Network connection tests
- Client-server communication tests
- **Future examples**: Lobby capacity tests, connection stability tests

### 🎮 **game/**
- Complete game flow tests
- Game mechanics integration tests
- End-to-end gameplay tests
- **Future examples**: Full game simulation tests, rule validation tests

### ⚙️ **infrastructure/**
- Logging system tests
- Configuration tests
- System utilities tests
- **Future examples**: Performance monitoring tests, error handling tests

## Usage Guidelines

1. **New Tests**: Place new test files in appropriate subdirectories
2. **Existing Tests**: Leave existing tests in root `test/` folder - DO NOT MOVE
3. **Naming Convention**: Use descriptive names that indicate the test purpose
4. **Related Files**: Keep `.tscn` and `.gd` files in corresponding subdirectories

## Example File Placement

```
✅ Good (new tests):
scenes/test/dominos/domino_combination_generator_test.tscn
scripts/test/dominos/domino_combination_generator_test.gd

scenes/test/server/multiplayer_sync_test.tscn
scripts/test/server/multiplayer_sync_test.gd

❌ Don't Move (existing tests):
scenes/test/mexican_train_complete_test.tscn (leave in root)
scripts/test/mexican_train_complete_test.gd (leave in root)
```

## Current State
- ✅ Subdirectories created for future organization
- ✅ Existing tests preserved in original locations
- ✅ Structure ready for new test development

---
*Created: June 23, 2025 - Mexican Train Domino Game Project*
