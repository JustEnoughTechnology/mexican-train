# Test Files Reorganization Summary

## Overview

This document summarizes the reorganization of test files to follow a
consistent naming convention with the `_test` suffix and proper folder
structure.

## Naming Convention Standard

- All test files must end with `_test` suffix (e.g., `domino_simple_test.gd`)
- Test components are organized by category (e.g., `station_`, `domino_`, `train_`)
- Files are properly located in `scripts/test/` and `scenes/test/` folders

## Files Moved and Renamed

### From Root Directory to scripts/test/

| Original File | New Location | Description |
|---------------|--------------|-------------|
| `test_domino_count.gd` | `scripts/test/domino_count_test.gd` | Domino count test |
| `test_gameconfig.gd` | `scripts/test/game_config_test.gd` | Game config test |
| `test_orientation_debug.gd` | `scripts/test/orientation_debug_test.gd` | Orientation debug |
| `test_orientation_fix.gd` | `scripts/test/orientation_fix_test.gd` | Orientation fix test |
| `test_texture_debug.gd` | `scripts/test/texture_debug_test.gd` | Texture debug |

### From Root Directory to scenes/test/

| Original File | New Location | Description |
|---------------|--------------|-------------|
| `test_texture_debug.tscn` | `scenes/test/texture_debug_test.tscn` | Texture debug |

### Renamed in scripts/test/ (suffix standardization)

| Original File | New File | Description |
|---------------|----------|-------------|
| `debug_station_layout.gd` | `station_layout_debug_test.gd` | Station layout debug |
| `mexican_train_launcher.gd` | `mexican_train_launcher_test.gd` | Game launcher test |
| `minimal_station_test.gd` | `station_minimal_test.gd` | Minimal station test |
| `pink_circle_test.gd` | `circle_pink_test.gd` | Pink circle test |
| `quick_station_test.gd` | `station_quick_test.gd` | Quick station test |
| `simple_domino_test.gd` | `domino_simple_test.gd` | Simple domino test |
| `verify_fixes.gd` | `fixes_verify_test.gd` | Fix verification test |

### Renamed in scenes/test/ (suffix standardization)

| Original File | New File | Description |
|---------------|----------|-------------|
| `debug_station_layout.tscn` | `station_layout_debug_test.tscn` | Station debug scene |
| `mexican_train_launcher.tscn` | `mexican_train_launcher_test.tscn` | Game launcher scene |
| `minimal_station_test.tscn` | `station_minimal_test.tscn` | Minimal station scene |
| `pink_circle_test.tscn` | `circle_pink_test.tscn` | Pink circle scene |
| `quick_station_test.tscn` | `station_quick_test.tscn` | Quick station scene |
| `simple_domino_test.tscn` | `domino_simple_test.tscn` | Simple domino scene |

## Script Path Updates

All renamed scene files (`.tscn`) had their script references updated to
point to the new script locations:

- Updated from `res://tests/[old_name].gd` to `res://scripts/test/[new_name]_test.gd`
- Fixed incorrect `res://tests/` references to use `res://scenes/test/` paths

## Reference Updates

Updated file references in:

- `scripts/lobby/client_lobby.gd`: Fixed multiplayer game scene path
  (`test_multiplayer_mexican_train.tscn` → `mexican_train_multiplayer_test.tscn`)
- `scripts/test/mexican_train_launcher_test.gd`: Updated all scene paths to
  use new `*_test.tscn` naming convention
- All scene files: Updated script references from `test_*.gd` to `*_test.gd` paths

## Automation Tools Created

- `rename_test_files.ps1`: Batch rename script for efficient file renaming
- `update_script_references.ps1`: Automated script reference updates in scene files

## Files Already Following Convention

These files were already properly named with `_test` suffix:

- All remaining `*_test.tscn` files in `scenes/test/`
- All remaining `*_test.gd` files in `scripts/test/`

## Complete Batch Rename (test\_\* → \*\_test)

All files with `test_*` prefix were batch renamed to follow `*_test` suffix:

### Scene Files (.tscn) - 25 files renamed

