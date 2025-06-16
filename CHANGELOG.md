# Changelog

All notable changes to the Mexican Train Dominoes project will be
documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.1] - 2025-06-16

### Added

- **Professional Logging System**
  - Complete RFC 5424 syslog-compatible logging framework
  - Logger autoload with 8 log levels (Emergency to Debug)
  - 10 application-specific log areas (Admin, AI, Game, Lobby, Network, etc.)
  - Runtime configuration with per-area log level control
  - Timestamp support and formatted console output
  - Backward compatibility with existing `Global.debug_print()` calls

### Changed

- **Comprehensive Logging Conversion**
  - Converted all `print()` statements in core game files to structured Logger calls
  - Converted all `push_error()` and `push_warning()` statements to appropriate log levels
  - Replaced informal debug output with professional logging throughout codebase
  - Updated all core game components: Domino, Player, AI Player, Admin Dashboard, Server, Lobby, etc.

- **Improved Code Quality**
  - Consistent logging patterns across entire codebase
  - Proper error categorization with appropriate log levels
  - Enhanced debugging capabilities with area-specific filtering
  - Better production-ready logging for deployment

### Technical Details

- **New Files:**
  - `autoload/logger.gd` - Complete logging framework
  - `docs/LOGGING_SYSTEM.md` - Comprehensive logging documentation
  - `docs/logging_configuration_examples.gd` - Configuration examples
  - Test files for logging system validation

- **Core Files Updated with Logger Integration:**
  - `scripts/domino/domino.gd` - Game logic logging
  - `scripts/players/player.gd` - Player state logging
  - `scripts/players/ai_player.gd` - AI decision logging
  - `scripts/admin/admin_dashboard.gd` - Admin operations logging
  - `scripts/server/headless_server.gd` - Server lifecycle logging
  - `scripts/lobby/client_lobby.gd` - Connection and lobby logging
  - `scripts/lobby/server_launcher.gd` - Server management logging
  - `scripts/bone_yard/v_box_container.gd` - Component logging
  - All autoload files with deprecation warnings converted

### Fixed

- **Inconsistent Debug Output**
  - Replaced informal print statements with structured logging
  - Fixed missing error handling with proper log levels
  - Resolved debug output inconsistencies across components

### Migration Guide

- **For Developers:**
  - Use `Logger.log_info(Logger.LogArea.GAME, "message")` instead of `print()`
  - Use `Logger.log_error(Logger.LogArea.SYSTEM, "error")` instead of `push_error()`
  - Configure logging in `Global.gd` using `get_logging_config()` method
  - Test files retain print statements for development purposes

- **For Users:**
  - No changes required - logging is transparent to end users
  - Better error messages and debugging information available
  - Configurable log verbosity for troubleshooting

---

## [0.5.0] - 2025-01-18

### Added

- **Complete Domino Orientation System**
  - First domino in train now orients with engine-matching side on the left
  - Automatic domino swapping when engine value is on the right side
  - Proper orientation validation for all domino placements
  - Debug logging for orientation decisions

- **Drag-Drop Restriction System**
  - Source-based drag detection in `Domino._get_source_type()`
  - Prevented dragging from trains and stations
  - Enforced realistic movement rules: Boneyard→Hand, Hand→Train/Station only
  - Added proper metadata cleanup in all drop operations

- **Player Identification System**
  - Created `PlayerNameUtil` utility class
  - OS username detection for Windows, macOS, and Linux
  - Fallback to "Player" + 3-digit random number
  - Integrated player names into Hand and Train labels

- **Enhanced Game Components**
  - Updated `Hand._ready()` to use player naming
  - Updated `Train._ready()` to use player naming
  - Improved drag-drop validation across all components
  - Added comprehensive debug output

- **Documentation**
  - Complete README.md with game features and usage
  - Architecture documentation  - Development setup instructions
  - Troubleshooting guide

### Changed

- **Train Orientation Logic**
  - Rewrote `Train._orient_domino_for_connection()` for proper engine connection
  - Modified first domino placement to ensure engine-side positioning
  - Updated connection validation to use new orientation system

- **Drag-Drop Behavior**
  - Enhanced `_can_drop_data()` methods in Train and Station
  - Modified `_drop_data()` methods to include metadata cleanup
  - Updated Domino class to prevent invalid drag operations

- **Component Labels**
  - Hand now displays "{Username}'s Hand"
  - Train now displays "{Username}'s Train"
  - Dynamic username detection based on operating system

### Fixed

- **Domino Orientation Issues**
  - Fixed first domino not orienting correctly with engine
  - Resolved domino swapping logic for proper connections
  - Corrected orientation constants usage

- **Drag-Drop Restrictions**
  - Prevented dragging dominoes from trains back to other areas
  - Blocked dragging from station after engine placement
  - Fixed direct boneyard-to-train/station drops

- **Player Naming**
  - Resolved generic "Hand" and "Train" labels
  - Added proper fallback when OS username unavailable
  - Fixed label updates in component initialization

### Technical Details

- **Files Modified:**
  - `scripts/domino/domino.gd` - Added source detection and drag blocking
  - `scripts/train/train.gd` - Rewrote orientation logic and drag validation
  - `scripts/hand/hand.gd` - Integrated player naming
  - `scripts/station/station.gd` - Enhanced drop validation
  - `scripts/util/player_name_util.gd` - NEW: Player identification utility

- **Test Files Updated:**
  - `tests/test_complete_mexican_train.gd` - Comprehensive integration test
  - All test scenarios now validate new features

### Breaking Changes

- None - All changes are backward compatible

### Migration Guide

- No migration needed - existing saves and configurations remain compatible
- New player naming system activates automatically
- Drag-drop restrictions are enforced immediately

---

## [Previous Development]

### Pre-0.5.0

- Basic domino, boneyard, hand, train, and station implementation
- Initial drag-drop functionality
- Core game mechanics
- Test scene development
- Asset creation and management

---

**Note**: This changelog tracks major feature releases. For detailed commit
history, see the Git log.
