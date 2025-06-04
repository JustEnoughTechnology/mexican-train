# Domino.gd Function List

This document lists all functions in the `scripts/domino/domino.gd` file.

**Version**: 0.5.0 - Updated with drag-drop restrictions and source detection

## Public Functions

### 1. `_ready() -> void`
- **Purpose**: Godot lifecycle method called when domino is added to scene tree
- **Actions**: 
  - Sets initial texture using `set_dots()`
  - Initializes orientation label reference
  - Sets mouse filter and pivot point

### 2. `set_pivot_to_center() -> void`
- **Purpose**: Helper to set pivot point to center of domino for proper rotation
- **Actions**: Calculates center point and sets `pivot_offset`

### 3. `_init(left := 0, right := 0) -> void`
- **Purpose**: Constructor that initializes domino with dot values
- **Parameters**: 
  - `left`: Left side dot count (default 0)
  - `right`: Right side dot count (default 0)
- **Actions**: Creates new `DominoData` instance

### 4. `get_preview() -> Control`
- **Purpose**: Creates preview control for drag and drop operations
- **Returns**: `ColorRect` with appropriate texture and sizing
- **Behavior**: Shows front texture if face up, back texture if face down

### 5. `_get_drag_data(_at_position: Vector2) -> Variant`
- **Purpose**: Godot drag-and-drop handler with source-based restrictions
- **Returns**: `self` if drag allowed, `null` if blocked
- **New Features (v0.5.0)**:
  - Detects source container type using `_get_source_type()`
  - Blocks dragging from trains and stations
  - Stores source metadata for drop validation
  - Enforces realistic game movement rules

### 6. `_get_source_type() -> String` **[NEW in v0.5.0]**
- **Purpose**: Identify the container type holding this domino
- **Returns**: String identifying source: "boneyard", "hand", "train", "station", or "unknown"
- **Logic**:
  - Traverses parent hierarchy to identify container type
  - Checks for specific node names and method signatures
  - Used by drag-drop system to enforce movement restrictions

### 7. `highlight(is_on: bool = true) -> void`
- **Purpose**: Highlight or unhighlight the domino
- **Parameters**: `is_on`: Whether to highlight (default true)
- **Note**: Currently only sets internal flag, visual highlighting not implemented

### 8. `set_face_up(is_on: bool = true) -> void`
- **Purpose**: Set whether domino shows front (dots) or back texture
- **Parameters**: `is_on`: Whether to show front (default true)
- **Actions**:
  - Updates data model
  - Controls front/back texture visibility
  - Adjusts sizing based on current orientation

### 9. `get_dots() -> Vector2i`
- **Purpose**: Get the dot values on this domino
- **Returns**: `Vector2i` with x=larger value, y=smaller value

### 10. `set_dots(p_left: int, p_right: int) -> void`
- **Purpose**: Set the dot values and update front texture
- **Parameters**: 
  - `p_left`: Left side dot count
  - `p_right`: Right side dot count
- **Actions**:
  - Stores dots with larger value first
  - Loads oriented texture using `get_texture_path_for_orientation()`

### 11. `get_texture_path_for_orientation() -> String`
- **Purpose**: Get the correct oriented SVG texture path
- **Returns**: Path to oriented texture file
- **Behavior**: 
  - Always returns oriented paths (never bare domino files)
  - Includes resource existence checking
  - Falls back to domino-back.svg if oriented texture missing

### 12. `toggle_dots() -> void`
- **Purpose**: Toggle between face up and face down
- **Actions**: Calls `set_face_up()` with opposite of current state

### 13. `_on_domino_dropped(target: Domino, dropped: Domino) -> void`
- **Purpose**: Handler for domino_dropped signal
- **Parameters**:
  - `target`: Domino being dropped onto
  - `dropped`: Domino being dropped
- **Actions**: Re-emits the signal (can be overridden in subclasses)

### 14. `set_orientation(orientation: int) -> void`
- **Purpose**: Set the visual and logical orientation of the domino
- **Parameters**: `orientation`: One of DominoData orientation constants
- **Actions**:
  - Updates data model orientation
  - Reorders dots (largest first)
  - Loads appropriate oriented texture
  - Adjusts sizing for horizontal/vertical orientations
  - Updates orientation label text and position

### 15. `toggle_orientation_label(value: Variant = null) -> void`
- **Purpose**: Toggle or set the visibility of orientation label overlay
- **Parameters**: `value`: Optional boolean to set specific state (null toggles)
- **Note**: Should only be called from external scripts (test scripts, etc.)

## Private Functions

### 16. `_update_orientation_label_position(orientation: int) -> void`
- **Purpose**: Position and align orientation label based on domino orientation
- **Parameters**: `orientation`: One of DominoData orientation constants
- **Actions**:
  - Sets anchor points and offsets for label positioning
  - Places labels in appropriate corners:
    - LEFT orientation: label at top-right
    - RIGHT orientation: label at top-left  
    - TOP orientation: label at bottom-right
    - BOTTOM orientation: label at top-right

## Properties and Signals

### Properties
- `data: DominoData` - The data model for this domino
- `imgpath: String` - Template for bare domino texture paths (legacy)
- `imgpath_oriented: String` - Template for oriented domino texture paths
- `show_orientation_label: bool` - Controls orientation label visibility
- `old_modulate: Color` - Stored original modulate value
- `is_highlighted: bool` - Whether domino is currently highlighted

### Signals
- `mouse_right_pressed(p_domino: Domino)` - Emitted on right mouse button press
- `domino_dropped(target: Domino, dropped: Domino)` - Emitted when domino dropped onto this one

## Node References
- `back: TextureRect` - Back texture display node
- `front: TextureRect` - Front texture display node  
- `container: CenterContainer` - Container for texture nodes
- `orientation_label: Label` - Optional orientation overlay label

## Constants
- `ORIENTATION_COLORS` - Debug color mapping for orientation visualization

---

**Total Functions: 16** (14 public, 3 private/lifecycle)
