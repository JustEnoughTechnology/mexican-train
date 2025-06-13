# Domino.gd Call Tree

This document shows the function call relationships within the
`scripts/domino/domino.gd` file.

## Call Tree Diagram

```text
_ready()
├── set_dots()
│   ├── get_texture_path_for_orientation()
│   └── front.set_texture()
└── set_pivot_to_center()

_init()
└── DominoData.new()

get_preview()
├── get_texture_path_for_orientation() (if face up)
└── ColorRect.new() + TextureRect.new()

_get_drag_data()
├── get_preview()
│   └── get_texture_path_for_orientation()
├── set_drag_preview()
└── get_tree().set_meta()

set_face_up()
└── (no internal function calls)

set_dots()
├── get_texture_path_for_orientation()
└── front.set_texture()

get_texture_path_for_orientation()
├── ResourceLoader.exists()
└── (string formatting operations)

toggle_dots()
└── set_face_up()

set_orientation()
├── set_dots()
│   ├── get_texture_path_for_orientation()
│   └── front.set_texture()
├── get_texture_path_for_orientation()
├── front.set_texture()
└── _update_orientation_label_position()

toggle_orientation_label()
└── (no internal function calls)

_update_orientation_label_position()
└── (anchor/offset positioning operations)
```

## Function Dependencies

### Primary Entry Points

- **`_ready()`** - Godot lifecycle, initializes domino state
- **`_init()`** - Constructor, creates data model
- **`_get_drag_data()`** - Drag and drop handler

### Core Functionality Chains

#### 1. **Texture Loading Chain**

```text
set_dots() → get_texture_path_for_orientation() → ResourceLoader.exists()
```

#### 2. **Orientation Setting Chain**

```text
set_orientation() → set_dots() → get_texture_path_for_orientation()
                 → _update_orientation_label_position()
```

#### 3. **Preview Creation Chain**

```text
_get_drag_data() → get_preview() → get_texture_path_for_orientation()
```

#### 4. **Face Toggle Chain**

```text
toggle_dots() → set_face_up()
```

### Function Call Statistics

| Function | Calls Other Functions | Called By Other Functions |
|----------|----------------------|---------------------------|
| `_ready()` | 2 | 0 (Godot lifecycle) |
| `set_dots()` | 2 | 3 (`_ready()`, `set_orientation()`, `set_orientation()`) |
| `get_texture_path_for_orientation()` | 1 | 4 functions |
| `set_orientation()` | 4 | 0 (external calls only) |
| `get_preview()` | 1 | 1 (`_get_drag_data()`) |
| `_get_drag_data()` | 3 | 0 (Godot drag system) |
| `toggle_dots()` | 1 | 0 (external calls only) |
| `set_face_up()` | 0 | 1 (`toggle_dots()`) |
| `toggle_orientation_label()` | 0 | 0 (external calls only) |
| `_update_orientation_label_position()` | 0 | 1 (`set_orientation()`) |

## Key Patterns

### 1. **Texture Path Resolution**

Most visual updates flow through `get_texture_path_for_orientation()`:

- `set_dots()` → texture loading
- `get_preview()` → drag preview texture
- `set_orientation()` → orientation-specific texture

### 2. **Orientation Updates**

`set_orientation()` is the most complex function, calling:

- `set_dots()` (which calls `get_texture_path_for_orientation()`)
- `get_texture_path_for_orientation()` (directly)
- `_update_orientation_label_position()`

### 3. **Lifecycle Flow**

```text
_init() → _ready() → set_dots() → get_texture_path_for_orientation()
```

### 4. **No Circular Dependencies**

The call tree is acyclic - no function calls itself or creates circular call chains.

### 5. **External Interface Functions**

These functions are designed to be called from outside:

- `set_dots()`
- `set_orientation()`
- `set_face_up()`
- `toggle_dots()`
- `toggle_orientation_label()`
- `get_dots()`
- `get_preview()`
- `highlight()`

### 6. **Internal Helper Functions**

These functions support internal operations:

- `get_texture_path_for_orientation()`
- `_update_orientation_label_position()`
- `set_pivot_to_center()`

## Notes

- **`get_texture_path_for_orientation()`** is the most frequently called
  function (4 callers)
- **`set_orientation()`** has the deepest call chain (4 levels deep)
- **Error handling** is present in `get_texture_path_for_orientation()`
  with fallback textures
- **Resource validation** occurs in `get_texture_path_for_orientation()`
  via `ResourceLoader.exists()`
- **Signal emissions** occur in `_on_domino_dropped()` but don't call
  other internal functions

---

**Total Internal Function Calls: 23** across the 15 functions