- `test_8_player_layout_clean.tscn` → `player_layout_8_clean_test.tscn`
- `test_8_player_mexican_train.tscn` → `mexican_train_8_player_test.tscn`
- `test_boneyard_basic.tscn` → `boneyard_basic_test.tscn`
- `test_boneyard_hand_drag_drop.tscn` → `boneyard_hand_drag_drop_test.tscn`
- `test_bone_yard.tscn` → `bone_yard_test.tscn`
- `test_comparison.tscn` → `comparison_test.tscn`
- `test_complete_mexican_train.tscn` → `mexican_train_complete_test.tscn`
- `test_domino_basic.tscn` → `domino_basic_test.tscn`
- `test_domino_game_container.tscn` → `domino_game_container_test.tscn`
- `test_domino_orientation.tscn` → `domino_orientation_test.tscn`
- `test_double_dominoes.tscn` → `dominoes_double_test.tscn`
- `test_hand_drag_drop.tscn` → `hand_drag_drop_test.tscn`
- `test_multiplayer_mexican_train.tscn` → `mexican_train_multiplayer_test.tscn`
- `test_player_hand.tscn` → `player_hand_test.tscn`
- `test_player_naming.tscn` → `player_naming_test.tscn`
- `test_server_admin_dashboard.tscn` → `server_admin_dashboard_test.tscn`
- `test_server_mechanics.tscn` → `server_mechanics_test.tscn`
- `test_server_system.tscn` → `server_system_test.tscn`
- `test_station_drag_fix.tscn` → `station_drag_fix_test.tscn`
- `test_station_only.tscn` → `station_only_test.tscn`
- `test_train.tscn` → `train_test.tscn`
- `test_train_drag_drop.tscn` → `train_drag_drop_test.tscn`
- `test_train_orientation.tscn` → `train_orientation_test.tscn`
- `test_train_simple.tscn` → `train_simple_test.tscn`
- `test_train_station_drag_drop.tscn` → `train_station_drag_drop_test.tscn`
- `test_unique_player_names.tscn` → `player_names_unique_test.tscn`

### Script Files (.gd) - 27 files renamed

- `test_8_player_layout_clean.gd` → `player_layout_8_clean_test.gd`
- `test_8_player_mexican_train.gd` → `mexican_train_8_player_test.gd`
- `test_boneyard_basic.gd` → `boneyard_basic_test.gd`
- `test_boneyard_hand_drag_drop.gd` → `boneyard_hand_drag_drop_test.gd`
- `test_bone_yard.gd` → `bone_yard_test.gd`
- `test_comparison.gd` → `comparison_test.gd`
- `test_complete_mexican_train.gd` → `mexican_train_complete_test.gd`
- `test_domino.gd` → `domino_test.gd`
- `test_domino_basic.gd` → `domino_basic_test.gd`
- `test_domino_orientation.gd` → `domino_orientation_test.gd`
- `test_double_dominoes.gd` → `dominoes_double_test.gd`
- `test_hand_drag_drop.gd` → `hand_drag_drop_test.gd`
- `test_multiplayer_mexican_train.gd` → `mexican_train_multiplayer_test.gd`
- `test_orientation_debug.gd` → `orientation_debug_test.gd`
- `test_orientation_fix.gd` → `orientation_fix_test.gd`
- `test_player_hand.gd` → `player_hand_test.gd`
- `test_player_naming.gd` → `player_naming_test.gd`
- `test_player_object_names.gd` → `player_object_names_test.gd`
- `test_server_admin_dashboard.gd` → `server_admin_dashboard_test.gd`
- `test_server_mechanics.gd` → `server_mechanics_test.gd`
- `test_server_system.gd` → `server_system_test.gd`
- `test_station_drag_fix.gd` → `station_drag_fix_test.gd`
- `test_station_only.gd` → `station_only_test.gd`
- `test_texture_debug.gd` → `texture_debug_test.gd`
- `test_train.gd` → `train_test.gd`
- `test_train_drag_drop.gd` → `train_drag_drop_test.gd`
- `test_train_orientation.gd` → `train_orientation_test.gd`
- `test_train_station_drag_drop.gd` → `train_station_drag_drop_test.gd`
- `test_train_station_drag_drop_simple.gd` → `train_station_drag_drop_simple_test.gd`

## Naming Categories

Files are now organized by functional categories:

- **Server**: `server_*_test` (mechanics, admin, system)
- **Station**: `station_*_test` (layout, minimal, quick)
- **Domino**: `domino_*_test` (simple, basic, count, orientation)
- **Train**: `train_*_test` (drag drop, orientation)
- **Boneyard**: `boneyard_*_test` (basic, hand interaction)
- **Player**: `player_*_test` (hand, naming)
- **Network**: `multiplayer_*_test`
- **Debug**: `*_debug_test` (texture, orientation, layout)
- **Config**: `config_*_test`, `fixes_*_test`

## Benefits of Reorganization

1. **Consistent Naming**: All test files now end with `_test` suffix
2. **Clear Organization**: Tests grouped by functionality
3. **Proper Structure**: All test files in appropriate folders
4. **Easier Discovery**: Standardized naming makes tests easier to find
5. **Better Maintenance**: Consistent structure improves code maintainability

## Next Steps

- Verify all scene files load correctly with updated script paths
- Test compilation to ensure no broken references
- Update any documentation that references old file names
- Consider creating test categories in project organization
