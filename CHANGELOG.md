# Changelog

All notable changes to the Mexican Train Dominoes project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
  - Architecture documentation
  - Development setup instructions
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

**Note**: This changelog tracks major feature releases. For detailed commit history, see the Git log.
